# pitcrew

A small set of Claude Code, Codex and OpenCode skills for how we build, fix and ship across our project repos (backend / web / mobile).

## Skills

In Claude Code call them as `/pitcrew:<name>`; in Codex as `$<name>` (e.g. `$drive fix ABC-123`); in OpenCode as `/pitcrew-<name>` (e.g. `/pitcrew-drive ABC-123`).

| Skill | What it does |
|---|---|
| `/pitcrew:drive <instructions or Linear ticket>` | Decides if it's a bug, feature, change or question, then drives it end to end. Builds to Figma designs when they're linked. Bugs are reproduced locally and re-verified until fixed. Keeps the Linear ticket updated along the way. Finishes with a review and PRs in every repo touched. |
| `/pitcrew:review` | Runs the change locally (backend + Supabase, web, iOS simulator), checks it works and matches any linked Figma designs, measures how fast the changed paths are, and reviews the code for bugs, dead code and bad code. Also the last step of `drive`. |
| `/pitcrew:ship` | Commit, push and open PRs in every repo with related changes, cross-linked to each other, the Linear ticket and any Figma frames. |
| `/pitcrew:branches` | Audit branches and worktrees not merged into the base branch, recommend merge / keep / delete, and clean up after you confirm. |

PRs target `development`, or `staging` if a repo has no `development` branch.

## Usage

```
/pitcrew:drive ABC-123
/pitcrew:drive the lounge feed is sorted oldest first, it should be newest first
/pitcrew:drive ABC-123 build the new trip card https://www.figma.com/design/<file>?node-id=12-34
/pitcrew:review
/pitcrew:review 83 focus on the feed query performance
/pitcrew:ship ABC-123
/pitcrew:branches all repos
```

How `drive` runs a task:

1. **Context:** reads the Linear ticket, any Figma frames (from the prompt or the ticket) and the repo's `AGENTS.md`; checks whether the work is already done.
2. **Classify:** bug, feature, change or question.
3. **Clarify:** assumes nothing; asks all its open questions at once, with recommended answers, and waits before starting.
4. **Branch** from `development` (or `staging`).
5. **Do the work:**
   - bug: reproduce locally, find the root cause, fix, re-run the repro until it passes
   - feature: plan (waits for your OK on database changes), backend first, then clients, built to the Figma designs
   - change: refactor / script / data work, dry run first
   - question: answer with `file:line` references, no PR
6. **Review** with `review`: runs it, compares with Figma, measures performance, checks code quality; fixes what it finds.
7. **Ship** with `ship`: PRs in every repo touched.
8. **Linear** is updated along the way: In Progress → repro / root cause comments → PR links → In Review.

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

### 1. Install pitcrew

**Claude Code**

```bash
claude plugin marketplace add timrekelj/pitcrew
claude plugin install pitcrew@pitcrew
```

Or inside Claude Code: `/plugin marketplace add timrekelj/pitcrew`, then `/plugin install pitcrew@pitcrew`. Restart Claude Code.

**Codex**

```bash
codex plugin marketplace add timrekelj/pitcrew
codex plugin add pitcrew@pitcrew
```

Restart Codex.

**OpenCode**

OpenCode has no skill marketplace, so clone the repo and copy the OpenCode-optimized skills into `~/.config/opencode`:

```bash
git clone https://github.com/timrekelj/pitcrew ~/.local/share/pitcrew
~/.local/share/pitcrew/opencode/install.sh
```

The script **copies** (not symlinks) OpenCode-optimized versions from `opencode/` into `~/.config/opencode/`:
- `opencode/skills/pitcrew-<name>/SKILL.md` → `~/.config/opencode/skills/` — enhanced with `metadata.opencode/autoinvoke` and OpenCode-specific subagent instructions
- `opencode/commands/pitcrew-<name>.md` → `~/.config/opencode/commands/` — with `agent`, `subagent` frontmatter
- `opencode/agents/pitcrew-*.md` → `~/.config/opencode/agents/` — custom subagents for explore and review

The skills are prefixed with `pitcrew-` to avoid conflicts with OpenCode built-ins (e.g. `review`, `ship` are reserved names).

**Global config:** Add these to `~/.config/opencode/opencode.json` for the full experience:
- Permission presets for `git`, `npm`, `go`, `gh`, `supabase`, `psql`, `curl` (ask for `git push`, `gh pr create`)
- `"formatter": true`
- `"experimental": { "todo": true, "background_compaction": true }`

**Project template:** Copy `opencode/templates/project-opencode.json` to your project root as `opencode.json` for project-specific permissions and instructions.

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

In a project repo, run `/pitcrew:branches` (Claude Code), `$branches` (Codex) or `/pitcrew-branches` (OpenCode). It only reads until you confirm, so it's a safe first check that the skills are installed and `gh` works.

## Updating

Each tool runs an installed copy, not this repo (OpenCode runs your copied files).

**Releasing a change**

1. Bump `version` in **both** `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json` (keep them equal).
2. Commit and push.

**Pulling it in**

- Claude Code: `claude plugin marketplace update pitcrew && claude plugin update pitcrew@pitcrew`, then restart. Or turn on auto-update: `/plugin` → Marketplaces → `pitcrew` → Enable auto-update.
- Codex: `codex plugin marketplace upgrade pitcrew && codex plugin add pitcrew@pitcrew`, then restart.
- OpenCode: `git -C ~/.local/share/pitcrew pull`, then re-run `~/.local/share/pitcrew/opencode/install.sh` to copy the updated files.

**Migrating from `tstack`**

The repo was renamed from `tstack` and `calda-mode` is now `drive`. Remove the old install, then do [step 1](#1-install-pitcrew) again:

- Claude Code: `claude plugin uninstall tstack@tstack && claude plugin marketplace remove tstack`
- Codex: `codex plugin remove tstack@tstack && codex plugin marketplace remove tstack`
- OpenCode: `rm ~/.config/opencode/commands/tstack-*.md ~/.config/opencode/skills/calda-mode`, and point your clone at the new remote: `git -C <clone> remote set-url origin https://github.com/timrekelj/pitcrew`

## Layout

| Path | Used by |
|---|---|
| `skills/<name>/SKILL.md` | Claude Code, Codex (shared, portable frontmatter) |
| `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` | Claude Code |
| `.codex-plugin/plugin.json`, `.agents/plugins/marketplace.json` | Codex |
| `opencode/skills/pitcrew-<name>/SKILL.md` | OpenCode (optimized, `pitcrew-` prefix) |
| `opencode/commands/pitcrew-<name>.md` | OpenCode (with agent/subagent frontmatter) |
| `opencode/agents/pitcrew-<name>.md` | OpenCode (custom subagents) |
| `opencode/templates/project-opencode.json` | OpenCode (project config template) |
| `opencode/install.sh` | OpenCode (copies files to `~/.config/opencode/`) |

**For Claude Code / Codex:** Add a skill in `skills/<name>/SKILL.md`. It's shared across both.

**For OpenCode:** Add an OpenCode-optimized skill in `opencode/skills/pitcrew-<name>/SKILL.md` with a matching command in `opencode/commands/pitcrew-<name>.md`. Run `opencode/install.sh` to copy it.

`argument-hint` in the skill frontmatter is Claude Code-only. `disable-model-invocation` (on `drive` and `branches`) is honoured by Claude Code and Codex; OpenCode uses `metadata.opencode/autoinvoke: false` instead. Codex ignores `disable-model-invocation` and may start those skills on its own when a request matches.
