#!/usr/bin/env bash
# Find files by pattern using fd or find
# Usage: repo-find.sh <owner/repo> <pattern> [--type <f|d>] [--ext <extension>]

set -euo pipefail

CACHE_DIR="${HOME}/.pi-repos"
MAX_RESULTS=100

# Parse arguments
REPO_INPUT=""
PATTERN=""
TYPE=""
EXT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --type|-t) TYPE="$2"; shift 2 ;;
        --ext|-e) EXT="$2"; shift 2 ;;
        *)
            if [[ -z "$REPO_INPUT" ]]; then
                REPO_INPUT="$1"
            elif [[ -z "$PATTERN" ]]; then
                PATTERN="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$REPO_INPUT" ]] || [[ -z "$PATTERN" ]]; then
    echo "Error: Repository and pattern required"
    echo "Usage: repo-find.sh <owner/repo> <pattern> [--type <f|d>] [--ext <extension>]"
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

cd "$REPO_PATH"

# Use fd if available, otherwise fall back to find
if command -v fd &> /dev/null; then
    FD_ARGS=(-E .git -E node_modules -E __pycache__ -E .venv -E dist -E build)
    
    if [[ -n "$TYPE" ]]; then
        FD_ARGS+=(-t "$TYPE")
    fi
    
    if [[ -n "$EXT" ]]; then
        FD_ARGS+=(-e "$EXT")
    fi
    
    fd "${FD_ARGS[@]}" "$PATTERN" . 2>/dev/null | head -"$MAX_RESULTS"
else
    # Fallback to find
    FIND_ARGS=(-not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/__pycache__/*')
    
    if [[ "$TYPE" == "f" ]]; then
        FIND_ARGS+=(-type f)
    elif [[ "$TYPE" == "d" ]]; then
        FIND_ARGS+=(-type d)
    fi
    
    if [[ -n "$EXT" ]]; then
        find . "${FIND_ARGS[@]}" -name "*.$EXT" 2>/dev/null | grep -i "$PATTERN" | head -"$MAX_RESULTS"
    else
        find . "${FIND_ARGS[@]}" -name "*${PATTERN}*" 2>/dev/null | head -"$MAX_RESULTS"
    fi
fi
