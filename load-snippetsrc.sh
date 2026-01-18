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

usage() {
    printf '%s\n' "Usage: load-snippetsrc.sh [--guest] [--persist] [--no-bashrc]"
    finish 1
}

if [ -z "${BASH_VERSION:-}" ]; then
    printf '%s\n' "This script requires bash." >&2
    finish 1
fi

if [ "$is_sourced" -eq 0 ]; then
    set -euo pipefail
fi

mode="persist"
persist_bashrc=1

while [ $# -gt 0 ]; do
    case "$1" in
        --) shift; break ;;
        --guest) mode="guest" ;;
        --persist) mode="persist" ;;
        --no-bashrc) persist_bashrc=0 ;;
        -h|--help) usage ;;
        *) printf '%s\n' "Unknown option: $1" >&2; usage ;;
    esac
    shift
 done

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

load_aliases_from_content() {
    local alias_file="$1"
    local current_func=""

    shopt -s expand_aliases 2>/dev/null || true

    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%%#*}"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        [ -z "$line" ] && {
            current_func=""
            continue
        }

        if [[ "$line" == *: ]]; then
            current_func="${line%:}"
            current_func="${current_func#"${current_func%%[![:space:]]*}"}"
            current_func="${current_func%"${current_func##*[![:space:]]}"}"
        elif [ -n "$current_func" ]; then
            alias "$line"="$current_func"
        fi
    done < "$alias_file"
}

if [ "$mode" = "guest" ]; then
    if [ "$is_sourced" -eq 0 ]; then
        printf '%s\n' "Guest mode must be sourced to affect the current shell." >&2
        rm -f "$snippetsrc_tmp" "$alias_tmp" 2>/dev/null || true
        finish 1
    fi

    # shellcheck source=/dev/null
    . "$snippetsrc_tmp"
    load_aliases_from_content "$alias_tmp"

    rm -f "$snippetsrc_tmp" "$alias_tmp" 2>/dev/null || true
    finish 0
fi

mv "$snippetsrc_tmp" "$HOME/.snippetsrc"
mv "$alias_tmp" "$HOME/ALIAS"

# shellcheck source=/dev/null
. "$HOME/.snippetsrc"

if [ "$persist_bashrc" -eq 1 ] && ! grep -q '#<SNIPPETS>' "$HOME/.bashrc" 2>/dev/null; then
    printf '%s\n' '#<SNIPPETS>' '[[ -f "$HOME/.snippetsrc" ]] && source "$HOME/.snippetsrc"' '#</SNIPPETS>' \
        >> "$HOME/.bashrc"
fi

finish 0
