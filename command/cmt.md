---
description: split the current diff into atomic commits with git
---

first load the `git` skill.

you are running `/cmt`.

`$ARGUMENTS` are extra instructions from the user. treat them as constraints on scope, files, commit count, or message hints.

follow the commit workflow from `git` exactly:

- inspect the entire diff first
- split it into the smallest meaningful commits
- use `git-hunk` when file-level staging is not enough
- use short lowercase conventional commit messages
- complete the commits end to end
