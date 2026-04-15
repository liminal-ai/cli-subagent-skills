#!/usr/bin/env bash
set -u

TEST_ROOT="/Users/leemoore/code/cli-as-subagent-skills/.tmp/claude-write-tests"
HELPER="$HOME/.claude/skills/claude-subagent/scripts/claude-result"

run_case() {
  local run_name="$1"
  local runner="$2"
  local model_slug="$3"
  local model_id="$4"
  local mode="$5"
  local allowed_tools="$6"

  local run_dir="$TEST_ROOT/runs/$run_name"
  local workspace="$run_dir/workspace"
  local prompt_file="$run_dir/prompt.txt"
  local stdout_file="$run_dir/stdout.txt"
  local stderr_file="$run_dir/stderr.txt"
  local command_file="$run_dir/command.txt"
  local meta_file="$run_dir/meta.json"
  local outputs_dir="$workspace/outputs/$model_slug/$mode"
  local created_file="$outputs_dir/created.txt"
  local nested_file="$outputs_dir/nested/result.json"
  local edit_file="$workspace/inputs/edit-target.md"

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

  if [[ "$runner" == "helper" ]]; then
    printf '%s\n' "$HELPER --cwd $workspace --json exec \"$prompt\" --model $model_id --permission-mode $mode --allowedTools $allowed_tools" >"$command_file"
    "$HELPER" --cwd "$workspace" --json exec "$prompt" \
      --model "$model_id" \
      --permission-mode "$mode" \
      --allowedTools "$allowed_tools" \
      >"$stdout_file" 2>"$stderr_file"
    status=$?
  else
    printf '%s\n' "cd $workspace && claude -p --output-format json --model $model_id --permission-mode $mode --allowedTools $allowed_tools -- \"$prompt\"" >"$command_file"
    (
      cd "$workspace" && \
      claude -p --output-format json \
        --model "$model_id" \
        --permission-mode "$mode" \
        --allowedTools "$allowed_tools" \
        -- "$prompt"
    ) >"$stdout_file" 2>"$stderr_file"
    status=$?
  fi

  local parsed_json="false"
  local agent_claimed_success="false"
  local session_id=""
  local result_text=""
  if jq -e . "$stdout_file" >/dev/null 2>&1; then
    parsed_json="true"
    session_id="$(jq -r '.session_id // empty' "$stdout_file")"
    result_text="$(jq -r '.result // empty' "$stdout_file")"
    if [[ "$(jq -r '.subtype // empty' "$stdout_file")" == "success" && "$(jq -r '.is_error // false' "$stdout_file")" == "false" ]]; then
      agent_claimed_success="true"
    fi
  fi

  local created_matches="false"
  local nested_matches="false"
  local edit_matches="false"
  local writes_happened="false"

  if [[ -f "$created_file" ]] && grep -Fxq -- 'created from source token ALPHA-42' "$created_file"; then
    created_matches="true"
  fi
  if [[ -f "$nested_file" ]] && jq -e --arg mode "$mode" --arg model "$model_id" '.sourceToken == "ALPHA-42" and .status == "written" and .mode == $mode and .model == $model' "$nested_file" >/dev/null 2>&1; then
    nested_matches="true"
  fi
  if grep -Fxq -- 'PLACEHOLDER: replaced with ALPHA-42' "$edit_file" && grep -Fxq -- '- added from source token ALPHA-42' "$edit_file"; then
    edit_matches="true"
  fi
  if [[ "$created_matches" == "true" || "$nested_matches" == "true" || "$edit_matches" == "true" ]]; then
    writes_happened="true"
  fi

  jq -n \
    --arg run_name "$run_name" \
    --arg runner "$runner" \
    --arg model_id "$model_id" \
    --arg mode "$mode" \
    --arg allowed_tools "$allowed_tools" \
    --arg status "$status" \
    --arg parsed_json "$parsed_json" \
    --arg agent_claimed_success "$agent_claimed_success" \
    --arg session_id "$session_id" \
    --arg result_text "$result_text" \
    --arg created_matches "$created_matches" \
    --arg nested_matches "$nested_matches" \
    --arg edit_matches "$edit_matches" \
    --arg writes_happened "$writes_happened" \
    '{
      run_name: $run_name,
      runner: $runner,
      model_id: $model_id,
      mode: $mode,
      allowed_tools: $allowed_tools,
      exit_status: ($status | tonumber),
      parsed_json: ($parsed_json == "true"),
      agent_claimed_success: ($agent_claimed_success == "true"),
      session_id: $session_id,
      result_text: $result_text,
      validation: {
        created_matches: ($created_matches == "true"),
        nested_matches: ($nested_matches == "true"),
        edit_matches: ($edit_matches == "true"),
        writes_happened: ($writes_happened == "true")
      }
    }' >"$meta_file"
}

run_case "sonnet-acceptEdits-readonly-helper" helper sonnet claude-sonnet-4-6 acceptEdits "Read,Grep,Glob"
run_case "sonnet-acceptEdits-direct-control" direct sonnet claude-sonnet-4-6 acceptEdits "Read,Write,Edit,Bash,Grep,Glob"
run_case "haiku-acceptEdits-helper-rerun" helper haiku claude-haiku-4-5 acceptEdits "Read,Write,Edit,Bash,Grep,Glob"
