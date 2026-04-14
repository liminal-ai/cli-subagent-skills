#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$ROOT/skills/cursor-subagent/scripts/cursor-result"

json="$("$HELPER" --json --cwd "$ROOT" exec "Reply with exactly: smoke-ok")"
out="$(printf '%s\n' "$json" | jq -r '.result' | perl -0pe 's/^\s+//; s/\s+$//')"
sid="$(printf '%s\n' "$json" | jq -r '.session_id')"
if [[ "$out" != "smoke-ok" ]]; then
  echo "cursor smoke test failed: unexpected output: $out" >&2
  exit 1
fi
if [[ -z "$sid" ]]; then
  echo "cursor smoke test failed: missing session id" >&2
  exit 1
fi

echo "cursor smoke test passed ($sid)"
