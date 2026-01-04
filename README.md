<h1 align="center">User Dev Environment</h1>

Create a Linux-like user environment in Windows

# Apportable Setup

Run this in PowerShell as administrator

```sh
curl.exe -L "https://raw.githubusercontent.com/judigot/user/main/Apportable.ps1" | powershell -NoProfile -
```

# Snippets/Aliases

Append to .bashrc to always load aliases to all terminal sessions

```sh
grep -q '#<SNIPPETS>' "$HOME/.bashrc" 2>/dev/null || printf '%s\n' '#<SNIPPETS>' '[[ -f "$HOME/.snippetsrc" ]] && source "$HOME/.snippetsrc"' '#<SNIPPETS/>' >> "$HOME/.bashrc"
```