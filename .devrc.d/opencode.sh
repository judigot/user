#!/bin/sh

syncOpenCodeChats() {
    local source_root="$HOME/.local/share/opencode/project"
    local repo_root="$HOME/.apportable/ai-chats"
    local remote_repo="git@github.com:judigot/ai-chats.git"
    local repo_target="$repo_root/opencode/project"

    if [ ! -d "$source_root" ]; then
        printf '%s\n' "OpenCode storage not found: $source_root" >&2
        return 1
    fi

    mkdir -p "$HOME/.apportable" 2>/dev/null || true

    if [ ! -d "$repo_root/.git" ]; then
        git clone "$remote_repo" "$repo_root" || return 1
    fi

    git -C "$repo_root" pull --ff-only || return 1

    if [ -d "$repo_target" ]; then
        cp -r "$repo_target/." "$source_root/" 2>/dev/null || true
    fi

    mkdir -p "$repo_target" 2>/dev/null || true
    cp -r "$source_root/." "$repo_target/" 2>/dev/null || true

    if ! git -C "$repo_root" status --porcelain | grep -q '.'; then
        return 0
    fi

    git -C "$repo_root" add . || return 1
    git -C "$repo_root" commit -m "chore: sync opencode chats" || return 1
    git -C "$repo_root" push
}
