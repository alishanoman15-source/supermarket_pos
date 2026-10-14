#!/usr/bin/env bash
# Loads Supabase credentials from the gitignored .env and runs the Supabase CLI.
# Contains no secrets itself. Usage: scripts/sb.sh <supabase args...>
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -f .env ]]; then
  echo "Missing .env (see README.md for required keys)" >&2
  exit 1
fi

export SUPABASE_ACCESS_TOKEN="$(grep '^SUPABASE_ACCESS_TOKEN=' .env | cut -d= -f2- | tr -d '\r')"
export SUPABASE_PROJECT_REF="$(grep '^SUPABASE_PROJECT_REF=' .env | cut -d= -f2- | tr -d '\r')"
export SUPABASE_DB_PASSWORD="$(grep '^SUPABASE_DB_PASSWORD=' .env | cut -d= -f2- | tr -d '\r')"

exec supabase "$@"
