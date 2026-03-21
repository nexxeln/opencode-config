# opencode setup

personal OpenCode config tuned for fast, practical software work.

the setup is biased toward:

- high-agency execution with minimal ceremony
- typescript backend and next.js workflows
- atomic git hygiene and safe PR creation
- simplifying recent code without changing behavior
- using the best available agent, skill, or tool instead of brute force

## layout

```text
.
├── AGENTS.md          # user-specific operating style and engineering defaults
├── command/           # custom slash commands
├── skill/             # installed skills
├── agent/             # available subagent prompts
└── opencode.jsonc     # local permissions and runtime config
```

## custom commands

| command | description |
|---------|-------------|
| `/commit` | inspect the full diff and split it into the smallest meaningful commits |
| `/pr` | finish local commits, push safely, and create a pull request |
| `/simplify` | refine recently modified code for clarity and maintainability without changing behavior |

## installed skills

| skill | purpose |
|-------|---------|
| `git` | atomic commit and pull request workflows, with `git-hunk` and `gh` guidance |
| `review` | evidence-first review and debugging standards |
| `frontend-design` | polished frontend and UI design work |
| `repo-explorer` | remote repository exploration and analysis |
| `skill-creator` | creating and iterating on OpenCode skills |

## operating style

`AGENTS.md` tunes the agent for Shoubhit Dash / `nexxel`:

- prefer direct, useful execution over ceremony
- stay concise, technically grounded, and high agency
- use subagents proactively when they improve quality
- favor practical architecture, fast iteration, and low-latency decisions
- preserve uncertainty instead of bluffing

## git guardrails

`opencode.jsonc` is permissive by default, with a few deliberate safety rails:

- allow normal tool usage and bash access
- deny `git add -A*`
- deny raw `git add .*`
- deny `git push --force*`, `git push -f*`, and `--force-with-lease`
- deny `rm *`

this keeps destructive git habits and broad staging out of the default workflow.

## notes

- `/commit` and `/pr` are intended to work with the git workflow conventions in `skill/git/SKILL.md`
- `/simplify` is command-only and does not rely on a separate skill
- the setup assumes `gh` and `git-hunk` are available when using the git workflows
