# tstack

Tim stack: a small set of Claude Code skills for how we build, fix and ship across our project repos (backend / web / mobile).

## Skills

| Skill | What it does |
|---|---|
| `/tstack:calda-mode <instructions or Linear ticket>` | Decides if it's a bug, feature, change or question, then drives it end to end. Bugs are reproduced locally and re-verified until fixed. Keeps the Linear ticket updated along the way. Finishes with a review and PRs in every repo touched. |
| `/tstack:review` | Runs the change locally (backend + Supabase, web, iOS simulator), checks it works, measures how fast the changed paths are, and reviews the code for bugs, dead code and bad code. Also the last step of `calda-mode`. |
| `/tstack:ship` | Commit, push and open cross-linked PRs in every repo with related changes. |
| `/tstack:branches` | Audit branches and worktrees not merged into the base branch, recommend merge / keep / delete, and clean up after you confirm. |

PRs target `development`, or `staging` if a repo has no `development` branch.

The skills read each repo's `AGENTS.md` for commands, tests and sibling repos, so keep that file up to date.

## Install

```bash
claude plugin marketplace add timrekelj/tstack
claude plugin install tstack@tstack
```

Or inside Claude Code: `/plugin marketplace add timrekelj/tstack`, then `/plugin install tstack@tstack`.

## Updating

Claude Code runs an installed copy, not this repo. To pick up changes:

1. Bump `version` in `.claude-plugin/plugin.json`, commit and push.
2. Run `claude plugin marketplace update tstack && claude plugin update tstack@tstack`.
3. Restart Claude Code.

To skip step 2, turn on auto-update: `/plugin` → Marketplaces → `tstack` → Enable auto-update.
