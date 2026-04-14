#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$ROOT/skills/claude-subagent/scripts/claude-result"

json="$("$HELPER" --json --cwd "$ROOT" exec "Reply with exactly: smoke-ok")"
out="$(printf '%s\n' "$json" | jq -r '.result')"
sid="$(printf '%s\n' "$json" | jq -r '.session_id')"
if [[ "$out" != "smoke-ok" ]]; then
  echo "claude smoke test failed: unexpected output: $out" >&2
  exit 1
fi
if [[ -z "$sid" ]]; then
  echo "claude smoke test failed: missing session id" >&2
  exit 1
fi

echo "claude smoke test passed ($sid)"
