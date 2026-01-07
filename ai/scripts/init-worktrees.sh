#!/bin/sh

readonly SCRIPT_DIR=$(cd "$(dirname "$0")" || exit 1; pwd)

usage() {
  printf '%s\n' "Usage: $0 <config.json>"
  printf '%s\n' "Creates git worktrees from JSON configuration file"
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

  if [ -z "$BASE_BRANCH" ] || [ "$BASE_BRANCH" = "null" ]; then
    printf '%s\n' "Error: baseBranch is required in config" >&2
    exit 1
  fi

  mkdir -p "$BASE_DIR"

  readonly REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$REPO_ROOT" ]; then
    printf '%s\n' "Error: Not in a git repository" >&2
    exit 1
  fi

  cd "$REPO_ROOT" || exit 1

  readonly WORKTREES_COUNT=$(jq '.worktrees | length' "$CONFIG_FILE")
  printf '%s\n' "Found $WORKTREES_COUNT worktrees in config"

  i=0
  while [ $i -lt "$WORKTREES_COUNT" ]; do
    readonly WORKTREE=$(jq -r ".worktrees[$i]" "$CONFIG_FILE")
    readonly ID=$(echo "$WORKTREE" | jq -r '.id // ""')
    readonly BRANCH=$(echo "$WORKTREE" | jq -r '.branch // ""')
    readonly DIR=$(echo "$WORKTREE" | jq -r '.dir // ""')
    readonly STATUS=$(echo "$WORKTREE" | jq -r '.status // "ready"')

    if [ -z "$BRANCH" ] || [ "$BRANCH" = "null" ]; then
      printf '%s\n' "Error: branch is required for worktree $i" >&2
      i=$((i + 1))
      continue
    fi

    if [ -z "$DIR" ] || [ "$DIR" = "null" ]; then
      printf '%s\n' "Error: dir is required for worktree $i" >&2
      i=$((i + 1))
      continue
    fi

    readonly WORKTREE_PATH="$BASE_DIR/$DIR"

    if [ -d "$WORKTREE_PATH" ]; then
      printf '%s\n' "Skipping $WORKTREE_PATH (already exists)"
      i=$((i + 1))
      continue
    fi

    printf '%s\n' "Creating worktree: $WORKTREE_PATH for branch $BRANCH"

    if git worktree add "$WORKTREE_PATH" -b "$BRANCH" 2>/dev/null; then
      printf '%s\n' "  ✓ Created worktree and branch"
    elif git worktree add "$WORKTREE_PATH" "$BRANCH" 2>/dev/null; then
      printf '%s\n' "  ✓ Created worktree (branch already exists)"
    else
      printf '%s\n' "  ✗ Failed to create worktree" >&2
      i=$((i + 1))
      continue
    fi

    readonly CONTEXT_DIR="$WORKTREE_PATH/.agent-task-context"
    readonly STATE_DIR="$CONTEXT_DIR/.state"
    mkdir -p "$STATE_DIR"

    printf '%s\n' "$BRANCH" > "$CONTEXT_DIR/BRANCH_NAME"

    if [ ! -f "$CONTEXT_DIR/Context.md" ]; then
      cat > "$CONTEXT_DIR/Context.md" << 'EOF'
# Context: <branch-name>

## Goal
<Clear, one-sentence objective explaining what needs to be accomplished>

## Background
<Why this task exists, what problem it solves, and any relevant context>

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
- <important decisions made during implementation>
EOF
    fi

    case "$STATUS" in
      ready|unclaimed)
        touch "$STATE_DIR/TASK_STATUS.unclaimed"
        ;;
      claimed)
        touch "$STATE_DIR/TASK_STATUS.claimed"
        ;;
      paused)
        touch "$STATE_DIR/TASK_STATUS.paused"
        ;;
      done)
        touch "$STATE_DIR/TASK_STATUS.done"
        ;;
      abandoned)
        touch "$STATE_DIR/TASK_STATUS.abandoned"
        ;;
      *)
        touch "$STATE_DIR/TASK_STATUS.unclaimed"
        ;;
    esac

    cd "$WORKTREE_PATH" || exit 1
    git add .agent-task-context/BRANCH_NAME .agent-task-context/Context.md 2>/dev/null
    git commit -m "chore: initialize worktree context" 2>/dev/null || true
    git push -u origin "$BRANCH" 2>/dev/null || true
    cd "$REPO_ROOT" || exit 1

    printf '%s\n' "  ✓ Initialized context files"
    i=$((i + 1))
  done

  printf '%s\n' "Worktree initialization complete"
}

main "$@"
