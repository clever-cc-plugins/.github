# clever-cc-plugins/.github

Org profile (`profile/README.md`), brand assets, and the shared `plugin-release` reusable workflow that every plugin repo calls.

## Key Config Files

| File                                         | Purpose                                                              |
| -------------------------------------------- | -------------------------------------------------------------------- |
| `.claude/settings.json`                      | Permissions, hooks                                                   |
| `.claude/guard-secret-files.sh`              | PreToolUse hook: blocks reads/edits/writes of secret .env files      |
| `.claude/format-markdown.sh`                 | PostToolUse hook: formats Markdown files with prettier after edits   |
| `.claude/lint-shell.sh`                      | PostToolUse hook: runs shellcheck on edited `.sh` files              |
| `.githooks/pre-commit`                       | Secret scanning (gitleaks)                                           |
| `.github/workflows/plugin-release.yml`       | Reusable workflow (`workflow_call`) that bumps versions and releases |
| `.github/workflows/test-release-scripts.yml` | CI: runs the bump script tests                                       |
| `.github/scripts/bump-plugin-version.sh`     | Computes semver bump from commits since the last tag                 |
| `CLAUDE.md`                                  | Project instructions, loaded every message                           |

<!-- cc-config: last-optimize-run: 2026-11-05 57a17cd -->

## Commands

- Test the bump script: `bash .github/scripts/test-bump-plugin-version.sh`
- Activate hooks (once per clone): `chmod +x .githooks/pre-commit && git config core.hooksPath .githooks`

## Conventions

- Other plugin repos call `plugin-release.yml` and sparse-checkout `.github/scripts` from this repo's `main` — renaming or moving either breaks every plugin's releases.
- Release bumps come from Conventional Commit prefixes since the last `vX.Y.Z` tag: `feat` → minor, `fix`/`perf` → patch, `!` or `BREAKING CHANGE:` → major, everything else → no release. Choose commit types accordingly.
- `bump-plugin-version.sh` is sourced by its test file; keep its functions side-effect free on source.

## Don't

- Don't commit secrets or credentials to git
- Don't use `--force` flags — fix the underlying issue instead
- Don't rename `.github/scripts/` or `plugin-release.yml` without updating every plugin repo

## Learnings

When the user corrects a mistake or points out a recurring issue, append a one-line
summary to `.claude/learnings.md`. Don't modify `CLAUDE.md` directly.

## Compact Instructions

When compacting, preserve: list of modified files, current test status, open TODOs, and key decisions made.
