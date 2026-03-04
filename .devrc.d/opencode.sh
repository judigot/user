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
