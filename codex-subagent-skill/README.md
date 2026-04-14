# Codex Subagent Skill Packaging Repo

## Project purpose

This repo is the source of truth for the `codex-subagent` skill and its local/release packaging workflow.

It provides Bun scripts to:

- build `.zip` and `.skill` distributables
- deploy the skill into `~/.claude/skills`
- run a local release flow with version tags

Current version: `v0.1.0`.

## Repository layout

```text
codex-subagent-skill/
  README.md
  CHANGELOG.md
  claude.md
  agents.md
  package.json
  .gitignore
  skills/
    codex-subagent/
      SKILL.md
      scripts/
        codex-result
  scripts/
    build-artifacts.ts
    deploy-local.ts
    release-local.ts
    verify.ts
  dist/                # generated artifacts
```

## Local development workflow

1. Edit skill source files under `skills/codex-subagent/`.
2. Run `bun run verify`.
3. Run `bun run build` to produce distributables.
4. Run `bun run deploy` to install locally for Claude Code.

## Build artifacts (`.zip` and `.skill`)

Build command:

```bash
bun run build
```

For `v0.1.0`, this produces:

- `dist/codex-subagent-v0.1.0.zip`
- `dist/codex-subagent-v0.1.0.skill`

Notes:

- `.skill` is a renamed copy of the `.zip` payload.
- archive root is `codex-subagent/`.
- required entries:
  - `codex-subagent/SKILL.md`
  - `codex-subagent/scripts/codex-result`

## Local deploy workflow

Deploy command:

```bash
bun run deploy
```

This copies `skills/codex-subagent` to:

- `~/.claude/skills/codex-subagent`

Behavior:

- replaces destination directory
- preserves executable mode for `scripts/codex-result`

## Local release/tag workflow

Release command:

```bash
bun run release:local
```

This will:

1. run build
2. require clean git working tree (fails if dirty)
3. create local annotated tag `v<version>` if missing
4. print manual publish steps

Optional override:

```bash
bun run release:local -- --allow-dirty
```

Use `--allow-dirty` to continue when the working tree is not clean (default behavior is fail).

## Manual GitHub release process (for now)

No CI release workflow is active in `v0.1.0`.
`dist/` is gitignored, so release artifacts must be uploaded manually for every version.

Manual process:

1. `bun run release:local`
2. `git push origin <branch>`
3. `git push origin v<version>`
4. create a GitHub Release and upload artifacts in one step:

```bash
gh release create v<version> \
  dist/codex-subagent-v<version>.zip \
  dist/codex-subagent-v<version>.skill \
  --repo liminal-ai/codex-subagent-skill \
  --title "v<version>" \
  --notes "Release v<version>."
```

If the release already exists, upload/replace assets:

```bash
gh release upload v<version> \
  dist/codex-subagent-v<version>.zip \
  dist/codex-subagent-v<version>.skill \
  --repo liminal-ai/codex-subagent-skill \
  --clobber
```

## Versioning policy

- Semantic Versioning (`SemVer`)
- Version source: `package.json`
- Starting version: `0.1.0`
