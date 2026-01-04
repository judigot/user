<h1 align="center">User Dev Environment</h1>

<p align="center">Monorepo for portable Linux-like development environment on Windows using MSYS2</p>

## Overview

This is the **single source of truth** for:
- Shell configuration files (dotfiles)
- Claude Code AI plugin
- Cursor IDE templates

## Quick Start

### Load Snippets/Aliases

Add to `.bashrc` to auto-load aliases:

```sh
grep -q '#<SNIPPETS>' "$HOME/.bashrc" 2>/dev/null || printf '%s\n' '#<SNIPPETS>' '[[ -f "$HOME/.snippetsrc" ]] && source "$HOME/.snippetsrc"' '#</SNIPPETS>' >> "$HOME/.bashrc"
```

### Windows Setup (PowerShell as Administrator)

```powershell
curl.exe -L "https://raw.githubusercontent.com/judigot/user/main/Apportable.ps1" | powershell -NoProfile -
```

### Linux/macOS Setup

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
├── Apportable.ps1              │
├── Apportable.sh              ─┘
├── DOTFILES                   ← manifest: files to sync to ~/
├── CURSOR                     ← manifest: files to sync to cursor repo
└── commit-and-sync.sh         ← runs all syncs
```

## Manifest Files

These files act as single sources of truth for file lists:

| File | Purpose | Used By |
|------|---------|---------|
| `DOTFILES` | List of files to sync to `~/` | `Apportable.sh`, `commit-and-sync.sh` |
| `CURSOR` | List of files to sync to cursor repo | `commit-and-sync.sh` |
| `PATH` | List of PATH entries | `.bashrc` |

**To add/remove a file from sync:** Edit the manifest file - scripts pick up changes automatically.

## Sync Destinations

| Source | Destination | Also Pushed To |
|--------|-------------|----------------|
| Files in `DOTFILES` | `~/` | - |
| `ai/` | `~/ai` | `judigot/ai` |
| Files in `CURSOR` | `~/.apportable/cursor` | `judigot/cursor` |

## Files

### Dotfiles (sync to `~/`)

| File | Description |
|------|-------------|
| `.bashrc` | Bash configuration with PATH loading and environment setup |
| `.zshrc` | Zsh configuration (mirrors .bashrc functionality) |
| `.profile` | Login shell profile |
| `.snippetsrc` | Shell aliases and utility functions |
| `profile.ps1` | PowerShell profile with bash integration |
| `PATH` | Portable PATH entries for development tools |
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
| `addcursorfiles` | Add Cursor boilerplate to current project |
| `updater` | Update shell configs from GitHub |
| `getssh` | Display SSH public key |
| `generatessh` | Create new SSH key |
| `testssh` | Test GitHub SSH connection |
| `deleteall` | Delete all files in cwd (with confirmation) |

See `.snippetsrc` for full list.

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
