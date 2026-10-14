#!/usr/bin/env bash
# Runs a SQL statement against the linked remote project via the Supabase
# Management API. Reads SQL from stdin. Contains no secrets itself.
# Usage: echo "select 1" | scripts/sql.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TOKEN="$(grep '^SUPABASE_ACCESS_TOKEN=' .env | cut -d= -f2- | tr -d '\r')"
REF="$(grep '^SUPABASE_PROJECT_REF=' .env | cut -d= -f2- | tr -d '\r')"

BODY="$(node -e 'const fs=require("fs");const q=fs.readFileSync(0,"utf8");process.stdout.write(JSON.stringify({query:q}))')"

curl -sS -X POST "https://api.supabase.com/v1/projects/${REF}/database/query" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  --data-binary "$BODY"
echo
