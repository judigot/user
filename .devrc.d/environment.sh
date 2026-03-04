#!/bin/sh

useEnvironmentVariables() {
    local note_name="Environment Variables"
    local env_file="$HOME/.devrc.d/.env"
    local env_dir
    env_dir="$(dirname "$env_file")"

    if ! command -v bw >/dev/null 2>&1; then
        echo "✗ Bitwarden CLI (bw) is required." >&2
        return 1
    fi

    if ! bw --version >/dev/null 2>&1; then
        echo "✗ Bitwarden CLI found but cannot execute. Please reinstall it." >&2
        return 1
    fi

    if ! command -v node >/dev/null 2>&1; then
        echo "✗ Node.js is required to parse Bitwarden responses." >&2
        return 1
    fi

    bw login --check >/dev/null 2>&1 || bw login

    if [ -z "${BW_SESSION:-}" ]; then
        export BW_SESSION="$(bw unlock --raw)"
    fi

    [ -n "${BW_SESSION:-}" ] || {
        echo "✗ Failed to unlock Bitwarden vault" >&2
        return 1
    }

    bw sync >/dev/null 2>&1

    local item_id
    item_id="$(bw list items --search "$note_name" 2>/dev/null | node -e "
        const input = require('fs').readFileSync(0, 'utf-8').trim();
        if (!input) process.exit(1);
        const data = JSON.parse(input);
        const match = data.find(i => i && i.name === process.argv[1] && i.type === 2);
        if (match) console.log(match.id);
        else process.exit(1);
    " "$note_name" 2>/dev/null)"

    [ -n "$item_id" ] || {
        echo "✗ Bitwarden secure note not found: $note_name" >&2
        return 1
    }

    local env_content
    env_content="$(bw get item "$item_id" 2>/dev/null | node -e "
        const data = JSON.parse(require('fs').readFileSync(0, 'utf-8'));
        if (typeof data.notes === 'string') process.stdout.write(data.notes);
    " 2>/dev/null)"

    [ -n "$env_content" ] || {
        echo "✗ Bitwarden note is empty: $note_name" >&2
        return 1
    }

    mkdir -p "$env_dir" 2>/dev/null || true

    local tmp_file
    tmp_file="/tmp/devrc-env.$$"
    printf '%s' "$env_content" > "$tmp_file" || {
        rm -f "$tmp_file" 2>/dev/null || true
        echo "✗ Failed to write temporary env file" >&2
        return 1
    }

    mv "$tmp_file" "$env_file" || {
        rm -f "$tmp_file" 2>/dev/null || true
        echo "✗ Failed to update $env_file" >&2
        return 1
    }

    chmod 600 "$env_file" 2>/dev/null || true

    local had_allexport=""
    case "$-" in
        *a*) had_allexport="true" ;;
    esac

    set -a
    # shellcheck source=/dev/null
    . "$env_file" || {
        if [ -z "$had_allexport" ]; then
            set +a
        fi
        echo "✗ Failed to source $env_file" >&2
        return 1
    }

    if [ -z "$had_allexport" ]; then
        set +a
    fi

    echo "✓ Environment variables loaded from Bitwarden into $env_file"
}
