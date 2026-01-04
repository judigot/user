<h1 align="center">User Dev Environment</h1>

<p align="center">Portable Linux-like development environment for Windows using MSYS2</p>

## Quick Start

### Windows Setup (PowerShell as Administrator)

```powershell
curl.exe -L "https://raw.githubusercontent.com/judigot/user/main/Apportable.ps1" | powershell -NoProfile -
```

### Linux/macOS Setup

```sh
curl -sL "https://raw.githubusercontent.com/judigot/user/main/Apportable.sh" | sh
```

## Structure

This is a monorepo containing:

| Directory | Syncs To | Also Pushed To |
|-----------|----------|----------------|
| Root dotfiles | `~/` | - |
| `ai/` | `~/ai` | `judigot/ai` |

## Files

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
| `ai/` | Claude Code plugin (agents, skills, hooks, rules) |

## Usage

### Commit and Sync Everything

```sh
./commit-and-sync.sh
```

This will:
1. Commit & push changes to `judigot/user`
2. Sync dotfiles to `~/`
3. Sync `ai/` to `~/ai`
4. Commit & push `~/ai` to `judigot/ai`

### Load Snippets/Aliases

Add to `.bashrc` to auto-load aliases in all terminal sessions:

```sh
grep -q '#<SNIPPETS>' "$HOME/.bashrc" 2>/dev/null || printf '%s\n' '#<SNIPPETS>' '[[ -f "$HOME/.snippetsrc" ]] && source "$HOME/.snippetsrc"' '#<SNIPPETS/>' >> "$HOME/.bashrc"
```

### Manual Sync

```sh
curl -sL "https://raw.githubusercontent.com/judigot/user/main/.bashrc" -o ~/.bashrc
curl -sL "https://raw.githubusercontent.com/judigot/user/main/.snippetsrc" -o ~/.snippetsrc
curl -sL "https://raw.githubusercontent.com/judigot/user/main/.zshrc" -o ~/.zshrc
```

## Key Aliases

| Alias | Description |
|-------|-------------|
| `updater` | Update shell configs from GitHub |
| `getssh` | Display SSH public key |
| `generatessh` | Create new SSH key |
| `testssh` | Test GitHub SSH connection |
| `deleteall` | Delete all files in cwd (with confirmation) |

See `.snippetsrc` for full list.

## AI Plugin

The `ai/` folder contains a Claude Code plugin. Use it with:

```sh
claude --plugin-dir ~/ai
```

Or add an alias:

```sh
alias cc='claude --plugin-dir ~/ai'
```

See `ai/README.md` for details.
