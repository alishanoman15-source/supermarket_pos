// staff-password-reset (SPEC §66, §83) — lets a `users.manage` holder set a
// new password for a team member's auth account.
//
// Why this exists: an invited member can lose the password chosen while
// accepting the invite, and Supabase's email reset link only lands somewhere
// usable once SMTP + redirect URLs are configured (BACKEND_SETUP.md §16).
// The owner can therefore reset it directly from the Team screen.
//
// Contract
//   POST /functions/v1/staff-password-reset
//   Authorization: Bearer <user jwt>
//   { "user_id": "uuid", "password": "new secret" }
//
// Requires `users.manage` AND the target profile must belong to the caller's
// business. The password itself is never logged, audited or returned.

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
  user_id?: string;
  password?: string;
}

const MIN_LENGTH = 8;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return cors();
  if (req.method !== "POST") return fail("METHOD_NOT_ALLOWED", "use POST", 405);

  const { caller, error: callerError } = await resolveCaller(req);
  if (!caller) return callerError!;
  const permissionError = await requirePermission(caller, "users.manage");
  if (permissionError) return permissionError;

  const { body, error: bodyError } = await readJson<Payload>(req);
  if (!body) return bodyError!;

  const userId = (body.user_id ?? "").trim();
  const password = body.password ?? "";

  if (!userId) return fail("VALIDATION_FAILED", "user_id is required");
  if (password.length < MIN_LENGTH) {
    return fail(
      "VALIDATION_FAILED",
      `password must be at least ${MIN_LENGTH} characters`,
    );
  }

  const { admin } = clients();

  // The target must be a member of the caller's business (never trust an id).
  const { data: profile, error: profileError } = await admin
    .from("profiles")
    .select("id, auth_user_id, business_id, name")
    .eq("id", userId)
    .maybeSingle();
  if (profileError) return fail("INTERNAL", profileError.message, 500);
  if (!profile) return fail("NOT_FOUND", "no such team member", 404);
  if (profile.business_id !== caller.businessId) {
    return fail("VALIDATION_FAILED", "user does not belong to your business", 400);
  }

  const authAdmin = (admin.auth as unknown as { admin: Record<string, Function> })
    .admin;
  if (typeof authAdmin.updateUserById !== "function") {
    return fail("INTERNAL", "auth admin api unavailable", 500);
  }

  const target = profile.auth_user_id ?? profile.id;
  const res = (await authAdmin.updateUserById(target, {
    password,
  })) as { error?: { message?: string } };
  if (res?.error) return fail("INTERNAL", res.error.message ?? "update failed", 500);

  // Audit trail (SPEC §58) — records WHO reset WHICH account, never the value.
  await admin.rpc("write_audit", {
    p_business: caller.businessId,
    p_branch: caller.branchId,
    p_action: "user.password_reset",
    p_table: "profiles",
    p_row_id: target,
    p_before: null,
    p_after: { name: profile.name },
  });

  return json({ ok: true, data: { user_id: target } });
});
