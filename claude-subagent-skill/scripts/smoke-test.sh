#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$ROOT/skills/claude-subagent/scripts/claude-result"

out="$("$HELPER" --cwd "$ROOT" exec "Reply with exactly: smoke-ok")"
if [[ "$out" != "smoke-ok" ]]; then
  echo "claude smoke test failed: unexpected output: $out" >&2
  exit 1
fi

sid="$("$HELPER" --cwd "$ROOT" session-id)"
if [[ -z "$sid" ]]; then
  echo "claude smoke test failed: missing session id" >&2
  exit 1
fi

echo "claude smoke test passed ($sid)"
