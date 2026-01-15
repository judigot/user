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
curl -fsSL "https://raw.githubusercontent.com/judigot/user/main/.snippetsrc" -o "$HOME/.snippetsrc" && curl -fsSL "https://raw.githubusercontent.com/judigot/user/main/ALIAS" -o "$HOME/ALIAS" && . "$HOME/.snippetsrc" && grep -q '#<SNIPPETS>' "$HOME/.bashrc" 2>/dev/null || printf '%s\n' '#<SNIPPETS>' '[[ -f "$HOME/.snippetsrc" ]] && source "$HOME/.snippetsrc"' '#</SNIPPETS>' >> "$HOME/.bashrc"
```

Set Up Termux
```sh
curl -fsSL "https://raw.githubusercontent.com/judigot/user/main/.snippetsrc" -o "$HOME/.snippetsrc" && curl -fsSL "https://raw.githubusercontent.com/judigot/user/main/ALIAS" -o "$HOME/ALIAS" && . "$HOME/.snippetsrc"
termuxubuntu
termuxloginubuntu
```

Setup Mobile Workflow

```sh
curl -fsSL "https://raw.githubusercontent.com/judigot/user/main/.snippetsrc" -o "$HOME/.snippetsrc" && curl -fsSL "https://raw.githubusercontent.com/judigot/user/main/ALIAS" -o "$HOME/ALIAS" && . "$HOME/.snippetsrc" && grep -q '#<SNIPPETS>' "$HOME/.bashrc" 2>/dev/null || printf '%s\n' '#<SNIPPETS>' '[[ -f "$HOME/.snippetsrc" ]] && source "$HOME/.snippetsrc"' '#</SNIPPETS>' >> "$HOME/.bashrc"

initubuntu
usessh
installAWS
useaws
installnodeenv
installterraform
cloneterraformrepo
```

Initialize Ubuntu

```sh
set -eu; sudo apt-get update -y; sudo apt-get upgrade -y; sudo apt-get install -y ca-certificates curl git openssh-client unzip vim
```

Install Terraform (Ubuntu/Debian)

```sh
sudo apt-get update && sudo apt-get install -y ca-certificates curl gnupg && . /etc/os-release && curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${VERSION_CODENAME} main" | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null && sudo apt-get update && sudo apt-get install -y terraform
```

Setup Node environment (Windows/MSYS2)

```sh
curl -fsSL "https://raw.githubusercontent.com/judigot/user/main/.snippetsrc" -o "$HOME/.snippetsrc" && curl -fsSL "https://raw.githubusercontent.com/judigot/user/main/ALIAS" -o "$HOME/ALIAS" && . "$HOME/.snippetsrc" && setupNodeEnv
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
├── .snippetsrc                 │→ syncs to ~/
├── .zshrc                      │
├── profile.ps1                 │
├── PATH                        │
├── ALIAS                       │
├── Apportable.ps1              │
├── Apportable.sh              ─┘
├── DOTFILES                   ← manifest: files to sync to ~/
├── PROJECT_CORE               ← manifest: files to sync to cursor repo
├── IDE_FILES                  ← manifest: ide settings files
├── UBUNTU                     ← manifest: files to sync to WSL Ubuntu
└── commit-and-sync.sh         ← runs all syncs
```

## Manifest Files

These files act as single sources of truth for file lists. Each manifest file lists **source files** that get synced to specific destinations.

| File | Purpose | Used By |
|------|---------|---------|
| `DOTFILES` | List of files to sync to `~/` | `Apportable.sh`, `commit-and-sync.sh` |
| `PROJECT_CORE` | List of files to sync to cursor repo | `commit-and-sync.sh` |
| `IDE_FILES` | List of IDE settings files | Reference |
| `UBUNTU` | List of files to sync to WSL Ubuntu | `commit-and-sync.sh` |
| `PATH` | List of PATH entries | `.bashrc` |
| `ALIAS` | Centralized aliases | `.snippetsrc`, `profile.ps1` |

**To add/remove a file from sync:** Edit the manifest file - scripts pick up changes automatically.

### How Syncing Works

The syncing mechanism reads manifest files line-by-line and copies each listed file to its destination. Here's how each manifest type works:

#### DOTFILES Manifest

**Purpose:** Sync files from the repository root to your Windows home directory (`~/` or `C:\Users\YourName\`).

**How it works:**
1. Script reads `DOTFILES` line by line
2. Each line is a **source file path** (relative to repo root)
3. Files are copied to `~/filename` (preserving the filename)
4. If `DOTFILES` lists itself (e.g., contains "DOTFILES"), it gets synced too
5. If `DOTFILES` doesn't list itself, it won't be synced

**Example `DOTFILES` content:**
```
.bashrc
.snippetsrc
ALIAS
DOTFILES
```

**Result:** 
- `.bashrc` → copied to `~/.bashrc`
- `.snippetsrc` → copied to `~/.snippetsrc`
- `ALIAS` → copied to `~/ALIAS`
- `DOTFILES` → copied to `~/DOTFILES` (because it's listed)

**Important:** All paths in `DOTFILES` are **source files** from the repository root.

#### UBUNTU Manifest

**Purpose:** Sync files from Windows to WSL Ubuntu (both root and user home).

**How it works:**
1. Script reads `UBUNTU` line by line
2. Each line can be:
   - A **repo file** (e.g., `.snippetsrc`) → copied from repo to WSL
   - A **Windows path** starting with `$HOME` (e.g., `$HOME\.ssh`) → copied from Windows home to WSL
3. `$HOME` in entries refers to **Windows home directory** (`C:\Users\YourName\`), not WSL's home
4. Files are synced to both WSL root (`/root/`) and user home (`/home/username/`)
5. For directories: contents are **merged** (adds/replaces files, preserves existing files in destination)

**Example `UBUNTU` content:**
```
.snippetsrc
$HOME\.ssh
```

**Result:**
- `.snippetsrc` → copied from repo to `/root/.snippetsrc` and `/home/username/.snippetsrc`
- `$HOME\.ssh` → copied from `C:\Users\YourName\.ssh` to `/root/.ssh` and `/home/username/.ssh`
  - If `.ssh` already exists in WSL, files are merged (not replaced)

**Important:** 
- `$HOME` always means **Windows home**, never WSL home
- Directory syncing **merges** contents (doesn't delete existing files)
- `UBUNTU` itself is only synced if it's listed in the file

#### PROJECT_CORE Manifest

**Purpose:** Sync files from repository to the Cursor repository (`~/.apportable/cursor`), which then gets pushed to `judigot/cursor`.

**How it works:**
1. Script reads `PROJECT_CORE` line by line
2. Each line is a **source file or directory** (relative to repo root)
3. Files are copied to `~/.apportable/cursor/`
4. The cursor repo is then committed and pushed to GitHub
5. This is different from `DOTFILES` and `UBUNTU` - it syncs to a **separate Git repository**

**Example `PROJECT_CORE` content:**
```
.cursor
agents
AGENTS.md
CLAUDE.md
```

**Result:**
- `.cursor/` → copied to `~/.apportable/cursor/.cursor/`
- `agents/` → copied to `~/.apportable/cursor/agents/`
- `AGENTS.md` → copied to `~/.apportable/cursor/AGENTS.md`
- `CLAUDE.md` → copied to `~/.apportable/cursor/CLAUDE.md`

**Important:** Files synced to Cursor repo are managed in a separate Git repository.

### Key Concepts for Beginners

1. **Manifest files are "source lists"**: They list what to copy, not where to copy (destination is hardcoded in scripts)

2. **Self-referencing**: If a manifest lists itself, it gets synced. If not, it doesn't.

3. **`$HOME` means Windows home**: In `UBUNTU` manifest, `$HOME` always refers to `C:\Users\YourName\`, never WSL's `/home/username/`

4. **Directory syncing merges**: When syncing directories (like `.ssh`), existing files in destination are preserved. Only matching files are replaced, new files are added.

5. **No hardcoded filenames**: The manifest filename is passed as an argument to sync functions, making it flexible and testable.

### Common Patterns

**Adding a new dotfile:**
1. Add the filename to `DOTFILES`
2. Run `commit-and-sync.sh` or `updater`

**Syncing a Windows directory to WSL:**
1. Add `$HOME\directoryname` to `UBUNTU`
2. Run `commit-and-sync.sh`

**Syncing a file to Cursor repo:**
1. Add the filename to `PROJECT_CORE`
2. Run `commit-and-sync.sh`

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
| Files in `PROJECT_CORE` | `~/.apportable/cursor` | `judigot/cursor` |
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
4. Sync files listed in `PROJECT_CORE` to `~/.apportable/cursor` → push to `judigot/cursor`
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
| [judigot/cursor](https://github.com/judigot/cursor) | Cursor IDE template (standalone) | Files in `PROJECT_CORE` |
| [judigot/ide](https://github.com/judigot/ide) | Editor settings (standalone) | `user/ide/` |

# Development Environment Setup (WSL 2)

## Required Programs
- WSL 2
- Docker


## Enable WSL 2 (Windows Subsystem for Linux)
Open PowerShell as Administrator (Start menu > PowerShell > right-click > Run as Administrator) and enter this command:  
  
Terminal: `PowerShell`  
  
Command:  
```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```

## Install Ubuntu
Terminal: `PowerShell`  
  
Command:  
```powershell
wsl --install
```

**once you open Ubuntu for the first time, **skip** creating a new UNIX username*  
  
If you want to remove old versions of Ubuntu, run the commands below:  
Terminal: `PowerShell`  
  
Command:  
```powershell
wsl --unregister Ubuntu
wsl --install -d Ubuntu
wsl --set-default Ubuntu
```

## Open Ubuntu in VS Code
Terminal: `Ubuntu`  
  
Command:  
```sh
code .
```

## Configure Git Credentials
Terminal: `Ubuntu`  
  
Command:  
```sh
git config --global user.name "example-username"
git config --global user.email "example@gmail.com"
```

## SSH Key Generation for Github
Terminal: `Ubuntu`  
  
Command:  
```sh
ssh-keygen -f ~/.ssh/id_rsa -P "" && clear && echo -e "Copy and paste the public key below to your GitHub account:\n\n\e[32m$(cat ~/.ssh/id_rsa.pub) \e[0m\n" # Green
```

**copy & paste the generated SSH key to your GitHub account*

## Test SSH Connection
Terminal: `Ubuntu`  
  
Command:  
```sh
ssh -T git@github.com -o StrictHostKeyChecking=no
```

Expected output:
```
Hi <username>! You've successfully authenticated, but GitHub does not provide shell access.
```

## Download and Run the Environment-Setup.sh
Terminal: `Ubuntu`  
  
Command:  
```sh
curl -o script.sh https://raw.githubusercontent.com/judestp/alpha-tokyo-dev-env-setup/main/script.sh && sh script.sh
```
# Install Ubuntu Personal and Ubuntu Work

```powershell
# One-shot PowerShell script (template = "Ubuntu" alias):
# - Installs "Ubuntu" (usually latest LTS)
# - Exports it
# - Imports TWO isolated clones: Ubuntu-Personal and Ubuntu-Work
# - Sets BOTH clones to default user root
# - Sets DEFAULT DISTRO to Ubuntu-Personal
# - Unregisters the template "Ubuntu" at the end
#
# NOTE: If "Ubuntu" has never been launched before, you must complete first-run setup once.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$templateDistro = "Ubuntu"
$personalDistro = "Ubuntu-Personal"
$workDistro     = "Ubuntu-Work"

$baseTar = Join-Path $env:USERPROFILE "wsl-ubuntu-base.tar"
$rootDir = Join-Path $env:USERPROFILE "WSL"
$personalDir = Join-Path $rootDir $personalDistro
$workDir     = Join-Path $rootDir $workDistro

function Get-WslDistros {
  $raw = & wsl.exe --list --quiet 2>$null
  if ($LASTEXITCODE -ne 0) { return @() }
  return $raw | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
}

function Ensure-DistroInstalled([string]$distroName) {
  $installed = Get-WslDistros
  if ($installed -contains $distroName) { return }

  Write-Host "Installing $distroName..."
  & wsl.exe --install -d $distroName
  if ($LASTEXITCODE -ne 0) {
    throw "wsl --install failed. If Windows asks for a reboot, reboot and re-run this script."
  }
}

function Ensure-Initialized([string]$distroName) {
  try {
    & wsl.exe -d $distroName -- bash -lc "echo ok" | Out-Null
    if ($LASTEXITCODE -eq 0) { return }
  } catch {}

  Write-Host ""
  Write-Host "WSL distro '$distroName' needs first-run initialization."
  Write-Host "A window may open asking you to create a Linux username/password."
  Write-Host "Complete that setup, then return here."
  Write-Host ""

  & wsl.exe -d $distroName
  Read-Host "Press Enter to continue after completing the first-run setup"
}

function Export-Distro([string]$distroName, [string]$tarPath) {
  if (Test-Path $tarPath) { Remove-Item -Force $tarPath }
  Write-Host "Exporting $distroName to $tarPath ..."
  & wsl.exe --export $distroName $tarPath
  if ($LASTEXITCODE -ne 0) { throw "wsl --export failed." }
}

function Import-DistroIfMissing([string]$newName, [string]$installDir, [string]$tarPath) {
  $installed = Get-WslDistros
  if ($installed -contains $newName) {
    Write-Host "$newName already exists. Skipping import."
    return
  }

  if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Force -Path $installDir | Out-Null }

  Write-Host "Importing $newName into $installDir ..."
  & wsl.exe --import $newName $installDir $tarPath
  if ($LASTEXITCODE -ne 0) { throw "wsl --import failed for $newName." }
}

function Invoke-WslRootBash([string]$distroName, [string]$bashCommand) {
  $cmd = $bashCommand.Replace('"','\"')
  & wsl.exe -d $distroName --user root -- bash -lc "$cmd"
  if ($LASTEXITCODE -ne 0) { throw "Command failed in $distroName." }
}

function Set-DefaultRoot([string]$distroName) {
  Write-Host "Setting default user to root in $distroName ..."
  $script = @"
set -euo pipefail
cat >/etc/wsl.conf <<EOF
[user]
default=root
EOF
"@
  Invoke-WslRootBash $distroName $script
}

# 1) Ensure template exists ("Ubuntu" alias)
Ensure-DistroInstalled -distroName $templateDistro

# 2) Ensure it can be exported (first-run may be required once)
Ensure-Initialized -distroName $templateDistro

# 3) Export template to tar
Export-Distro -distroName $templateDistro -tarPath $baseTar

# 4) Import clones
if (-not (Test-Path $rootDir)) { New-Item -ItemType Directory -Force -Path $rootDir | Out-Null }
Import-DistroIfMissing -newName $personalDistro -installDir $personalDir -tarPath $baseTar
Import-DistroIfMissing -newName $workDistro     -installDir $workDir     -tarPath $baseTar

# 5) Default BOTH clones to root
Set-DefaultRoot -distroName $personalDistro
Set-DefaultRoot -distroName $workDistro

# 6) Set default distro to Personal
Write-Host "Setting default distro to $personalDistro ..."
& wsl.exe --set-default $personalDistro
if ($LASTEXITCODE -ne 0) { throw "wsl --set-default failed." }

# 7) Restart WSL to apply /etc/wsl.conf
Write-Host "Restarting WSL..."
& wsl.exe --shutdown | Out-Null

# 8) Cleanup tar
if (Test-Path $baseTar) { Remove-Item -Force $baseTar }

# 9) Remove template distro (leave only Personal + Work)
Write-Host "Unregistering template distro $templateDistro ..."
& wsl.exe --unregister $templateDistro
if ($LASTEXITCODE -ne 0) { throw "wsl --unregister failed." }

Write-Host ""
Write-Host "Done."
Write-Host "Launch personal (root): wsl -d $personalDistro"
Write-Host "Launch work (root):     wsl -d $workDistro"
Write-Host "List distros:           wsl --list --verbose"
Write-Host "Default distro:         $personalDistro"
```

## Delete Ubuntu Personal and Ubuntu Work

```powershell
# WSL CLEANUP (one-shot) — removes EVERYTHING from this setup:
# - Unregisters: Ubuntu-Personal, Ubuntu-Work, Ubuntu (template if present)
# - Deletes: %USERPROFILE%\WSL\Ubuntu-Personal and \Ubuntu-Work directories (if they exist)
# - Deletes: exported tar file(s) if present
#
# IMPORTANT:
# - This permanently deletes those distros and all their data.
# - It does NOT remove docker-desktop (owned by Docker Desktop).

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$personalDistro = "Ubuntu-Personal"
$workDistro     = "Ubuntu-Work"
$templateDistro = "Ubuntu"

$rootDir = Join-Path $env:USERPROFILE "WSL"
$personalDir = Join-Path $rootDir $personalDistro
$workDir     = Join-Path $rootDir $workDistro

$tarCandidates = @(
  (Join-Path $env:USERPROFILE "wsl-ubuntu-base.tar"),
  (Join-Path $env:USERPROFILE "wsl-ubuntu-24.04-base.tar")
)

function Get-WslDistros {
  $raw = & wsl.exe --list --quiet 2>$null
  if ($LASTEXITCODE -ne 0) { return @() }
  return $raw | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
}

function Unregister-IfExists([string]$name) {
  $installed = Get-WslDistros
  if ($installed -contains $name) {
    Write-Host "Unregistering $name ..."
    & wsl.exe --unregister $name
    if ($LASTEXITCODE -ne 0) { throw "Failed to unregister $name." }
  } else {
    Write-Host "$name not found. Skipping."
  }
}

function Remove-DirIfExists([string]$path) {
  if (Test-Path $path) {
    Write-Host "Deleting directory $path ..."
    Remove-Item -Recurse -Force $path
  } else {
    Write-Host "Directory not found: $path. Skipping."
  }
}

function Remove-FileIfExists([string]$path) {
  if (Test-Path $path) {
    Write-Host "Deleting file $path ..."
    Remove-Item -Force $path
  }
}

Write-Host "Shutting down WSL..."
& wsl.exe --shutdown | Out-Null

# Unregister distros (this deletes their virtual disks)
Unregister-IfExists $personalDistro
Unregister-IfExists $workDistro
Unregister-IfExists $templateDistro

# Remove leftover directories (in case they remain)
Remove-DirIfExists $personalDir
Remove-DirIfExists $workDir

# Remove any leftover export tar files
foreach ($tar in $tarCandidates) {
  Remove-FileIfExists $tar
}

Write-Host ""
Write-Host "Cleanup complete."
Write-Host "Remaining distros:"
& wsl.exe --list --verbose
```
