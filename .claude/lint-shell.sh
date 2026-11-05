#!/usr/bin/env bash
# PostToolUse: runs shellcheck on edited .sh files; findings go to stderr with exit 2 so Claude sees them.
input=$(cat)
f=$(echo "$input" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
if [[ "$f" == *.sh ]] && command -v shellcheck >/dev/null 2>&1; then
  out=$(shellcheck "$f" 2>&1) || { echo "$out" >&2; exit 2; }
fi
exit 0
