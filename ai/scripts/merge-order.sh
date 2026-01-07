#!/bin/sh

readonly SCRIPT_DIR=$(cd "$(dirname "$0")" || exit 1; pwd)

usage() {
  printf '%s\n' "Usage: $0 <config.json>"
  printf '%s\n' "Determines merge order based on dependencies and TASK_STATUS.done"
  exit 1
}

main() {
  if [ $# -lt 1 ]; then
    usage
  fi

  readonly CONFIG_FILE="$1"
  if [ ! -f "$CONFIG_FILE" ]; then
    printf '%s\n' "Error: Config file not found: $CONFIG_FILE" >&2
    exit 1
  fi

  readonly BASE_DIR=$(jq -r '.baseDir // ".worktrees"' "$CONFIG_FILE")
  readonly BASE_BRANCH=$(jq -r '.baseBranch // "main"' "$CONFIG_FILE")
  
  if [ -z "$BASE_DIR" ] || [ "$BASE_DIR" = "null" ]; then
    printf '%s\n' "Error: baseDir is required in config" >&2
    exit 1
  fi

  readonly REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$REPO_ROOT" ]; then
    printf '%s\n' "Error: Not in a git repository" >&2
    exit 1
  fi

  cd "$REPO_ROOT" || exit 1

  readonly DONE_DIRS=$(find "$BASE_DIR" -name "TASK_STATUS.done" 2>/dev/null | while IFS= read -r status_file; do
    worktree_dir=$(dirname "$(dirname "$(dirname "$status_file")")")
    dir_name=$(basename "$worktree_dir")
    printf '%s\n' "$dir_name"
  done)

  if [ -z "$DONE_DIRS" ]; then
    printf '%s\n' "No worktrees with TASK_STATUS.done found"
    exit 0
  fi

  readonly DONE_DIRS_JSON=$(printf '%s\n' "$DONE_DIRS" | jq -R -s -c 'split("\n") | map(select(length > 0))')

  printf '%s\n' "Merge order (based on dependencies and status):"
  printf '%s\n' ""

  readonly SORTED=$(jq -r --argjson done_dirs "$DONE_DIRS_JSON" '.worktrees | 
    map(select(.dir as $dir | $done_dirs | index($dir) != null)) |
    sort_by(.priority // 0) |
    reverse |
    .[] | 
    "\(.branch) (depends on: \(.dependsOn | join(", ") // "none"))"
  ' "$CONFIG_FILE" 2>/dev/null)

  if [ -n "$SORTED" ]; then
    printf '%s\n' "$SORTED"
  else
    printf '%s\n' "No worktrees ready for merge (TASK_STATUS.done found but not in config)"
  fi
}

main "$@"
