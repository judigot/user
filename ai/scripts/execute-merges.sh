#!/bin/sh

readonly PROJECT_DIRECTORY=$(cd "$(dirname "$0")" || exit 1; pwd)

main() {
  if [ $# -lt 1 ]; then
    printf '%s\n' "Usage: $0 <config.json> [--dry-run]" >&2
    printf '%s\n' "Example: $0 worktree-config.json" >&2
    printf '%s\n' "Example: $0 worktree-config.json --dry-run" >&2
    exit 1
  fi

  readonly CONFIG_FILE="$1"
  readonly DRY_RUN=false
  if [ "${2:-}" = "--dry-run" ]; then
    readonly DRY_RUN=true
  fi

  if [ ! -f "$CONFIG_FILE" ]; then
    printf '%s\n' "Error: Config file not found: $CONFIG_FILE" >&2
    exit 1
  fi

  readonly REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$REPO_ROOT" ]; then
    printf '%s\n' "Error: Not in a git repository" >&2
    exit 1
  fi

  cd "$REPO_ROOT" || exit 1

  readonly BASE_BRANCH=$(jq -r '.baseBranch // "main"' "$CONFIG_FILE")
  readonly WORKTREES_DIR=".worktrees"

  if [ ! -d "$WORKTREES_DIR" ]; then
    printf '%s\n' "Error: Worktrees directory not found: $WORKTREES_DIR" >&2
    exit 1
  fi

  readonly MERGE_ORDER_SCRIPT="$PROJECT_DIRECTORY/merge-order.sh"
  readonly MERGE_ORDER=$(sh "$MERGE_ORDER_SCRIPT" "$CONFIG_FILE" | grep -v "^Merge order")

  if [ -z "$MERGE_ORDER" ]; then
    printf '%s\n' "No branches ready for merge (all must have TASK_STATUS.done)" >&2
    exit 1
  fi

  git fetch origin || {
    printf '%s\n' "Error: Failed to fetch from origin" >&2
    exit 1
  }

  git checkout "$BASE_BRANCH" || {
    printf '%s\n' "Error: Failed to checkout $BASE_BRANCH" >&2
    exit 1
  }

  git pull origin "$BASE_BRANCH" || {
    printf '%s\n' "Error: Failed to pull $BASE_BRANCH" >&2
    exit 1
  }

  printf '%s\n' "$MERGE_ORDER" | while IFS= read -r branch; do
    [ -z "$branch" ] && continue

    readonly BRANCH_SLUG=$(echo "$branch" | tr '/' '-')
    readonly WORKTREE_PATH="$WORKTREES_DIR/$BRANCH_SLUG"

    if [ ! -d "$WORKTREE_PATH" ]; then
      printf '%s\n' "Warning: Worktree not found: $WORKTREE_PATH, skipping $branch" >&2
      continue
    fi

    printf '%s\n' "Merging $branch into $BASE_BRANCH..."

    if [ "$DRY_RUN" = "true" ]; then
      printf '%s\n' "[DRY RUN] Would merge $branch into $BASE_BRANCH"
      git merge --no-commit --no-ff "$branch" 2>&1 || true
      git merge --abort 2>/dev/null || true
    else
      git merge --no-ff "$branch" -m "merge: $branch into $BASE_BRANCH" || {
        printf '%s\n' "Error: Merge conflict or failure for $branch" >&2
        printf '%s\n' "Please resolve conflicts and run again" >&2
        exit 1
      }
    fi
  done

  if [ "$DRY_RUN" = "false" ]; then
    printf '%s\n' "All merges completed successfully"
    printf '%s\n' "Review changes with: git log --oneline -10"
    printf '%s\n' "Push with: git push origin $BASE_BRANCH"
  else
    printf '%s\n' "[DRY RUN] No changes were made"
  fi
}

main "$@"
