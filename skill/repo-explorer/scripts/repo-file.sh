#!/usr/bin/env bash
# Read a file from a cloned repo
# Usage: repo-file.sh <owner/repo> <file-path> [--start <line>] [--end <line>]

set -euo pipefail

CACHE_DIR="${HOME}/.pi-repos"
MAX_LINES=500

# Parse arguments
REPO_INPUT=""
FILE_PATH=""
START_LINE=""
END_LINE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --start|-s) START_LINE="$2"; shift 2 ;;
        --end|-e) END_LINE="$2"; shift 2 ;;
        *)
            if [[ -z "$REPO_INPUT" ]]; then
                REPO_INPUT="$1"
            elif [[ -z "$FILE_PATH" ]]; then
                FILE_PATH="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$REPO_INPUT" ]] || [[ -z "$FILE_PATH" ]]; then
    echo "Error: Repository and file path required"
    echo "Usage: repo-file.sh <owner/repo> <file-path> [--start <line>] [--end <line>]"
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
FULL_PATH="${REPO_PATH}/${FILE_PATH}"

if [[ ! -d "$REPO_PATH" ]]; then
    echo "Error: Repo not cloned. Run: repo-clone.sh ${OWNER}/${REPO}"
    exit 1
fi

if [[ ! -f "$FULL_PATH" ]]; then
    echo "Error: File not found: $FILE_PATH"
    exit 1
fi

# Get total line count
TOTAL_LINES=$(wc -l < "$FULL_PATH" | tr -d ' ')

# Read with line numbers
if [[ -n "$START_LINE" ]] || [[ -n "$END_LINE" ]]; then
    START=${START_LINE:-1}
    END=${END_LINE:-$TOTAL_LINES}
    
    sed -n "${START},${END}p" "$FULL_PATH" | nl -ba -v "$START"
    
    if [[ $END -lt $TOTAL_LINES ]]; then
        echo ""
        echo "... (showing lines ${START}-${END} of ${TOTAL_LINES})"
    fi
else
    # Show file with line numbers, truncate if too long
    if [[ $TOTAL_LINES -gt $MAX_LINES ]]; then
        head -"$MAX_LINES" "$FULL_PATH" | nl -ba
        echo ""
        echo "... (${TOTAL_LINES} total lines, showing first ${MAX_LINES})"
        echo "Use --start and --end to view specific ranges"
    else
        nl -ba "$FULL_PATH"
    fi
fi
