#!/bin/bash

set -e

is_sourced=0
if [ "${BASH_SOURCE[0]}" != "$0" ]; then
    is_sourced=1
fi

finish() {
    if [ "$is_sourced" -eq 1 ]; then
        return "$1"
    fi
    exit "$1"
}

usage() {
    printf '%s\n' "Usage: load-snippetsrc.sh [--guest] [--persist] [--no-bashrc]"
    finish 1
}

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

cachebustkey="$(date +%s 2>/dev/null || echo "0")"
base_url="https://raw.githubusercontent.com/judigot/user/main"
snippetsrc_url="$base_url/.snippetsrc?cachebust=$cachebustkey"
alias_url="$base_url/ALIAS?cachebust=$cachebustkey"

download() {
    curl -fsSL "$1"
}

load_aliases_from_content() {
    local alias_content="$1"
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
    done <<< "$alias_content"
}

if [ "$mode" = "guest" ]; then
    if [ "$is_sourced" -eq 0 ]; then
        printf '%s\n' "Guest mode must be sourced to affect the current shell." >&2
    fi

    snippetsrc_content="$(download "$snippetsrc_url")" || finish 1
    alias_content="$(download "$alias_url")" || finish 1

    # shellcheck source=/dev/null
    source <(printf '%s\n' "$snippetsrc_content")
    load_aliases_from_content "$alias_content"
    finish 0
fi

download "$snippetsrc_url" > "$HOME/.snippetsrc"
download "$alias_url" > "$HOME/ALIAS"

if [ "$persist_bashrc" -eq 1 ]; then
    grep -q '#<SNIPPETS>' "$HOME/.bashrc" 2>/dev/null || printf '%s\n' \
        '#<SNIPPETS>' '[[ -f "$HOME/.snippetsrc" ]] && source "$HOME/.snippetsrc"' '#</SNIPPETS>' \
        >> "$HOME/.bashrc"
fi

# shellcheck source=/dev/null
[ -f "$HOME/.snippetsrc" ] && source "$HOME/.snippetsrc"

finish 0
