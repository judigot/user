#!/bin/sh

readonly PROJECT_DIRECTORY=$(cd "$(dirname "$0")" || exit 1; pwd)

main() {
    commit_user_repo
    sync_to_home
    sync_ai_folder
    commit_ai_repo
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

sync_ai_folder() {
    cd "$PROJECT_DIRECTORY" || exit 1
    
    printf '%s\n' "Syncing ai folder to ~/ai..."
    
    # Fresh install: ~/ai doesn't exist
    if [ ! -d "$HOME/ai" ]; then
        cp -r ai "$HOME/ai"
        printf '%s\n' "AI folder sync complete (fresh install)"
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
    
    printf '%s\n' "AI folder sync complete"
}

commit_ai_repo() {
    cd "$HOME/ai" || exit 1
    
    # Fresh install: no .git, clone it
    if [ ! -d ".git" ]; then
        printf '%s\n' "Initializing git repo in ~/ai..."
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
    
    printf '%s\n' "AI repo committed and pushed"
}

main "$@"
