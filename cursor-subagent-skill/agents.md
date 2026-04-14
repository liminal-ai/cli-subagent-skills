# Agent Instructions

Scope: entire repository.

## Purpose

Maintain packaging/deployment scripts and release process for the `cursor-subagent` Claude skill.

## Non-negotiable Release Requirement

`dist/` artifacts are ignored by git by default. Every version pushed to GitHub must include manual release asset upload.

Required assets per version tag `cursor-subagent-vX.Y.Z`:
- `dist/cursor-subagent-vX.Y.Z.zip`
- `dist/cursor-subagent-vX.Y.Z.skill`

## Required Commands For Any New Version

1. `npm run verify`
2. `npm run build`
3. `git tag -a cursor-subagent-vX.Y.Z -m "Release cursor-subagent-vX.Y.Z"` (if tag does not already exist)
4. `git push origin <branch>`
5. `git push origin cursor-subagent-vX.Y.Z`
6. Upload release assets:
   - `gh release create cursor-subagent-vX.Y.Z dist/cursor-subagent-vX.Y.Z.zip dist/cursor-subagent-vX.Y.Z.skill --repo <owner>/<monorepo> --title "cursor-subagent vX.Y.Z" --notes "Release cursor-subagent vX.Y.Z."`
   - or, if the release exists:
   - `gh release upload cursor-subagent-vX.Y.Z dist/cursor-subagent-vX.Y.Z.zip dist/cursor-subagent-vX.Y.Z.skill --repo <owner>/<monorepo> --clobber`

Never finish a release without verifying both assets are visible on the GitHub Release page.
