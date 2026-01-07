# Worktree Management Scripts

CLI-native scripts for managing git worktrees with JSON configuration and dependency-based merge ordering.

## Scripts

### `init-worktrees.sh`

Creates worktrees from a JSON configuration file.

**Usage:**
```sh
~/ai/scripts/init-worktrees.sh <config.json>
```

**What it does:**
- Reads JSON config file
- Creates worktrees for each branch defined
- Sets up `.agent-task-context/` structure (BRANCH_NAME, Context.md)
- Initializes TASK_STATUS.unclaimed
- Commits and pushes initial context files

**Requirements:**
- Must be run from git repository root
- Requires `jq` command-line JSON processor
- Requires write access to repository

### `merge-order.sh`

Determines the correct merge order based on dependencies and task status.

**Usage:**
```sh
~/ai/scripts/merge-order.sh <config.json>
```

**What it does:**
- Reads JSON config and dependency graph
- Checks TASK_STATUS.done for each worktree
- Outputs merge order respecting dependencies
- Only includes branches with TASK_STATUS.done

**Output:**
- Lists branches in merge order (one per line)
- Skips branches that aren't done
- Detects circular dependencies

### `execute-merges.sh`

Executes merges in the correct dependency order.

**Usage:**
```sh
# Dry run (preview)
~/ai/scripts/execute-merges.sh <config.json> --dry-run

# Execute merges
~/ai/scripts/execute-merges.sh <config.json>
```

**What it does:**
- Determines merge order using `merge-order.sh`
- Checks out base branch
- Merges each branch in dependency order
- Stops on merge conflicts

**Safety:**
- Always use `--dry-run` first
- Stops on conflicts (requires manual resolution)
- Does not push automatically

## Configuration Format

Create a JSON file (e.g., `worktree-config.json`):

```json
{
  "baseBranch": "main",
  "worktrees": [
    {
      "dir": "repo--feat-auth-refresh",
      "branch": "feat/auth-refresh",
      "priority": 1,
      "dependsOn": []
    },
    {
      "dir": "repo--fix-payment-webhook",
      "branch": "fix/payment-webhook",
      "priority": 2,
      "dependsOn": ["feat/auth-refresh"]
    }
  ]
}
```

**Fields:**
- `baseBranch`: Base branch to create worktrees from (default: "main")
- `worktrees`: Array of worktree definitions
  - `dir`: Directory name (not used, branch-slug derived from branch)
  - `branch`: Git branch name (e.g., `feat/auth-refresh`)
  - `priority`: Priority number (lower = higher priority, currently informational)
  - `dependsOn`: Array of branch names that must be merged first

## Complete Workflow

### 1. Create Configuration

```sh
cat > worktree-config.json << 'EOF'
{
  "baseBranch": "main",
  "worktrees": [
    {
      "dir": "repo--feat-auth-refresh",
      "branch": "feat/auth-refresh",
      "priority": 1,
      "dependsOn": []
    },
    {
      "dir": "repo--fix-payment-webhook",
      "branch": "fix/payment-webhook",
      "priority": 2,
      "dependsOn": ["feat/auth-refresh"]
    }
  ]
}
EOF
```

### 2. Initialize Worktrees

```sh
~/ai/scripts/init-worktrees.sh worktree-config.json
```

### 3. Work on Tasks

Work on each worktree until TASK_STATUS.done:
- Use `task-master` agent in each worktree
- Or work manually in separate Cursor windows
- Mark as done when complete: `touch .worktrees/<branch-slug>/.agent-task-context/.state/TASK_STATUS.done`

### 4. Check Merge Order

```sh
~/ai/scripts/merge-order.sh worktree-config.json
```

This shows which branches are ready and in what order they should be merged.

### 5. Preview Merges

```sh
~/ai/scripts/execute-merges.sh worktree-config.json --dry-run
```

This shows what would be merged without making changes.

### 6. Execute Merges

```sh
~/ai/scripts/execute-merges.sh worktree-config.json
```

This merges branches in the correct order.

### 7. Review and Push

```sh
git log --oneline -10
git push origin main
```

## Integration with Claude Code

All scripts work in Claude Code terminal:

```sh
# In Claude Code terminal
cd /path/to/repo
~/ai/scripts/init-worktrees.sh worktree-config.json

# Work on tasks (use task-master agent or manual work)

# When ready to merge
~/ai/scripts/merge-order.sh worktree-config.json
~/ai/scripts/execute-merges.sh worktree-config.json --dry-run
~/ai/scripts/execute-merges.sh worktree-config.json
```

## Dependencies

- `jq`: JSON processor (install: `brew install jq` or `apt-get install jq`)
- `git`: Git version control
- POSIX-compliant shell (`sh`)

## Notes

- Scripts use POSIX-compliant `sh` syntax
- All scripts must be run from git repository root
- Worktrees are created in `.worktrees/` directory
- Branch names are converted to kebab-case for directory names
- Only branches with TASK_STATUS.done are included in merge order
- Merge order respects dependency graph (topological sort)
