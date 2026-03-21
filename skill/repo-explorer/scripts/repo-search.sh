#!/usr/bin/env bash
# Search in a cloned repo using ripgrep
# Usage: repo-search.sh <owner/repo> <pattern> [--glob <glob>] [--context <n>] [--max <n>]

set -euo pipefail

CACHE_DIR="${HOME}/.pi-repos"
MAX_OUTPUT=50000
MAX_LINES=500

# Parse arguments
REPO_INPUT=""
PATTERN=""
GLOB=""
CONTEXT=2
MAX_RESULTS=50

while [[ $# -gt 0 ]]; do
    case $1 in
        --glob) GLOB="$2"; shift 2 ;;
        --context|-C) CONTEXT="$2"; shift 2 ;;
        --max|-m) MAX_RESULTS="$2"; shift 2 ;;
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
    echo "Usage: repo-search.sh <owner/repo> <pattern> [--glob <glob>] [--context <n>]"
    exit 1
fi

# Parse repo to get path
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

# Build ripgrep command
RG_ARGS=(-n --color never -C "$CONTEXT" --max-count "$MAX_RESULTS")
if [[ -n "$GLOB" ]]; then
    RG_ARGS+=(--glob "$GLOB")
fi

# Run search and truncate output
cd "$REPO_PATH"
OUTPUT=$(rg "${RG_ARGS[@]}" "$PATTERN" . 2>/dev/null | head -"$MAX_LINES") || true

if [[ -z "$OUTPUT" ]]; then
    echo "No matches found for: $PATTERN"
else
    # Truncate by bytes if needed
    if [[ ${#OUTPUT} -gt $MAX_OUTPUT ]]; then
        echo "${OUTPUT:0:$MAX_OUTPUT}"
        echo ""
        echo "... (output truncated at ${MAX_OUTPUT} bytes)"
    else
        echo "$OUTPUT"
    fi
fi
