#!/bin/sh

syncOpenCodeChats() {
    local source_root="$HOME/.local/share/opencode/storage"
    local repo_root="$HOME/.apportable/ai-chats"
    local remote_repo="git@github.com:judigot/ai-chats.git"
    local repo_target="$repo_root/opencode/storage"
    local branch="main"

    if [ ! -d "$source_root" ]; then
        printf '%s\n' "OpenCode storage not found: $source_root" >&2
        return 1
    fi

    mkdir -p "$HOME/.apportable" 2>/dev/null || true

    if [ ! -d "$repo_root/.git" ]; then
        git clone "$remote_repo" "$repo_root" || return 1
    fi

    if git -C "$repo_root" rev-parse --verify HEAD >/dev/null 2>&1; then
        git -C "$repo_root" checkout "$branch" >/dev/null 2>&1 || true
        git -C "$repo_root" pull --ff-only || return 1
    fi

    if [ -d "$repo_target" ]; then
        cp -r "$repo_target/." "$source_root/" 2>/dev/null || true
    fi

    mkdir -p "$repo_target" 2>/dev/null || true

    if [ -d "$source_root/message" ]; then
        cp -r "$source_root/message" "$repo_target/" 2>/dev/null || true
    fi
    if [ -d "$source_root/part" ]; then
        cp -r "$source_root/part" "$repo_target/" 2>/dev/null || true
    fi
    if [ -d "$source_root/project" ]; then
        cp -r "$source_root/project" "$repo_target/" 2>/dev/null || true
    fi
    if [ -d "$source_root/session" ]; then
        cp -r "$source_root/session" "$repo_target/" 2>/dev/null || true
    fi
    if [ -d "$source_root/session_diff" ]; then
        cp -r "$source_root/session_diff" "$repo_target/" 2>/dev/null || true
    fi
    if [ -d "$source_root/todo" ]; then
        cp -r "$source_root/todo" "$repo_target/" 2>/dev/null || true
    fi

    if ! git -C "$repo_root" status --porcelain | awk 'NF{found=1} END{exit found?0:1}'; then
        return 0
    fi

    if ! git -C "$repo_root" rev-parse --verify HEAD >/dev/null 2>&1; then
        git -C "$repo_root" checkout -b "$branch" || return 1
    fi

    git -C "$repo_root" add . || return 1
    git -C "$repo_root" commit -m "chore: sync opencode chats" || return 1

    if git -C "$repo_root" rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
        git -C "$repo_root" push
    else
        git -C "$repo_root" push -u origin "$branch"
    fi
}

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
