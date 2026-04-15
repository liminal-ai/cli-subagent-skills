# Claude Working Notes

This repository packages and releases the `codex-subagent` skill.

## Release Rule (Required)

When publishing any new version to GitHub, you must manually upload release artifacts.

`dist/` is gitignored by design, so artifacts are never available from source checkout alone.

## Required Release Steps

1. Bump `package.json` version.
2. Build artifacts:
   - `bun run build`
3. Commit and push branch.
4. Create/push tag:
   - `git tag -a codex-subagent-v<version> -m "Release codex-subagent-v<version>"`
   - `git push origin <branch>`
   - `git push origin codex-subagent-v<version>`
5. Publish artifacts to GitHub Release:
   - If creating new release:
     - `gh release create codex-subagent-v<version> dist/codex-subagent-v<version>.zip --repo <owner>/<monorepo> --title "codex-subagent v<version>" --notes "Release codex-subagent v<version>."`
   - If release already exists:
     - `gh release upload codex-subagent-v<version> dist/codex-subagent-v<version>.zip --repo <owner>/<monorepo> --clobber`

Do not mark a release complete until the `.zip` asset is attached.
