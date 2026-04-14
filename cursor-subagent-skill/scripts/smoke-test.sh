#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$ROOT/skills/cursor-subagent/scripts/cursor-result"

out="$("$HELPER" --cwd "$ROOT" exec "Reply with exactly: smoke-ok")"
if [[ "$out" != "smoke-ok" ]]; then
  echo "cursor smoke test failed: unexpected output: $out" >&2
  exit 1
fi

sid="$("$HELPER" --cwd "$ROOT" session-id)"
if [[ -z "$sid" ]]; then
  echo "cursor smoke test failed: missing session id" >&2
  exit 1
fi

echo "cursor smoke test passed ($sid)"
