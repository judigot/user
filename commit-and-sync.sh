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
    
    cp .bashrc "$HOME/.bashrc"
    cp .snippetsrc "$HOME/.snippetsrc"
    cp .profile "$HOME/.profile"
    cp .zshrc "$HOME/.zshrc"
    cp profile.ps1 "$HOME/profile.ps1"
    cp PATH "$HOME/PATH"
    cp Apportable.ps1 "$HOME/Apportable.ps1"
    cp Apportable.sh "$HOME/Apportable.sh"
    
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
    
    # Clone cursor repo to temp dir
    rm -rf /tmp/cursor-sync
    git clone --depth 1 git@github.com:judigot/cursor.git /tmp/cursor-sync
    
    # Remove old files (keep .git)
    cd /tmp/cursor-sync || exit 1
    find . -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +
    
    # Copy cursor files from user repo
    cp -r "$PROJECT_DIRECTORY/.cursor" .
    cp -r "$PROJECT_DIRECTORY/agents" .
    cp "$PROJECT_DIRECTORY/AGENTS.md" .
    cp "$PROJECT_DIRECTORY/CLAUDE.md" .
    
    # Commit and push
    if [ -z "$(git status --porcelain)" ]; then
        printf '%s\n' "No changes to commit in cursor repo"
        rm -rf /tmp/cursor-sync
        return 0
    fi
    
    git add -A
    git commit -m "chore: sync from user repo"
    git push
    
    rm -rf /tmp/cursor-sync
    printf '%s\n' "Cursor repo synced and pushed"
}

main "$@"
