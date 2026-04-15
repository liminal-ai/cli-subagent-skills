# Agent Instructions

Scope: entire repository.

## Purpose

Maintain packaging/deployment scripts and release process for the `claude-subagent` Claude skill.

## Non-negotiable Release Requirement

`dist/` artifacts are ignored by git by default. Every version pushed to GitHub must include manual release asset upload.

Required release asset per version tag `claude-subagent-vX.Y.Z`:
- `dist/claude-subagent-vX.Y.Z.zip`

Local build output should also include:
- `dist/claude-subagent/`

## Required Commands For Any New Version

1. `npm run verify`
2. `npm run build`
3. `git tag -a claude-subagent-vX.Y.Z -m "Release claude-subagent-vX.Y.Z"` (if tag does not already exist)
4. `git push origin <branch>`
5. `git push origin claude-subagent-vX.Y.Z`
6. Upload release assets:
   - `gh release create claude-subagent-vX.Y.Z dist/claude-subagent-vX.Y.Z.zip --repo <owner>/<monorepo> --title "claude-subagent vX.Y.Z" --notes "Release claude-subagent vX.Y.Z."`
   - or, if the release exists:
   - `gh release upload claude-subagent-vX.Y.Z dist/claude-subagent-vX.Y.Z.zip --repo <owner>/<monorepo> --clobber`

Never finish a release without verifying the `.zip` asset is visible on the GitHub Release page.
