// Shared helpers for Supabase Edge Functions (BACKEND_SETUP.md §8):
// CORS, the SPEC §60 `{ok, data | error}` envelope, caller resolution from the
// request JWT, and a permission check that mirrors `has_permission()` in Postgres.
//
// Import relatively: `import { json } from "../_shared/http.ts";`

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

export const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-client-name",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export type Envelope =
  | { ok: true; data: unknown }
  | { ok: false; error: { code: string; message: string; details?: unknown } };

export function json(body: Envelope, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

export function cors(): Response {
  return new Response("ok", { status: 200, headers: CORS_HEADERS });
}

export function fail(code: string, message: string, status = 400, details?: unknown): Response {
  return json({ ok: false, error: { code, message, details } }, status);
}

/** Supabase clients: the service-role client does the work, the anon client
 *  resolves the caller from the incoming JWT. */
export function clients() {
  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const admin = createClient(url, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const anon = createClient(url, anonKey, {
    global: { headers: { Authorization: "" } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  return { admin, anon };
}

export interface Caller {
  userId: string;
  profileId: string;
  businessId: string;
  branchId: string | null;
  roleId: string | null;
}

/** Resolves the authenticated user and their profile row. Returns an error
 *  Response instead of a Caller when the caller may not proceed. */
export async function resolveCaller(
  req: Request,
): Promise<{ caller?: Caller; error?: Response }> {
  const header = req.headers.get("Authorization") ?? "";
  const token = header.replace(/^Bearer\s+/i, "").trim();
  if (!token) return { error: fail("UNAUTHENTICATED", "missing bearer token", 401) };

  const { admin } = clients();
  const { data, error } = await admin.auth.getUser(token);
  if (error || !data?.user) {
    return { error: fail("UNAUTHENTICATED", "invalid or expired session", 401) };
  }

  const { data: profile, error: profileError } = await admin
    .from("profiles")
    .select("id, auth_user_id, business_id, branch_id, role_id, status")
    .eq("auth_user_id", data.user.id)
    .maybeSingle();

  if (profileError) return { error: fail("INTERNAL", profileError.message, 500) };
  if (!profile) return { error: fail("NO_BUSINESS", "no profile for this account", 403) };
  if (profile.status !== "active") {
    return { error: fail("ACCOUNT_DISABLED", "this account is deactivated", 403) };
  }
  if (!profile.business_id) {
    return { error: fail("NO_BUSINESS", "account is not linked to a business yet", 403) };
  }

  return {
    caller: {
      userId: data.user.id,
      profileId: profile.id as string,
      businessId: profile.business_id as string,
      branchId: (profile.branch_id as string | null) ?? null,
      roleId: (profile.role_id as string | null) ?? null,
    },
  };
}

/** Mirrors `public.has_permission()` for the caller's role. */
export async function requirePermission(
  caller: Caller,
  key: string,
): Promise<Response | undefined> {
  if (!caller.roleId) return fail("NO_PERMISSION", `missing permission ${key}`, 403);

  const { admin } = clients();
  const { data, error } = await admin
    .from("role_permissions")
    .select("permission:permissions(key)")
    .eq("role_id", caller.roleId);

  if (error) return fail("INTERNAL", error.message, 500);
  const keys = (data ?? [])
    .map((row) => {
      const embedded = (row as { permission?: { key?: string } | { key?: string }[] }).permission;
      if (Array.isArray(embedded)) return embedded.map((p) => p.key ?? "");
      return embedded?.key ?? "";
    })
    .filter(Boolean);

  if (!keys.includes(key)) return fail("NO_PERMISSION", `missing permission ${key}`, 403);
  return undefined;
}

/** Reads the JSON body, rejecting malformed payloads with VALIDATION_FAILED. */
export async function readJson<T>(req: Request): Promise<{ body?: T; error?: Response }> {
  try {
    const body = (await req.json()) as T;
    return { body };
  } catch {
    return { error: fail("VALIDATION_FAILED", "request body must be JSON", 400) };
  }
}
