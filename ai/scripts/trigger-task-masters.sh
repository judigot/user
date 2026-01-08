#!/bin/sh

# Script to help trigger task-master agents for unclaimed worktrees
# Usage: ./trigger-task-masters.sh [worktree-path]

readonly PROJECT_DIRECTORY=$(cd "$(dirname "$0")/.." || exit 1; pwd)

main() {
  if [ -n "$1" ]; then
    check_worktree "$1"
  else
    list_unclaimed_worktrees
  fi
}

check_worktree() {
  readonly WORKTREE_PATH="$1"
  
  if [ ! -d "$WORKTREE_PATH" ]; then
    printf '%s\n' "Error: Worktree path does not exist: $WORKTREE_PATH" >&2
    exit 1
  fi
  
  readonly STATUS_FILE="$WORKTREE_PATH/.agent-task-context/.state/TASK_STATUS.unclaimed"
  readonly CONTEXT_FILE="$WORKTREE_PATH/.agent-task-context/Context.md"
  
  if [ ! -f "$STATUS_FILE" ]; then
    printf '%s\n' "Worktree is not unclaimed: $WORKTREE_PATH" >&2
    exit 1
  fi
  
  if [ ! -f "$CONTEXT_FILE" ]; then
    printf '%s\n' "Warning: Context.md missing in $WORKTREE_PATH" >&2
  fi
  
  readonly BRANCH_NAME=$(cat "$WORKTREE_PATH/.agent-task-context/BRANCH_NAME" 2>/dev/null)
  
  printf '%s\n' "Worktree: $WORKTREE_PATH"
  printf '%s\n' "Branch: ${BRANCH_NAME:-unknown}"
  printf '%s\n' "Status: unclaimed"
  printf '%s\n' ""
  printf '%s\n' "To trigger task-master:"
  printf '%s\n' "1. Open Cursor window in: $WORKTREE_PATH"
  printf '%s\n' "2. Invoke task-master agent"
  printf '%s\n' "3. Task-master will auto-discover and claim this worktree"
}

list_unclaimed_worktrees() {
  cd "$PROJECT_DIRECTORY" || exit 1
  
  if [ ! -d ".worktrees" ]; then
    printf '%s\n' "No .worktrees directory found" >&2
    exit 1
  fi
  
  readonly UNCLAIMED=$(find .worktrees -name "TASK_STATUS.unclaimed" 2>/dev/null | sort)
  
  if [ -z "$UNCLAIMED" ]; then
    printf '%s\n' "No unclaimed worktrees found"
    exit 0
  fi
  
  printf '%s\n' "Unclaimed worktrees ready for task-master:"
  printf '%s\n' ""
  
  for status_file in $UNCLAIMED; do
    readonly wt="${status_file%/.agent-task-context/.state/TASK_STATUS.unclaimed}"
    readonly branch=$(cat "$wt/.agent-task-context/BRANCH_NAME" 2>/dev/null || echo "unknown")
    
    printf '%s\n' "  - $wt"
    printf '%s\n' "    Branch: $branch"
    printf '%s\n' "    Path: $(cd "$PROJECT_DIRECTORY" && pwd)/$wt"
    printf '%s\n' ""
  done
  
  printf '%s\n' "To trigger task-master agents:"
  printf '%s\n' "1. Open a Cursor window for each worktree above"
  printf '%s\n' "2. In each window, invoke the task-master agent"
  printf '%s\n' "3. Task-master will auto-discover and claim the worktree"
}

main "$@"
