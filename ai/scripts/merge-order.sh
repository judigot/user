#!/bin/sh

readonly PROJECT_DIRECTORY=$(cd "$(dirname "$0")" || exit 1; pwd)

main() {
  if [ $# -lt 1 ]; then
    printf '%s\n' "Usage: $0 <config.json>" >&2
    printf '%s\n' "Example: $0 worktree-config.json" >&2
    exit 1
  fi

  readonly CONFIG_FILE="$1"
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

  readonly TOTAL=$(jq '.worktrees | length' "$CONFIG_FILE")
  readonly MERGE_ORDER=$(mktemp)
  readonly PROCESSED=$(mktemp)

  printf '' > "$MERGE_ORDER"
  printf '' > "$PROCESSED"

  while [ "$(wc -l < "$PROCESSED")" -lt "$TOTAL" ]; do
    readonly ROUND_START=$(wc -l < "$PROCESSED")
    
    jq -c '.worktrees[]' "$CONFIG_FILE" | while IFS= read -r worktree; do
      readonly BRANCH=$(echo "$worktree" | jq -r '.branch')
      readonly BRANCH_SLUG=$(echo "$BRANCH" | tr '/' '-')
      readonly DEPENDS_ON=$(echo "$worktree" | jq -r '.dependsOn[]? // empty')
      
      if grep -q "^$BRANCH$" "$PROCESSED" 2>/dev/null; then
        continue
      fi

      ALL_DEPS_MET=true
      for dep in $DEPENDS_ON; do
        if ! grep -q "^$dep$" "$PROCESSED" 2>/dev/null; then
          ALL_DEPS_MET=false
          break
        fi
      done

      if [ "$ALL_DEPS_MET" = "true" ]; then
        readonly WORKTREE_PATH="$WORKTREES_DIR/$BRANCH_SLUG"
        readonly STATUS_FILE=$(find "$WORKTREE_PATH/.agent-task-context/.state" -name "TASK_STATUS.*" 2>/dev/null | head -1)
        readonly STATUS=$(basename "$STATUS_FILE" 2>/dev/null | sed 's|TASK_STATUS\.||' || echo "unknown")

        if [ "$STATUS" = "done" ]; then
          printf '%s\n' "$BRANCH" >> "$MERGE_ORDER"
          printf '%s\n' "$BRANCH" >> "$PROCESSED"
        fi
      fi
    done

    readonly ROUND_END=$(wc -l < "$PROCESSED")
    if [ "$ROUND_START" -eq "$ROUND_END" ]; then
      printf '%s\n' "Warning: Circular dependency or missing dependencies detected" >&2
      break
    fi
  done

  printf '%s\n' "Merge order (based on dependencies and TASK_STATUS.done):"
  cat "$MERGE_ORDER"

  rm -f "$MERGE_ORDER" "$PROCESSED"
}

main "$@"
