#!/usr/bin/env bash
# Analyze dependencies in a cloned repo
# Usage: repo-deps.sh <owner/repo>

set -euo pipefail

CACHE_DIR="${HOME}/.pi-repos"

# Parse arguments
REPO_INPUT="${1:-}"

if [[ -z "$REPO_INPUT" ]]; then
    echo "Error: Repository required"
    echo "Usage: repo-deps.sh <owner/repo>"
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
FOUND_ANY=false

# Node.js - package.json
if [[ -f "package.json" ]]; then
    FOUND_ANY=true
    echo "## Node.js (package.json)"
    echo ""
    
    # Extract dependencies using jq if available, otherwise grep
    if command -v jq &> /dev/null; then
        DEPS=$(jq -r '.dependencies // {} | keys | .[]' package.json 2>/dev/null | head -25 | tr '\n' ', ' | sed 's/,$//')
        DEV_DEPS=$(jq -r '.devDependencies // {} | keys | .[]' package.json 2>/dev/null | head -20 | tr '\n' ', ' | sed 's/,$//')
        DEP_COUNT=$(jq -r '.dependencies // {} | keys | length' package.json 2>/dev/null)
        DEV_COUNT=$(jq -r '.devDependencies // {} | keys | length' package.json 2>/dev/null)
        
        echo "Dependencies (${DEP_COUNT}):"
        echo "$DEPS"
        echo ""
        echo "DevDependencies (${DEV_COUNT}):"
        echo "$DEV_DEPS"
    else
        grep -A 50 '"dependencies"' package.json 2>/dev/null | head -30 || echo "(install jq for better output)"
    fi
    echo ""
fi

# Python - requirements.txt
if [[ -f "requirements.txt" ]]; then
    FOUND_ANY=true
    echo "## Python (requirements.txt)"
    echo ""
    grep -v '^#' requirements.txt | grep -v '^$' | head -25
    echo ""
fi

# Python - pyproject.toml
if [[ -f "pyproject.toml" ]]; then
    FOUND_ANY=true
    echo "## Python (pyproject.toml)"
    echo ""
    head -60 pyproject.toml
    echo ""
fi

# Go - go.mod
if [[ -f "go.mod" ]]; then
    FOUND_ANY=true
    echo "## Go (go.mod)"
    echo ""
    head -50 go.mod
    echo ""
fi

# Rust - Cargo.toml
if [[ -f "Cargo.toml" ]]; then
    FOUND_ANY=true
    echo "## Rust (Cargo.toml)"
    echo ""
    head -60 Cargo.toml
    echo ""
fi

# Ruby - Gemfile
if [[ -f "Gemfile" ]]; then
    FOUND_ANY=true
    echo "## Ruby (Gemfile)"
    echo ""
    head -40 Gemfile
    echo ""
fi

# Java/Kotlin - build.gradle or pom.xml
if [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
    FOUND_ANY=true
    echo "## Java/Kotlin (build.gradle)"
    echo ""
    head -50 build.gradle* 2>/dev/null
    echo ""
fi

if [[ -f "pom.xml" ]]; then
    FOUND_ANY=true
    echo "## Java (pom.xml)"
    echo ""
    head -80 pom.xml
    echo ""
fi

if [[ "$FOUND_ANY" == false ]]; then
    echo "No dependency files found"
    echo ""
    echo "Looked for: package.json, requirements.txt, pyproject.toml, go.mod, Cargo.toml, Gemfile, build.gradle, pom.xml"
fi
