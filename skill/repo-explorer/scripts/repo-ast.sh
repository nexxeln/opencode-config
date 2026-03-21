#!/usr/bin/env bash
# AST-grep structural search in a cloned repo
# Usage: repo-ast.sh <owner/repo> <pattern> [--lang <language>]
#
# Requires: ast-grep (sg) - https://ast-grep.github.io/

set -euo pipefail

CACHE_DIR="${HOME}/.pi-repos"

# Parse arguments
REPO_INPUT=""
PATTERN=""
LANG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --lang|-l) LANG="$2"; shift 2 ;;
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
    echo "Usage: repo-ast.sh <owner/repo> <pattern> [--lang <language>]"
    echo ""
    echo "Examples:"
    echo "  repo-ast.sh owner/repo 'function \$NAME(\$\$ARGS) { \$\$BODY }'"
    echo "  repo-ast.sh owner/repo 'console.log(\$\$ARGS)' --lang ts"
    echo "  repo-ast.sh owner/repo 'async function \$_(\$\$_) { \$\$_ }'"
    echo ""
    echo "Pattern syntax:"
    echo "  \$NAME  - single metavariable (matches one node)"
    echo "  \$\$ARGS - multi metavariable (matches zero or more)"
    echo "  \$_     - anonymous metavariable (matches but doesn't capture)"
    exit 1
fi

# Check if ast-grep is installed
if ! command -v sg &> /dev/null && ! command -v ast-grep &> /dev/null; then
    echo "Error: ast-grep not installed"
    echo ""
    echo "Install with:"
    echo "  brew install ast-grep    # macOS"
    echo "  cargo install ast-grep   # Rust/Cargo"
    echo "  npm install -g @ast-grep/cli  # npm"
    echo ""
    echo "See: https://ast-grep.github.io/"
    exit 1
fi

# Use sg or ast-grep
AST_GREP="sg"
if ! command -v sg &> /dev/null; then
    AST_GREP="ast-grep"
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

# Build ast-grep command
AST_ARGS=(--pattern "$PATTERN")
if [[ -n "$LANG" ]]; then
    AST_ARGS+=(--lang "$LANG")
fi

# Run ast-grep and limit output
$AST_GREP "${AST_ARGS[@]}" . 2>/dev/null | head -200 || echo "No matches found"
