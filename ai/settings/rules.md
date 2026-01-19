# General

- I want the code to be self-documenting.
- Don't suggest to run terminal commands.
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

## Tool Usage
- Batch file reads in parallel
- Don't re-read files already in context
- Use grep/codebase_search before reading large files
- Skip node_modules, dist, .git, lock files, generated files

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
