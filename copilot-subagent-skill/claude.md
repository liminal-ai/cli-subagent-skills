# Claude Working Notes

This repository packages and releases the `copilot-subagent` skill.

## Release Rule (Required)

When publishing any new version to GitHub, you must manually upload release artifacts.

`dist/` is gitignored by design, so artifacts are never available from source checkout alone.

## Required Release Steps

1. Bump `package.json` version.
2. Build artifacts:
   - `bun run build`
3. Commit and push branch.
4. Create/push tag:
   - `git tag -a copilot-subagent-v<version> -m "Release copilot-subagent-v<version>"`
   - `git push origin <branch>`
   - `git push origin copilot-subagent-v<version>`
5. Publish artifacts to GitHub Release:
   - If creating new release:
     - `gh release create copilot-subagent-v<version> dist/copilot-subagent-v<version>.zip dist/copilot-subagent-v<version>.skill --repo <owner>/<monorepo> --title "copilot-subagent v<version>" --notes "Release copilot-subagent v<version>."`
   - If release already exists:
     - `gh release upload copilot-subagent-v<version> dist/copilot-subagent-v<version>.zip dist/copilot-subagent-v<version>.skill --repo <owner>/<monorepo> --clobber`

Do not mark a release complete until both `.zip` and `.skill` assets are attached.
