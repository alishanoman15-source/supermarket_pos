#!/usr/bin/env bash
# Configures a custom SMTP provider and applies the OTP + staff-invite email
# templates on the linked Supabase project (BACKEND_SETUP.md §16).
#
# Why: free-tier projects on the default Supabase email provider reject every
# template edit (HTTP 400), so the sign-in email keeps mailing a magic link
# instead of the 6-digit code the app expects. Custom SMTP lifts that limit.
#
# Required .env keys (gitignored — never commit them):
#   SMTP_HOST=smtp.gmail.com
#   SMTP_PORT=465
#   SMTP_USER=you@gmail.com
#   SMTP_PASS=16-char-app-password      # Google Account -> App passwords
#   SMTP_SENDER_NAME=Supermarket POS
#   SMTP_ADMIN_EMAIL=you@gmail.com
#
# Usage: scripts/configure_email.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
mkdir -p .tmpdbg

REF="$(grep '^SUPABASE_PROJECT_REF=' .env | cut -d= -f2- | tr -d '\r')"
TOKEN="$(grep '^SUPABASE_ACCESS_TOKEN=' .env | cut -d= -f2- | tr -d '\r')"

get() { grep "^$1=" .env | cut -d= -f2- | tr -d '\r'; }

missing=0
for key in SMTP_HOST SMTP_PORT SMTP_USER SMTP_PASS SMTP_SENDER_NAME SMTP_ADMIN_EMAIL; do
  if [[ -z "$(get "$key")" ]]; then
    echo "Missing $key in .env — see the header of scripts/configure_email.sh" >&2
    missing=1
  fi
done
[[ $missing -eq 0 ]] || exit 1

patch() { # $1 = json payload file, $2 = human label
  local code
  code="$(curl -sS --max-time 100 -X PATCH \
    "https://api.supabase.com/v1/projects/${REF}/config/auth" \
    -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" \
    --data-binary @"$1" -o .tmpdbg/email_patch_res.json -w '%{http_code}')"
  if [[ "$code" != "200" ]]; then
    echo "FAILED $2 (HTTP $code):" >&2
    cat .tmpdbg/email_patch_res.json >&2
    echo >&2
    exit 1
  fi
  echo "ok  $2 (HTTP $code)"
}

# 1. SMTP settings (the secret goes straight to Supabase, never to the repo).
SMTP_HOST="$(get SMTP_HOST)" SMTP_PORT="$(get SMTP_PORT)" \
SMTP_USER="$(get SMTP_USER)" SMTP_PASS="$(get SMTP_PASS)" \
SMTP_SENDER_NAME="$(get SMTP_SENDER_NAME)" SMTP_ADMIN_EMAIL="$(get SMTP_ADMIN_EMAIL)" \
node > .tmpdbg/smtp_payload.json <<'JS'
const esc = (s) => String(s ?? "").replace(/[^\w .@:-]/g, "");
process.stdout.write(JSON.stringify({
  smtp_host: process.env.SMTP_HOST,
  smtp_port: Number(process.env.SMTP_PORT) || 465,
  smtp_user: process.env.SMTP_USER,
  smtp_pass: process.env.SMTP_PASS,
  smtp_sender_name: esc(process.env.SMTP_SENDER_NAME),
  smtp_admin_email: process.env.SMTP_ADMIN_EMAIL,
}));
JS
patch .tmpdbg/smtp_payload.json "custom SMTP"

# 2. Templates: 6-digit code for sign-in, descriptive staff invite.
node > .tmpdbg/templates_payload.json <<'JS'
const fs = require("fs");
const magic = fs.readFileSync("supabase/templates/magic_link.html", "utf8");
const invite = fs.readFileSync("supabase/templates/invite.html", "utf8");
process.stdout.write(JSON.stringify({
  mailer_subjects_magic_link: "Your sign-in code",
  mailer_templates_magic_link_content: magic,
  mailer_subjects_invite: "You have been invited to Supermarket POS",
  mailer_templates_invite_content: invite,
}));
JS
patch .tmpdbg/templates_payload.json "OTP + invite templates"

# 3. Verify what actually landed.
curl -sS --max-time 100 "https://api.supabase.com/v1/projects/${REF}/config/auth" \
  -H "Authorization: Bearer ${TOKEN}" -o .tmpdbg/auth_config.json
node -e '
const j = require("./.tmpdbg/auth_config.json");
const tpl = j.mailer_templates_magic_link_content || "";
console.log("smtp:", j.smtp_host ? `${j.smtp_host}:${j.smtp_port} as ${j.smtp_user}` : "NOT SET");
console.log("otp code in email:", tpl.includes("{{ .Token }}") ? "yes" : "NO");
console.log("magic link removed:", tpl.includes("ConfirmationURL") ? "NO" : "yes");
if (!j.smtp_host || !tpl.includes("{{ .Token }}")) process.exit(1);
'
echo "Email setup complete. Send a test sign-in OTP to confirm delivery."
