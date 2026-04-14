#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> claude contract"
claude_json="$("$ROOT/claude-subagent-skill/skills/claude-subagent/scripts/claude-result" --json --cwd "$ROOT/claude-subagent-skill" exec "Reply with exactly: contract-ok")"
[[ "$(printf '%s\n' "$claude_json" | jq -r '.result')" == "contract-ok" ]]
[[ -n "$(printf '%s\n' "$claude_json" | jq -r '.session_id')" ]]

echo "==> codex contract"
codex_tmp="$(mktemp /tmp/codex-contract.XXXXXX.jsonl)"
trap 'rm -f "$codex_tmp"' EXIT
(
  cd "$ROOT/codex-subagent-skill"
  codex exec --json "Reply with exactly: contract-ok" </dev/null >"$codex_tmp"
)
[[ "$("$ROOT/codex-subagent-skill/skills/codex-subagent/scripts/codex-result" last "$codex_tmp")" == "contract-ok" ]]
[[ -n "$("$ROOT/codex-subagent-skill/skills/codex-subagent/scripts/codex-result" session-id "$codex_tmp" | tail -1)" ]]

echo "==> copilot contract"
copilot_json="$(
  cd "$ROOT/copilot-subagent-skill"
  "$ROOT/copilot-subagent-skill/skills/copilot-subagent/scripts/copilot-result" --json exec "Reply with exactly: contract-ok" --allow-all
)"
[[ "$(printf '%s\n' "$copilot_json" | jq -r '.result')" == "contract-ok" ]]
[[ -n "$(printf '%s\n' "$copilot_json" | jq -r '.session_id')" ]]

echo "==> cursor contract"
cursor_json="$("$ROOT/cursor-subagent-skill/skills/cursor-subagent/scripts/cursor-result" --json --cwd "$ROOT/cursor-subagent-skill" exec "Reply with exactly: contract-ok")"
[[ "$(printf '%s\n' "$cursor_json" | jq -r '.result')" == "contract-ok" ]]
[[ -n "$(printf '%s\n' "$cursor_json" | jq -r '.session_id')" ]]

echo "All runtime contract tests passed."
