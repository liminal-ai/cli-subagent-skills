# Claude Subagent Skill Packaging Repo

## Project purpose

This package is the source of truth for the `claude-subagent` skill inside the `cli-as-subagent-skills` monorepo.

It provides scripts to:

- build `.zip` and `.skill` distributables
- deploy the skill into `~/.claude/skills`
- run a local release flow with version tags

Current version: `v0.1.0`.

## Repository layout

```text
claude-subagent-skill/
  README.md
  CHANGELOG.md
  claude.md
  agents.md
  package.json
  .gitignore
  skills/
    claude-subagent/
      SKILL.md
      scripts/
        claude-result
  scripts/
    build-artifacts.mjs
    deploy-local.mjs
    release-local.mjs
    verify.mjs
  dist/                # generated artifacts
```

## Local development workflow

1. Edit skill source files under `skills/claude-subagent/`.
2. Run `npm run verify`.
3. Run `npm run build` to produce distributables.
4. Run `npm run deploy` to install locally for Claude Code.

## Build artifacts (`.zip` and `.skill`)

Build command:

```bash
npm run build
```

For `v0.1.0`, this produces:

- `dist/claude-subagent-v0.1.0.zip`
- `dist/claude-subagent-v0.1.0.skill`

Notes:

- `.skill` is a renamed copy of the `.zip` payload.
- archive root is `claude-subagent/`.
- required entries:
  - `claude-subagent/SKILL.md`
  - `claude-subagent/scripts/claude-result`

## Local deploy workflow

Deploy command:

```bash
npm run deploy
```

This copies `skills/claude-subagent` to:

- `~/.claude/skills/claude-subagent`

Behavior:

- replaces destination directory
- preserves executable mode for `scripts/claude-result`

## Local release/tag workflow

Release command:

```bash
npm run release:local
```

This will:

1. run build
2. require clean git working tree (fails if dirty)
3. create local annotated tag `claude-subagent-v<version>` if missing
4. print manual publish steps

Optional override:

```bash
npm run release:local -- --allow-dirty
```

Use `--allow-dirty` to continue when the working tree is not clean (default behavior is fail).

## Manual GitHub release process (for now)

No CI release workflow is active in `v0.1.0`.
`dist/` is gitignored, so release artifacts should be treated as release assets, not source of truth.

Manual process:

1. `npm run release:local`
2. `git push origin <branch>`
3. `git push origin claude-subagent-v<version>`
4. create a GitHub Release and upload artifacts in one step:

```bash
gh release create claude-subagent-v<version> \
  dist/claude-subagent-v<version>.zip \
  dist/claude-subagent-v<version>.skill \
  --repo <owner>/<monorepo> \
  --title "claude-subagent v<version>" \
  --notes "Release claude-subagent v<version>."
```

If the release already exists, upload/replace assets:

```bash
gh release upload claude-subagent-v<version> \
  dist/claude-subagent-v<version>.zip \
  dist/claude-subagent-v<version>.skill \
  --repo <owner>/<monorepo> \
  --clobber
```

## Versioning policy

- Semantic Versioning (`SemVer`)
- Version source: `package.json`
- Starting version: `0.1.0`
