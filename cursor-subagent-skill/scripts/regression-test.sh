#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$ROOT/skills/cursor-subagent/scripts/cursor-result"

trim() {
  perl -0pe 's/^\s+//; s/\s+$//'
}

echo "==> model matrix"
for model in claude-4.6-sonnet-medium gpt-5.4-medium composer-2-fast; do
  json="$("$HELPER" --json --cwd "$ROOT" exec "Reply with exactly: model-ok" --model "$model")"
  [[ "$(printf '%s\n' "$json" | jq -r '.result' | trim)" == "model-ok" ]]
  [[ -n "$(printf '%s\n' "$json" | jq -r '.session_id')" ]]
done

echo "==> read"
read_json="$("$HELPER" --json --cwd "$ROOT" exec "Read README.md and answer in one sentence what this package is.")"
read_sid="$(printf '%s\n' "$read_json" | jq -r '.session_id')"
[[ -n "$("$HELPER" --cwd "$ROOT" tools "$read_sid")" ]]
[[ -n "$("$HELPER" --cwd "$ROOT" summary "$read_sid")" ]]

echo "==> ask mode"
ask_json="$("$HELPER" --json --cwd "$ROOT" exec "Explain in one sentence what scripts/smoke-test.sh does." --mode ask)"
ask_sid="$(printf '%s\n' "$ask_json" | jq -r '.session_id')"
[[ -n "$(printf '%s\n' "$ask_json" | jq -r '.result')" ]]
[[ -n "$("$HELPER" --cwd "$ROOT" summary "$ask_sid")" ]]

echo "==> plan mode"
plan_json="$("$HELPER" --json --cwd "$ROOT" exec "Review scripts/smoke-test.sh and report either one real issue or exactly 'no issues found'." --mode plan)"
plan_sid="$(printf '%s\n' "$plan_json" | jq -r '.session_id')"
[[ -n "$(printf '%s\n' "$plan_json" | jq -r '.result')" ]]
[[ -n "$("$HELPER" --cwd "$ROOT" summary "$plan_sid")" ]]

echo "==> command extraction"
cmd_json="$("$HELPER" --json --cwd "$ROOT" exec "Run pwd and then reply with exactly done.")"
cmd_sid="$(printf '%s\n' "$cmd_json" | jq -r '.session_id')"
cmds="$("$HELPER" --cwd "$ROOT" commands "$cmd_sid")"
[[ "$cmds" == *"pwd"* ]]

echo "==> write"
rm -f /tmp/cursor-regression-write.txt
write_json="$("$HELPER" --json --cwd "$ROOT" exec "Write the exact text cursor regression ok followed by a newline to /tmp/cursor-regression-write.txt, verify it by reading the file, then reply with exactly done.")"
[[ "$(printf '%s\n' "$write_json" | jq -r '.result' | trim)" == "done" ]]
[[ "$(cat /tmp/cursor-regression-write.txt)" == "cursor regression ok" ]]

echo "==> resume"
resume_base="$("$HELPER" --json --cwd "$ROOT" exec "Reply with exactly: resume-base-ok")"
resume_sid="$(printf '%s\n' "$resume_base" | jq -r '.session_id')"
resume_out="$("$HELPER" --cwd "$ROOT" exec "Reply with exactly: resume-ok" --resume "$resume_sid")"
[[ "$(printf '%s\n' "$resume_out" | trim)" == "resume-ok" ]]

echo "==> parallel"
out_a=/tmp/cursor-regression-a.out
out_b=/tmp/cursor-regression-b.out
rm -f "$out_a" "$out_b"
"$HELPER" --cwd "$ROOT" exec "Reply with exactly: par-a" >"$out_a" 2>/dev/null &
PID_A=$!
"$HELPER" --cwd "$ROOT" exec "Reply with exactly: par-b" >"$out_b" 2>/dev/null &
PID_B=$!
wait $PID_A $PID_B
[[ "$(cat "$out_a" | trim)" == "par-a" ]]
[[ "$(cat "$out_b" | trim)" == "par-b" ]]

echo "Cursor regression tests passed."
