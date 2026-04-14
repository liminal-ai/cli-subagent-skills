# Agent Instructions

Scope: entire repository.

## Purpose

Maintain packaging/deployment scripts and release process for the `copilot-subagent` Claude skill.

## Non-negotiable Release Requirement

`dist/` artifacts are ignored by git. Every version pushed to GitHub must include manual release asset upload.

Required assets per version tag `copilot-subagent-vX.Y.Z`:
- `dist/copilot-subagent-vX.Y.Z.zip`
- `dist/copilot-subagent-vX.Y.Z.skill`

## Required Commands For Any New Version

1. `bun run verify`
2. `bun run build`
3. `git tag -a copilot-subagent-vX.Y.Z -m "Release copilot-subagent-vX.Y.Z"` (if tag does not already exist)
4. `git push origin <branch>`
5. `git push origin copilot-subagent-vX.Y.Z`
6. Upload release assets:
   - `gh release create copilot-subagent-vX.Y.Z dist/copilot-subagent-vX.Y.Z.zip dist/copilot-subagent-vX.Y.Z.skill --repo <owner>/<monorepo> --title "copilot-subagent vX.Y.Z" --notes "Release copilot-subagent vX.Y.Z."`
   - or, if the release exists:
   - `gh release upload copilot-subagent-vX.Y.Z dist/copilot-subagent-vX.Y.Z.zip dist/copilot-subagent-vX.Y.Z.skill --repo <owner>/<monorepo> --clobber`

Never finish a release without verifying both assets are visible on the GitHub Release page.
