#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

tests=(
  "$ROOT/claude-subagent-skill/scripts/smoke-test.sh"
  "$ROOT/codex-subagent-skill/scripts/smoke-test.sh"
  "$ROOT/copilot-subagent-skill/scripts/smoke-test.sh"
  "$ROOT/cursor-subagent-skill/scripts/smoke-test.sh"
)

for test_script in "${tests[@]}"; do
  echo "==> $(basename "$(dirname "$(dirname "$test_script")")")"
  bash "$test_script"
  echo
done

echo "All CLI subagent smoke tests passed."
