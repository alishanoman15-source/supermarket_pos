// staff-invite (SPEC §83, §93) — creates an auth user for a new employee and
// links their profile to this business with the requested role.
//
// Contract
//   POST /functions/v1/staff-invite
//   Authorization: Bearer <user jwt>
//   { "email": "x@y.z", "name": "Ali", "role_id": "uuid", "role_key": "cashier", "branch_id": "uuid?" }
//
// Requires `users.manage`. The `service_role` key never leaves the server
// (SPEC §56) — this is the only sanctioned way to create staff accounts.

import {
  clients,
  cors,
  fail,
  json,
  readJson,
  requirePermission,
  resolveCaller,
} from "../_shared/http.ts";

interface Payload {
  email?: string;
  name?: string;
  role_id?: string;
  role_key?: string;
  branch_id?: string | null;
  phone?: string | null;
}

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return cors();
  if (req.method !== "POST") return fail("METHOD_NOT_ALLOWED", "use POST", 405);

  const { caller, error: callerError } = await resolveCaller(req);
  if (!caller) return callerError!;
  const permissionError = await requirePermission(caller, "users.manage");
  if (permissionError) return permissionError;

  const { body, error: bodyError } = await readJson<Payload>(req);
  if (!body) return bodyError!;

  const email = (body.email ?? "").trim().toLowerCase();
  const name = (body.name ?? "").trim();
  const roleId = (body.role_id ?? "").trim();
  const roleKey = (body.role_key ?? "").trim();

  if (!EMAIL_RE.test(email)) {
    return fail("VALIDATION_FAILED", "a valid email address is required");
  }
  if (!name) return fail("VALIDATION_FAILED", "name is required");
  if (!roleId && !roleKey) {
    return fail("VALIDATION_FAILED", "role_id or role_key is required");
  }

  const { admin } = clients();

  // The role must belong to this business (never trust a caller-supplied id).
  let roleQuery = admin
    .from("roles")
    .select("id, key, name")
    .eq("business_id", caller.businessId);
  roleQuery = roleId ? roleQuery.eq("id", roleId) : roleQuery.eq("key", roleKey);
  const { data: role, error: roleError } = await roleQuery.maybeSingle();
  if (roleError) return fail("INTERNAL", roleError.message, 500);
  if (!role) {
    return fail(
      "VALIDATION_FAILED",
      `unknown role '${roleId || roleKey}'`,
      400,
    );
  }

  if (body.branch_id) {
    const { data: branch } = await admin
      .from("branches")
      .select("id")
      .eq("business_id", caller.businessId)
      .eq("id", body.branch_id)
      .maybeSingle();
    if (!branch) return fail("VALIDATION_FAILED", "branch does not belong to this business", 400);
  }

  // 1. Create the auth user (invite email when SMTP is configured, otherwise a
  //    plain account the person can activate with "forgot password").
  const authAdmin = (admin.auth as unknown as { admin: Record<string, Function> }).admin;
  let userId: string | null = null;
  let lastError: string | null = null;
  // True when the account was created through the invite API: the person has
  // not accepted yet, so the profile stays 'invited' (not usable in the app)
  // until they click the emailed link. The fallback below confirms the email
  // immediately, so that account is usable straight away.
  let pendingInvite = false;

  const metadata = {
    full_name: name,
    business_id: caller.businessId,
    invited_by: caller.userId,
  };

  // Prefer the invite API (it emails a set-password link); fall back to a
  // plain confirmed account when the deployment has no SMTP configured.
  const inviteFn = authAdmin.inviteUserWithEmail ?? authAdmin.inviteUserByEmail;
  if (typeof inviteFn === "function") {
    try {
      const res = (await inviteFn.call(authAdmin, email, {
        data: metadata,
        redirectTo: Deno.env.get("SITE_URL") ?? "",
      })) as { data?: { user?: { id?: string } }; error?: { message?: string } };
      if (res?.error) {
        lastError = res.error.message ?? "invite failed";
      } else {
        userId = res?.data?.user?.id ?? null;
        pendingInvite = userId != null;
      }
    } catch (e) {
      lastError = e instanceof Error ? e.message : String(e);
    }
  }

  if (!userId) {
    if (typeof authAdmin.createUser !== "function") {
      return fail("INTERNAL", "auth admin api unavailable", 500);
    }
    const res = (await authAdmin.createUser({
      email,
      email_confirm: true,
      user_metadata: metadata,
      app_metadata: { business_id: caller.businessId },
    })) as { data?: { user?: { id?: string } }; error?: { message?: string } };
    if (res?.error) {
      const message = res.error.message ?? "could not create the account";
      if (/already/i.test(message)) {
        return fail("DUPLICATE", "that email is already registered", 409);
      }
      return fail("INTERNAL", message, 500);
    }
    userId = res?.data?.user?.id ?? null;
  }

  if (!userId) {
    return fail("INTERNAL", lastError ?? "could not create the account", 500);
  }

  // 2. Link the profile (the auth.users trigger already created the row).
  const { error: profileError } = await admin
    .from("profiles")
    .update({
      auth_user_id: userId,
      business_id: caller.businessId,
      branch_id: body.branch_id ?? caller.branchId,
      role_id: role.id,
      name,
      phone: body.phone ?? null,
      status: pendingInvite ? "invited" : "active",
      updated_at: new Date().toISOString(),
    })
    .eq("id", userId);
  if (profileError) return fail("INTERNAL", profileError.message, 500);

  // 3. Audit trail (SPEC §58).
  await admin.rpc("write_audit", {
    p_business: caller.businessId,
    p_branch: caller.branchId,
    p_action: "user.invite",
    p_table: "profiles",
    p_row_id: userId,
    p_before: null,
    p_after: {
      email,
      name,
      role_key: role.key,
      role_name: role.name,
      branch_id: body.branch_id ?? null,
      status: pendingInvite ? "invited" : "active",
    },
  });

  return json({
    ok: true,
    data: {
      user_id: userId,
      profile_id: userId,
      role_key: roleKey,
    },
  });
});
