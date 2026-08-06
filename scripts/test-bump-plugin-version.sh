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
