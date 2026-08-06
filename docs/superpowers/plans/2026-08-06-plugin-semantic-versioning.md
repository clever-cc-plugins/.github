# Plugin Semantic Versioning Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every clever-cc-plugins repo's `plugin.json` version reflects reality automatically after each merge to `main`, and the three currently-stale repos (cc-concept, cc-config, cc-content) get bumped now so the Claude Code updater actually detects pending changes.

**Architecture:** A reusable GitHub Actions workflow in the `clever-cc-plugins/.github` repo (`plugin-release.yml`) runs a bash script that classifies commits since the last `vX.Y.Z` tag using Conventional Commits (tolerant of a leading gitmoji), bumps `plugin.json`'s `version` field via `jq`, commits, tags, and creates a GitHub Release. Each of the 5 plugin repos gets a ~10-line caller workflow that triggers on push to `main`.

**Tech Stack:** bash, jq, gh CLI, GitHub Actions (`workflow_call` reusable workflows) — all preinstalled on GitHub-hosted runners, no new dependencies.

## Global Constraints

- Commits use Conventional Commits with gitmoji (project-wide convention, e.g. `✨ feat(scope): ...`, `🐛 fix: ...`) — the parser must tolerate a leading emoji, and plain (no-emoji) Conventional Commits headers, both of which already occur in commit history.
- `plugin.json`'s `version` field is the sole source of truth the Claude Code updater reads — no other file (marketplace.json, a CHANGELOG) needs to change.
- No new runtime dependencies: only `bash`, `jq`, and `gh`, all present on `ubuntu-latest` GitHub-hosted runners.
- Every push to a shared remote (`git push origin ...`, tag push, `gh release create`) is a hard-to-reverse, shared-state action — pause and get explicit user confirmation immediately before each such push, per repo. Local commits/tags may be created without asking; pushing them is the gated step.
- Default branch for every repo in this plan is `main`.

---

### Task 1: Bump-version script + local unit tests

**Files:**

- Create: `.github/scripts/bump-plugin-version.sh` (in the `clever-cc-plugins/.github` repo, at `/home/vanlaarmi12/Git-Repos/clever-cc-plugins/.github`)
- Create: `.github/scripts/test-bump-plugin-version.sh`

**Interfaces:**

- Produces: `classify_commit(subject, body) -> "major"|"minor"|"patch"|"none"`, `highest_bump(...) -> "major"|"minor"|"patch"|"none"`, `bump_semver(version, bump) -> "X.Y.Z"`, `strip_emoji_prefix(subject) -> string`. Task 2's workflow invokes the script as a whole (via its `main` entry point, guarded by `BASH_SOURCE` so sourcing the file for tests does not run `main`), reading its `GITHUB_OUTPUT` keys `bump` and `new_version`.

- [ ] **Step 1: Write the failing test script**

Create `.github/scripts/test-bump-plugin-version.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=bump-plugin-version.sh
source "$(dirname "${BASH_SOURCE[0]}")/bump-plugin-version.sh"

fail=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$expected" != "$actual" ]]; then
    echo "FAIL: $desc -- expected '$expected', got '$actual'"
    fail=1
  else
    echo "PASS: $desc"
  fi
}

# strip_emoji_prefix
assert_eq "strips gitmoji" "feat: add thing" "$(strip_emoji_prefix "✨ feat: add thing")"
assert_eq "strips multi-codepoint gitmoji" "refactor!: drop prefix" "$(strip_emoji_prefix "♻️ refactor!: drop prefix")"
assert_eq "passes through plain header" "fix: bug" "$(strip_emoji_prefix "fix: bug")"

# classify_commit
assert_eq "feat with emoji -> minor" "minor" "$(classify_commit "✨ feat(x): add thing" "")"
assert_eq "fix with emoji -> patch" "patch" "$(classify_commit "🐛 fix: bug" "")"
assert_eq "perf -> patch" "patch" "$(classify_commit "perf: speed up" "")"
assert_eq "breaking bang -> major" "major" "$(classify_commit "♻️ refactor!: drop prefix" "")"
assert_eq "BREAKING CHANGE in body -> major" "major" "$(classify_commit "feat: add thing" "some body

BREAKING CHANGE: removes old API")"
assert_eq "docs -> none" "none" "$(classify_commit "📝 docs: update readme" "")"
assert_eq "chore -> none" "none" "$(classify_commit "🔥 chore: cleanup" "")"

# highest_bump
assert_eq "major beats minor and patch" "major" "$(highest_bump minor patch major none)"
assert_eq "minor beats patch" "minor" "$(highest_bump patch minor none)"
assert_eq "patch beats none" "patch" "$(highest_bump none patch none)"
assert_eq "all none -> none" "none" "$(highest_bump none none)"
assert_eq "empty -> none" "none" "$(highest_bump)"

# bump_semver
assert_eq "major bump" "2.0.0" "$(bump_semver "1.4.7" major)"
assert_eq "minor bump" "1.5.0" "$(bump_semver "1.4.7" minor)"
assert_eq "patch bump" "1.4.8" "$(bump_semver "1.4.7" patch)"

if [[ "$fail" -ne 0 ]]; then
  echo "Some tests FAILED"
  exit 1
fi
echo "All tests passed"
```

- [ ] **Step 2: Run the test script to verify it fails**

Run: `bash .github/scripts/test-bump-plugin-version.sh`
Expected: FAIL — `bump-plugin-version.sh: No such file or directory` (the sourced file doesn't exist yet).

- [ ] **Step 3: Write the implementation**

Create `.github/scripts/bump-plugin-version.sh`:

```bash
#!/usr/bin/env bash
# bump-plugin-version.sh
#
# Computes a semver bump for a clever-cc-plugins plugin repo from commits
# since the last vX.Y.Z tag, updates plugins/*/.claude-plugin/plugin.json,
# and creates a local commit + annotated tag. Does not push or create a
# GitHub Release -- the caller workflow does that after checking the
# `bump` output.
#
# Classification (Conventional Commits, gitmoji prefix tolerated):
#   type(scope)!: ...  or body contains "BREAKING CHANGE:" -> major
#   feat                                                     -> minor
#   fix, perf                                                -> patch
#   anything else (docs, chore, refactor, test, ci, style..) -> ignored
# The highest bump across all commits since the last tag wins. If there is
# no prior vX.Y.Z tag, or no release-worthy commits, this is a no-op that
# writes bump=none to $GITHUB_OUTPUT and exits 0.

set -euo pipefail

strip_emoji_prefix() {
  local subject="$1"
  if [[ "$subject" =~ ^[^a-zA-Z]*([a-zA-Z].*)$ ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
  else
    printf '%s' "$subject"
  fi
}

classify_commit() {
  local subject="$1" body="$2" stripped
  stripped="$(strip_emoji_prefix "$subject")"

  if [[ "$stripped" =~ ^[a-zA-Z]+(\([^\)]*\))?!: ]]; then
    echo "major"
    return
  fi
  if [[ "$body" == *"BREAKING CHANGE:"* ]]; then
    echo "major"
    return
  fi
  if [[ "$stripped" =~ ^feat(\([^\)]*\))?:[[:space:]] ]]; then
    echo "minor"
    return
  fi
  if [[ "$stripped" =~ ^(fix|perf)(\([^\)]*\))?:[[:space:]] ]]; then
    echo "patch"
    return
  fi
  echo "none"
}

highest_bump() {
  local level bump="none"
  for level in "$@"; do
    case "$level" in
      major) echo "major"; return ;;
      minor) bump="minor" ;;
      patch) [[ "$bump" == "none" ]] && bump="patch" ;;
    esac
  done
  echo "$bump"
}

bump_semver() {
  local version="$1" bump="$2" major minor patch
  IFS='.' read -r major minor patch <<< "$version"
  case "$bump" in
    major) echo "$((major + 1)).0.0" ;;
    minor) echo "$major.$((minor + 1)).0" ;;
    patch) echo "$major.$minor.$((patch + 1))" ;;
  esac
}

find_plugin_json() {
  local -a matches
  mapfile -t matches < <(find plugins -type f -name plugin.json)
  if [[ ${#matches[@]} -ne 1 ]]; then
    echo "Expected exactly one plugins/*/.claude-plugin/plugin.json, found ${#matches[@]}" >&2
    exit 1
  fi
  echo "${matches[0]}"
}

write_output() {
  local key="$1" value="$2"
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "${key}=${value}" >> "$GITHUB_OUTPUT"
  fi
}

main() {
  local last_tag plugin_json current_version bump new_version hash subject body
  local -a bumps=()

  if ! last_tag="$(git describe --tags --abbrev=0 2>/dev/null)"; then
    echo "No baseline tag found; skipping until the bootstrap tag exists."
    write_output "bump" "none"
    exit 0
  fi

  plugin_json="$(find_plugin_json)"

  while IFS= read -r hash; do
    [[ -z "$hash" ]] && continue
    subject="$(git show -s --format=%s "$hash")"
    body="$(git show -s --format=%B "$hash")"
    bumps+=("$(classify_commit "$subject" "$body")")
  done < <(git log "${last_tag}..HEAD" --format=%H)

  bump="$(highest_bump "${bumps[@]}")"

  if [[ "$bump" == "none" ]]; then
    echo "No release-worthy commits since ${last_tag}."
    write_output "bump" "none"
    exit 0
  fi

  current_version="$(jq -r '.version' "$plugin_json")"
  new_version="$(bump_semver "$current_version" "$bump")"

  jq --arg v "$new_version" '.version = $v' "$plugin_json" > "${plugin_json}.tmp"
  mv "${plugin_json}.tmp" "$plugin_json"

  git add "$plugin_json"
  git commit -m "🔖 chore(release): v${new_version}"
  git tag -a "v${new_version}" -m "v${new_version}"

  echo "Bumped ${current_version} -> ${new_version} (${bump})"
  write_output "bump" "$bump"
  write_output "new_version" "$new_version"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
```

- [ ] **Step 4: Run the test script to verify it passes**

Run: `chmod +x .github/scripts/bump-plugin-version.sh .github/scripts/test-bump-plugin-version.sh && bash .github/scripts/test-bump-plugin-version.sh`
Expected: every line prints `PASS:` and the script ends with `All tests passed`.

- [ ] **Step 5: Shellcheck both scripts**

Run: `shellcheck .github/scripts/bump-plugin-version.sh .github/scripts/test-bump-plugin-version.sh`
Expected: no warnings/errors. Fix anything shellcheck flags (e.g. quoting) and re-run Step 4 to confirm tests still pass.

- [ ] **Step 6: Commit (local only)**

```bash
cd /home/vanlaarmi12/Git-Repos/clever-cc-plugins/.github
git add .github/scripts/bump-plugin-version.sh .github/scripts/test-bump-plugin-version.sh
git commit -m "✨ feat: add plugin version bump script with unit tests"
```

---

### Task 2: Reusable release workflow

**Files:**

- Create: `.github/workflows/plugin-release.yml` (in the `clever-cc-plugins/.github` repo)

**Interfaces:**

- Consumes: `.github/scripts/bump-plugin-version.sh` from Task 1 (its `main` entry point, `GITHUB_OUTPUT` keys `bump` and `new_version`).
- Produces: a `workflow_call` reusable workflow at `clever-cc-plugins/.github/.github/workflows/plugin-release.yml`, invoked as `uses: clever-cc-plugins/.github/.github/workflows/plugin-release.yml@main` — this exact reference string is what Task 3-7's caller workflows use.

- [ ] **Step 1: Write the workflow**

Create `.github/workflows/plugin-release.yml`:

```yaml
name: Plugin release

on:
  workflow_call: {}

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - name: Checkout plugin repo
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
          fetch-tags: true

      - name: Checkout release tooling
        uses: actions/checkout@v4
        with:
          repository: clever-cc-plugins/.github
          path: .release-tools
          sparse-checkout: |
            .github/scripts
          sparse-checkout-cone-mode: false

      - name: Configure git identity
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"

      - name: Compute version bump
        id: bump
        run: bash .release-tools/.github/scripts/bump-plugin-version.sh

      - name: Push release
        if: steps.bump.outputs.bump != 'none' && steps.bump.outputs.bump != ''
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          git push origin HEAD:main --follow-tags
          gh release create "v${{ steps.bump.outputs.new_version }}" --generate-notes
```

- [ ] **Step 2: Validate YAML syntax**

Run:

```bash
pip install --quiet --user pyyaml
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/plugin-release.yml')); print('valid')"
```

Expected: `valid`.

- [ ] **Step 3: Commit (local only)**

```bash
git add .github/workflows/plugin-release.yml
git commit -m "✨ feat: add reusable plugin-release workflow"
```

---

### Task 3: cc-chime bootstrap

**Files:**

- Modify: `plugins/cc-chime/.claude-plugin/plugin.json` (in the `cc-chime` repo, at `/home/vanlaarmi12/Git-Repos/clever-cc-plugins/cc-chime`)
- Create: `.github/workflows/release.yml`

**Interfaces:**

- Consumes: `clever-cc-plugins/.github/.github/workflows/plugin-release.yml@main` from Task 2.

- [ ] **Step 1: Add the version field**

Read the current file first, then insert `"version": "1.0.0"` immediately after `"description"` (before `"author"`), matching the key order already used in cc-concept/cc-config/cc-content's `plugin.json`. Result:

```json
{
  "name": "cc-chime",
  "description": "Plays an audio notification at the end of every Claude turn and when Claude needs your input",
  "version": "1.0.0",
  "author": {
    "name": "Michael van Laar"
  },
  "homepage": "https://github.com/clever-cc-plugins/cc-chime",
  "repository": "https://github.com/clever-cc-plugins/cc-chime",
  "license": "MIT",
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/scripts/notify.sh\""
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/scripts/notify.sh\""
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: Add the caller workflow**

Create `.github/workflows/release.yml`:

```yaml
name: Release

on:
  push:
    branches: [main]

permissions:
  contents: write

jobs:
  release:
    uses: clever-cc-plugins/.github/.github/workflows/plugin-release.yml@main
    permissions:
      contents: write
```

- [ ] **Step 3: Verify plugin.json is still valid JSON**

Run: `jq . plugins/cc-chime/.claude-plugin/plugin.json`
Expected: pretty-printed JSON, no parse error.

- [ ] **Step 4: Commit (local only)**

```bash
cd /home/vanlaarmi12/Git-Repos/clever-cc-plugins/cc-chime
git add plugins/cc-chime/.claude-plugin/plugin.json .github/workflows/release.yml
git commit -m "🔖 chore(release): v1.0.0 -- add version field and release automation"
```

- [ ] **Step 5: Confirm with user, then push commit and tag**

Ask the user to confirm before pushing (this is a shared remote and will make `.github`'s reusable workflow live for this repo). On confirmation:

```bash
git tag -a v1.0.0 -m "v1.0.0"
git push origin main
git push origin v1.0.0
```

---

### Task 4: cc-handoff bootstrap

**Files:**

- Modify: `plugins/cc-handoff/.claude-plugin/plugin.json` (in the `cc-handoff` repo, at `/home/vanlaarmi12/Git-Repos/clever-cc-plugins/cc-handoff`)
- Create: `.github/workflows/release.yml`

**Interfaces:**

- Consumes: `clever-cc-plugins/.github/.github/workflows/plugin-release.yml@main` from Task 2.

- [ ] **Step 1: Add the version field**

Read the current file first, then insert `"version": "1.0.0"` immediately after `"description"` (before `"author"`):

```json
{
  "name": "cc-handoff",
  "description": "Create and restore machine-transfer handoff summaries between Claude Code sessions",
  "version": "1.0.0",
  "author": {
    "name": "Michael van Laar"
  },
  "homepage": "https://github.com/clever-cc-plugins/cc-handoff",
  "repository": "https://github.com/clever-cc-plugins/cc-handoff",
  "license": "MIT"
}
```

- [ ] **Step 2: Add the caller workflow**

Create `.github/workflows/release.yml` with the identical content used in Task 3 Step 2.

- [ ] **Step 3: Verify plugin.json is still valid JSON**

Run: `jq . plugins/cc-handoff/.claude-plugin/plugin.json`
Expected: pretty-printed JSON, no parse error.

- [ ] **Step 4: Commit (local only)**

```bash
cd /home/vanlaarmi12/Git-Repos/clever-cc-plugins/cc-handoff
git add plugins/cc-handoff/.claude-plugin/plugin.json .github/workflows/release.yml
git commit -m "🔖 chore(release): v1.0.0 -- add version field and release automation"
```

- [ ] **Step 5: Confirm with user, then push commit and tag**

```bash
git tag -a v1.0.0 -m "v1.0.0"
git push origin main
git push origin v1.0.0
```

---

### Task 5: cc-concept bootstrap (catch-up bump)

**Files:**

- Modify: `plugins/cc-concept/.claude-plugin/plugin.json` (in the `cc-concept` repo, at `/home/vanlaarmi12/Git-Repos/clever-cc-plugins/cc-concept`)
- Create: `.github/workflows/release.yml`

**Interfaces:**

- Consumes: `clever-cc-plugins/.github/.github/workflows/plugin-release.yml@main` from Task 2.

- [ ] **Step 1: Bump the version field**

Read the current file first, then change `"version": "1.0.0"` to `"version": "1.1.0"` (minor bump: `feat` commits have landed since 1.0.0 was set and never released).

- [ ] **Step 2: Add the caller workflow**

Create `.github/workflows/release.yml` with the identical content used in Task 3 Step 2.

- [ ] **Step 3: Verify plugin.json is still valid JSON**

Run: `jq . plugins/cc-concept/.claude-plugin/plugin.json`
Expected: pretty-printed JSON, `.version` is `"1.1.0"`.

- [ ] **Step 4: Commit (local only)**

```bash
cd /home/vanlaarmi12/Git-Repos/clever-cc-plugins/cc-concept
git add plugins/cc-concept/.claude-plugin/plugin.json .github/workflows/release.yml
git commit -m "🔖 chore(release): v1.1.0 -- catch-up bump and add release automation"
```

- [ ] **Step 5: Confirm with user, then push commit and tag**

```bash
git tag -a v1.1.0 -m "v1.1.0"
git push origin main
git push origin v1.1.0
```

---

### Task 6: cc-config bootstrap (catch-up bump)

**Files:**

- Modify: `plugins/cc-config/.claude-plugin/plugin.json` (in the `cc-config` repo, at `/home/vanlaarmi12/Git-Repos/clever-cc-plugins/cc-config`)
- Create: `.github/workflows/release.yml`

**Interfaces:**

- Consumes: `clever-cc-plugins/.github/.github/workflows/plugin-release.yml@main` from Task 2.

- [ ] **Step 1: Bump the version field**

Read the current file first, then change `"version": "1.0.0"` to `"version": "1.1.0"`.

- [ ] **Step 2: Add the caller workflow**

Create `.github/workflows/release.yml` with the identical content used in Task 3 Step 2.

- [ ] **Step 3: Verify plugin.json is still valid JSON**

Run: `jq . plugins/cc-config/.claude-plugin/plugin.json`
Expected: pretty-printed JSON, `.version` is `"1.1.0"`.

- [ ] **Step 4: Commit (local only)**

```bash
cd /home/vanlaarmi12/Git-Repos/clever-cc-plugins/cc-config
git add plugins/cc-config/.claude-plugin/plugin.json .github/workflows/release.yml
git commit -m "🔖 chore(release): v1.1.0 -- catch-up bump and add release automation"
```

- [ ] **Step 5: Confirm with user, then push commit and tag**

```bash
git tag -a v1.1.0 -m "v1.1.0"
git push origin main
git push origin v1.1.0
```

---

### Task 7: cc-content bootstrap (catch-up bump)

**Files:**

- Modify: `plugins/cc-content/.claude-plugin/plugin.json` (in the `cc-content` repo, at `/home/vanlaarmi12/Git-Repos/clever-cc-plugins/cc-content`)
- Create: `.github/workflows/release.yml`

**Interfaces:**

- Consumes: `clever-cc-plugins/.github/.github/workflows/plugin-release.yml@main` from Task 2.

- [ ] **Step 1: Bump the version field**

Read the current file first, then change `"version": "1.0.0"` to `"version": "1.1.0"` (this is the repo from the original bug report — cc-content has 10 `feat`/`fix`/`docs` commits since Aug 4 that were never reflected in the version).

- [ ] **Step 2: Add the caller workflow**

Create `.github/workflows/release.yml` with the identical content used in Task 3 Step 2.

- [ ] **Step 3: Verify plugin.json is still valid JSON**

Run: `jq . plugins/cc-content/.claude-plugin/plugin.json`
Expected: pretty-printed JSON, `.version` is `"1.1.0"`.

- [ ] **Step 4: Commit (local only)**

```bash
cd /home/vanlaarmi12/Git-Repos/clever-cc-plugins/cc-content
git add plugins/cc-content/.claude-plugin/plugin.json .github/workflows/release.yml
git commit -m "🔖 chore(release): v1.1.0 -- catch-up bump and add release automation"
```

- [ ] **Step 5: Confirm with user, then push commit and tag**

```bash
git tag -a v1.1.0 -m "v1.1.0"
git push origin main
git push origin v1.1.0
```

---

### Task 8: Push Task 1/2 (.github repo) and end-to-end validation

**Files:**

- None new — pushes the commits from Tasks 1-2, then validates the whole chain with a throwaway commit in cc-handoff.

**Interfaces:**

- Consumes: everything from Tasks 1-7.

- [ ] **Step 1: Confirm with user, then push the .github repo**

Tasks 1 and 2 must land in `clever-cc-plugins/.github` on `main` before any plugin repo's caller workflow can resolve `uses: clever-cc-plugins/.github/.github/workflows/plugin-release.yml@main`. Push it first, before Task 3-7's pushes if those haven't happened yet either:

```bash
cd /home/vanlaarmi12/Git-Repos/clever-cc-plugins/.github
git push origin main
```

- [ ] **Step 2: Confirm ordering — push Task 3-7 repos if not already done**

If Tasks 3-7's push steps were deferred, do them now (each still needs its own explicit confirmation per that task's Step 5).

- [ ] **Step 3: End-to-end validation on cc-handoff**

cc-handoff is the lowest-traffic repo, good for a real test. After confirming with the user:

```bash
cd /home/vanlaarmi12/Git-Repos/clever-cc-plugins/cc-handoff
git commit --allow-empty -m "🐛 fix: trigger release automation smoke test"
git push origin main
```

- [ ] **Step 4: Watch the workflow run and verify the result**

```bash
gh run watch --repo clever-cc-plugins/cc-handoff
```

Expected: the run succeeds, and afterward:

- `git ls-remote --tags origin` (in cc-handoff) shows a new `v1.0.1` tag.
- `gh release view v1.0.1 --repo clever-cc-plugins/cc-handoff` shows an auto-generated release.
- `git pull && jq .version plugins/cc-handoff/.claude-plugin/plugin.json` shows `"1.0.1"`.

- [ ] **Step 5: Clean up the smoke-test commit's effect if desired**

This is a real patch release (v1.0.1) left in place intentionally — it proves the pipeline works and costs nothing to leave. No cleanup needed unless the user wants a clean release history, in which case ask before deleting the tag/release.
