<h1 align="center">User Dev Environment</h1>

<p align="center">Monorepo for portable Linux-like development environment on Windows using MSYS2</p>

## Overview

This is the **single source of truth** for:
- Shell configuration files (dotfiles)
- Claude Code AI plugin
- Cursor IDE templates
- Editor settings (Cursor, VS Code, Zed)

## Easy-Copy Snippets

Download and use `.snippetsrc`

```sh
curl -fsSL https://raw.githubusercontent.com/judigot/user/main/ALIAS -o "$HOME/ALIAS" && curl -fsSL https://raw.githubusercontent.com/judigot/user/main/.snippetsrc -o "$HOME/.snippetsrc" && . "$HOME/.snippetsrc"
```

Initialize Ubuntu

```sh
set -eu; sudo apt-get update -y; sudo apt-get upgrade -y; sudo apt-get install -y ca-certificates curl git openssh-client unzip
```

Generate SSH Keys Using Bitwarden

```sh
curl -fsSL https://raw.githubusercontent.com/judigot/user/main/setup-ssh-bitwarden.sh | bash
```

Auto-load `.snippetsrc` in `.bashrc`

```sh
grep -q '#<SNIPPETS>' "$HOME/.bashrc" 2>/dev/null || printf '%s\n' '#<SNIPPETS>' '[[ -f "$HOME/.snippetsrc" ]] && source "$HOME/.snippetsrc"' '#</SNIPPETS>' >> "$HOME/.bashrc"
```

Windows Setup (PowerShell as Administrator)

```powershell
curl.exe -L "https://raw.githubusercontent.com/judigot/user/main/Apportable.ps1" | powershell -NoProfile -
```

Linux/macOS Setup

```sh
curl -sL "https://raw.githubusercontent.com/judigot/user/main/Apportable.sh" | sh
```

## Repository Structure

```
user/                          ← judigot/user (source of truth)
├── ai/                        → syncs to ~/ai → pushes to judigot/ai
│   ├── .claude-plugin/
│   ├── agents/
│   ├── hooks/
│   ├── settings/rules.md
│   └── skills/
├── ide/                       → syncs to ~/.apportable/ide → pushes to judigot/ide
│   ├── cursor/                → syncs to ~/AppData/Roaming/Cursor/User
│   └── zed/                   → syncs to ~/AppData/Roaming/Zed
├── .cursor/                   ─┐
├── agents/                     │→ syncs to ~/.apportable/cursor → pushes to judigot/cursor
├── AGENTS.md                   │
├── CLAUDE.md                  ─┘
├── .bashrc                    ─┐
├── .snippetsrc                 │
├── .profile                    │→ syncs to ~/
├── .zshrc                      │
├── profile.ps1                 │
├── PATH                        │
├── ALIAS                       │
├── Apportable.ps1              │
├── Apportable.sh              ─┘
├── DOTFILES                   ← manifest: files to sync to ~/
├── CURSOR                     ← manifest: files to sync to cursor repo
├── IDE_FILES                  ← manifest: ide settings files
├── UBUNTU                     ← manifest: files to sync to WSL Ubuntu
└── commit-and-sync.sh         ← runs all syncs
```

## Manifest Files

These files act as single sources of truth for file lists:

| File | Purpose | Used By |
|------|---------|---------|
| `DOTFILES` | List of files to sync to `~/` | `Apportable.sh`, `commit-and-sync.sh` |
| `CURSOR` | List of files to sync to cursor repo | `commit-and-sync.sh` |
| `IDE_FILES` | List of IDE settings files | Reference |
| `UBUNTU` | List of files to sync to WSL Ubuntu | `commit-and-sync.sh` |
| `PATH` | List of PATH entries | `.bashrc` |
| `ALIAS` | Centralized aliases | `.snippetsrc`, `profile.ps1` |

**To add/remove a file from sync:** Edit the manifest file - scripts pick up changes automatically.

## Centralized Aliases

The `ALIAS` file is the **single source of truth** for all shell aliases. It works in both **bash** and **PowerShell**.

### Format

```
functionName:
alias1
alias2
alias3

anotherFunction:
shortalias
```

- Line ending with `:` → function name
- Lines below → aliases that call that function
- Empty lines separate groups (optional, for readability)

### Example

```
helloWorld:
hi
hello

updateUserEnv:
updater
updaterc
updateenv
```

This creates:
- `hi` → calls `helloWorld`
- `hello` → calls `helloWorld`
- `updater` → calls `updateUserEnv`
- `updaterc` → calls `updateUserEnv`
- `updateenv` → calls `updateUserEnv`

### Adding a New Alias

1. Find the function in `ALIAS` (or add a new function block)
2. Add your alias on a new line under the function
3. Run `updater` to sync

### Adding a New Function

1. Define the function in `.snippetsrc`
2. Add a new block in `ALIAS`:
   ```
   myNewFunction:
   myalias
   shortcut
   ```
3. Run `updater` to sync

### How It Works

| Shell | Behavior |
|-------|----------|
| Bash | `.snippetsrc` parses `ALIAS` and creates bash aliases |
| PowerShell | `profile.ps1` parses `ALIAS` and creates functions that call bash |

Both shells read from the same file, so aliases stay in sync automatically.

## Sync Destinations

| Source | Destination | Also Pushed To |
|--------|-------------|----------------|
| Files in `DOTFILES` | `~/` | - |
| `ai/` | `~/ai` | `judigot/ai` |
| Files in `CURSOR` | `~/.apportable/cursor` | `judigot/cursor` |
| `ide/` | `~/.apportable/ide` | `judigot/ide` |
| `ide/cursor/` | `~/AppData/Roaming/Cursor/User` | - |
| `ide/zed/` | `~/AppData/Roaming/Zed` | - |
| VS Code | Symlinks → Cursor | - |
| Files in `UBUNTU` | `//wsl.localhost/Ubuntu/root/` | - |

## Files

### Dotfiles (sync to `~/`)

| File | Description |
|------|-------------|
| `.bashrc` | Bash configuration with PATH loading and environment setup |
| `.zshrc` | Zsh configuration (mirrors .bashrc functionality) |
| `.profile` | Login shell profile |
| `.snippetsrc` | Shell functions and alias loader |
| `profile.ps1` | PowerShell profile with bash integration |
| `PATH` | Portable PATH entries for development tools |
| `ALIAS` | Centralized aliases for bash and PowerShell |
| `Apportable.ps1` | Windows setup script (installs portable dev tools) |
| `Apportable.sh` | Linux/macOS setup script |

### AI Plugin (sync to `~/ai` → `judigot/ai`)

| File | Description |
|------|-------------|
| `ai/.claude-plugin/` | Claude Code plugin manifest |
| `ai/agents/` | AI agent definitions |
| `ai/hooks/` | Session hooks (loads rules on start) |
| `ai/settings/rules.md` | Coding standards and rules |
| `ai/skills/` | Specialized skills (lint-master, test-master) |

### Cursor Templates (sync to `~/.apportable/cursor` → `judigot/cursor`)

| File | Description |
|------|-------------|
| `.cursor/rules/` | Cursor IDE rules (references ~/ai) |
| `agents/` | Project-specific agent templates |
| `AGENTS.md` | Agent documentation |
| `CLAUDE.md` | Claude Code entry point |

### IDE Settings (sync to `~/.apportable/ide` → `judigot/ide`)

| File | Destination |
|------|-------------|
| `ide/cursor/settings.jsonc` | `~/AppData/Roaming/Cursor/User/settings.json` |
| `ide/cursor/keybindings.jsonc` | `~/AppData/Roaming/Cursor/User/keybindings.json` |
| `ide/cursor/Master of Snippets.code-snippets` | `~/AppData/Roaming/Cursor/User/snippets/` |
| `ide/zed/settings.jsonc` | `~/AppData/Roaming/Zed/settings.json` |
| `ide/zed/keymap.jsonc` | `~/AppData/Roaming/Zed/keymap.json` |

**VS Code:** Symlinks to Cursor settings (shares the same files)

## Usage

### Commit and Sync Everything

```sh
./commit-and-sync.sh
```

This will:
1. Commit & push changes to `judigot/user`
2. Sync files listed in `DOTFILES` to `~/`
3. Sync `ai/` to `~/ai` → commit & push to `judigot/ai`
4. Sync files listed in `CURSOR` to `~/.apportable/cursor` → push to `judigot/cursor`
5. Sync `ide/` to `~/.apportable/ide` → push to `judigot/ide`
6. Sync Cursor settings + create VS Code symlinks
7. Sync Zed settings
8. Sync files listed in `UBUNTU` to WSL Ubuntu

### Add Cursor Boilerplate to a Project

```sh
addcursorfiles
```

This downloads `.cursor/`, `agents/`, `AGENTS.md`, `CLAUDE.md` from `judigot/cursor` to the current directory.

### Load Snippets/Aliases

Add to `.bashrc` to auto-load aliases:

```sh
grep -q '#<SNIPPETS>' "$HOME/.bashrc" 2>/dev/null || printf '%s\n' '#<SNIPPETS>' '[[ -f "$HOME/.snippetsrc" ]] && source "$HOME/.snippetsrc"' '#</SNIPPETS>' >> "$HOME/.bashrc"
```

### Manual Dotfile Sync

```sh
curl -sL "https://raw.githubusercontent.com/judigot/user/main/.bashrc" -o ~/.bashrc
curl -sL "https://raw.githubusercontent.com/judigot/user/main/.snippetsrc" -o ~/.snippetsrc
curl -sL "https://raw.githubusercontent.com/judigot/user/main/.zshrc" -o ~/.zshrc
```

## Key Aliases

| Alias | Description |
|-------|-------------|
| `updater` | Update all configs from GitHub |
| `syncdotfiles` | Sync only dotfiles |
| `syncidefiles` | Sync only IDE settings |
| `addcursorfiles` | Add Cursor boilerplate to current project |
| `ghfiles` | Download files from GitHub repo |
| `getssh` | Display SSH public key |
| `generatessh` | Create new SSH key |
| `testssh` | Test GitHub SSH connection |
| `deleteall` | Delete all files in cwd (with confirmation) |

See `ALIAS` for full list of 81 aliases.

## AI Plugin Usage

Use Claude Code with the AI plugin:

```sh
claude --plugin-dir ~/ai
```

Or add an alias to `.bashrc`:

```sh
alias cc='claude --plugin-dir ~/ai'
```

See `ai/README.md` for details.

## Related Repositories

| Repository | Purpose | Synced From |
|------------|---------|-------------|
| [judigot/user](https://github.com/judigot/user) | Monorepo (source of truth) | - |
| [judigot/ai](https://github.com/judigot/ai) | Claude Code plugin (standalone) | `user/ai/` |
| [judigot/cursor](https://github.com/judigot/cursor) | Cursor IDE template (standalone) | Files in `CURSOR` |
| [judigot/ide](https://github.com/judigot/ide) | Editor settings (standalone) | `user/ide/` |
