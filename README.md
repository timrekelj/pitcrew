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

## Requirements

The skills work with whatever is installed and say what they had to skip. For the full workflow:

| Need | For | Setup |
|---|---|---|
| `gh` (logged in) | PRs, branch audit | `brew install gh && gh auth login` |
| Linear connector | Reading and updating tickets | Connect Linear in claude.ai connector settings |
| Docker runtime (running) | Local Supabase for backend runs and reviews | OrbStack or Docker Desktop |
| Supabase CLI | Local database | `brew install supabase/tap/supabase` |
| `psql` | `EXPLAIN ANALYZE` on queries | `brew install libpq && brew link --force libpq` |
| Sentry connector | Production errors, traces and profiles | Connect Sentry in claude.ai connector settings |
| Chrome DevTools MCP | Driving the web app, console errors, performance traces | `claude mcp add -s user chrome-devtools -- npx -y chrome-devtools-mcp@latest` |
| Xcode + iOS simulator | Running the mobile app, `xctrace` profiles | Xcode from the App Store |
| Maestro | Driving the mobile app via `.maestro/` flows | `brew install maestro` (optional) |
| Go profiling in the API | CPU / memory / goroutine profiles | The backend serves pprof when `PPROF_ADDR=127.0.0.1:6060` and `APP_ENV=local` (see its `AGENTS.md`) |
| Dead-code tools | Code-quality checks in `review` | `go install honnef.co/go/tools/cmd/staticcheck@latest golang.org/x/tools/cmd/deadcode@latest`; `npx knip` needs no install (optional) |

Each repo's `AGENTS.md` should say how to run, test and seed it, and list its sibling repos.

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
