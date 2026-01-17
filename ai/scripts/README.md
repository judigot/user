# CLI-Native Worktree Workflow

This directory contains scripts for managing git worktrees using JSON configuration files. This workflow enables dependency-aware merge ordering and automated worktree initialization.

## Overview

The CLI-native workflow provides:
- **JSON-based configuration**: Define worktrees with dependencies in a single file
- **Dependency-aware merge ordering**: Automatically determines merge order based on `dependsOn` relationships
- **Status-aware**: Only includes branches with `TASK_STATUS.done` in merge order
- **CLI-native**: All scripts work in Claude Code terminal
- **Safety**: Dry-run mode to preview merges before execution

## Ralph Loop Workflow (Sequential, Hands-Off)

The Ralph loop runs one small task per iteration with a fresh agent context. Use this when tasks overlap or you want strict sequencing.

**Files:**
- `ai/scripts/ralph/ralph.sh` - the loop runner
- `ai/scripts/ralph/prompt.md` - instructions for each iteration
- `ai/scripts/ralph/prd.json.example` - example task format

**Minimum setup:**
1) Copy `ai/scripts/ralph/` into the target project (or reference it directly).
2) Create a `prd.json` in `ai/scripts/ralph/` (same folder as `ralph.sh`).
3) Run the loop:
```sh
./ai/scripts/ralph/ralph.sh 10
```

**How it works:**
- Picks the highest priority story where `passes: false`
- Implements that single story
- Runs checks (as defined in `prompt.md`)
- Commits if checks pass
- Marks the story as `passes: true`
- Appends learnings to `progress.txt`
- Repeats until all stories pass or max iterations reached

## Worked Examples (Beginner-Friendly)

These examples are intentionally simple and boring so any low-tier agent or beginner can follow them.

### Example A: Two Tiny Tasks in Parallel (Worktrees)

**Goal:** Create two files in parallel: `file1.txt` and `file2.txt`.

1) Create a worktree config:
```sh
cat > worktree-config.json << 'EOF'
{
  "baseDir": ".worktrees",
  "baseBranch": "main",
  "worktrees": [
    { "id": "file1", "branch": "feat/file1", "dir": "feat-file1", "status": "unclaimed" },
    { "id": "file2", "branch": "feat/file2", "dir": "feat-file2", "status": "unclaimed" }
  ]
}
EOF
```

2) Initialize worktrees:
```sh
~/ai/scripts/init-worktrees.sh worktree-config.json
```

3) Open two editor windows:
- Window A: `.worktrees/feat-file1`
- Window B: `.worktrees/feat-file2`

4) In Window A:
- Create `.worktrees/feat-file1/file1.txt` with any text
- Commit: `feat: add file1`
- Mark status done: `touch .agent-task-context/.state/TASK_STATUS.done`

5) In Window B:
- Create `.worktrees/feat-file2/file2.txt` with any text
- Commit: `feat: add file2`
- Mark status done: `touch .agent-task-context/.state/TASK_STATUS.done`

6) Merge in order:
```sh
~/ai/scripts/merge-order.sh worktree-config.json
~/ai/scripts/execute-merges.sh worktree-config.json --dry-run
~/ai/scripts/execute-merges.sh worktree-config.json
```

### Example B: Two Tiny Tasks Sequentially (Ralph Loop)

**Goal:** Create two files one after another in the same branch.

1) Create `prd.json` in `ai/scripts/ralph/`:
```sh
cat > ai/scripts/ralph/prd.json << 'EOF'
{
  "branchName": "ralph/tiny-files",
  "userStories": [
    {
      "id": "story-1",
      "title": "Create fileA.txt",
      "priority": 2,
      "passes": false
    },
    {
      "id": "story-2",
      "title": "Create fileB.txt",
      "priority": 1,
      "passes": false
    }
  ]
}
EOF
```

2) Run the loop:
```sh
./ai/scripts/ralph/ralph.sh 5
```

3) Expected result:
- Iteration 1 creates `fileA.txt` and marks story-1 as `passes: true`
- Iteration 2 creates `fileB.txt` and marks story-2 as `passes: true`
- The loop prints `<promise>COMPLETE</promise>`

## Configuration Format

Create a JSON configuration file (e.g., `worktree-config.json`):

```json
{
  "baseDir": ".worktrees/w",
  "baseBranch": "main",
  "worktrees": [
    {
      "id": "feat-auth-refresh",
      "branch": "feat/auth-refresh",
      "dir": "repo--feat-auth-refresh",
      "priority": 10,
      "dependsOn": [],
      "status": "ready"
    },
    {
      "id": "fix-payment-webhook",
      "branch": "fix/payment-webhook",
      "dir": "repo--fix-payment-webhook",
      "priority": 2,
      "dependsOn": ["feat/auth-refresh"],
      "status": "ready"
    }
  ]
}
```

### Configuration Fields

- **`baseDir`** (required): Base directory for worktrees (default: `.worktrees`)
- **`baseBranch`** (required): Target branch for merges (default: `main`)
- **`worktrees`** (required): Array of worktree definitions
  - **`id`**: Unique identifier for the worktree
  - **`branch`**: Git branch name (with forward slashes, e.g., `feat/auth-refresh`)
  - **`dir`**: Directory name within baseDir (kebab-case, e.g., `repo--feat-auth-refresh`)
  - **`priority`**: Merge priority (higher = merge first, optional)
  - **`dependsOn`**: Array of branch names this worktree depends on (optional)
  - **`status`**: Initial status (`ready`, `unclaimed`, `claimed`, `paused`, `done`, `abandoned`)

## Scripts

### 1. `init-worktrees.sh`

Creates worktrees from JSON configuration.

**Usage:**
```sh
~/ai/scripts/init-worktrees.sh worktree-config.json
```

**What it does:**
- Creates all worktrees defined in config
- Initializes `.agent-task-context/` files (BRANCH_NAME, Context.md)
- Sets initial TASK_STATUS based on `status` field
- Commits BRANCH_NAME and Context.md
- Pushes branches to remote

**Example:**
```sh
~/ai/scripts/init-worktrees.sh worktree-config.json
# Found 2 worktrees in config
# Creating worktree: .worktrees/w/repo--feat-auth-refresh for branch feat/auth-refresh
#   ✓ Created worktree and branch
#   ✓ Initialized context files
# Creating worktree: .worktrees/w/repo--fix-payment-webhook for branch fix/payment-webhook
#   ✓ Created worktree and branch
#   ✓ Initialized context files
# Worktree initialization complete
```

### 2. `merge-order.sh`

Determines merge order based on dependencies and TASK_STATUS.done.

**Usage:**
```sh
~/ai/scripts/merge-order.sh worktree-config.json
```

**What it does:**
- Lists worktrees with `TASK_STATUS.done`
- Orders by dependencies (`dependsOn` relationships)
- Orders by priority (higher priority first)
- Shows merge sequence

**Example:**
```sh
~/ai/scripts/merge-order.sh worktree-config.json
# Merge order (based on dependencies and status):
#
# feat/auth-refresh (depends on: none)
# fix/payment-webhook (depends on: feat/auth-refresh)
```

### 3. `execute-merges.sh`

Executes merges in correct dependency order.

**Usage:**
```sh
# Dry-run (preview)
~/ai/scripts/execute-merges.sh worktree-config.json --dry-run

# Execute
~/ai/scripts/execute-merges.sh worktree-config.json
```

**What it does:**
- Only merges worktrees with `TASK_STATUS.done`
- Respects dependency order (dependencies merged first)
- Respects priority order (higher priority first)
- Supports `--dry-run` to preview merges
- Executes merges into `baseBranch`

**Example:**
```sh
# Preview
~/ai/scripts/execute-merges.sh worktree-config.json --dry-run
# DRY RUN: Would merge in this order:
#
# Branch feat/auth-refresh depends on: none
#   [DRY RUN] Would merge feat/auth-refresh into main
#
# Branch fix/payment-webhook depends on: feat/auth-refresh
#   [DRY RUN] Would merge fix/payment-webhook into main

# Execute
~/ai/scripts/execute-merges.sh worktree-config.json
# Executing merges in dependency order:
#
# Merging feat/auth-refresh into main...
#   ✓ Merged successfully
#
# Merging fix/payment-webhook into main...
#   ✓ Merged successfully
#
# Merge execution complete
```

## Complete Workflow

### Step 1: Create Configuration

```sh
cat > worktree-config.json << 'EOF'
{
  "baseDir": ".worktrees/w",
  "baseBranch": "main",
  "worktrees": [
    {
      "id": "feat-auth-refresh",
      "branch": "feat/auth-refresh",
      "dir": "repo--feat-auth-refresh",
      "priority": 10,
      "dependsOn": [],
      "status": "ready"
    },
    {
      "id": "fix-payment-webhook",
      "branch": "fix/payment-webhook",
      "dir": "repo--fix-payment-webhook",
      "priority": 2,
      "dependsOn": ["feat/auth-refresh"],
      "status": "ready"
    }
  ]
}
EOF
```

### Step 2: Initialize Worktrees

```sh
~/ai/scripts/init-worktrees.sh worktree-config.json
```

### Step 3: Work on Tasks

Work on tasks in each worktree until `TASK_STATUS.done` is set.

### Step 4: Check Merge Order

```sh
~/ai/scripts/merge-order.sh worktree-config.json
```

### Step 5: Execute Merges

```sh
# Preview first
~/ai/scripts/execute-merges.sh worktree-config.json --dry-run

# Then execute
~/ai/scripts/execute-merges.sh worktree-config.json
```

## Integration with Agents

### Multitasker Agent

The **multitasker** agent coordinates this workflow:

1. **Create worktrees**: Use `init-worktrees.sh` with a JSON config
2. **Monitor status**: Check `TASK_STATUS.done` files in worktrees
3. **Determine merge order**: Use `merge-order.sh` to see merge sequence
4. **Execute merges**: Use `execute-merges.sh` when tasks are complete

The multitasker has visibility into all worktrees and their status, making it the natural coordinator for merge ordering and execution.

### Task-Master Agent

The **task-master** agent automatically discovers worktrees in the configured `baseDir`:

- Auto-discovers worktrees from JSON config (if available)
- Falls back to `.worktrees/` if no config found
- Works with custom baseDir locations

### Code-Reviewer Agent

The **code-reviewer** agent verifies safety before merges:

- Reviews each branch before merge
- Works with multitasker's merge coordination
- Provides safety assessment for merge plan

## Requirements

- `jq`: JSON processor (required for parsing config files)
- Git: Version control
- POSIX-compliant shell: Scripts use standard `sh` syntax

## Example Config File

See `worktree-config.example.json` for a complete example configuration.
