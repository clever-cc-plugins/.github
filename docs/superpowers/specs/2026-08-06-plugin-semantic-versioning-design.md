# Plugin Semantic Versioning — Design

## Problem

The Claude Code plugin updater compares `plugin.json`'s `version` field, not
git commits. Three of the five clever-cc-plugins repos ship a static
`"version": "1.0.0"` that has never been bumped despite real changes (e.g.
cc-content gained the `gated-long-form-content` and `landing-page` skills
without a version bump). Two repos (cc-chime, cc-handoff) have no `version`
field at all. Because the version never changes, "Update now" in the
marketplace UI sees no version delta and treats the plugin as current,
forcing users to reinstall instead of update.

## Goals

- Every plugin repo's `plugin.json` version reflects reality after every
  merge to `main`, with zero manual step required going forward.
- Fix today's actual bug: bump the three stale repos now so existing
  installs pick up pending content.
- Reuse the existing Conventional Commits + gitmoji convention already used
  in every repo's commit history — no change to how commits are written.

## Non-goals

- Versioning the `marketplace` repo itself (it references plugins via
  `git-subdir` at branch HEAD, not a pinned version — no version field to
  bump).
- A changelog file (GitHub Release notes, auto-generated from commits,
  serve this purpose).
- Retroactively computing "correct" versions for the full commit history of
  each repo — see Bootstrap below.

## Architecture

A single reusable GitHub Actions workflow lives in the org's `.github`
repo:

- `.github/workflows/plugin-release.yml` — `workflow_call` entry point.
- `.github/scripts/bump-plugin-version.sh` — the bump logic, as a plain
  bash script (not inlined in YAML) so it can be tested locally.

Each of the 5 plugin repos (cc-chime, cc-concept, cc-config, cc-content,
cc-handoff) gets a thin caller workflow,
`.github/workflows/release.yml`, that triggers on push to `main` and
invokes the reusable workflow with `permissions: contents: write`.

The `marketplace` repo is untouched.

## Version bump logic

On push to `main`:

1. Locate the plugin manifest at `plugins/*/.claude-plugin/plugin.json`
   (each repo has exactly one).
2. Find the latest `v*` git tag reachable from `main`. If none exists, this
   is the bootstrap case (handled once manually — see below); the workflow
   exits without acting until a baseline tag exists.
3. Collect commit headers since that tag. Strip a leading gitmoji (if
   present) and any surrounding whitespace, then match the Conventional
   Commits header pattern `type(scope)!: subject`.
4. Classify each commit:
   - `!` after type/scope, or `BREAKING CHANGE:` in the commit body → major
   - `feat` → minor
   - `fix`, `perf` → patch
   - anything else (`docs`, `chore`, `refactor`, `test`, `ci`, `style`,
     ...) → ignored
5. Take the highest bump found across all commits since the last tag. If
   none qualify, exit cleanly — no tag, no release, no commit.
6. Otherwise: bump the `version` field in `plugin.json` via `jq`, commit as
   `🔖 chore(release): vX.Y.Z` using the default `GITHUB_TOKEN` (pushes
   made with the default token do not retrigger workflows, so this cannot
   loop), create and push an annotated tag `vX.Y.Z`, and create a GitHub
   Release via `gh release create --generate-notes`.

## Bootstrap (one-time, part of this change)

No repo has a git tag today, so the automation needs a manually-established
starting point that also fixes the live bug:

| Repo       | Current version | Action                                                                                                                         |
| ---------- | --------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| cc-chime   | none            | Add `"version": "1.0.0"` to `plugin.json` (positioned after `description`, matching the other repos' key order). Tag `v1.0.0`. |
| cc-handoff | none            | Same as cc-chime: add `"version": "1.0.0"`. Tag `v1.0.0`.                                                                      |
| cc-concept | 1.0.0 (stale)   | Bump to `1.1.0` by hand. Tag `v1.1.0`.                                                                                         |
| cc-config  | 1.0.0 (stale)   | Bump to `1.1.0` by hand. Tag `v1.1.0`.                                                                                         |
| cc-content | 1.0.0 (stale)   | Bump to `1.1.0` by hand. Tag `v1.1.0`.                                                                                         |

cc-concept/cc-config/cc-content get a minor bump (not patch) because each
has accumulated `feat` commits since `1.0.0` was set. This bump is what
makes the Claude Code updater notice pending content on other machines
today; the automated workflow takes over for every commit after this
baseline tag.

## Files touched

- `.github` repo (new):
  - `.github/workflows/plugin-release.yml`
  - `.github/scripts/bump-plugin-version.sh`
- Each of the 5 plugin repos (new):
  - `.github/workflows/release.yml` (~10-line caller)
- Each of the 5 plugin repos (edited, one-time):
  - `plugins/<name>/.claude-plugin/plugin.json` (version field)
  - a new `vX.Y.Z` git tag

No new dependencies: `bash`, `jq`, and `gh` are all preinstalled on
GitHub-hosted runners.

## Edge cases

- **Squash merges**: only the squash commit's header is inspected — this
  is correct because GitHub squash-merge uses the PR title as the header.
- **Multiple qualifying commits in one push**: highest bump wins; one
  release per push, not per commit.
- **Push with only ignored commit types** (e.g. `docs`, `chore`): workflow
  exits cleanly with no side effects — this is the expected steady state
  for changes that don't affect plugin behavior.

## Testing

- `bump-plugin-version.sh` is a standalone script: unit-testable locally
  by feeding it a list of commit header strings and asserting the computed
  bump.
- End-to-end: after rollout, merge a `fix:` commit into one plugin repo
  (e.g. cc-handoff, lowest-traffic) and confirm a tag, release, and
  `plugin.json` bump appear automatically.
