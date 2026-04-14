#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$ROOT/skills/codex-subagent/scripts/codex-result"
TMP_JSONL="$(mktemp /tmp/codex-smoke.XXXXXX.jsonl)"
TMP_ERR="$(mktemp /tmp/codex-smoke.XXXXXX.err)"

trap 'rm -f "$TMP_JSONL" "$TMP_ERR"' EXIT

(
  cd "$ROOT"
  codex exec --json "Reply with exactly: smoke-ok" </dev/null >"$TMP_JSONL" 2>"$TMP_ERR"
)

out="$("$HELPER" last "$TMP_JSONL")"
if [[ "$out" == \"*\" ]]; then
  out="$(printf '%s\n' "$out" | jq -r .)"
fi
if [[ "$out" != "smoke-ok" ]]; then
  echo "codex smoke test failed: unexpected output: $out" >&2
  exit 1
fi

sid="$("$HELPER" session-id "$TMP_JSONL" | tail -1)"
if [[ -z "$sid" ]]; then
  echo "codex smoke test failed: missing session id" >&2
  exit 1
fi

echo "codex smoke test passed ($sid)"
