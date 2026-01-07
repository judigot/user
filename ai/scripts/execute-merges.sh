#!/bin/sh

readonly SCRIPT_DIR=$(cd "$(dirname "$0")" || exit 1; pwd)

usage() {
  printf '%s\n' "Usage: $0 <config.json> [--dry-run]"
  printf '%s\n' "Executes merges in correct dependency order"
  exit 1
}

main() {
  if [ $# -lt 1 ]; then
    usage
  fi

  readonly CONFIG_FILE="$1"
  DRY_RUN=false
  if [ "$2" = "--dry-run" ]; then
    DRY_RUN=true
  fi
  readonly DRY_RUN

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

  if [ -z "$BASE_BRANCH" ] || [ "$BASE_BRANCH" = "null" ]; then
    printf '%s\n' "Error: baseBranch is required in config" >&2
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

  readonly MERGE_ORDER=$(jq -r --argjson done_dirs "$DONE_DIRS_JSON" '.worktrees | 
    map(select(.dir as $dir | $done_dirs | index($dir) != null)) |
    sort_by(.priority // 0) |
    reverse |
    .[] | 
    "\(.branch)|\(.dir)|\(.dependsOn | join(",") // "")"
  ' "$CONFIG_FILE" 2>/dev/null)

  if [ -z "$MERGE_ORDER" ]; then
    printf '%s\n' "No worktrees ready for merge (status: done)"
    exit 0
  fi

  if [ "$DRY_RUN" = "true" ]; then
    printf '%s\n' "DRY RUN: Would merge in this order:"
    printf '%s\n' ""
  else
    printf '%s\n' "Executing merges in dependency order:"
    printf '%s\n' ""
  fi

  printf '%s\n' "$MERGE_ORDER" | while IFS='|' read -r branch dir depends_on; do
    if [ -z "$branch" ] || [ -z "$dir" ]; then
      continue
    fi

    readonly WORKTREE_PATH="$BASE_DIR/$dir"
    if [ ! -d "$WORKTREE_PATH" ]; then
      printf '%s\n' "Skipping $branch: worktree not found at $WORKTREE_PATH"
      continue
    fi

    if [ ! -f "$WORKTREE_PATH/.agent-task-context/.state/TASK_STATUS.done" ]; then
      printf '%s\n' "Skipping $branch: TASK_STATUS.done not found"
      continue
    fi

    if [ -n "$depends_on" ] && [ "$depends_on" != "" ]; then
      printf '%s\n' "Branch $branch depends on: $depends_on"
      printf '%s\n' "  (Ensure dependencies are merged first)"
    fi

    if [ "$DRY_RUN" = "true" ]; then
      printf '%s\n' "  [DRY RUN] Would merge $branch into $BASE_BRANCH"
    else
      printf '%s\n' "Merging $branch into $BASE_BRANCH..."
      
      git fetch origin 2>/dev/null || true
      git checkout "$BASE_BRANCH" 2>/dev/null || exit 1
      git pull origin "$BASE_BRANCH" 2>/dev/null || true
      
      if git merge --no-ff "$branch" -m "Merge $branch into $BASE_BRANCH" 2>/dev/null; then
        printf '%s\n' "  ✓ Merged successfully"
        git push origin "$BASE_BRANCH" 2>/dev/null || true
      else
        printf '%s\n' "  ✗ Merge failed (conflicts or errors)" >&2
        git merge --abort 2>/dev/null || true
        exit 1
      fi
    fi
    printf '%s\n' ""
  done

  if [ "$DRY_RUN" = "true" ]; then
    printf '%s\n' "Dry run complete. Run without --dry-run to execute merges."
  else
    printf '%s\n' "Merge execution complete"
  fi
}

main "$@"
