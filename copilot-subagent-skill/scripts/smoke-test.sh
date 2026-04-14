#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$ROOT/skills/copilot-subagent/scripts/copilot-result"

out="$(
  cd "$ROOT"
  "$HELPER" exec "Reply with exactly: smoke-ok" --allow-all
)"
if [[ "$out" != "smoke-ok" ]]; then
  echo "copilot smoke test failed: unexpected output: $out" >&2
  exit 1
fi

sid="$("$HELPER" session-id)"
if [[ -z "$sid" ]]; then
  echo "copilot smoke test failed: missing session id" >&2
  exit 1
fi

echo "copilot smoke test passed ($sid)"
