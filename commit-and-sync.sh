#!/bin/sh

readonly PROJECT_DIRECTORY=$(cd "$(dirname "$0")" || exit 1; pwd)

main() {
    commit_user_repo
    sync_to_home
    sync_ai_repo
    sync_cursor_repo
}

commit_user_repo() {
    cd "$PROJECT_DIRECTORY" || exit 1
    
    if [ -z "$(git status --porcelain)" ]; then
        printf '%s\n' "No changes to commit in user repo"
        return 0
    fi
    
    git add -A
    git commit -m "chore: update user files"
    git push
}

sync_to_home() {
    cd "$PROJECT_DIRECTORY" || exit 1
    
    printf '%s\n' "Syncing dotfiles to home directory..."
    
    while read -r file; do
        [ -n "$file" ] && cp "$file" "$HOME/$file"
    done < DOTFILES
    
    printf '%s\n' "Dotfiles sync complete"
}

sync_ai_repo() {
    cd "$PROJECT_DIRECTORY" || exit 1
    
    printf '%s\n' "Syncing ai folder to ~/ai..."
    
    # Fresh install: ~/ai doesn't exist
    if [ ! -d "$HOME/ai" ]; then
        cp -r ai "$HOME/ai"
        cd "$HOME/ai" || exit 1
        git init
        git remote add origin git@github.com:judigot/ai.git
        git add -A
        git commit -m "chore: initial sync from user repo"
        git branch -M main
        git push -u origin main --force
        printf '%s\n' "AI repo created and pushed"
        return 0
    fi
    
    # Preserve .git if it exists
    if [ -d "$HOME/ai/.git" ]; then
        mv "$HOME/ai/.git" "$HOME/ai-git-tmp"
    fi
    
    rm -rf "$HOME/ai"
    cp -r ai "$HOME/ai"
    rm -rf "$HOME/ai/.git" 2>/dev/null
    
    # Restore .git if it was preserved
    if [ -d "$HOME/ai-git-tmp" ]; then
        mv "$HOME/ai-git-tmp" "$HOME/ai/.git"
    fi
    
    # Commit and push
    cd "$HOME/ai" || exit 1
    
    if [ ! -d ".git" ]; then
        git init
        git remote add origin git@github.com:judigot/ai.git
        git add -A
        git commit -m "chore: initial sync from user repo"
        git branch -M main
        git push -u origin main --force
        printf '%s\n' "AI repo initialized and pushed"
        return 0
    fi
    
    if [ -z "$(git status --porcelain)" ]; then
        printf '%s\n' "No changes to commit in ai repo"
        return 0
    fi
    
    git add -A
    git commit -m "chore: sync from user repo"
    git push
    
    printf '%s\n' "AI repo synced and pushed"
}

sync_cursor_repo() {
    cd "$PROJECT_DIRECTORY" || exit 1
    
    printf '%s\n' "Syncing cursor files to judigot/cursor..."
    
    cursor_local="$HOME/.apportable/cursor"
    
    # Fresh install: doesn't exist
    if [ ! -d "$cursor_local" ]; then
        mkdir -p "$HOME/.apportable"
        git clone git@github.com:judigot/cursor.git "$cursor_local"
    fi
    
    # Preserve .git, sync files
    if [ -d "$cursor_local/.git" ]; then
        mv "$cursor_local/.git" "$HOME/.apportable/cursor-git-tmp"
    fi
    
    rm -rf "$cursor_local"
    mkdir -p "$cursor_local"
    
    while read -r item; do
        [ -n "$item" ] && cp -r "$PROJECT_DIRECTORY/$item" "$cursor_local/"
    done < "$PROJECT_DIRECTORY/CURSOR"
    
    if [ -d "$HOME/.apportable/cursor-git-tmp" ]; then
        mv "$HOME/.apportable/cursor-git-tmp" "$cursor_local/.git"
    fi
    
    # Commit and push
    cd "$cursor_local" || exit 1
    
    if [ ! -d ".git" ]; then
        git init
        git remote add origin git@github.com:judigot/cursor.git
        git add -A
        git commit -m "chore: initial sync from user repo"
        git branch -M main
        git push -u origin main --force
        printf '%s\n' "Cursor repo initialized and pushed"
        return 0
    fi
    
    if [ -z "$(git status --porcelain)" ]; then
        printf '%s\n' "No changes to commit in cursor repo"
        return 0
    fi
    
    git add -A
    git commit -m "chore: sync from user repo"
    git push
    
    printf '%s\n' "Cursor repo synced and pushed"
}

main "$@"
