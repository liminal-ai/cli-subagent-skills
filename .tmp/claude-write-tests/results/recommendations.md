# Recommendations

Is file writing reliable for Sonnet / Opus / Haiku?
- In this test root, yes. Sonnet 4.6, Opus 4.6, and Haiku 4.5 all passed the requested helper-based write task in both `acceptEdits` and `bypassPermissions`, and a direct Sonnet CLI control also passed.

Is the problem model-specific, helper-specific, or permission-specific?
- No write failure reproduced in the core matrix, so there is no evidence here of a model-specific, helper-specific, or permission-mode-specific inability to write files.
- The meaningful issue that did reproduce is tool-profile-specific semantics: `--allowedTools Read,Grep,Glob` did not prevent Sonnet from using `Write` and `Edit`. That matches the skill warning that `allowedTools` is a runtime preference, not a hard boundary.

What exact command pattern is most reliable?
- Use the helper with explicit cwd, JSON output, exact model ID, explicit permission mode, and the full write-capable tool set.

```bash
~/.claude/skills/claude-subagent/scripts/claude-result \
  --cwd /Users/leemoore/code/cli-as-subagent-skills/.tmp/claude-write-tests/runs/sonnet-acceptEdits/workspace \
  --json exec "<prompt>" \
  --model claude-sonnet-4-6 \
  --permission-mode acceptEdits \
  --allowedTools Read,Write,Edit,Bash,Grep,Glob
```

What should we change in the Claude subagent skill or instructions, if anything?
- Keep the current helper-first pattern.
- Strengthen the warning that `--allowedTools` is not a dependable enforcement boundary for read-only runs.
- Add an explicit post-run verification step for workflows that care about actual file effects: verify expected files or diffs instead of trusting the agent summary alone.
- If a workflow truly must forbid writes, rely on sandboxing or an external enforcement mechanism, not only `allowedTools`.

If direct file writing is flaky, should the orchestrator instead materialize markdown artifacts from structured output?
- Not as the default path based on this investigation. Direct writing looked stable in the tested cases.
- For high-assurance flows, it is still reasonable for the orchestrator to materialize artifacts from structured output or verify the expected diff after the run, especially when a false-success would be costly.
