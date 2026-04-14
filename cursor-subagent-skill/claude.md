# Claude Working Notes

This repository packages and releases the `cursor-subagent` skill.

## Release Rule (Required)

When publishing any new version to GitHub, you must manually upload release artifacts.

`dist/` is gitignored by design, so artifacts are not the source of truth for the repository.

## Required Release Steps

1. Bump `package.json` version.
2. Build artifacts:
   - `npm run build`
3. Commit and push branch.
4. Create/push tag:
   - `git tag -a cursor-subagent-v<version> -m "Release cursor-subagent-v<version>"`
   - `git push origin <branch>`
   - `git push origin cursor-subagent-v<version>`
5. Publish artifacts to GitHub Release:
   - If creating new release:
     - `gh release create cursor-subagent-v<version> dist/cursor-subagent-v<version>.zip dist/cursor-subagent-v<version>.skill --repo <owner>/<monorepo> --title "cursor-subagent v<version>" --notes "Release cursor-subagent v<version>."`
   - If release already exists:
     - `gh release upload cursor-subagent-v<version> dist/cursor-subagent-v<version>.zip dist/cursor-subagent-v<version>.skill --repo <owner>/<monorepo> --clobber`

Do not mark a release complete until both `.zip` and `.skill` assets are attached.
