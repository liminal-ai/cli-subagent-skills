# CLI As Subagent Skills

This repository is a monorepo for CLI-driven subagent skills.

Each package is self-contained and keeps its own packaging workflow, helper scripts, and skill files.
The root repository is only responsible for grouping them together in one place.

## Packages

- `claude-subagent-skill`
- `codex-subagent-skill`
- `copilot-subagent-skill`
- `cursor-subagent-skill` — reserved scaffold for future implementation

## Notes

- Existing package layouts are preserved to minimize churn.
- Tooling is still package-local for now.
- Future CLI subagent skills can be added alongside these packages.
