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
