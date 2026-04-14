# Agent Instructions

Scope: entire repository.

## Purpose

Maintain packaging/deployment scripts and release process for the `claude-subagent` Claude skill.

## Non-negotiable Release Requirement

`dist/` artifacts are ignored by git by default. Every version pushed to GitHub must include manual release asset upload.

Required assets per version tag `vX.Y.Z`:
- `dist/claude-subagent-vX.Y.Z.zip`
- `dist/claude-subagent-vX.Y.Z.skill`

## Required Commands For Any New Version

1. `npm run verify`
2. `npm run build`
3. `git tag -a vX.Y.Z -m "Release vX.Y.Z"` (if tag does not already exist)
4. `git push origin <branch>`
5. `git push origin vX.Y.Z`
6. Upload release assets:
   - `gh release create vX.Y.Z dist/claude-subagent-vX.Y.Z.zip dist/claude-subagent-vX.Y.Z.skill --repo liminal-ai/claude-subagent-skill --title "vX.Y.Z" --notes "Release vX.Y.Z."`
   - or, if the release exists:
   - `gh release upload vX.Y.Z dist/claude-subagent-vX.Y.Z.zip dist/claude-subagent-vX.Y.Z.skill --repo liminal-ai/claude-subagent-skill --clobber`

Never finish a release without verifying both assets are visible on the GitHub Release page.
