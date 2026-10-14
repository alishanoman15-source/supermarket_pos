#!/usr/bin/env bash
# Runs every pgTAP suite in supabase/tests against the linked remote project
# via the Supabase Management API. Works without Docker (unlike `supabase test db`).
# Each suite is self-contained: it opens a transaction, asserts, and rolls back.
#
# A suite fails the build when the API returns an error object (the suites raise
# on any failing assertion via num_failed()).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail=0
shopt -s nullglob
for f in supabase/tests/*.sql; do
  name="$(basename "$f")"
  out="$(./scripts/sql.sh < "$f" 2>&1)"
  if [[ "$out" == *'"message"'* ]]; then
    echo "FAIL  $name"
    echo "      $out"
    fail=1
  else
    echo "PASS  $name"
  fi
done

if [[ $fail -eq 0 ]]; then
  echo "All backend suites passed."
else
  echo "Backend suites FAILED." >&2
fi
exit $fail
