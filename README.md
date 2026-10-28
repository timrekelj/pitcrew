# tstack

Tim stack: a small set of Claude Code, Codex and OpenCode skills for how we build, fix and ship across our project repos (backend / web / mobile).

## Skills

In Claude Code call them as `/tstack:<name>`; in Codex as `$<name>` (e.g. `$calda-mode fix ABC-123`); in OpenCode as `/tstack-<name>` (e.g. `/tstack-calda-mode ABC-123`).

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

| Need | For |
|---|---|
| `gh` (logged in) | PRs, branch audit |
| Linear MCP | Reading and updating tickets |
| Sentry MCP | Production errors, traces and profiles |
| Figma MCP | Building to and comparing against Figma designs when a ticket or prompt has Figma links |
| Chrome DevTools MCP | Driving the web app, console errors, performance traces |
| Docker runtime (running) | Local Supabase for backend runs and reviews |
| Supabase CLI | Local database |
| `psql` | `EXPLAIN ANALYZE` on queries |
| Xcode + iOS simulator | Running the mobile app, `xctrace` profiles |
| Maestro (optional) | Driving the mobile app via `.maestro/` flows |
| Go profiling in the API | CPU / memory / goroutine profiles |
| Dead-code tools (optional) | Code-quality checks in `review` |

[Setup](#setup) covers installing all of it.

## Setup

Do steps 1 and 2 for each tool you use (Claude Code, Codex, OpenCode). Steps 3 and 4 are shared.

### 1. Install tstack

**Claude Code**

```bash
claude plugin marketplace add timrekelj/tstack
claude plugin install tstack@tstack
```

Or inside Claude Code: `/plugin marketplace add timrekelj/tstack`, then `/plugin install tstack@tstack`. Restart Claude Code.

**Codex**

```bash
codex plugin marketplace add timrekelj/tstack
codex plugin add tstack@tstack
```

Restart Codex.

**OpenCode**

OpenCode has no skill marketplace, so clone the repo and link it into `~/.config/opencode`:

```bash
git clone https://github.com/timrekelj/tstack ~/.local/share/tstack
~/.local/share/tstack/opencode/install.sh
opencode service restart
```

The script symlinks each `skills/<name>` into `~/.config/opencode/skills/` and the `/tstack-*` commands from `opencode/commands/` into `~/.config/opencode/commands/`. It won't overwrite a file or folder that isn't a symlink; it prints `skip` instead (e.g. if you already have a skill called `review`). Use any clone path you like; the links point at it.

### 2. Connect the MCP servers

Each tool keeps its own MCP config. The remote servers ask you to log in the first time.

**Claude Code:** connect **Linear**, **Sentry** and **Figma** in claude.ai → Settings → Connectors (they're shared with Claude Code when you're logged in with that account), then add Chrome DevTools:

```bash
claude mcp add -s user chrome-devtools -- npx -y chrome-devtools-mcp@latest
```

**Codex**

```bash
codex mcp add linear --url https://mcp.linear.app/mcp
codex mcp add sentry --url https://mcp.sentry.dev/mcp
codex mcp add figma --url https://mcp.figma.com/mcp
codex mcp add chrome-devtools -- npx -y chrome-devtools-mcp@latest
```

**OpenCode**

```bash
opencode mcp add --global linear --url https://mcp.linear.app/mcp
opencode mcp add --global sentry --url https://mcp.sentry.dev/mcp
opencode mcp add --global figma --url https://mcp.figma.com/mcp
opencode mcp add --global chrome-devtools -- npx -y chrome-devtools-mcp@latest
opencode mcp auth linear && opencode mcp auth sentry && opencode mcp auth figma
opencode mcp list   # all four should show as connected
```

### 3. Install the CLI tools

```bash
brew install gh supabase/tap/supabase libpq
brew link --force libpq          # psql
gh auth login
brew install maestro             # optional, for .maestro/ mobile flows
go install honnef.co/go/tools/cmd/staticcheck@latest golang.org/x/tools/cmd/deadcode@latest   # optional
```

`npx knip` (JS dead code) needs no install. Also needed:

- A Docker runtime, running: OrbStack or Docker Desktop (for local Supabase).
- Xcode from the App Store, with an iOS simulator (for the mobile app and `xctrace`).
- Go profiling: the backend serves pprof when `PPROF_ADDR=127.0.0.1:6060` and `APP_ENV=local` (see its `AGENTS.md`).

### 4. Check each repo's `AGENTS.md`

Each project repo's `AGENTS.md` should say how to run, test and seed it, and list its sibling repos (backend / web / mobile). The skills read it first.

### 5. Try it

In a project repo, run `/tstack:branches` (Claude Code), `$branches` (Codex) or `/tstack-branches` (OpenCode). It only reads until you confirm, so it's a safe first check that the skills are installed and `gh` works.

## Updating

Each tool runs an installed copy, not this repo (OpenCode runs your clone).

**Releasing a change**

1. Bump `version` in **both** `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json` (keep them equal).
2. Commit and push.

**Pulling it in**

- Claude Code: `claude plugin marketplace update tstack && claude plugin update tstack@tstack`, then restart. Or turn on auto-update: `/plugin` → Marketplaces → `tstack` → Enable auto-update.
- Codex: `codex plugin marketplace upgrade tstack && codex plugin add tstack@tstack`, then restart.
- OpenCode: `git -C ~/.local/share/tstack pull`, then `opencode service restart`. Re-run `opencode/install.sh` if a skill or command was added or renamed.

## Layout

| Path | Used by |
|---|---|
| `skills/<name>/SKILL.md` | All three |
| `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` | Claude Code |
| `.codex-plugin/plugin.json`, `.agents/plugins/marketplace.json` | Codex |
| `opencode/install.sh`, `opencode/commands/tstack-<name>.md` | OpenCode |

When you add a skill, add a matching `opencode/commands/tstack-<name>.md` that loads it.

`argument-hint` in the skill frontmatter is Claude Code-only. `disable-model-invocation` (on `calda-mode` and `branches`) is honoured by Claude Code and OpenCode, so the agent only runs those two when you ask for them. Codex ignores it and may start them on its own when a request matches.
