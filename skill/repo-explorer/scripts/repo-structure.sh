#!/usr/bin/env bash
# Get directory structure of a cloned repo
# Usage: repo-structure.sh <owner/repo> [--path <subpath>] [--depth <n>]

set -euo pipefail

CACHE_DIR="${HOME}/.pi-repos"

# Parse arguments
REPO_INPUT=""
SUBPATH=""
DEPTH=4

while [[ $# -gt 0 ]]; do
    case $1 in
        --path|-p) SUBPATH="$2"; shift 2 ;;
        --depth|-d) DEPTH="$2"; shift 2 ;;
        *) REPO_INPUT="$1"; shift ;;
    esac
done

if [[ -z "$REPO_INPUT" ]]; then
    echo "Error: Repository required"
    echo "Usage: repo-structure.sh <owner/repo> [--path <subpath>] [--depth <n>]"
    exit 1
fi

# Parse repo
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
    echo "Error: Repo not cloned. Run: repo-clone.sh ${OWNER}/${REPO}"
    exit 1
fi

TARGET_PATH="$REPO_PATH"
if [[ -n "$SUBPATH" ]]; then
    TARGET_PATH="${REPO_PATH}/${SUBPATH}"
fi

if [[ ! -d "$TARGET_PATH" ]]; then
    echo "Error: Path not found: $SUBPATH"
    exit 1
fi

# Try tree first, fall back to find
IGNORE_PATTERN='.git|node_modules|__pycache__|.venv|dist|build|.next|target|vendor'

if command -v tree &> /dev/null; then
    tree -L "$DEPTH" --dirsfirst -I "$IGNORE_PATTERN" "$TARGET_PATH" 2>/dev/null | head -300
else
    # Fallback to find
    find "$TARGET_PATH" -maxdepth "$DEPTH" \
        -not -path '*/.git/*' \
        -not -path '*/node_modules/*' \
        -not -path '*/__pycache__/*' \
        -not -path '*/.venv/*' \
        -not -path '*/dist/*' \
        -not -path '*/build/*' \
        -not -path '*/.next/*' \
        -not -path '*/target/*' \
        -not -path '*/vendor/*' \
        2>/dev/null | head -300 | sort
fi
