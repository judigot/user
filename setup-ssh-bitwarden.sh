#!/bin/bash
# One-liner SSH key setup from Bitwarden
# Usage: curl -fsSL https://raw.githubusercontent.com/judigot/user/main/setup-ssh-bitwarden.sh | bash

set -eu

# Default to both personal and work if no arguments provided
if [ $# -eq 0 ]; then
    ITEM_NAMES=("SSH Personal" "SSH Work")
else
    ITEM_NAMES=("$@")
fi

KEY_FILENAME="${2:-}"  # Auto-detect if not provided (legacy support)
BW_VER="2025.12.0"  # Hardcoded as of 2026-01-05

# Fix HOME if malformed (MSYS2 sometimes has issues)
[[ "$HOME" != /* ]] && [[ "$HOME" != /c/* ]] && HOME="/c/Users/$USERNAME"
export PATH="$HOME/.local/bin:$PATH"

# Install Bitwarden CLI if needed
if ! command -v bw >/dev/null 2>&1; then
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  tmp="${TMPDIR:-/tmp}"
  if [ "$os" = "linux" ]; then
    curl -fsSL "https://github.com/bitwarden/clients/releases/download/cli-v$BW_VER/bw-linux-$BW_VER.zip" -o "$tmp/bw.zip"
    sudo unzip -o "$tmp/bw.zip" -d /usr/local/bin >/dev/null && sudo chmod +x /usr/local/bin/bw
  else
    mkdir -p "$HOME/.local/bin"
    curl -fsSL "https://github.com/bitwarden/clients/releases/download/cli-v$BW_VER/bw-windows-$BW_VER.zip" -o "$tmp/bw.zip"
    unzip -o "$tmp/bw.zip" -d "$HOME/.local/bin" >/dev/null && chmod +x "$HOME/.local/bin/bw.exe" 2>/dev/null || true
  fi
  rm -f "$tmp/bw.zip"
fi

# Login if needed
bw login --check >/dev/null 2>&1 || bw login

# Unlock vault
export BW_SESSION="$(bw unlock --raw)"
[ -n "$BW_SESSION" ] || { echo "✗ Failed to unlock Bitwarden vault" >&2; exit 1; }

# Check for awk (required for JSON parsing)
if ! command -v awk >/dev/null 2>&1; then
    echo "✗ awk not found. Please install awk to use this script." >&2
    exit 1
fi

# Function to normalize string (remove spaces/hyphens, lowercase)
normalize_str() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[[:space:]_-]//g'
}

# Function to process a single SSH key item
process_ssh_key() {
    local ITEM_NAME="$1"
    local KEY_FILENAME_OVERRIDE="$2"
    
    echo ""
    echo "=== Processing: $ITEM_NAME ==="
    
    # Get SSH key from Bitwarden item fields (case-insensitive search, normalize spaces/hyphens)
    local search_term=$(normalize_str "$ITEM_NAME")
    item_id="$(bw list items 2>/dev/null | awk -v search="$search_term" '
        function normalize(s) {
            gsub(/[[:space:]_-]/, "", s)
            return tolower(s)
        }
        function extract_value(line, key,    arr) {
            if (match(line, "\"" key "\"[[:space:]]*:[[:space:]]*\"([^\"]+)\"", arr)) {
                return arr[1]
            }
            if (match(line, "\"" key "\"[[:space:]]*:[[:space:]]*([0-9]+)", arr)) {
                return arr[1]
            }
            return ""
        }
        BEGIN {
            RS=""
            found = 0
        }
        {
            # Process each line looking for JSON objects
            # For type 5 items (SSH key items)
            if (match($0, /"type"[[:space:]]*:[[:space:]]*5/)) {
                name = extract_value($0, "name")
                id = extract_value($0, "id")
                if (name != "" && id != "") {
                    norm_name = normalize(name)
                    if (norm_name == search || index(norm_name, search) > 0) {
                        if (!found) {
                            print id
                            found = 1
                            exit
                        }
                    }
                }
            }
            # For type 4 items with login
            if (match($0, /"type"[[:space:]]*:[[:space:]]*4/) && match($0, /"login"/)) {
                name = extract_value($0, "name")
                id = extract_value($0, "id")
                if (name != "" && id != "") {
                    norm_name = normalize(name)
                    if (norm_name == search || index(norm_name, search) > 0) {
                        if (!found) {
                            print id
                            found = 1
                            exit
                        }
                    }
                }
            }
        }
    ')"

    [ -n "$item_id" ] || { 
        echo "✗ Bitwarden item not found: $ITEM_NAME" >&2
        echo "Available SSH key items:" >&2
        bw list items 2>/dev/null | awk '
            function extract_json_value(json, key,    arr) {
                match(json, "\"" key "\"[[:space:]]*:[[:space:]]*\"([^\"]+)\"", arr)
                if (arr[1] != "") return arr[1]
                match(json, "\"" key "\"[[:space:]]*:[[:space:]]*([0-9]+)", arr)
                if (arr[1] != "") return arr[1]
                return ""
            }
            {
                type_val = extract_json_value($0, "type")
                if (type_val == "5" || (type_val == "4" && index($0, "\"login\"") > 0)) {
                    name = extract_json_value($0, "name")
                    if (name != "") print "  -", name
                }
            }
        ' || echo "  (error listing items)" >&2
        return 1
    }

# Extract private key from item fields (field name: "Private key")
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh" 2>/dev/null || true

# Extract private key and public key, auto-detect key type
    item_json="$(bw get item "$item_id")"
    
    # Extract private key from sshKey.privateKey (type 5)
    # The value is on one line with \\n escapes
    private_key="$(echo "$item_json" | awk '
        BEGIN { in_sshkey = 0; found = 0 }
        /"sshKey"/ { in_sshkey = 1 }
        in_sshkey && /"privateKey"/ && !found {
            # Extract value between quotes
            if (match($0, /"privateKey"[[:space:]]*:[[:space:]]*"([^"]+)"/, arr)) {
                key = arr[1]
                # Replace \\n with actual newlines
                gsub(/\\\\n/, "\n", key)
                # Handle other escapes
                gsub(/\\"/, "\"", key)
                gsub(/\\t/, "\t", key)
                print key
                found = 1
                exit
            }
        }
    ')"
    
    # Extract public key
    public_key="$(echo "$item_json" | awk '
        BEGIN { in_sshkey = 0 }
        /"sshKey"/ { in_sshkey = 1 }
        in_sshkey && /"publicKey"/ {
            if (match($0, /"publicKey"[[:space:]]*:[[:space:]]*"([^"]+)"/, arr)) {
                print arr[1]
                exit
            }
        }
    ')"
    
    # Detect key type
    key_type="ed25519"  # default
    if echo "$public_key" | grep -q "ssh-ed25519"; then
        key_type="ed25519"
    elif echo "$public_key" | grep -q "ssh-rsa"; then
        key_type="rsa"
    elif echo "$public_key" | grep -q "ecdsa"; then
        key_type="ecdsa"
    elif echo "$public_key" | grep -q "ssh-dss"; then
        key_type="dsa"
    elif echo "$private_key" | grep -q "BEGIN OPENSSH PRIVATE KEY"; then
        if echo "$private_key" | grep -q "ssh-ed25519"; then
            key_type="ed25519"
        elif echo "$private_key" | grep -q "ssh-rsa"; then
            key_type="rsa"
        fi
    elif echo "$private_key" | grep -q "BEGIN RSA PRIVATE KEY"; then
        key_type="rsa"
    elif echo "$private_key" | grep -q "BEGIN EC PRIVATE KEY"; then
        key_type="ecdsa"
    fi
    
    # Auto-generate filename if not provided
    local KEY_FILENAME
    if [ -n "$KEY_FILENAME_OVERRIDE" ]; then
        KEY_FILENAME="$KEY_FILENAME_OVERRIDE"
    else
        # Extract just the descriptive part (remove "SSH " prefix if present)
        item_part="$(echo "$ITEM_NAME" | sed 's/^[Ss][Ss][Hh][[:space:]]*//' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')"
        # Special case: "personal" becomes just the key type (no postfix)
        if [ "$item_part" = "personal" ]; then
            KEY_FILENAME="id_${key_type}"
        else
            KEY_FILENAME="id_${key_type}_${item_part}"
        fi
        # Fallback if sanitization results in empty string
        [ -z "$item_part" ] && KEY_FILENAME="id_${key_type}"
    fi
    
    if [ -z "$private_key" ]; then
        echo "✗ Private key not found in item '$ITEM_NAME'" >&2
        echo "Item type: $(bw get item "$item_id" | awk 'match($0, /"type"[[:space:]]*:[[:space:]]*([0-9]+)/, arr) { print arr[1]; exit }')" >&2
        echo "Available fields:" >&2
        bw get item "$item_id" | awk '
            /"type"[[:space:]]*:[[:space:]]*5/ && /"sshKey"/ {
                print "  SSH key item (type 5)"
                if (match($0, /"privateKey"[[:space:]]*:[[:space:]]*"[^"]+"/)) {
                    print "  - sshKey.privateKey: present"
                } else {
                    print "  - sshKey.privateKey: missing"
                }
                if (match($0, /"publicKey"[[:space:]]*:[[:space:]]*"[^"]+"/)) {
                    print "  - sshKey.publicKey: present"
                } else {
                    print "  - sshKey.publicKey: missing"
                }
                exit
            }
            /"type"[[:space:]]*:[[:space:]]*4/ {
                print "  SSH key item (type 4) - check login.password field"
                exit
            }
            /"fields"/ {
                in_fields = 1
            }
            in_fields && /"name"/ {
                if (match($0, /"name"[[:space:]]*:[[:space:]]*"([^"]+)"/, arr)) {
                    name = arr[1]
                    if (match($0, /"type"[[:space:]]*:[[:space:]]*([0-9]+)/, arr2)) {
                        print "  - \"" name "\" (type: " arr2[1] ")"
                    } else {
                        print "  - \"" name "\""
                    }
                }
            }
            END {
                if (!in_fields && !/"type"[[:space:]]*:[[:space:]]*5/ && !/"type"[[:space:]]*:[[:space:]]*4/) {
                    print "  (no fields found)"
                }
            }
        ' || echo "  (none)" >&2
        return 1
    fi

# Save private key to file (ensure it ends with newline)
printf '%s\n' "$private_key" > "$HOME/.ssh/$KEY_FILENAME"
chmod 600 "$HOME/.ssh/$KEY_FILENAME" 2>/dev/null || true

# Save public key if available, otherwise generate it
if [ -n "$public_key" ]; then
    printf '%s\n' "$public_key" > "$HOME/.ssh/${KEY_FILENAME}.pub"
    chmod 644 "$HOME/.ssh/${KEY_FILENAME}.pub" 2>/dev/null || true
    echo "✓ Public key saved: ~/.ssh/${KEY_FILENAME}.pub"
else
    # Generate public key from private key
    if command -v ssh-keygen >/dev/null 2>&1; then
        ssh-keygen -y -f "$HOME/.ssh/$KEY_FILENAME" > "$HOME/.ssh/${KEY_FILENAME}.pub" 2>/dev/null && \
            chmod 644 "$HOME/.ssh/${KEY_FILENAME}.pub" 2>/dev/null && \
            echo "✓ Public key generated: ~/.ssh/${KEY_FILENAME}.pub" || \
            echo "⚠ Could not generate public key (ssh-keygen not available or key format issue)"
    fi
fi

    # Add to SSH agent
    [ "$(uname -s | tr '[:upper:]' '[:lower:]')" = "linux" ] && eval "$(ssh-agent -s)" >/dev/null 2>&1 || true
    ssh-add "$HOME/.ssh/$KEY_FILENAME"
    
    # Setup git config aliases based on key type
    item_part="$(echo "$ITEM_NAME" | sed 's/^[Ss][Ss][Hh][[:space:]]*//' | tr '[:upper:]' '[:lower:]')"
    if [ "$item_part" = "personal" ]; then
        # Setup git alias for personal SSH
        git config --global alias.usepersonalssh "!git config user.name 'judigot'"
        echo "✓ Git alias 'usepersonalssh' configured (sets user.name to 'judigot')"
    elif [ "$item_part" = "work" ]; then
        # Setup git alias for work SSH
        git config --global alias.useworkssh "!git config user.name 'judestp'"
        echo "✓ Git alias 'useworkssh' configured (sets user.name to 'judestp')"
    fi
    
    echo "✓ SSH key ready: ~/.ssh/$KEY_FILENAME"
}

# Process each item
for ITEM_NAME in "${ITEM_NAMES[@]}"; do
    process_ssh_key "$ITEM_NAME" "" || echo "⚠ Failed to process: $ITEM_NAME" >&2
done

echo ""
echo "✓ All SSH keys processed"
