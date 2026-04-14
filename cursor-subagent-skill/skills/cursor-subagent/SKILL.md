---
name: cursor-subagent
description: Run Cursor Agent CLI as a subagent for code tasks, review, validation, and implementation. Supports sync, async, parallel, and resume workflows with tiered output management.
---

# Cursor Agent CLI Subagent

Run Cursor Agent (`cursor-agent -p`) as a subagent for code-related tasks.

## When to Use

- **Implementation** — code changes, bug fixes, feature work
- **Validation** — second opinion on specs, code, architecture
- **Code review** — focused review in a fresh Cursor session
- **Parallel work** — fan out independent tasks across multiple agents
- **Cross-agent workflows** — when Claude Code, Codex, Copilot, or another harness should call Cursor as an external worker

Avoid for:
- Tiny tasks faster to do inline
- Work requiring tight back-and-forth in a single context

## Prerequisites

- `cursor-agent` CLI installed
- Authenticated (`cursor-agent whoami`)
- `jq` installed
- Workspace trusted, or use `--trust`

## Current Config Defaults

This skill does **not** hard-code expected model or mode defaults.

Cursor config can vary by machine and account state. Treat the installed Cursor CLI as the source of truth and pass flags explicitly when you need a specific model, execution mode, or autonomy level.

## Output Strategy (Tiered)

**Always write full stream JSONL for each run. Only read into context what you need.**

`cursor-result exec` runs Cursor with `--output-format stream-json`, saves the full event stream beside the saved Cursor transcript, and returns only the final assistant text by default.

### Tier 1 — Last message only (default, ~90% of tasks)

```bash
cd /path/to/project && cursor-result exec "prompt"
```

### Tier 2 — All agent messages (when final message needs context)

```bash
cursor-result messages
```

### Tier 3 — Inspect specific details on demand

```bash
cursor-result session-id
cursor-result usage
cursor-result commands
cursor-result tools
cursor-result reasoning
cursor-result summary
```

## Extraction Helper

Use `~/.claude/skills/cursor-subagent/scripts/cursor-result` for all operations:

```bash
cursor-result exec "prompt"
cursor-result --json exec "prompt"
cursor-result last [session-id]
cursor-result messages [session-id]
cursor-result session-id [session-id]
cursor-result tools [session-id]
cursor-result commands [session-id]
cursor-result reasoning [session-id]
cursor-result usage [session-id]
cursor-result summary [session-id]
```

## Execution Patterns

### 1) Synchronous (blocking, result inline)

```bash
cd /path/to/project && cursor-result exec "your prompt"
```

### 2) Asynchronous (background, poll later)

```bash
cd /path/to/project && cursor-result exec "your prompt" > /tmp/cursor-async.txt 2>/dev/null &
echo "PID=$!"
```

Check completion and retrieve result:

```bash
jobs -l
cat /tmp/cursor-async.txt
cursor-result last
```

### 3) Parallel (multiple simultaneous agents)

```bash
cd /path/to/project
cursor-result exec "task A" > /tmp/cursor-a.txt 2>/dev/null &
PID_A=$!
cursor-result exec "task B" > /tmp/cursor-b.txt 2>/dev/null &
PID_B=$!
wait $PID_A $PID_B

cat /tmp/cursor-a.txt
cat /tmp/cursor-b.txt
```

### 4) Resume (continue a prior session)

```bash
cd /path/to/project && cursor-result exec "follow-up prompt" --resume "$(cursor-result session-id)"
```

### 5) Planning / read-only-ish analysis

Cursor does not expose the same fine-grained tool allowlist model as Claude Code or Copilot CLI.
Use `--mode plan` or `--mode ask` when you want to bias the runtime away from edits.

```bash
cd /path/to/project && cursor-result exec "Plan how to add rate limiting" --mode plan
```

### 6) Implementation / higher-autonomy execution

```bash
cd /path/to/project && cursor-result exec "Implement the requested fix and update tests" --trust
```

If you need more aggressive command execution:

```bash
cd /path/to/project && cursor-result exec "Run the tests, fix failures, and summarize the result" --trust --force
```

## Useful Cursor Flags

Pass these after the prompt when using `cursor-result exec`:

```bash
# Different model
cursor-result exec "prompt" --model sonnet-4

# Planning / read-only-ish mode
cursor-result exec "prompt" --mode plan

# Resume a specific session
cursor-result exec "prompt" --resume <session-id>

# Workspace override
cursor-result exec "prompt" --workspace /path/to/project

# More autonomous execution
cursor-result exec "prompt" --trust --force
```

## Content Passing

### Inline prompt (simple)

```bash
cursor-result exec "your prompt here"
```

### Heredoc (complex/multi-line prompts)

```bash
cursor-result exec "$(cat <<'EOF'
Task: Review authentication module
Scope: src/auth/
Constraints: No changes, analysis only

Report issues with severity [P1], [P2], [P3].
EOF
)"
```

### File reference (preferred for code tasks)

Let Cursor read files itself:

```bash
cursor-result exec "Read src/auth/login.ts and identify security issues"
```

## Session Storage

Cursor persists transcripts at:

```text
~/.cursor/projects/<cwd-with-leading-slash-removed-and-slashes-replaced-by-dashes>/agent-transcripts/<session-id>/<session-id>.jsonl
```

`cursor-result exec` also saves the richer stream JSONL beside the transcript as:

```text
<session-id>.stream.jsonl
```

## Cursor-Specific Notes

- `cursor-agent -p --output-format json` returns a final result object, but it can concatenate intermediate assistant text in ways that are less useful for subagent extraction.
- `cursor-result` uses `stream-json` by default so it can reliably capture tool calls, command attempts, and the final result.
- In testing, shell writes were sometimes rejected and Cursor fell back to its edit tool. This is normal runtime behavior and not a helper bug.
- Cursor does not currently expose reasoning summaries in the same way as Codex or Copilot. `cursor-result reasoning` returns text only if the runtime emits it.
