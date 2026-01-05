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

# Check Node.js availability
if ! command -v node >/dev/null 2>&1; then
    echo "✗ Node.js not found. Please install Node.js to use this script." >&2
    exit 1
fi

# Function to process a single SSH key item
process_ssh_key() {
    local ITEM_NAME="$1"
    local KEY_FILENAME_OVERRIDE="$2"
    
    echo ""
    echo "=== Processing: $ITEM_NAME ==="
    
    # Get SSH key from Bitwarden item fields (case-insensitive search, normalize spaces/hyphens)
item_id="$(bw list items 2>/dev/null | node -e "
    try {
        const normalize = (s) => s ? s.toLowerCase().replace(/[\\s_-]+/g, '').trim() : '';
        const searchTerm = normalize(process.argv[1]);
        const input = require('fs').readFileSync(0, 'utf-8').trim();
        if (!input) {
            process.exit(1);
        }
        const data = JSON.parse(input);
        if (!Array.isArray(data)) {
            process.exit(1);
        }
        
        // Filter to SSH key items only (type 5 or type 4 with login)
        const sshItems = data.filter(i => i && (i.type === 5 || (i.type === 4 && i.login)));
        
        // Try exact match first (normalized), then partial match
        let matches = sshItems.filter(i => 
            i.name && normalize(i.name) === searchTerm
        );
        
        if (matches.length === 0) {
            matches = sshItems.filter(i => 
                i.name && normalize(i.name).includes(searchTerm)
            );
        }
        
        if (matches.length === 1) {
            console.log(matches[0].id);
        } else if (matches.length > 1) {
            // Multiple matches - use first one
            console.log(matches[0].id);
            console.error('Multiple matches found, using:', matches[0].name);
        } else {
            process.exit(1);
        }
    } catch (e) {
        process.exit(1);
    }
" "$ITEM_NAME")"

    [ -n "$item_id" ] || { 
        echo "✗ Bitwarden item not found: $ITEM_NAME" >&2
        echo "Available SSH key items:" >&2
        bw list items 2>/dev/null | node -e "
            try {
                const data = JSON.parse(require('fs').readFileSync(0, 'utf-8'));
                const sshItems = data.filter(i => i.type === 5 || (i.type === 4 && i.login));
                if (sshItems.length > 0) {
                    sshItems.forEach(i => console.log('  -', i.name));
                } else {
                    console.log('  (no SSH key items found)');
                }
            } catch (e) {
                console.log('  (error listing items)');
            }
        " || echo "  (error listing items)" >&2
        return 1
    }

# Extract private key from item fields (field name: "Private key")
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh" 2>/dev/null || true

# Extract private key and public key, auto-detect key type
    key_data="$(bw get item "$item_id" | node -e "
        const data = JSON.parse(require('fs').readFileSync(0, 'utf-8'));
        const result = { privateKey: null, publicKey: null, keyType: null };
        
        // For SSH key items (type 5)
        if (data.type === 5 && data.sshKey) {
            result.privateKey = data.sshKey.privateKey || null;
            result.publicKey = data.sshKey.publicKey || null;
            // Unescape \\n to actual newlines
            if (result.privateKey) {
                result.privateKey = result.privateKey.replace(/\\\\n/g, '\n');
            }
        }
        
        // Fallback: For SSH key items (type 4) - legacy format
        if (!result.privateKey && data.type === 4 && data.login) {
            result.privateKey = data.login.password || null;
            if (data.fields) {
                const pubKeyField = data.fields.find(f => 
                    f.name && f.name.toLowerCase().includes('public')
                );
                if (pubKeyField) result.publicKey = pubKeyField.value;
            }
        }
        
        // Fallback: For regular items, check fields
        if (!result.privateKey && data.fields && data.fields.length > 0) {
            const fieldNames = ['Private key', 'private key', 'Private Key', 'PRIVATE KEY', 'private_key', 'privatekey'];
            let privField = null;
            for (const name of fieldNames) {
                privField = data.fields.find(f => f.name === name || f.name.toLowerCase() === name.toLowerCase());
                if (privField) break;
            }
            if (!privField) {
                privField = data.fields.find(f => f.name.toLowerCase().includes('private'));
            }
            if (privField) result.privateKey = privField.value;
            
            const pubKeyField = data.fields.find(f => 
                f.name && f.name.toLowerCase().includes('public')
            );
            if (pubKeyField) result.publicKey = pubKeyField.value;
        }
        
        // Detect key type from public key
        if (result.publicKey) {
            if (result.publicKey.includes('ssh-ed25519')) result.keyType = 'ed25519';
            else if (result.publicKey.includes('ssh-rsa')) result.keyType = 'rsa';
            else if (result.publicKey.includes('ecdsa')) result.keyType = 'ecdsa';
            else if (result.publicKey.includes('ssh-dss')) result.keyType = 'dsa';
        }
        
        // Detect from private key if public key not available
        if (!result.keyType && result.privateKey) {
            if (result.privateKey.includes('BEGIN OPENSSH PRIVATE KEY')) {
                // OpenSSH format - usually ed25519 or rsa
                if (result.privateKey.includes('ssh-ed25519')) result.keyType = 'ed25519';
                else if (result.privateKey.includes('ssh-rsa')) result.keyType = 'rsa';
                else result.keyType = 'ed25519'; // Default for OpenSSH
            } else if (result.privateKey.includes('BEGIN RSA PRIVATE KEY')) result.keyType = 'rsa';
            else if (result.privateKey.includes('BEGIN EC PRIVATE KEY')) result.keyType = 'ecdsa';
            else if (result.privateKey.includes('BEGIN DSA PRIVATE KEY')) result.keyType = 'dsa';
        }
        
        console.log(JSON.stringify(result));
    ")"
    
    private_key="$(echo "$key_data" | node -e "const d=JSON.parse(require('fs').readFileSync(0,'utf-8')); console.log(d.privateKey || '')")"
    key_type="$(echo "$key_data" | node -e "const d=JSON.parse(require('fs').readFileSync(0,'utf-8')); console.log(d.keyType || 'ed25519')")"
    
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
    
    if [ -z "$private_key" ] || [ "$private_key" = "null" ]; then
        echo "✗ Private key not found in item '$ITEM_NAME'" >&2
        echo "Item type: $(bw get item "$item_id" | node -e "const d=JSON.parse(require('fs').readFileSync(0,'utf-8')); console.log(d.type || 'unknown')")" >&2
        echo "Available fields:" >&2
        bw get item "$item_id" | node -e "
            const data = JSON.parse(require('fs').readFileSync(0, 'utf-8'));
            if (data.type === 5 && data.sshKey) {
                console.log('  SSH key item (type 5)');
                console.log('  - sshKey.privateKey: ' + (data.sshKey.privateKey ? 'present' : 'missing'));
                console.log('  - sshKey.publicKey: ' + (data.sshKey.publicKey ? 'present' : 'missing'));
            } else if (data.fields && data.fields.length > 0) {
                data.fields.forEach(f => console.log('  - \"' + f.name + '\" (type: ' + f.type + ')'));
            } else if (data.type === 4) {
                console.log('  SSH key item (type 4) - check login.password field');
            } else {
                console.log('  (no fields found)');
            }
        " || echo "  (none)" >&2
        return 1
    fi

# Save private key to file (ensure it ends with newline)
printf '%s\n' "$private_key" > "$HOME/.ssh/$KEY_FILENAME"
chmod 600 "$HOME/.ssh/$KEY_FILENAME" 2>/dev/null || true

# Save public key if available, otherwise generate it
public_key="$(echo "$key_data" | node -e "const d=JSON.parse(require('fs').readFileSync(0,'utf-8')); console.log(d.publicKey || '')")"
if [ -n "$public_key" ] && [ "$public_key" != "null" ]; then
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
    
    echo "✓ SSH key ready: ~/.ssh/$KEY_FILENAME"
}

# Process each item
for ITEM_NAME in "${ITEM_NAMES[@]}"; do
    process_ssh_key "$ITEM_NAME" "" || echo "⚠ Failed to process: $ITEM_NAME" >&2
done

echo ""
echo "✓ All SSH keys processed"