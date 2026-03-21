#!/usr/bin/env bash
# Clone or update a GitHub repository locally for analysis
# Usage: repo-clone.sh <owner/repo or URL> [--refresh]

set -euo pipefail

CACHE_DIR="${HOME}/.pi-repos"
REFRESH=false

# Parse arguments
REPO_INPUT=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --refresh) REFRESH=true; shift ;;
        *) REPO_INPUT="$1"; shift ;;
    esac
done

if [[ -z "$REPO_INPUT" ]]; then
    echo "Error: Repository required"
    echo "Usage: repo-clone.sh <owner/repo or URL> [--refresh]"
    exit 1
fi

# Parse repo URL/path to get owner and repo
parse_repo() {
    local input="$1"
    
    # Handle git@ URLs
    if [[ "$input" == git@* ]]; then
        if [[ "$input" =~ git@github\.com:([^/]+)/(.+?)(\.git)?$ ]]; then
            echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]%.git}"
            return 0
        fi
    fi
    
    # Handle https:// URLs or owner/repo format
    if [[ "$input" =~ ^(https?://)?github\.com/([^/]+)/([^/\s]+)/?$ ]] || \
       [[ "$input" =~ ^([^/]+)/([^/\s]+)$ ]]; then
        local owner="${BASH_REMATCH[-2]}"
        local repo="${BASH_REMATCH[-1]}"
        # Remove .git suffix if present
        repo="${repo%.git}"
        echo "$owner $repo"
        return 0
    fi
    
    # Try simple owner/repo format
    if [[ "$input" =~ ^([^/]+)/([^/]+)$ ]]; then
        echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]%.git}"
        return 0
    fi
    
    return 1
}

# Parse the input
read -r OWNER REPO <<< "$(parse_repo "$REPO_INPUT")" || {
    echo "Error: Invalid repo format. Use: owner/repo or GitHub URL"
    exit 1
}

REPO_URL="https://github.com/${OWNER}/${REPO}.git"
REPO_PATH="${CACHE_DIR}/${OWNER}/${REPO}"
OWNER_DIR="${CACHE_DIR}/${OWNER}"

# Create cache directory
mkdir -p "$OWNER_DIR"

# Clone or update
if [[ -d "$REPO_PATH" ]]; then
    if [[ "$REFRESH" == true ]]; then
        echo "Refreshing ${OWNER}/${REPO}..."
        cd "$REPO_PATH"
        git fetch --all --prune 2>/dev/null || true
        git reset --hard origin/HEAD 2>/dev/null || git reset --hard HEAD
        STATUS="(refreshed)"
    else
        STATUS="(cached)"
    fi
else
    echo "Cloning ${OWNER}/${REPO}..."
    git clone --depth 100 "$REPO_URL" "$REPO_PATH" 2>&1
    STATUS="(cloned)"
fi

# Get repo stats
cd "$REPO_PATH"
FILE_COUNT=$(find . -type f -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ')
EXTENSIONS=$(find . -type f -not -path '*/.git/*' -name '*.*' 2>/dev/null | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -10)

echo ""
echo "✓ Repo ready: ${REPO_PATH} ${STATUS}"
echo ""
echo "Files: ${FILE_COUNT}"
echo ""
echo "Top extensions:"
echo "$EXTENSIONS"
echo ""
echo "Available commands:"
echo "  repo-structure.sh ${OWNER}/${REPO}  - directory tree"
echo "  repo-search.sh ${OWNER}/${REPO} <pattern>  - ripgrep search"
echo "  repo-file.sh ${OWNER}/${REPO} <path>  - read file"
echo "  repo-find.sh ${OWNER}/${REPO} <pattern>  - find files"
echo "  repo-deps.sh ${OWNER}/${REPO}  - dependency analysis"
echo "  repo-hotspots.sh ${OWNER}/${REPO}  - code hotspots"
echo "  repo-exports.sh ${OWNER}/${REPO}  - map public API"
echo "  repo-ast.sh ${OWNER}/${REPO} <pattern>  - AST search"
