#!/bin/sh

readonly PROJECT_DIRECTORY=$(cd "$(dirname "$0")" || exit 1; pwd)

main() {
    commit_user_repo
    sync_to_home "DOTFILES"
    sync_ai_repo
    sync_cursor_repo "CURSOR"
    sync_ide_repo
    sync_ubuntu "UBUNTU"
    sync_zed_settings
    sync_cursor_settings
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
    local manifest="$1"
    cd "$PROJECT_DIRECTORY" || exit 1
    
    if [ ! -f "$manifest" ]; then
        printf '%s\n' "Manifest file not found: $manifest" >&2
        return 1
    fi
    
    # Ensure we use Windows home directory, not MSYS2 home
    local target_home="$HOME"
    if [ -n "$USERPROFILE" ]; then
        # Convert Windows path to Unix path (C:\Users\Jude -> /c/Users/Jude)
        target_home=$(echo "$USERPROFILE" | sed 's|\\|/|g' | sed 's|^\([A-Z]\):|/\1|' | tr '[:upper:]' '[:lower:]')
    elif [ -d "/c/Users/$USER" ]; then
        target_home="/c/Users/$USER"
    elif [ -d "/c/Users/$(whoami)" ]; then
        target_home="/c/Users/$(whoami)"
    fi
    
    printf '%s\n' "Syncing files from $manifest to: $target_home"
    
    # Sync only what's listed in the manifest (handle files without trailing newline)
    while read -r file || [ -n "$file" ]; do
        if [ -n "$file" ]; then
            if [ -f "$file" ]; then
                if [ "$(dirname "$file")" != "." ]; then
                    mkdir -p "$target_home/$(dirname "$file")" 2>/dev/null || true
                fi
                cp "$file" "$target_home/$file" || printf '%s\n' "Warning: Failed to copy $file" >&2
            elif [ -d "$file" ]; then
                mkdir -p "$target_home/$(dirname "$file")" 2>/dev/null || true
                cp -r "$file" "$target_home/$file" || printf '%s\n' "Warning: Failed to copy $file" >&2
            fi
        fi
    done < "$manifest"
    
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
    local manifest="$1"
    cd "$PROJECT_DIRECTORY" || exit 1
    
    if [ ! -f "$manifest" ]; then
        printf '%s\n' "Manifest file not found: $manifest" >&2
        return 1
    fi
    
    printf '%s\n' "Syncing files from $manifest to judigot/cursor..."
    
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
    
    # Sync only what's listed in the manifest (handle files without trailing newline)
    while read -r item || [ -n "$item" ]; do
        [ -n "$item" ] && cp -r "$PROJECT_DIRECTORY/$item" "$cursor_local/"
    done < "$manifest"
    
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
    
    # Remove existing symlinks/files in Cursor (they might be dangling symlinks)
    rm -f "$cursor_user/settings.json" 2>/dev/null
    rm -f "$cursor_user/keybindings.json" 2>/dev/null
    rm -rf "$cursor_user/snippets" 2>/dev/null
    
    # Create directories
    mkdir -p "$cursor_user/snippets"
    mkdir -p "$vscode_user"
    
    # Copy to Cursor (actual files) - .jsonc → .json
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
    local manifest="$1"
    cd "$PROJECT_DIRECTORY" || exit 1
    
    if [ ! -f "$manifest" ]; then
        printf '%s\n' "Manifest file not found: $manifest" >&2
        return 1
    fi
    
    # Get Windows home directory
    local win_home="$HOME"
    if [ -n "$USERPROFILE" ]; then
        win_home=$(echo "$USERPROFILE" | sed 's|\\|/|g' | sed 's|^\([A-Z]\):|/\1|' | tr '[:upper:]' '[:lower:]')
    elif [ -d "/c/Users/$USER" ]; then
        win_home="/c/Users/$USER"
    fi
    
    wsl_root="//wsl.localhost/Ubuntu/root"
    wsl_user="//wsl.localhost/Ubuntu/home/$USER"
    
    # Check if WSL is accessible
    if [ ! -d "$wsl_root" ]; then
        printf '%s\n' "WSL Ubuntu not accessible, skipping"
        return 0
    fi
    
    printf '%s\n' "Syncing files from $manifest to WSL Ubuntu..."
    
    # Function to sync a single entry
    sync_entry() {
        local entry="$1"
        local dest_base="$2"
        
        # If entry starts with $HOME, expand to Windows home path
        if echo "$entry" | grep -q '^\$HOME'; then
            # Get relative path (e.g., .ssh from $HOME\.ssh)
            local rel_path=$(echo "$entry" | sed 's|^\$HOME[\\/]*||' | sed 's|\\|/|g')
            local src_path="$win_home/$rel_path"
            local dest_path="$dest_base/$rel_path"
            
            if [ -d "$src_path" ]; then
                mkdir -p "$(dirname "$dest_path")" 2>/dev/null || true
                cp -r "$src_path" "$dest_path" 2>/dev/null || true
            elif [ -f "$src_path" ]; then
                mkdir -p "$(dirname "$dest_path")" 2>/dev/null || true
                cp "$src_path" "$dest_path" 2>/dev/null || true
            fi
        else
            # Regular file from repo
            if [ -d "$entry" ]; then
                cp -r "$entry" "$dest_base/$entry" 2>/dev/null || true
            elif [ -f "$entry" ]; then
                cp "$entry" "$dest_base/$entry" 2>/dev/null || true
            fi
        fi
    }
    
    # Sync only what's listed in the manifest (handle files without trailing newline)
    while read -r file || [ -n "$file" ]; do
        [ -n "$file" ] && sync_entry "$file" "$wsl_root"
    done < "$manifest"
    
    # Sync to user home if exists
    if [ -d "$wsl_user" ]; then
        while read -r file || [ -n "$file" ]; do
            [ -n "$file" ] && sync_entry "$file" "$wsl_user"
        done < "$manifest"
    fi
    
    printf '%s\n' "WSL Ubuntu sync complete"
}

main "$@"
