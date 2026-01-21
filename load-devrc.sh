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
base_url="https://raw.githubusercontent.com/judigot/user/main"
devrc_url="$base_url/.devrc?cachebustkey=$cachebustkey"
alias_url="$base_url/ALIAS?cachebustkey=$cachebustkey"
devrc_d_url="https://api.github.com/repos/judigot/user/contents/.devrc.d"

devrc_tmp="$(mktemp "${TMPDIR:-/tmp}/devrc.XXXXXX")" || finish 1
alias_tmp="$(mktemp "${TMPDIR:-/tmp}/alias.XXXXXX")" || {
    rm -f "$devrc_tmp" 2>/dev/null || true
    finish 1
}
devrc_d_tmp="$(mktemp -d "${TMPDIR:-/tmp}/devrc-d.XXXXXX")" || {
    rm -f "$devrc_tmp" "$alias_tmp" 2>/dev/null || true
    finish 1
}

if ! curl -fsSL "$devrc_url" -o "$devrc_tmp"; then
    printf '%s\n' "Failed to download .devrc" >&2
    rm -f "$devrc_tmp" "$alias_tmp" "$devrc_module_tmp" 2>/dev/null || true
    finish 1
fi

if ! curl -fsSL "$alias_url" -o "$alias_tmp"; then
    printf '%s\n' "Failed to download ALIAS" >&2
    rm -f "$devrc_tmp" "$alias_tmp" "$devrc_module_tmp" 2>/dev/null || true
    finish 1
fi

# Download all files in .devrc.d directory
if ! curl -fsSL "$devrc_d_url" -o "${devrc_d_tmp}/contents.json"; then
    printf '%s\n' "Failed to download .devrc.d directory listing" >&2
    rm -f "$devrc_tmp" "$alias_tmp" 2>/dev/null || true
    rm -rf "$devrc_d_tmp" 2>/dev/null || true
    finish 1
fi

# Download each file in .devrc.d
if command -v jq >/dev/null 2>&1; then
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            filename=$(echo "$file" | jq -r '.name')
            download_url=$(echo "$file" | jq -r '.download_url')
            if [ "$download_url" != "null" ] && [ "$filename" != "null" ]; then
                if ! curl -fsSL "$download_url" -o "${devrc_d_tmp}/${filename}"; then
                    printf '%s\n' "Failed to download .devrc.d/$filename" >&2
                fi
            fi
        fi
    done < <(jq -c '.[]' "${devrc_d_tmp}/contents.json")
else
    printf '%s\n' "Warning: jq not found, skipping .devrc.d directory contents download" >&2
fi

if [ ! -s "$devrc_tmp" ] || [ ! -s "$alias_tmp" ]; then
    printf '%s\n' "Downloaded files are empty" >&2
    rm -f "$devrc_tmp" "$alias_tmp" 2>/dev/null || true
    rm -rf "$devrc_d_tmp" 2>/dev/null || true
    finish 1
fi

# Download all files in .devrc.d directory
if ! curl -fsSL "$devrc_d_url" -o "${devrc_d_tmp}/contents.json"; then
    printf '%s\n' "Failed to download .devrc.d directory listing" >&2
    rm -f "$devrc_tmp" "$alias_tmp" "$devrc_module_tmp" 2>/dev/null || true
    rm -rf "$devrc_d_tmp" 2>/dev/null || true
    finish 1
fi

# Download each file in .devrc.d
if command -v jq >/dev/null 2>&1; then
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            filename=$(echo "$file" | jq -r '.name')
            download_url=$(echo "$file" | jq -r '.download_url')
            if [ "$download_url" != "null" ] && [ "$filename" != "null" ]; then
                if ! curl -fsSL "$download_url" -o "${devrc_d_tmp}/${filename}"; then
                    printf '%s\n' "Failed to download .devrc.d/$filename" >&2
                fi
            fi
        fi
    done < <(jq -c '.[]' "${devrc_d_tmp}/contents.json")
else
    printf '%s\n' "Warning: jq not found, skipping .devrc.d directory contents download" >&2
fi

if [ ! -s "$devrc_tmp" ] || [ ! -s "$alias_tmp" ] || [ ! -s "$devrc_module_tmp" ]; then
    printf '%s\n' "Downloaded files are empty" >&2
    rm -f "$devrc_tmp" "$alias_tmp" "$devrc_module_tmp" 2>/dev/null || true
    rm -rf "$devrc_d_tmp" 2>/dev/null || true
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
rm -f "$devrc_tmp" "$alias_tmp" 2>/dev/null || true
rm -rf "$devrc_d_tmp" 2>/dev/null || true
        finish 1
    fi

    # shellcheck source=/dev/null
    . "$devrc_tmp"
    load_aliases_from_content "$alias_tmp"

    rm -f "$devrc_tmp" "$alias_tmp" 2>/dev/null || true
    rm -rf "$devrc_d_tmp" 2>/dev/null || true
    finish 0
fi

mv "$devrc_tmp" "$HOME/.devrc"
mv "$alias_tmp" "$HOME/ALIAS"
mkdir -p "$HOME/.devrc.d" 2>/dev/null || true
cp -r "$devrc_d_tmp"/* "$HOME/.devrc.d/" 2>/dev/null || true

# shellcheck source=/dev/null
. "$HOME/.devrc"

if [ "$persist_bashrc" -eq 1 ] && ! grep -q '#<DEVRC>' "$HOME/.bashrc" 2>/dev/null; then
    printf '%s\n' '#<DEVRC>' '[[ -f "$HOME/.devrc" ]] && source "$HOME/.devrc"' '#</DEVRC>' \
        >> "$HOME/.bashrc"
fi

finish 0
