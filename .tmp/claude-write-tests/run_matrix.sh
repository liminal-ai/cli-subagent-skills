#!/usr/bin/env bash
set -u

TEST_ROOT="/Users/leemoore/code/cli-as-subagent-skills/.tmp/claude-write-tests"
HELPER="$HOME/.claude/skills/claude-subagent/scripts/claude-result"
ALLOWED_TOOLS="Read,Write,Edit,Bash,Grep,Glob"
RUN_TIMEOUT_SECS=180

mkdir -p "$TEST_ROOT/results" "$TEST_ROOT/runs"

json_escape() {
  jq -Rs . <<<"${1-}"
}

run_with_timeout() {
  local timeout_secs="$1"
  shift
  "$@" &
  local cmd_pid=$!
  local elapsed=0
  while kill -0 "$cmd_pid" 2>/dev/null; do
    if (( elapsed >= timeout_secs )); then
      kill "$cmd_pid" 2>/dev/null || true
      wait "$cmd_pid" 2>/dev/null || true
      return 124
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done
  wait "$cmd_pid"
  return $?
}

run_one() {
  local model_slug="$1"
  local model_id="$2"
  local mode="$3"
  local runner="$4"

  local run_name="${model_slug}-${mode}"
  if [[ "$runner" == "direct" ]]; then
    run_name="${run_name}-direct"
  fi
  local run_dir="$TEST_ROOT/runs/$run_name"
  local workspace="$run_dir/workspace"
  local outputs_dir="$workspace/outputs/$model_slug/$mode"
  local stdout_file="$run_dir/stdout.txt"
  local stderr_file="$run_dir/stderr.txt"
  local prompt_file="$run_dir/prompt.txt"
  local command_file="$run_dir/command.txt"
  local result_json_file="$run_dir/result.json"
  local validation_file="$run_dir/validation.json"
  local meta_file="$run_dir/meta.json"

  rm -rf "$run_dir"
  mkdir -p "$workspace"
  cp -R "$TEST_ROOT/inputs" "$workspace/"

  mkdir -p "$outputs_dir/nested"

  cat >"$prompt_file" <<EOF
Read inputs/source.txt.
Create outputs/$model_slug/$mode/created.txt containing exactly:
created from source token ALPHA-42

Edit inputs/edit-target.md in place:
- replace the line "PLACEHOLDER: REPLACE_ME" with "PLACEHOLDER: replaced with ALPHA-42"
- append the bullet "- added from source token ALPHA-42"

Create outputs/$model_slug/$mode/nested/result.json containing valid JSON with:
- "sourceToken": "ALPHA-42"
- "status": "written"
- "mode": "$mode"
- "model": "$model_id"

Then return a short summary stating whether each requested write was completed.
EOF

  local prompt
  prompt="$(cat "$prompt_file")"

  local command
  if [[ "$runner" == "helper" ]]; then
    command="$HELPER --cwd $workspace --json exec \"$prompt\" --model $model_id --permission-mode $mode --allowedTools $ALLOWED_TOOLS"
  else
    command="cd $workspace && claude -p --output-format json --model $model_id --permission-mode $mode --allowedTools $ALLOWED_TOOLS -- \"\$PROMPT\""
  fi
  printf '%s\n' "$command" >"$command_file"

  local exit_status=0
  if [[ "$runner" == "helper" ]]; then
    run_with_timeout "$RUN_TIMEOUT_SECS" \
      "$HELPER" --cwd "$workspace" --json exec "$prompt" \
      --model "$model_id" \
      --permission-mode "$mode" \
      --allowedTools "$ALLOWED_TOOLS" \
      >"$stdout_file" 2>"$stderr_file"
    exit_status=$?
  else
    run_with_timeout "$RUN_TIMEOUT_SECS" \
      bash -lc '
        cd "$1" && \
        PROMPT="$2" claude -p --output-format json \
          --model "$3" \
          --permission-mode "$4" \
          --allowedTools "$5" \
          -- "$PROMPT"
      ' bash "$workspace" "$prompt" "$model_id" "$mode" "$ALLOWED_TOOLS" \
      >"$stdout_file" 2>"$stderr_file"
    exit_status=$?
  fi

  local parsed="false"
  local session_id=""
  local agent_claimed_success="false"
  local result_text=""
  local timed_out="false"
  if [[ "$exit_status" -eq 124 ]]; then
    timed_out="true"
  fi
  if jq -e . "$stdout_file" >/dev/null 2>&1; then
    cp "$stdout_file" "$result_json_file"
    parsed="true"
    session_id="$(jq -r '.session_id // empty' "$stdout_file")"
    result_text="$(jq -r '.result // empty' "$stdout_file")"
    if [[ "$(jq -r '.subtype // empty' "$stdout_file")" == "success" && "$(jq -r '.is_error // false' "$stdout_file")" == "false" ]]; then
      agent_claimed_success="true"
    fi
  else
    printf '{}\n' >"$result_json_file"
  fi

  local created_file="$outputs_dir/created.txt"
  local nested_file="$outputs_dir/nested/result.json"
  local edit_file="$workspace/inputs/edit-target.md"

  local created_exists="false"
  local created_matches="false"
  local nested_exists="false"
  local nested_matches="false"
  local edit_matches="false"
  local writes_happened="false"

  [[ -f "$created_file" ]] && created_exists="true"
  [[ -f "$nested_file" ]] && nested_exists="true"

  if [[ "$created_exists" == "true" ]] && grep -Fxq 'created from source token ALPHA-42' "$created_file"; then
    created_matches="true"
  fi

  if [[ "$nested_exists" == "true" ]] && jq -e \
    --arg mode "$mode" \
    --arg model "$model_id" \
    '.sourceToken == "ALPHA-42" and .status == "written" and .mode == $mode and .model == $model' \
    "$nested_file" >/dev/null 2>&1; then
    nested_matches="true"
  fi

  if grep -Fxq -- 'PLACEHOLDER: replaced with ALPHA-42' "$edit_file" && grep -Fxq -- '- added from source token ALPHA-42' "$edit_file"; then
    edit_matches="true"
  fi

  if [[ "$created_exists" == "true" || "$nested_exists" == "true" || "$edit_matches" == "true" ]]; then
    writes_happened="true"
  fi

  local rubric="FAIL"
  if [[ "$agent_claimed_success" == "true" && "$created_matches" == "true" && "$nested_matches" == "true" && "$edit_matches" == "true" ]]; then
    rubric="PASS"
  elif [[ "$agent_claimed_success" == "true" ]]; then
    rubric="FALSE_SUCCESS"
  fi

  jq -n \
    --arg runner "$runner" \
    --arg model_slug "$model_slug" \
    --arg model_id "$model_id" \
    --arg mode "$mode" \
    --arg exit_status "$exit_status" \
    --arg session_id "$session_id" \
    --arg result_text "$result_text" \
    --arg parsed "$parsed" \
    --arg agent_claimed_success "$agent_claimed_success" \
    --arg timed_out "$timed_out" \
    --arg rubric "$rubric" \
    --arg created_exists "$created_exists" \
    --arg created_matches "$created_matches" \
    --arg nested_exists "$nested_exists" \
    --arg nested_matches "$nested_matches" \
    --arg edit_matches "$edit_matches" \
    --arg writes_happened "$writes_happened" \
    --arg stdout_file "$stdout_file" \
    --arg stderr_file "$stderr_file" \
    --arg command_file "$command_file" \
    '{
      runner: $runner,
      model_slug: $model_slug,
      model_id: $model_id,
      mode: $mode,
      exit_status: ($exit_status | tonumber),
      session_id: $session_id,
      parsed_json: ($parsed == "true"),
      agent_claimed_success: ($agent_claimed_success == "true"),
      timed_out: ($timed_out == "true"),
      result_text: $result_text,
      rubric: $rubric,
      validation: {
        created_exists: ($created_exists == "true"),
        created_matches: ($created_matches == "true"),
        nested_exists: ($nested_exists == "true"),
        nested_matches: ($nested_matches == "true"),
        edit_matches: ($edit_matches == "true"),
        writes_happened: ($writes_happened == "true")
      },
      artifacts: {
        stdout_file: $stdout_file,
        stderr_file: $stderr_file,
        command_file: $command_file
      }
    }' >"$meta_file"

  cp "$meta_file" "$validation_file"
}

classify_failure() {
  local helper_meta="$1"
  local direct_meta="$2"
  local helper_rubric
  local direct_rubric
  helper_rubric="$(jq -r '.rubric' "$helper_meta")"
  direct_rubric="$(jq -r '.rubric' "$direct_meta")"

  if [[ "$helper_rubric" == "PASS" ]]; then
    printf 'PASS\n'
  elif [[ "$direct_rubric" == "PASS" ]]; then
    printf 'HELPER_SPECIFIC\n'
  else
    printf 'CLAUDE_WIDE\n'
  fi
}

run_one sonnet claude-sonnet-4-6 acceptEdits helper
run_one sonnet claude-sonnet-4-6 bypassPermissions helper
run_one opus claude-opus-4-6 acceptEdits helper
run_one opus claude-opus-4-6 bypassPermissions helper
run_one haiku claude-haiku-4-5 acceptEdits helper
run_one haiku claude-haiku-4-5 bypassPermissions helper

controls=()
for helper_meta in "$TEST_ROOT"/runs/*/meta.json; do
  helper_rubric="$(jq -r '.rubric' "$helper_meta")"
  helper_writes_complete="$(jq -r '.validation.created_matches and .validation.nested_matches and .validation.edit_matches' "$helper_meta")"
  if [[ "$helper_rubric" == "PASS" || "$helper_writes_complete" == "true" ]]; then
    continue
  fi

  model_slug="$(jq -r '.model_slug' "$helper_meta")"
  model_id="$(jq -r '.model_id' "$helper_meta")"
  mode="$(jq -r '.mode' "$helper_meta")"
  run_one "$model_slug" "$model_id" "$mode" direct
  controls+=("$TEST_ROOT/runs/${model_slug}-${mode}-direct/meta.json")
done

matrix_tmp="$TEST_ROOT/results/matrix.json"
summary_tmp="$TEST_ROOT/results/summary.md"
recommend_tmp="$TEST_ROOT/results/recommendations.md"

{
  printf '[\n'
  first=1
  for helper_meta in "$TEST_ROOT"/runs/*/meta.json; do
    base_name="$(basename "$(dirname "$helper_meta")")"
    if [[ "$base_name" == *"-direct" ]]; then
      continue
    fi

    model_slug="$(jq -r '.model_slug' "$helper_meta")"
    mode="$(jq -r '.mode' "$helper_meta")"
    final_rubric="$(jq -r '.rubric' "$helper_meta")"
    direct_meta="$TEST_ROOT/runs/${model_slug}-${mode}-direct/meta.json"
    if [[ -f "$direct_meta" ]]; then
      final_rubric="$(classify_failure "$helper_meta" "$direct_meta")"
    fi

    entry="$(jq \
      --arg final_rubric "$final_rubric" \
      --argjson helper "$(cat "$helper_meta")" \
      --argjson direct "$(if [[ -f "$direct_meta" ]]; then cat "$direct_meta"; else printf 'null'; fi)" \
      -n '{helper: $helper, direct_control: $direct, final_rubric: $final_rubric}')"
    if [[ $first -eq 0 ]]; then
      printf ',\n'
    fi
    printf '%s' "$entry"
    first=0
  done
  printf '\n]\n'
} >"$matrix_tmp"

pass_count="$(jq '[.[] | select(.final_rubric == "PASS")] | length' "$matrix_tmp")"
false_success_count="$(jq '[.[] | select(.final_rubric == "FALSE_SUCCESS")] | length' "$matrix_tmp")"
fail_count="$(jq '[.[] | select(.final_rubric == "FAIL")] | length' "$matrix_tmp")"
helper_specific_count="$(jq '[.[] | select(.final_rubric == "HELPER_SPECIFIC")] | length' "$matrix_tmp")"
claude_wide_count="$(jq '[.[] | select(.final_rubric == "CLAUDE_WIDE")] | length' "$matrix_tmp")"

{
  printf '# Claude Write Test Summary\n\n'
  printf '| Model | Mode | Helper rubric | Final rubric | Exit | Session | Writes matched |\n'
  printf '| --- | --- | --- | --- | ---: | --- | --- |\n'
  jq -r '.[] | [
    .helper.model_slug,
    .helper.mode,
    .helper.rubric,
    .final_rubric,
    (.helper.exit_status | tostring),
    (.helper.session_id // ""),
    ((.helper.validation.created_matches and .helper.validation.nested_matches and .helper.validation.edit_matches) | tostring)
  ] | @tsv' "$matrix_tmp" | while IFS=$'\t' read -r model mode helper_rubric final_rubric exit_status session_id writes; do
    printf '| %s | %s | %s | %s | %s | %s | %s |\n' "$model" "$mode" "$helper_rubric" "$final_rubric" "$exit_status" "$session_id" "$writes"
  done
  printf '\n'
  printf 'PASS=%s, FALSE_SUCCESS=%s, FAIL=%s, HELPER_SPECIFIC=%s, CLAUDE_WIDE=%s\n' \
    "$pass_count" "$false_success_count" "$fail_count" "$helper_specific_count" "$claude_wide_count"
} >"$summary_tmp"

sonnet_status="$(jq -r '[.[] | select(.helper.model_slug == "sonnet") | .final_rubric] | unique | join(", ")' "$matrix_tmp")"
opus_status="$(jq -r '[.[] | select(.helper.model_slug == "opus") | .final_rubric] | unique | join(", ")' "$matrix_tmp")"
haiku_status="$(jq -r '[.[] | select(.helper.model_slug == "haiku") | .final_rubric] | unique | join(", ")' "$matrix_tmp")"
accept_status="$(jq -r '[.[] | select(.helper.mode == "acceptEdits") | .final_rubric] | unique | join(", ")' "$matrix_tmp")"
bypass_status="$(jq -r '[.[] | select(.helper.mode == "bypassPermissions") | .final_rubric] | unique | join(", ")' "$matrix_tmp")"

best_command="$(jq -r '
  .[]
  | select(.final_rubric == "PASS")
  | .helper.artifacts.command_file
' "$matrix_tmp" | head -n 1)"

{
  printf '# Recommendations\n\n'
  printf '## Reliability by model\n\n'
  printf '- Sonnet: %s\n' "${sonnet_status:-no passing data}"
  printf '- Opus: %s\n' "${opus_status:-no passing data}"
  printf '- Haiku: %s\n\n' "${haiku_status:-no passing data}"
  printf '## Cause analysis\n\n'
  printf '- acceptEdits outcomes: %s\n' "${accept_status:-no data}"
  printf '- bypassPermissions outcomes: %s\n' "${bypass_status:-no data}"
  printf -- '- Helper-specific failures detected: %s\n' "$helper_specific_count"
  printf -- '- Claude-wide failures detected: %s\n\n' "$claude_wide_count"
  printf '## Most reliable command pattern\n\n'
  if [[ -n "${best_command:-}" ]]; then
    printf '```bash\n'
    cat "$best_command"
    printf '```\n\n'
  else
    printf 'No PASS command was observed in the helper matrix.\n\n'
  fi
  printf '## Skill / instruction changes\n\n'
  if [[ "$helper_specific_count" -gt 0 ]]; then
    printf -- '- The helper path or invocation should be adjusted because direct Claude CLI succeeded where the helper did not.\n'
  else
    printf -- '- No helper-only failure was isolated in this run set.\n'
  fi
  if [[ "$claude_wide_count" -gt 0 ]]; then
    printf -- '- Some write failures reproduced without the helper, so any skill change should focus on fallback behavior and verification rather than helper syntax alone.\n'
  else
    printf -- '- No Claude-wide write failure was reproduced in the tested cases.\n'
  fi
  printf -- '- The current skill contract already points callers toward explicit model, permission mode, allowed tools, and captured session IDs; this test only justifies tightening post-run verification if false success appears.\n\n'
  printf '## Orchestrator fallback\n\n'
  if [[ "$false_success_count" -gt 0 || "$claude_wide_count" -gt 0 ]]; then
    printf -- '- If direct file writing remains flaky in broader use, the orchestrator should consider materializing markdown artifacts from structured output and verifying the expected filesystem diff.\n'
  else
    printf -- '- For the tested matrix, direct file writing was reliable enough that structured-output materialization does not appear necessary as the default path.\n'
  fi
} >"$recommend_tmp"
