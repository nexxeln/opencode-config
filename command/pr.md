---
description: commit pending work and create a pull request with git
---

first load the `git` skill.

you are running `/pr`.

`$ARGUMENTS` are extra instructions from the user. treat them as constraints on commit scope, base branch, title, body, draft state, labels, reviewers, or other `gh` options.

follow the pull request workflow from `git` exactly:

- run the commit workflow first for intended local changes
- push the branch if needed without force
- create the pull request with `gh pr create`
- return the pr url
