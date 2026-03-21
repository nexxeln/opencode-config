#!/usr/bin/env bash
# Find code hotspots - most changed files, largest files, TODOs
# Usage: repo-hotspots.sh <owner/repo>

set -euo pipefail

CACHE_DIR="${HOME}/.pi-repos"

# Parse arguments
REPO_INPUT="${1:-}"

if [[ -z "$REPO_INPUT" ]]; then
    echo "Error: Repository required"
    echo "Usage: repo-hotspots.sh <owner/repo>"
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

# Git churn - most frequently changed files
echo "## Most Changed Files (Git Churn - last 100 commits)"
echo ""
git log --oneline --name-only --pretty=format: -100 2>/dev/null | \
    grep -v '^$' | \
    sort | uniq -c | sort -rn | head -15 || echo "(no git history)"
echo ""

# Largest files by line count
echo "## Largest Files (by lines)"
echo ""
if command -v fd &> /dev/null; then
    fd -t f -E .git -E node_modules -E __pycache__ -E dist -E build -E '*.lock' -E '*.min.*' . 2>/dev/null | \
        xargs wc -l 2>/dev/null | sort -rn | head -16 | tail -15
else
    find . -type f \
        -not -path '*/.git/*' \
        -not -path '*/node_modules/*' \
        -not -path '*/__pycache__/*' \
        -not -path '*/dist/*' \
        -not -path '*/build/*' \
        -not -name '*.lock' \
        -not -name '*.min.*' \
        2>/dev/null | \
        head -500 | xargs wc -l 2>/dev/null | sort -rn | head -16 | tail -15
fi
echo ""

# Files with most TODOs/FIXMEs
echo "## Files with Most TODOs/FIXMEs"
echo ""
if command -v rg &> /dev/null; then
    rg -c 'TODO|FIXME|HACK|XXX|BUG' --glob '!.git' --glob '!node_modules' --glob '!dist' 2>/dev/null | \
        sort -t: -k2 -rn | head -10 || echo "(none found)"
else
    grep -r -c -E 'TODO|FIXME|HACK|XXX|BUG' --include='*' . 2>/dev/null | \
        grep -v '.git' | grep -v 'node_modules' | \
        sort -t: -k2 -rn | head -10 || echo "(none found)"
fi
echo ""

# Recent commits
echo "## Recent Commits (last 20)"
echo ""
git log --oneline -20 2>/dev/null || echo "(no git history)"
echo ""

# Active branches
echo "## Active Branches"
echo ""
git branch -a 2>/dev/null | head -15 || echo "(no branches)"
