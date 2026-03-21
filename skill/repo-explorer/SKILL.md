---
name: repo-explorer
description: |
  Clone and explore GitHub repositories locally for analysis. Use when the user wants to:
  (1) Analyze a GitHub repo's architecture or code structure
  (2) Search for patterns, functions, or code in a remote repo
  (3) Understand dependencies and entry points of a project
  (4) Find code hotspots, TODOs, or frequently changed files
  (5) Map the public API/exports of a library
  
  Triggers: "explore repo", "analyze this github repo", "search in repo", "clone and analyze",
  "what's in this repo", "show me the structure of", "find in github repo"
---

# Repo Explorer

Clone GitHub repositories locally and explore them with powerful search and analysis tools.

## Quick Start

```bash
# 1. Clone/cache the repo
./scripts/repo-clone.sh owner/repo

# 2. Explore structure
./scripts/repo-structure.sh owner/repo

# 3. Search code
./scripts/repo-search.sh owner/repo "pattern"
```

All repos are cached at `~/.pi-repos/` for fast subsequent access.

## Available Commands

| Command | Purpose |
|---------|---------|
| `repo-clone.sh` | Clone or update a GitHub repo |
| `repo-structure.sh` | Show directory tree |
| `repo-search.sh` | Search with ripgrep |
| `repo-file.sh` | Read file contents |
| `repo-find.sh` | Find files by pattern |
| `repo-deps.sh` | Analyze dependencies |
| `repo-hotspots.sh` | Find code hotspots |
| `repo-exports.sh` | Map public API exports |
| `repo-ast.sh` | AST structural search |
| `repo-cleanup.sh` | Remove cached repos |

## Command Reference

### repo-clone.sh
Clone or update a repository.

```bash
repo-clone.sh <owner/repo or URL> [--refresh]

# Examples
repo-clone.sh vercel/next.js
repo-clone.sh https://github.com/facebook/react
repo-clone.sh git@github.com:owner/repo.git
repo-clone.sh owner/repo --refresh  # Force update
```

### repo-structure.sh
Show directory structure.

```bash
repo-structure.sh <owner/repo> [--path <subpath>] [--depth <n>]

# Examples
repo-structure.sh vercel/next.js
repo-structure.sh vercel/next.js --path packages/next/src --depth 3
```

### repo-search.sh
Search code with ripgrep.

```bash
repo-search.sh <owner/repo> <pattern> [--glob <glob>] [--context <n>]

# Examples
repo-search.sh vercel/next.js "useRouter" --glob "*.ts"
repo-search.sh facebook/react "useState" --context 5
repo-search.sh owner/repo "TODO|FIXME"
```

### repo-file.sh
Read file contents with line numbers.

```bash
repo-file.sh <owner/repo> <path> [--start <line>] [--end <line>]

# Examples
repo-file.sh vercel/next.js package.json
repo-file.sh owner/repo src/index.ts --start 1 --end 50
```

### repo-find.sh
Find files by pattern.

```bash
repo-find.sh <owner/repo> <pattern> [--type <f|d>] [--ext <ext>]

# Examples
repo-find.sh vercel/next.js "config" --type f
repo-find.sh owner/repo "test" --ext ts
```

### repo-deps.sh
Analyze project dependencies.

```bash
repo-deps.sh <owner/repo>

# Supports: package.json, requirements.txt, pyproject.toml,
#           go.mod, Cargo.toml, Gemfile, build.gradle, pom.xml
```

### repo-hotspots.sh
Find code hotspots (churn, large files, TODOs).

```bash
repo-hotspots.sh <owner/repo>

# Shows:
# - Most frequently changed files (git churn)
# - Largest files by line count
# - Files with most TODOs/FIXMEs
# - Recent commits
```

### repo-exports.sh
Map public API and exports.

```bash
repo-exports.sh <owner/repo> [--entry <path>]

# Examples
repo-exports.sh vercel/next.js
repo-exports.sh owner/repo --entry src/lib/index.ts
```

### repo-ast.sh
AST-grep structural code search. See [ast-patterns.md](references/ast-patterns.md) for pattern examples.

```bash
repo-ast.sh <owner/repo> <pattern> [--lang <language>]

# Examples
repo-ast.sh owner/repo 'function $NAME($$ARGS) { $$BODY }'
repo-ast.sh owner/repo 'console.log($$_)' --lang ts
repo-ast.sh owner/repo 'useState($INIT)' --lang tsx
```

### repo-cleanup.sh
Remove cached repositories.

```bash
repo-cleanup.sh <owner/repo>  # Remove specific repo
repo-cleanup.sh --all         # Clear entire cache
repo-cleanup.sh               # List cached repos
```

## Common Workflows

### Understand a new codebase
```bash
repo-clone.sh owner/repo
repo-structure.sh owner/repo --depth 3
repo-deps.sh owner/repo
repo-exports.sh owner/repo
```

### Find specific functionality
```bash
repo-clone.sh owner/repo
repo-search.sh owner/repo "authentication" --glob "*.ts"
repo-ast.sh owner/repo 'async function $NAME($$_) { $$_ }' --lang ts
```

### Assess code quality
```bash
repo-clone.sh owner/repo
repo-hotspots.sh owner/repo
repo-search.sh owner/repo "TODO|FIXME|HACK|XXX"
```

### Analyze library API
```bash
repo-clone.sh owner/repo
repo-exports.sh owner/repo
repo-file.sh owner/repo src/index.ts
```

## Requirements

**Required:**
- `git` - For cloning repositories
- `rg` (ripgrep) - For fast code search

**Optional (enhanced features):**
- `fd` - Better file finding (falls back to `find`)
- `tree` - Better directory structure (falls back to `find`)
- `ast-grep` / `sg` - Structural code search
- `jq` - Better JSON parsing for dependencies

Install on macOS:
```bash
brew install ripgrep fd tree ast-grep jq
```

Install on Linux:
```bash
# Debian/Ubuntu
apt install ripgrep fd-find tree jq
cargo install ast-grep  # or npm i -g @ast-grep/cli
```
