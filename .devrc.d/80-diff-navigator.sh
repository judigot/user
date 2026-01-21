#!/bin/bash

# Terminal-Based Git Diff Navigator
# Provides side-by-side diff navigation using portable tools

# Global arrays for diff data
declare -A FILE_DIFFS  # Associative array: [file]="status"
declare -a FILE_ORDER   # Preserve file ordering

# Layer 1: Generate side-by-side diff for single file
getSideBySideDiff() {
    local file="$1"
    local base="$2"
    local target="$3"
    
    # Generate temp files for each version
    local temp_base="/tmp/diff_base_$$"
    local temp_target="/tmp/diff_target_$$"
    
    git show "$base:$file" > "$temp_base" 2>/dev/null || true
    git show "$target:$file" > "$temp_target" 2>/dev/null || true
    
    # Use portable diff -y for side-by-side
    diff -y "$temp_base" "$temp_target" 2>/dev/null
    
    # Cleanup
    rm -f "$temp_base" "$temp_target"
}

# Layer 1: Get raw diff for agent mode
getPlainDiff() {
    local base="${1:-origin/main}"
    local target="${2:-HEAD}"
    git diff "$base...$target" --no-color
}

# Layer 2: Parse diff headers to build file list
parseDiffIndex() {
    local raw_diff="$1"
    local current_file=""
    
    # Reset arrays
    FILE_DIFFS=()
    FILE_ORDER=()
    
    while IFS= read -r line; do
        # Parse diff headers
        if [[ "$line" =~ ^diff\ --git\ a/(.+)\ b/(.+)$ ]]; then
            current_file="${BASH_REMATCH[1]}"
            FILE_ORDER+=("$current_file")
        elif [[ "$line" =~ ^new\ file\ mode ]]; then
            FILE_DIFFS["$current_file"]="A"  # Added
        elif [[ "$line" =~ ^deleted\ file\ mode ]]; then
            FILE_DIFFS["$current_file"]="D"  # Deleted
        elif [[ "$line" =~ ^index[[:space:]] ]] && [[ -n "$current_file" ]]; then
            # Default to Modified if not already set as A or D
            if [[ -z "${FILE_DIFFS[$current_file]}" ]]; then
                FILE_DIFFS["$current_file"]="M"  # Modified
            fi
        fi
    done <<< "$raw_diff"
}

# Layer 3: Show diff view for single file
showDiffView() {
    local file_path="$1"
    local base_branch="$2"
    local current_branch="$3"
    
    clear
    printf '\033[1m=== %s ===\033[0m\n' "$file_path"
    printf '\033[2mSide-by-side: %s | %s\033[0m\n\n' "$base_branch" "$current_branch"
    
    getSideBySideDiff "$file_path" "$base_branch" "$current_branch"
    
    printf '\n\n\033[2mPress any key to return to file list...\033[0m'
    
    # Wait for any key
    read -rsn1 -p ""
}

# Layer 3: Show all changes view
showAllChanges() {
    local base_branch="$1"
    local current_branch="$2"
    
    clear
    printf '\033[1m=== All Changes ===\033[0m\n'
    printf '\033[2mDiff: %s...%s\033[0m\n\n' "$base_branch" "$current_branch"
    
    git diff "$base_branch...$current_branch" --no-color
    
    printf '\n\n\033[2mPress any key to return to file list...\033[0m'
    
    # Wait for any key
    read -rsn1 -p ""
}

# Layer 3: Handle file selection
handleSelection() {
    local selected="$1"
    local base_branch="$2"
    local current_branch="$3"
    local raw_diff="$4"
    
    if [[ $? -eq 0 ]] && [[ -n "$selected" ]]; then
        if [[ "$selected" == "[ All changes ]" ]]; then
            showAllChanges "$base_branch" "$current_branch"
        else
            showDiffView "$selected" "$base_branch" "$current_branch"
        fi
    fi
}

# Layer 3: Main navigation UI
showDiffNavigator() {
    local base_branch="$1"
    local current_branch="$2"
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        printf '\033[31mError: Not in a Git repository\033[0m\n' >&2
        return 1
    fi
    
    # Get diff data for parsing
    local raw_diff
    raw_diff=$(getPlainDiff "origin/$base_branch" "$current_branch")
    
    # Check if there are any changes
    if [[ -z "$raw_diff" ]]; then
        printf '\033[33mNo changes found between %s and %s\033[0m\n' "$base_branch" "$current_branch"
        return 0
    fi
    
    # Parse the diff to get file list
    parseDiffIndex "$raw_diff"
    
    # Build choices for arrowKeySelect
    local choices=("[ All changes ]")
    local file_path
    local status
    
    for file_path in "${FILE_ORDER[@]}"; do
        status="${FILE_DIFFS[$file_path]}"
        choices+=("$status $file_path")
    done
    
    # Show file list navigator
    local selected
    selected=$(arrowKeySelect "PR Diff Navigator" "${choices[@]}")
    
    # Handle selection
    handleSelection "$selected" "$base_branch" "$current_branch" "$raw_diff"
}

# Help function
showDifferUsage() {
    cat << 'EOF'
Usage: differ [base-branch]

Shows interactive diff navigator between base branch and current branch.

Examples:
  differ              # Show diff between main and current branch
  differ "develop"     # Show diff between develop and current branch
  differ --help        # Show this help

Agent mode (raw output):
  ai_diffnav           # Show raw diff between main and current branch
  ai_diffnav "dev"    # Show raw diff between dev and current branch

EOF
}

# Entry point: Human interactive mode
differ() {
    local base_branch="${1:-main}"
    local current_branch
    
    # Get current branch name
    current_branch=$(git branch --show-current 2>/dev/null || echo "HEAD")
    
    if [[ "$1" == "--help" ]]; then
        showDifferUsage
        return 0
    fi
    
    showDiffNavigator "$base_branch" "$current_branch"
}

# Entry point: Agent programmatic mode
ai_diffnav() {
    local base_branch="${1:-main}"
    local current_branch
    
    # Get current branch name
    current_branch=$(git branch --show-current 2>/dev/null || echo "HEAD")
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        printf 'Error: Not in a Git repository\n' >&2
        return 1
    fi
    
    # Output raw diff to stdout
    getPlainDiff "origin/$base_branch" "$current_branch"
}