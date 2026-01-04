#!/bin/sh

readonly PROJECT_DIRECTORY=$(cd "$(dirname "$0")" || exit 1; pwd)

main() {
    commit_changes
    sync_to_home
}

commit_changes() {
    cd "$PROJECT_DIRECTORY" || exit 1
    
    if [ -z "$(git status --porcelain)" ]; then
        printf '%s\n' "No changes to commit"
        return 0
    fi
    
    git add -A
    git commit -m "chore: update user files"
    git push
}

sync_to_home() {
    cd "$PROJECT_DIRECTORY" || exit 1
    
    printf '%s\n' "Syncing files to home directory..."
    
    cp .bashrc "$HOME/.bashrc"
    cp .snippetsrc "$HOME/.snippetsrc"
    cp .profile "$HOME/.profile"
    cp .zshrc "$HOME/.zshrc"
    cp profile.ps1 "$HOME/profile.ps1"
    cp PATH "$HOME/PATH"
    cp Apportable.ps1 "$HOME/Apportable.ps1"
    cp Apportable.sh "$HOME/Apportable.sh"
    
    printf '%s\n' "Sync complete"
}

main "$@"

