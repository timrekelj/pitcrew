# tstack

Tim stack: a small set of Claude Code and Codex skills for how we build, fix and ship across our project repos (backend / web / mobile).

## Skills

In Claude Code call them as `/tstack:<name>`; in Codex as `$<name>` (e.g. `$calda-mode fix ABC-123`).

| Skill | What it does |
|---|---|
| `/tstack:calda-mode <instructions or Linear ticket>` | Decides if it's a bug, feature, change or question, then drives it end to end. Builds to Figma designs when they're linked. Bugs are reproduced locally and re-verified until fixed. Keeps the Linear ticket updated along the way. Finishes with a review and PRs in every repo touched. |
| `/tstack:review` | Runs the change locally (backend + Supabase, web, iOS simulator), checks it works and matches any linked Figma designs, measures how fast the changed paths are, and reviews the code for bugs, dead code and bad code. Also the last step of `calda-mode`. |
| `/tstack:ship` | Commit, push and open PRs in every repo with related changes, cross-linked to each other, the Linear ticket and any Figma frames. |
| `/tstack:branches` | Audit branches and worktrees not merged into the base branch, recommend merge / keep / delete, and clean up after you confirm. |

PRs target `development`, or `staging` if a repo has no `development` branch.

## Usage

```
/tstack:calda-mode ABC-123
/tstack:calda-mode the lounge feed is sorted oldest first, it should be newest first
/tstack:calda-mode ABC-123 build the new trip card https://www.figma.com/design/<file>?node-id=12-34
/tstack:review
/tstack:review 83 focus on the feed query performance
/tstack:ship ABC-123
/tstack:branches all repos
```

How `calda-mode` runs a task:

1. **Context:** reads the Linear ticket, any Figma frames (from the prompt or the ticket) and the repo's `AGENTS.md`; checks whether the work is already done.
2. **Classify:** bug, feature, change or question. Asks if it's unclear.
3. **Branch** from `development` (or `staging`).
4. **Do the work:**
   - bug: reproduce locally, find the root cause, fix, re-run the repro until it passes
   - feature: plan (waits for your OK on database changes), backend first, then clients, built to the Figma designs
   - change: refactor / script / data work, dry run first
   - question: answer with `file:line` references, no PR
5. **Review** with `review`: runs it, compares with Figma, measures performance, checks code quality; fixes what it finds.
6. **Ship** with `ship`: PRs in every repo touched.
7. **Linear** is updated along the way: In Progress → repro / root cause comments → PR links → In Review.

Broad code searches, the code-quality review and multi-repo branch audits run in subagents, so the main agent's context stays focused.

## Requirements

The skills work with whatever is installed and say what they had to skip. For the full workflow:

| Need | For | Setup |
|---|---|---|
| `gh` (logged in) | PRs, branch audit | `brew install gh && gh auth login` |
| Linear MCP | Reading and updating tickets | Claude Code: connect Linear in claude.ai connector settings. Codex: `codex mcp add linear --url https://mcp.linear.app/mcp` |
| Docker runtime (running) | Local Supabase for backend runs and reviews | OrbStack or Docker Desktop |
| Supabase CLI | Local database | `brew install supabase/tap/supabase` |
| `psql` | `EXPLAIN ANALYZE` on queries | `brew install libpq && brew link --force libpq` |
| Sentry MCP | Production errors, traces and profiles | Claude Code: connect Sentry in claude.ai connector settings. Codex: `codex mcp add sentry --url https://mcp.sentry.dev/mcp` |
| Figma MCP | Building to and comparing against Figma designs when a ticket or prompt has Figma links | Claude Code: connect Figma in claude.ai connector settings. Codex: `codex mcp add figma --url https://mcp.figma.com/mcp` |
| Chrome DevTools MCP | Driving the web app, console errors, performance traces | Claude Code: `claude mcp add -s user chrome-devtools -- npx -y chrome-devtools-mcp@latest`. Codex: `codex mcp add chrome-devtools -- npx -y chrome-devtools-mcp@latest` |
| Xcode + iOS simulator | Running the mobile app, `xctrace` profiles | Xcode from the App Store |
| Maestro | Driving the mobile app via `.maestro/` flows | `brew install maestro` (optional) |
| Go profiling in the API | CPU / memory / goroutine profiles | The backend serves pprof when `PPROF_ADDR=127.0.0.1:6060` and `APP_ENV=local` (see its `AGENTS.md`) |
| Dead-code tools | Code-quality checks in `review` | `go install honnef.co/go/tools/cmd/staticcheck@latest golang.org/x/tools/cmd/deadcode@latest`; `npx knip` needs no install (optional) |

Each repo's `AGENTS.md` should say how to run, test and seed it, and list its sibling repos.

## Install

### Claude Code

```bash
claude plugin marketplace add timrekelj/tstack
claude plugin install tstack@tstack
```

Or inside Claude Code: `/plugin marketplace add timrekelj/tstack`, then `/plugin install tstack@tstack`. Restart Claude Code.

### Codex

```bash
codex plugin marketplace add timrekelj/tstack
codex plugin add tstack@tstack
```

Restart Codex. Codex has its own MCP config, so add the Linear, Sentry, Figma and Chrome DevTools servers from [Requirements](#requirements) too.

## Updating

Both tools run an installed copy, not this repo.

**Releasing a change**

1. Bump `version` in **both** `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json` (keep them equal).
2. Commit and push.

**Pulling it in**

- Claude Code: `claude plugin marketplace update tstack && claude plugin update tstack@tstack`, then restart. Or turn on auto-update: `/plugin` → Marketplaces → `tstack` → Enable auto-update.
- Codex: `codex plugin marketplace upgrade tstack && codex plugin add tstack@tstack`, then restart.

## Layout

| Path | Used by |
|---|---|
| `skills/<name>/SKILL.md` | Both |
| `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` | Claude Code |
| `.codex-plugin/plugin.json`, `.agents/plugins/marketplace.json` | Codex |

`disable-model-invocation` and `argument-hint` in the skill frontmatter are Claude Code-only; Codex ignores them, so it may start `calda-mode` or `branches` on its own when a request matches.
