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
    
    # Preserve .git, delete everything else, copy fresh
    mv "$HOME/ai/.git" "$HOME/ai-git-tmp"
    rm -rf "$HOME/ai"
    cp -r ai "$HOME/ai"
    rm -rf "$HOME/ai/.git" 2>/dev/null
    mv "$HOME/ai-git-tmp" "$HOME/ai/.git"
    
    printf '%s\n' "AI folder sync complete"
}

commit_ai_repo() {
    cd "$HOME/ai" || exit 1
    
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
