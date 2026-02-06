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
    printf '%s\n' "Usage: load-devrc.sh [--guest] [--persist] [--no-bashrc]"
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
archive_url="https://codeload.github.com/judigot/user/tar.gz/refs/heads/main?cachebustkey=$cachebustkey"

devrc_tmp="$(mktemp "${TMPDIR:-/tmp}/devrc.XXXXXX")" || finish 1
alias_tmp="$(mktemp "${TMPDIR:-/tmp}/alias.XXXXXX")" || {
    rm -f "$devrc_tmp" 2>/dev/null || true
    finish 1
}

repo_tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/userrepo.XXXXXX")" || {
    rm -f "$devrc_tmp" "$alias_tmp" 2>/dev/null || true
    finish 1
}
repo_tar="$repo_tmp_root/user.tar.gz"
repo_dir="$repo_tmp_root/user-main"

if ! curl -fsSL "$archive_url" -o "$repo_tar"; then
    printf '%s\n' "Failed to download user archive" >&2
    rm -f "$devrc_tmp" "$alias_tmp" "$repo_tar" 2>/dev/null || true
    rm -rf "$repo_tmp_root" 2>/dev/null || true
    finish 1
fi

if ! tar -xzf "$repo_tar" -C "$repo_tmp_root"; then
    printf '%s\n' "Failed to extract user archive" >&2
    rm -f "$devrc_tmp" "$alias_tmp" "$repo_tar" 2>/dev/null || true
    rm -rf "$repo_tmp_root" 2>/dev/null || true
    finish 1
fi

if ! cp "$repo_dir/.devrc" "$devrc_tmp"; then
    printf '%s\n' "Failed to download .devrc" >&2
    rm -f "$devrc_tmp" "$alias_tmp" "$repo_tar" 2>/dev/null || true
    rm -rf "$repo_tmp_root" 2>/dev/null || true
    finish 1
fi

if ! cp "$repo_dir/ALIAS" "$alias_tmp"; then
    printf '%s\n' "Failed to download ALIAS" >&2
    rm -f "$devrc_tmp" "$alias_tmp" "$repo_tar" 2>/dev/null || true
    rm -rf "$repo_tmp_root" 2>/dev/null || true
    finish 1
fi

tmp_devrc_dir="$(dirname "$devrc_tmp")/.devrc.d"
mkdir -p "$tmp_devrc_dir" 2>/dev/null || true

if ! cp "$repo_dir/.devrc.d/80-diff-navigator.sh" "$tmp_devrc_dir/80-diff-navigator.sh" || \
   ! cp "$repo_dir/.devrc.d/opencode.sh" "$tmp_devrc_dir/opencode.sh" || \
   ! cp "$repo_dir/.devrc.d/prompts.sh" "$tmp_devrc_dir/prompts.sh"; then
    printf '%s\n' "Failed to download .devrc.d files" >&2
    rm -f "$devrc_tmp" "$alias_tmp" "$repo_tar" 2>/dev/null || true
    rm -rf "$repo_tmp_root" 2>/dev/null || true
    rm -rf "$tmp_devrc_dir" 2>/dev/null || true
    finish 1
fi

if [ ! -s "$devrc_tmp" ] || [ ! -s "$alias_tmp" ]; then
    printf '%s\n' "Downloaded files are empty" >&2
    rm -f "$devrc_tmp" "$alias_tmp" "$repo_tar" 2>/dev/null || true
    rm -rf "$repo_tmp_root" 2>/dev/null || true
    finish 1
fi

rm -f "$repo_tar" 2>/dev/null || true
rm -rf "$repo_tmp_root" 2>/dev/null || true

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
rm -f "$devrc_tmp" "$alias_tmp" 2>/dev/null || true
rm -rf "$(dirname "$devrc_tmp")/.devrc.d" 2>/dev/null || true
        finish 1
    fi

    # shellcheck source=/dev/null
    . "$devrc_tmp"
    load_aliases_from_content "$alias_tmp"

rm -f "$devrc_tmp" "$alias_tmp" 2>/dev/null || true
rm -rf "$(dirname "$devrc_tmp")/.devrc.d" 2>/dev/null || true
    finish 0
fi

mv "$devrc_tmp" "$HOME/.devrc"
mv "$alias_tmp" "$HOME/ALIAS"
mkdir -p "$HOME/.devrc.d" 2>/dev/null || true
find "$(dirname "$devrc_tmp")" -path "*/.devrc.d/*.sh" -exec cp {} "$HOME/.devrc.d/" \; 2>/dev/null || true

# shellcheck source=/dev/null
. "$HOME/.devrc"

if [ "$persist_bashrc" -eq 1 ] && ! grep -q '#<DEVRC>' "$HOME/.bashrc" 2>/dev/null; then
    printf '%s\n' '#<DEVRC>' '[[ -f "$HOME/.devrc" ]] && source "$HOME/.devrc"' '#</DEVRC>' \
        >> "$HOME/.bashrc"
fi

finish 0
