#!/bin/sh

readonly PROJECT_DIRECTORY=$(cd "$(dirname "$0")" || exit 1; pwd)

main() {
    commit_user_repo
    sync_to_home
    sync_ai_repo
    sync_cursor_repo
    sync_ide_repo
    sync_cursor_settings
    sync_zed_settings
    sync_ubuntu
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

sync_ide_repo() {
    cd "$PROJECT_DIRECTORY" || exit 1
    
    printf '%s\n' "Syncing ide folder to judigot/ide..."
    
    ide_local="$HOME/.apportable/ide"
    
    # Fresh install: doesn't exist
    if [ ! -d "$ide_local" ]; then
        mkdir -p "$HOME/.apportable"
        git clone git@github.com:judigot/ide.git "$ide_local"
    fi
    
    # Preserve .git, sync files
    if [ -d "$ide_local/.git" ]; then
        mv "$ide_local/.git" "$HOME/.apportable/ide-git-tmp"
    fi
    
    rm -rf "$ide_local"
    cp -r "$PROJECT_DIRECTORY/ide" "$ide_local"
    rm -rf "$ide_local/.git" 2>/dev/null
    
    if [ -d "$HOME/.apportable/ide-git-tmp" ]; then
        mv "$HOME/.apportable/ide-git-tmp" "$ide_local/.git"
    fi
    
    # Commit and push
    cd "$ide_local" || exit 1
    
    if [ ! -d ".git" ]; then
        git init
        git remote add origin git@github.com:judigot/ide.git
        git add -A
        git commit -m "chore: initial sync from user repo"
        git branch -M main
        git push -u origin main --force
        printf '%s\n' "IDE repo initialized and pushed"
        return 0
    fi
    
    if [ -z "$(git status --porcelain)" ]; then
        printf '%s\n' "No changes to commit in ide repo"
        return 0
    fi
    
    git add -A
    git commit -m "chore: sync from user repo"
    git push
    
    printf '%s\n' "IDE repo synced and pushed"
}

sync_cursor_settings() {
    cd "$PROJECT_DIRECTORY" || exit 1
    
    printf '%s\n' "Syncing Cursor/VS Code settings..."
    
    appdata="$HOME/AppData/Roaming"
    cursor_user="$appdata/Cursor/User"
    vscode_user="$appdata/Code/User"
    
    # Create directories
    mkdir -p "$cursor_user/snippets"
    mkdir -p "$vscode_user"
    
    # Copy to Cursor (actual files)
    cp "ide/cursor/settings.jsonc" "$cursor_user/settings.json"
    cp "ide/cursor/keybindings.jsonc" "$cursor_user/keybindings.json"
    cp "ide/cursor/Master of Snippets.code-snippets" "$cursor_user/snippets/"
    
    # Create symlinks for VS Code → Cursor (via PowerShell)
    powershell.exe -Command "
        \$cursor = \"\$env:APPDATA\\Cursor\\User\"
        \$vscode = \"\$env:APPDATA\\Code\\User\"
        
        \$links = @(
            @{ Link = \"\$vscode\\snippets\"; Target = \"\$cursor\\snippets\" },
            @{ Link = \"\$vscode\\keybindings.json\"; Target = \"\$cursor\\keybindings.json\" },
            @{ Link = \"\$vscode\\settings.json\"; Target = \"\$cursor\\settings.json\" }
        )
        
        foreach (\$l in \$links) {
            if (Test-Path \$l.Link) {
                Remove-Item \$l.Link -Force -Recurse 2>\$null
            }
            if (Test-Path \$l.Target) {
                New-Item -ItemType SymbolicLink -Path \$l.Link -Target \$l.Target -Force | Out-Null
            }
        }
    "
    
    printf '%s\n' "Cursor/VS Code settings synced"
}

sync_zed_settings() {
    cd "$PROJECT_DIRECTORY" || exit 1
    
    printf '%s\n' "Syncing Zed settings..."
    
    appdata="$HOME/AppData/Roaming"
    zed_dir="$appdata/Zed"
    
    mkdir -p "$zed_dir"
    
    cp "ide/zed/settings.jsonc" "$zed_dir/settings.json"
    cp "ide/zed/keymap.jsonc" "$zed_dir/keymap.json"
    
    printf '%s\n' "Zed settings synced"
}

sync_ubuntu() {
    cd "$PROJECT_DIRECTORY" || exit 1
    
    wsl_root="//wsl.localhost/Ubuntu/root"
    wsl_user="//wsl.localhost/Ubuntu/home/$USER"
    
    # Check if WSL is accessible
    if [ ! -d "$wsl_root" ]; then
        printf '%s\n' "WSL Ubuntu not accessible, skipping"
        return 0
    fi
    
    printf '%s\n' "Syncing to WSL Ubuntu..."
    
    # Sync to root
    while read -r file; do
        [ -n "$file" ] && cp "$file" "$wsl_root/$file" 2>/dev/null
    done < UBUNTU
    
    # Sync to user home if exists
    if [ -d "$wsl_user" ]; then
        while read -r file; do
            [ -n "$file" ] && cp "$file" "$wsl_user/$file" 2>/dev/null
        done < UBUNTU
    fi
    
    printf '%s\n' "WSL Ubuntu sync complete"
}

main "$@"
