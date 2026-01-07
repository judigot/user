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

  mkdir -p "$WORKTREES_DIR"

  jq -c '.worktrees[]' "$CONFIG_FILE" | while IFS= read -r worktree; do
    readonly DIR=$(echo "$worktree" | jq -r '.dir')
    readonly BRANCH=$(echo "$worktree" | jq -r '.branch')
    readonly BRANCH_SLUG=$(echo "$BRANCH" | tr '/' '-')
    readonly WORKTREE_PATH="$WORKTREES_DIR/$BRANCH_SLUG"

    if [ -d "$WORKTREE_PATH" ]; then
      printf '%s\n' "Skipping $WORKTREE_PATH (already exists)"
      continue
    fi

    printf '%s\n' "Creating worktree: $WORKTREE_PATH for branch: $BRANCH"

    git worktree add "$WORKTREE_PATH" -b "$BRANCH" "$BASE_BRANCH" || {
      printf '%s\n' "Error: Failed to create worktree for $BRANCH" >&2
      continue
    }

    readonly CONTEXT_DIR="$WORKTREE_PATH/.agent-task-context"
    readonly STATE_DIR="$CONTEXT_DIR/.state"

    mkdir -p "$STATE_DIR"

    printf '%s\n' "$BRANCH" > "$CONTEXT_DIR/BRANCH_NAME"

    cat > "$CONTEXT_DIR/Context.md" << EOF
# Context: $BRANCH

## Goal
<Clear, one-sentence objective explaining what needs to be accomplished>

## Background
<Why this task exists, what problem it solves, and any relevant context about the codebase or system>

## Scope
**Touch only:**
- <explicit list of files/directories that CAN be modified>

**Do not touch:**
- <explicit list of files/directories that MUST NOT be modified>

**Dependencies:**
- <related systems, files, or components to be aware of>

## Step-by-Step Instructions
<Detailed, actionable steps written for a junior developer>

## Definition of Done
- <clear checklist item 1>
- <clear checklist item 2>
- <clear checklist item 3>

## Examples
<Code examples, patterns to follow, or reference implementations>

## Troubleshooting
**Common Issue 1:**
- Problem: <description>
- Solution: <how to fix it>

## Notes / Decisions
<important decisions made during implementation>
EOF

    touch "$STATE_DIR/TASK_STATUS.unclaimed"

    cd "$WORKTREE_PATH" || exit 1
    git add .agent-task-context/BRANCH_NAME .agent-task-context/Context.md
    git commit -m "chore: initialize worktree context" || true
    git push -u origin "$BRANCH" || true
    cd "$REPO_ROOT" || exit 1

    printf '%s\n' "Created worktree: $WORKTREE_PATH"
  done

  printf '%s\n' "Worktree initialization complete"
}

main "$@"
