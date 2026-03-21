#!/usr/bin/env bash
# Remove cloned repos from local cache
# Usage: repo-cleanup.sh <owner/repo> or repo-cleanup.sh --all

set -euo pipefail

CACHE_DIR="${HOME}/.pi-repos"

# Parse arguments
REPO_INPUT="${1:-}"

if [[ -z "$REPO_INPUT" ]]; then
    echo "Error: Repository or --all required"
    echo "Usage: repo-cleanup.sh <owner/repo>"
    echo "       repo-cleanup.sh --all"
    echo ""
    
    # Show cached repos
    if [[ -d "$CACHE_DIR" ]]; then
        echo "Currently cached repos:"
        find "$CACHE_DIR" -mindepth 2 -maxdepth 2 -type d 2>/dev/null | \
            sed "s|${CACHE_DIR}/||" | sort
        
        # Show total size
        SIZE=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)
        echo ""
        echo "Total cache size: ${SIZE:-0}"
    else
        echo "No repos cached yet."
    fi
    exit 1
fi

# Clean all repos
if [[ "$REPO_INPUT" == "--all" ]]; then
    if [[ -d "$CACHE_DIR" ]]; then
        SIZE=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)
        echo "Removing all cached repos (${SIZE})..."
        rm -rf "$CACHE_DIR"
        echo "✓ Cleared ${CACHE_DIR}"
    else
        echo "Cache directory doesn't exist"
    fi
    exit 0
fi

# Clean specific repo
parse_repo() {
    local input="$1"
    if [[ "$input" =~ ^([^/]+)/([^/]+)$ ]]; then
        echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]%.git}"
        return 0
    fi
    if [[ "$input" =~ github\.com[/:]([^/]+)/([^/\s]+) ]]; then
        echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]%.git}"
        return 0
    fi
    return 1
}

read -r OWNER REPO <<< "$(parse_repo "$REPO_INPUT")" || {
    echo "Error: Invalid repo format"
    exit 1
}

REPO_PATH="${CACHE_DIR}/${OWNER}/${REPO}"

if [[ ! -d "$REPO_PATH" ]]; then
    echo "Repo not in cache: ${OWNER}/${REPO}"
    exit 0
fi

SIZE=$(du -sh "$REPO_PATH" 2>/dev/null | cut -f1)
echo "Removing ${OWNER}/${REPO} (${SIZE})..."
rm -rf "$REPO_PATH"
echo "✓ Removed: ${REPO_PATH}"

# Clean up empty owner directory
OWNER_DIR="${CACHE_DIR}/${OWNER}"
if [[ -d "$OWNER_DIR" ]] && [[ -z "$(ls -A "$OWNER_DIR")" ]]; then
    rmdir "$OWNER_DIR"
fi
