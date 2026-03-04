#!/bin/sh

ensureBitwardenCLI() {
    local npm_prefix=""

    if command -v bw >/dev/null 2>&1 && bw --version >/dev/null 2>&1; then
        return 0
    fi

    if ! command -v npm >/dev/null 2>&1; then
        echo "✗ Node.js/npm is required to install Bitwarden CLI." >&2
        return 1
    fi

    npm_prefix="$(npm config get prefix 2>/dev/null || echo "$HOME/.local")"
    export PATH="$npm_prefix/bin:$HOME/.local/bin:$PATH"

    echo "Installing Bitwarden CLI via npm..." >&2
    if ! npm install -g @bitwarden/cli >/dev/null 2>&1; then
        echo "✗ Failed to install Bitwarden CLI via npm." >&2
        return 1
    fi

    hash -r 2>/dev/null || true

    if ! command -v bw >/dev/null 2>&1 || ! bw --version >/dev/null 2>&1; then
        echo "✗ Bitwarden CLI installation completed but 'bw' is not executable." >&2
        return 1
    fi

    return 0
}

useEnvironmentVariables() {
    local note_name="Environment Variables"
    local env_file="$HOME/.devrc.d/.env"
    local env_dir
    local items_json
    local item_id
    local item_json
    local env_content
    env_dir="$(dirname "$env_file")"

    ensureBitwardenCLI || return 1

    if ! command -v node >/dev/null 2>&1; then
        echo "✗ Node.js is required to parse Bitwarden responses." >&2
        return 1
    fi

    if ! bw login --check >/dev/null 2>&1; then
        if ! bw login; then
            echo "✗ Bitwarden login failed." >&2
            return 1
        fi
    fi

    if [ -z "${BW_SESSION:-}" ]; then
        export BW_SESSION="$(bw unlock --raw 2>/dev/null)"
    fi

    [ -n "${BW_SESSION:-}" ] || {
        echo "✗ Failed to unlock Bitwarden vault. Verify master password and account state." >&2
        return 1
    }

    if ! bw sync >/dev/null 2>&1; then
        echo "✗ Bitwarden sync failed. Run 'bw sync' and retry." >&2
        return 1
    fi

    if ! items_json="$(bw list items --search "$note_name" 2>/dev/null)"; then
        echo "✗ Failed to query Bitwarden items (authentication/session issue)." >&2
        return 1
    fi

    item_id="$(printf '%s' "$items_json" | node -e "
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

    if ! item_json="$(bw get item "$item_id" 2>/dev/null)"; then
        echo "✗ Failed to read Bitwarden secure note: $note_name" >&2
        return 1
    fi

    env_content="$(printf '%s' "$item_json" | node -e "
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
