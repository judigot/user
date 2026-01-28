

# General

- I want the code to be self-documenting.
- Agents should always run terminal commands by sourcing the ~/.devrc file first. It is needed to be able to use aliases:

```bash
. ~/.devrc; eval "hi" # For running aliases
```

- I prefer readable code that I can go back to after a long time and still be able to understand it.
- Use "current datetime" for chat titles.
- Show code before explanations.
- Avoid Nano; use Vim-compatible instructions.
- ESLint: Follow 'plugin:@typescript-eslint/strict-type-checked'.
- Use short, semantic git commit messages following Conventional Commits format

# Token Efficiency

## Response Rules
- No preambles ("Let me...", "I'll...", "Sure!", "Great question!")
- No summaries after completing tasks
- No repeating the user's request back
- No "Here's what I found" phrases
- Code blocks only - skip prose when code is self-explanatory
- One-line answers when possible
- Prefer explicit rules over implicit assumptions; restate key rules when asked
- Use ai_* aliases when they map to the requested action

## Tool Usage
- Batch file reads in parallel
- Don't re-read files already in context
- Use grep/codebase_search before reading large files
- Skip node_modules, dist, .git, lock files, generated files
- Prefer targeted reads and diffs; avoid full-file dumps
- Use Context7 for docs lookup to avoid verbose explanations

## Code Output
- Show only changed lines with context, not full files
- Skip unchanged imports/boilerplate in explanations

# Defaults (Don't Ask, Just Do)

- TypeScript strict mode, ESM imports
- Latest stable versions
- Bun as package manager
- Follow existing project patterns
- Auto-create directories when writing files

# MCP Tools

- Always use Context7 MCP for library/API documentation, code generation, setup, or configuration steps without requiring explicit request
- MCP server binaries can be shared across tools, but each client (OpenCode, Claude Code, Codex) requires its own config pointing to those servers
- Required MCP servers: Context7, GitHub
- Required CLI tools for agents: gh

# File Operations

- If files should have the same content, move them instead of rewriting (saves tokens)
- Safe file relocation: copy file first, then delete the original
- Use terminal `mv` command for simple moves/renames
- Use terminal `cp` then `rm` for safe cloning when needed

# Comment Rules

- Only add useful comments.
- Don't add obvious comments.
- Comment like how a senior-level engineer would
- Don't comment on architectural decisions that are self-evident from code structure
- Don't add "explanation comments" that restate what the code already makes clear

# Terminal

- Write all shell scripts and command examples as POSIX-compliant `sh` scripts, avoiding Bash/Zsh-specific features.
- Always use MSYS2 bash instead of PowerShell for shell commands
- Use bash syntax
- If you need to change the same code like one-liners across multiple files, use terminal commands rather than changing the files manually.

## Destructive Commands (STRICT SAFETY RULE)

**NEVER run destructive commands without explicit prior approval in the same conversation.**

If the user has NOT explicitly instructed you to run destructive commands, you MUST:
1. Stop and explain what you intend to do
2. List the exact command(s) and their consequences
3. Wait for explicit approval before proceeding

Skip permission only if the user explicitly requested the destructive action beforehand.

### Destructive Commands List

| Git (can lose history/commits) | System (can lose data/corrupt files) |
|--------------------------------|--------------------------------------|
| `git reset --hard` | `rm -rf`, `rm -r` |
| `git push --force`, `--force-with-lease` | `del /s /q`, `rmdir /s` |
| `git clean -fd`, `-fx` | `format`, `diskpart` |
| `git rebase` (on pushed/shared branches) | `shutdown`, `reboot` |
| `git branch -D` (force delete) | `chmod -R`, `chown -R` |
| `git stash drop`, `stash clear` | `mkfs`, `dd` |
| `git reflog expire`, `gc --prune` | Registry edits (`reg delete`) |
| `git filter-branch`, `filter-repo` | `takeown`, `icacls` (permissions) |

### Pre-Flight Checklist (MANDATORY before any destructive git command)

Even with explicit user approval, you MUST complete these steps IN ORDER before running any destructive git command:

1. Run `git status` — if there are uncommitted changes, STOP and stash them first (`git stash push -m "backup before <command>"`)
2. Run `git log --oneline -5` — confirm which commits exist and will be affected
3. Run `git stash list` — note existing stashes so they aren't accidentally dropped
4. Show the user exactly what will be lost/changed and get final confirmation
5. ONLY THEN execute the destructive command

**If `git reset --hard` is requested:**
- ALWAYS run `git stash push -u -m "backup before reset"` FIRST (includes untracked files)
- Record the current HEAD SHA in the conversation so it can be recovered via reflog
- Prefer `git reset --soft` or `git reset --mixed` when the goal is just to uncommit (not discard changes)

**If `git clean` is requested:**
- Run `git clean -nd` (dry run) first and show the user what will be deleted
- Never run `git clean -fx` without showing dry run output first

### Why This Rule Exists

- Prevent accidental deletion of git history
- Prevent repository corruption
- Prevent loss of uncommitted work
- Prevent system file damage

## MSYS2 Bash from PowerShell

When in PowerShell, use `bash` function (defined in ~/profile.ps1):

```powershell
bash "

cd ~/ai
git status

"
```

For snippets:

```powershell
bash "

. ~/.devrc
downloadGithubRepo judigot/project-core

"
```

**Formatting rules:**
- Use newlines as padding (empty line after opening quote, before closing quote)
- One command per line for human readability and easy copy-paste

When already in MSYS2 bash, run commands directly.

**How to detect terminal:**
- PowerShell errors contain `At C:\...\ps-script-...`
- PowerShell rejects `&&` with "not a valid statement separator"

## Git SSH

- ALWAYS use SSH URLs, never HTTPS: `git@github.com:user/repo.git`
- When cloning: `git clone git@github.com:user/repo.git`
- If git asks for credentials, the remote is HTTPS. Fix with: `git remote set-url origin git@github.com:user/repo.git`

## Git Commits (Conventional Commits)

Format: `<type>: <description>`

| Type | Purpose |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation |
| `style` | Formatting (no code change) |
| `refactor` | Code restructure (no feature/fix) |
| `perf` | Performance improvement |
| `test` | Add/update tests |
| `chore` | Maintenance, deps, config |

Examples: `feat: add user auth`, `fix: null check in parser`, `chore: update deps`

# Snippets (~/.devrc)

- Location: `~/.devrc` (sourced by .bashrc)
- Prefer using existing snippets over writing new scripts
- When adding new utilities, add them to `~/.devrc` with descriptive function names and multiple aliases. But always ask permission first.
- Usage: `bash -c ". ~/.devrc && functionName"`
- Always source `~/.devrc` at the start of every agent CLI session (OpenCode, Claude Code, Codex, etc.) and before running shell commands so aliases are available.

## User Aliases

| Command | Purpose |
|---------|---------|
| `helloWorld` | Test greeting |
| `updateCurrentBranch` | Merge origin/main and push |
| `updater` | Update shell configs from GitHub |
| `bbvite` | Scaffold Vite project |
| `bblaravel` | Scaffold Laravel project |
| `getssh` | Display SSH public key |
| `generatessh` | Create new SSH key |
| `testssh` | Test GitHub SSH connection |
| `personalssh` | Switch to personal SSH key |
| `workssh` | Switch to work SSH key |
| `deleteall` | Delete all files in cwd (confirm) |
| `loadsnippets` | Add devrc to .bashrc |
| `newagent` | Create Cursor/agents structure |
| `downloadGithubRepo user/repo` | Download GitHub repo without .git |

## Agent Aliases (Token-Efficient)

| Command | Purpose |
|---------|---------|
| `ai_diffnav [branch]` | Show raw PR diff between main/current branch |
| `ai_prdiff [branch]` | Alternative alias for ai_diffnav |
| `ai_gitdiff [branch]` | Alternative alias for ai_diffnav |
| `ai_gc "msg"` | Stage all + commit (no push) |
| `ai_gcp` | Preview staged changes |
| `ai_gpr` | Create PR (gh cli) |
| `ai_nr "script"` | Run bun script |
| `ai_status` | Git status (short) |
| `ai_diff` | Git diff (unstaged) |
| `ai_diffstaged` | Git diff (staged) |
| `ai_log` | Git log (recent) |
| `ai_add` | Git add all |
| `ai_pull` | Git pull with rebase |
| `ai_search "pattern" [path]` | Ripgrep search |
| `ai_replace "file" "old" "new"` | Replace string in file |
| `ai_mkdir "dir"` | Make directory (parents) |
| `ai_touch "file"` | Touch file |
| `ai_copy "src" "dest"` | Copy file/dir |
| `ai_move "src" "dest"` | Move/rename file/dir |

# TypeScript/JavaScript

- Never add console.log. You can add console.error
- Use unknown instead of any.
- Prefer interfaces (prefix with "I") over types.
- Wrap variables in String() when interpolating.
- Avoid unnecessary type casts.
- Handle null, undefined, 0, or NaN explicitly.
- Always use braces for void arrow functions.
- Always escape dollar signs when using template literals

# React

- Use function components only.
- Include all dependencies in hooks.
- Fix click handlers on non-interactive elements.

# Formatting

- Block Comments: Use `/* This is a comment */` for inline comments.
- SQL: Use heredoc syntax.

# Shell/Bash

- Avoid grep; prefer awk.
- Follow this structure in script files:

  ```sh
  #!/bin/sh
  
  readonly GLOBAL_VARIABLE="Hello, World!"
  
  readonly PROJECT_DIRECTORY=$(cd "$(dirname "$0")" || exit 1; pwd) # Directory of this script
  
  main() {
      action1
      action2
  }
  
  action1() {
      cd "$PROJECT_DIRECTORY" || exit 1
      printf '%s\n' "Action 1"
  }
  
  action2() {
      cd "$PROJECT_DIRECTORY" || exit 1
      printf '%s\n' "Action 2"
  }
  
  main "$@"
  ```

  *the main function should be at the very top to easily have an idea on what the script is all about
  
- Omit unused global variables.

# SPA Content Extraction

- For JavaScript-rendered SPAs: use Jina Reader first (prepend `https://r.jina.ai/` to URL)
- Handle hash routes with POST requests; wait for stable selectors if loading
- Fallback: headless browser → wait for ready → extract outerHTML/innerText/accessibility tree
- Auth required: only use user-provided access; never guess credentials
- Output: clean docs with source, URL, timestamp, summary, structured content
- Mark unavailable sections explicitly; don't invent content