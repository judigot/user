#!/usr/bin/env bash

is_sourced=0
if [ "${BASH_SOURCE[0]}" != "$0" ]; then
    is_sourced=1
fi

finish() {
    local status="$1"
    if [ "$is_sourced" -eq 1 ]; then
        return "$status"
    fi
    exit "$status"
}

if [ -z "${BASH_VERSION:-}" ]; then
    printf '%s\n' "This script requires bash." >&2
    finish 1
fi

if [ "$is_sourced" -eq 0 ]; then
    set -euo pipefail
fi

cachebustkey="$(date +%s 2>/dev/null || echo 0)"
base_url="https://raw.githubusercontent.com/judigot/user/main"
snippetsrc_url="$base_url/.snippetsrc?cb=$cachebustkey"
alias_url="$base_url/ALIAS?cb=$cachebustkey"

snippetsrc_tmp="$(mktemp "${TMPDIR:-/tmp}/snippetsrc.XXXXXX")" || finish 1
alias_tmp="$(mktemp "${TMPDIR:-/tmp}/alias.XXXXXX")" || {
    rm -f "$snippetsrc_tmp" 2>/dev/null || true
    finish 1
}

if ! curl -fsSL "$snippetsrc_url" -o "$snippetsrc_tmp"; then
    printf '%s\n' "Failed to download .snippetsrc" >&2
    rm -f "$snippetsrc_tmp" "$alias_tmp" 2>/dev/null || true
    finish 1
fi

if ! curl -fsSL "$alias_url" -o "$alias_tmp"; then
    printf '%s\n' "Failed to download ALIAS" >&2
    rm -f "$snippetsrc_tmp" "$alias_tmp" 2>/dev/null || true
    finish 1
fi

if [ ! -s "$snippetsrc_tmp" ] || [ ! -s "$alias_tmp" ]; then
    printf '%s\n' "Downloaded files are empty" >&2
    rm -f "$snippetsrc_tmp" "$alias_tmp" 2>/dev/null || true
    finish 1
fi

mv "$snippetsrc_tmp" "$HOME/.snippetsrc"
mv "$alias_tmp" "$HOME/ALIAS"

# shellcheck source=/dev/null
. "$HOME/.snippetsrc"

if ! grep -q '#<SNIPPETS>' "$HOME/.bashrc" 2>/dev/null; then
    printf '%s\n' '#<SNIPPETS>' '[[ -f "$HOME/.snippetsrc" ]] && source "$HOME/.snippetsrc"' '#</SNIPPETS>' \
        >> "$HOME/.bashrc"
fi

finish 0
