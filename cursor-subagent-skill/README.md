# Cursor Subagent Skill Packaging Repo

## Project purpose

This repo is the source of truth for the `cursor-subagent` skill and its local/release packaging workflow.

It provides scripts to:

- build `.zip` and `.skill` distributables
- deploy the skill into `~/.claude/skills`
- run a local release flow with version tags

Current version: `v0.1.0`.

## Repository layout

```text
cursor-subagent-skill/
  README.md
  CHANGELOG.md
  claude.md
  agents.md
  package.json
  .gitignore
  skills/
    cursor-subagent/
      SKILL.md
      scripts/
        cursor-result
  scripts/
    build-artifacts.mjs
    deploy-local.mjs
    release-local.mjs
    verify.mjs
    smoke-test.sh
  dist/                # generated artifacts
```

## Local development workflow

1. Edit skill source files under `skills/cursor-subagent/`.
2. Run `npm run verify`.
3. Run `npm run build` to produce distributables.
4. Run `npm run deploy` to install locally for Claude Code.

## Build artifacts (`.zip` and `.skill`)

Build command:

```bash
npm run build
```

For `v0.1.0`, this produces:

- `dist/cursor-subagent-v0.1.0.zip`
- `dist/cursor-subagent-v0.1.0.skill`

Notes:

- `.skill` is a renamed copy of the `.zip` payload.
- archive root is `cursor-subagent/`.
- required entries:
  - `cursor-subagent/SKILL.md`
  - `cursor-subagent/scripts/cursor-result`

## Local deploy workflow

Deploy command:

```bash
npm run deploy
```

This copies `skills/cursor-subagent` to:

- `~/.claude/skills/cursor-subagent`

Behavior:

- replaces destination directory
- preserves executable mode for `scripts/cursor-result`

## Local release/tag workflow

Release command:

```bash
npm run release:local
```

This will:

1. run build
2. require clean git working tree (fails if dirty)
3. create local annotated tag `v<version>` if missing
4. print manual publish steps

Optional override:

```bash
npm run release:local -- --allow-dirty
```

## Manual GitHub release process (for now)

No CI release workflow is active in `v0.1.0`.
`dist/` is gitignored, so release artifacts should be treated as release assets, not source of truth.

Manual process:

1. `npm run release:local`
2. `git push origin <branch>`
3. `git push origin v<version>`
4. create a GitHub Release and upload artifacts in one step:

```bash
gh release create v<version> \
  dist/cursor-subagent-v<version>.zip \
  dist/cursor-subagent-v<version>.skill \
  --repo liminal-ai/cursor-subagent-skill \
  --title "v<version>" \
  --notes "Release v<version>."
```

If the release already exists, upload/replace assets:

```bash
gh release upload v<version> \
  dist/cursor-subagent-v<version>.zip \
  dist/cursor-subagent-v<version>.skill \
  --repo liminal-ai/cursor-subagent-skill \
  --clobber
```

## Versioning policy

- Semantic Versioning (`SemVer`)
- Version source: `package.json`
- Starting version: `0.1.0`
