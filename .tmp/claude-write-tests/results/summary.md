# Claude Write Test Summary

Core helper matrix: 6/6 PASS.

| Model | Mode | Helper rubric | Exit | Session | Writes matched |
| --- | --- | --- | ---: | --- | --- |
| haiku | acceptEdits | PASS | 0 | 96bf3f3c-2712-4305-9439-3d914c250a06 | true |
| haiku | bypassPermissions | PASS | 0 | cceb289e-5225-411d-9665-aaed3a0cfd90 | true |
| opus | acceptEdits | PASS | 0 | fed5e7d2-1bff-4b2d-87dd-d2bde24cb174 | true |
| opus | bypassPermissions | PASS | 0 | 042d8ce1-9464-406c-94e9-859581acc77a | true |
| sonnet | acceptEdits | PASS | 0 | d5343ee5-5598-448a-af04-08a08886f7c5 | true |
| sonnet | bypassPermissions | PASS | 0 | d0793fe1-4fcc-43c5-9575-269f7af7889d | true |

Core rubric totals: PASS=6, FALSE_SUCCESS=0, FAIL=0, HELPER_SPECIFIC=0, CLAUDE_WIDE=0.

Supplemental gorilla tests:
- Sonnet direct CLI positive control: PASS. Direct `claude -p` also wrote files successfully.
- Haiku acceptEdits helper rerun: PASS. The second run also completed cleanly.
- Sonnet helper with `--allowedTools Read,Grep,Glob`: PASS for writes, which is the key edge case. The model still used `Write` and `Edit`; see `runs/sonnet-acceptEdits-readonly-helper/` and the tool trace at `runs/sonnet-acceptEdits-readonly-helper/tool-trace.jsonl`.
