---
name: git
description: "git workflows for agents. use when handling commits, atomic split commits, selective staging, hunk-level staging with `git-hunk`, branch pushes, or pull request creation with `gh`. triggers on: commit, pr, push, stage, hunk, git-hunk, selective staging, pull request, atomic commit."
---

# git

use this skill when the job is to turn a messy diff into clean commits or a clean pull request. prefer atomic commits, short lowercase conventional messages, and explicit staging over convenience.

## defaults

- use conventional prefixes: `feat` `fix` `refactor` `perf` `test` `docs` `chore` `build` `ci` `style` `revert`
- keep commit subjects short, lowercase, and direct; no trailing period
- add a scope only when it adds signal: `fix(auth): refresh session`
- stage only what you mean to commit; never use `git add -A`
- never force push
- prefer `gh` for github operations
- leave unrelated user changes alone

## commit message convention

- default format: `type(scope): subject` or `type: subject`
- prefer the smallest honest type; do not inflate `feat` when the change is really `fix`, `refactor`, or `chore`
- make the subject describe the shipped change, not the process
- good: `fix(cache): avoid stale reads`
- good: `refactor(router): split auth helpers`
- good: `docs: add local setup note`

## commit workflow

if the user provides extra instructions, treat them as constraints on scope, file selection, commit count, message hints, or exclusions.

1. inspect the entire change first
   - run `git status`, `git diff`, `git diff --staged`, and `git log --oneline -10`
   - reason about the full diff before staging anything
   - identify the smallest meaningful commit boundaries by intent, not by file count

2. decide how to split
   - separate independent bug fixes, refactors, tests, docs, formatting, and generated changes when they can stand alone
   - keep tightly coupled code and tests together when one without the other would be misleading or broken
   - if the diff is already one unit, make one commit

3. stage the next atomic unit
   - if whole files belong together, stage files explicitly with `git add <file ...>`
   - if a file mixes multiple concerns, use `git-hunk`
   - before using `git-hunk`, read `references/git-hunk.md`

4. use `git-hunk` safely when needed
    - prefer `git-hunk scan --mode stage --compact --json`
    - prefer `change_key` over `change_id`
    - prefer selector bundles from `scan` or `resolve` json instead of rebuilding selectors by hand
    - use `git-hunk resolve` when you only have a file and line hint
    - keep the returned `snapshot_id` and rescan after every successful `stage`, `unstage`, or `commit`
    - if a snapshot goes stale, use `git-hunk validate` to recover `change_key` selections before retrying
    - use `git-hunk stage --dry-run ... --json`, `unstage --dry-run ... --json`, or `commit --dry-run ... --json` before a risky partial mutation
    - treat raw line ranges as a last resort unless the user asked for an exact range
    - if a path is reported as unsupported, fall back to normal git for that path

5. commit and continue
   - write a short lowercase conventional message
   - create exactly one atomic commit for the selected unit
   - re-check `git status` and the remaining diff
   - repeat until the requested work is committed

6. failure handling
   - if there is nothing to commit, do not create an empty commit
   - if a hook changes files or rejects the commit, inspect the new diff, fix the issue, and create a new commit instead of amending by default
   - ask only if ownership or grouping is genuinely ambiguous and the wrong split would be misleading

## pull request workflow

if the user provides extra instructions, treat them as constraints on commit scope, base branch, title, body, draft state, labels, reviewers, or other `gh` options.

1. run the commit workflow first for all intended uncommitted changes
2. inspect branch state with `git status`, `git branch --show-current`, tracking status, `git log`, and `git diff <base>...HEAD`
3. choose the base branch from arguments when provided; otherwise prefer the repo default or current tracking setup
4. push the branch with `git push -u origin <branch>` when needed; never force push
5. create the pull request with `gh pr create`
6. keep the PR title concise and aligned with the overall change set
7. keep the PR body short and useful; default shape:

```md
## summary
- ...
- ...

## testing
- ...
```

8. return the PR URL

## argument handling

- accept natural language arguments and explicit flags or key-value hints
- honor user-provided titles, scopes, prefixes, commit-count limits, base branches, draft requests, labels, and reviewer hints when they are safe
- if arguments conflict with atomicity, preserve correctness first and explain the tradeoff briefly

## references

- read `references/git-hunk.md` before any hunk-level staging or committing
- the reference is adapted from the upstream `git-hunk` skill so the workflow stays self-contained
