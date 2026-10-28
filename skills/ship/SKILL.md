---
name: ship
description: Commit, push and open a pull request to development in the current repo and in every sibling repo with related changes, cross-linking the PRs and the Linear ticket. Use when asked to commit, push, open a PR or ship work.
argument-hint: "[Linear ticket id] [notes]"
---

# ship

Open PRs to `development` for the current work, in every repo it touches.

## 1. Find the repos

- The current repo, plus any sibling repo listed in `AGENTS.md` that has uncommitted changes or a branch ahead of `origin/development` for this work.
- List them and what's changed in each. If a sibling's changes look unrelated, ask before including it.

## 2. Per repo

1. If on `development` (or another protected branch: `staging`, `master`, `main`, `production`), create a branch first: `fix/…`, `feat/…` or `chore/…`, plus the Linear id if known.
2. Check what's staged. Don't commit secrets, `.env` files, build output or stray scratch files — ask if unsure.
3. Commit in small logical commits with conventional messages (`fix(feed): …`, `feat(trips): …`).
4. Push with `-u`.
5. Open the PR with `gh pr create --base development`. If the repo has no `development` branch, ask which base to use. If a PR already exists for the branch, update it instead of opening another.

PR body:

```
## What
<one or two sentences>

## Why
<the problem or ticket; root cause for bugs>

## How it was verified
<tests, repro steps, what was run; say plainly if something wasn't verified>

## Related
- Linear: <ticket link>
- <links to the sibling PRs>

## Notes for review / deploy
<migrations, backfills, env vars, order to merge — omit if none>
```

## 3. Cross-link

After all PRs exist, edit each one so its **Related** section links every other PR. If the PRs must merge in an order (e.g. backend before mobile), say so in each.

If there's a Linear ticket, add a comment on it with the PR links (when Linear tools are available).

## 4. Report

One line per repo: PR link and branch. Mention anything the user still has to do.
