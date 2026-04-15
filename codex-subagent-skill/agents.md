# Agent Instructions

Scope: entire repository.

## Purpose

Maintain packaging/deployment scripts and release process for the `codex-subagent` Claude skill.

## Non-negotiable Release Requirement

`dist/` artifacts are ignored by git. Every version pushed to GitHub must include manual release asset upload.

Required release asset per version tag `codex-subagent-vX.Y.Z`:
- `dist/codex-subagent-vX.Y.Z.zip`

Local build output should also include:
- `dist/codex-subagent/`

## Required Commands For Any New Version

1. `bun run verify`
2. `bun run build`
3. `git tag -a codex-subagent-vX.Y.Z -m "Release codex-subagent-vX.Y.Z"` (if tag does not already exist)
4. `git push origin <branch>`
5. `git push origin codex-subagent-vX.Y.Z`
6. Upload release assets:
   - `gh release create codex-subagent-vX.Y.Z dist/codex-subagent-vX.Y.Z.zip --repo <owner>/<monorepo> --title "codex-subagent vX.Y.Z" --notes "Release codex-subagent vX.Y.Z."`
   - or, if the release exists:
   - `gh release upload codex-subagent-vX.Y.Z dist/codex-subagent-vX.Y.Z.zip --repo <owner>/<monorepo> --clobber`

Never finish a release without verifying the `.zip` asset is visible on the GitHub Release page.
