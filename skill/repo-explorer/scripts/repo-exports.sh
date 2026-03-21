#!/usr/bin/env bash
# Map public API - find all exports in a repo
# Usage: repo-exports.sh <owner/repo> [--entry <path>]

set -euo pipefail

CACHE_DIR="${HOME}/.pi-repos"

# Parse arguments
REPO_INPUT=""
ENTRY_POINT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --entry|-e) ENTRY_POINT="$2"; shift 2 ;;
        *) REPO_INPUT="$1"; shift ;;
    esac
done

if [[ -z "$REPO_INPUT" ]]; then
    echo "Error: Repository required"
    echo "Usage: repo-exports.sh <owner/repo> [--entry <path>]"
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

# Find entry point if not specified
if [[ -z "$ENTRY_POINT" ]]; then
    POSSIBLE_ENTRIES=(
        "src/index.ts" "src/index.tsx" "src/index.js"
        "lib/index.ts" "lib/index.js"
        "index.ts" "index.js"
        "src/main.ts" "src/main.js"
        "mod.ts" "src/lib.rs" "lib.rs"
    )
    
    for entry in "${POSSIBLE_ENTRIES[@]}"; do
        if [[ -f "$entry" ]]; then
            ENTRY_POINT="$entry"
            break
        fi
    done
fi

# Show entry point if found
if [[ -n "$ENTRY_POINT" ]] && [[ -f "$ENTRY_POINT" ]]; then
    echo "## Entry Point: $ENTRY_POINT"
    echo ""
    echo '```'
    head -80 "$ENTRY_POINT"
    LINES=$(wc -l < "$ENTRY_POINT" | tr -d ' ')
    if [[ $LINES -gt 80 ]]; then
        echo ""
        echo "// ... (${LINES} total lines)"
    fi
    echo '```'
    echo ""
fi

# Named exports (TypeScript/JavaScript)
echo "## Named Exports"
echo ""
if command -v rg &> /dev/null; then
    rg "^export (const|function|class|type|interface|enum|let|var|async function) " \
        --glob '*.ts' --glob '*.tsx' --glob '*.js' --glob '*.jsx' \
        -o -N 2>/dev/null | \
        sort | uniq -c | sort -rn | head -30 || echo "(none found)"
else
    grep -rh "^export \(const\|function\|class\|type\|interface\|enum\)" \
        --include='*.ts' --include='*.tsx' --include='*.js' . 2>/dev/null | \
        sort | uniq -c | sort -rn | head -30 || echo "(none found)"
fi
echo ""

# Default exports
echo "## Files with Default Exports"
echo ""
if command -v rg &> /dev/null; then
    rg "^export default" --glob '*.ts' --glob '*.tsx' --glob '*.js' -l 2>/dev/null | head -20 || echo "(none found)"
else
    grep -rl "^export default" --include='*.ts' --include='*.tsx' --include='*.js' . 2>/dev/null | head -20 || echo "(none found)"
fi
echo ""

# Re-exports
echo "## Re-exports (barrel files)"
echo ""
if command -v rg &> /dev/null; then
    rg "^export \* from|^export \{[^}]+\} from" \
        --glob '*.ts' --glob '*.tsx' --glob '*.js' \
        2>/dev/null | head -30 || echo "(none found)"
else
    grep -rh "^export \* from\|^export {" \
        --include='*.ts' --include='*.tsx' --include='*.js' . 2>/dev/null | \
        head -30 || echo "(none found)"
fi
