---
name: review
description: Review finished work by actually running it (backend, web, mobile simulator), checking it works and how fast, and reviewing the code for bugs, dead code and poor quality. Use after implementing or fixing something, or to review a branch or PR.
argument-hint: "[PR number | branch | repo paths] [what to focus on]"
---

# review

Review a change the way a senior engineer would: run it, try it, measure it, then read the code. Report with evidence.

## 0. Scope

1. Work out what's being reviewed: the given PR / branch, otherwise the current branch. Include sibling repos (from `AGENTS.md`) that have related changes on a branch.
2. **Base branch:** `development` if the repo has it, otherwise `staging`.
3. Per repo, collect `git diff origin/<base>...HEAD` and the intent: the Linear ticket, PR description, or what the user said. Review against the intent, not just the diff.
4. Read each repo's `AGENTS.md` for how to run, test and seed it.

## 1. Run it

Start only what the change needs, locally. Never point anything at a staging or production database or service. Stop what you started when you're done.

| Repo type | Run | Exercise the change |
|---|---|---|
| **Backend** (Go + Supabase) | Local Supabase (`supabase start`, reset/seed per `AGENTS.md`), then the API (`air`, `go run`, or docker compose). Integration tests per `AGENTS.md`. | Call the changed endpoints with `curl` or the Bruno collection: happy path, bad input, wrong user / no auth, empty data. Check responses, status codes, and the rows written. |
| **Web** (Next.js) | `npm run dev` against the local backend. Use `e2e` tests if present. | Open the changed pages in the browser. Click through the flow; check the browser console and server logs for errors; check loading, empty and error states. |
| **Mobile** (Expo) | `npm run check`, then the app on the iOS simulator (`npx expo run:ios` or the existing dev build) against the local backend. | Run the relevant `.maestro/` flows if Maestro is installed; otherwise drive it and take screenshots (`xcrun simctl io booted screenshot`). Check Metro logs for errors and warnings. |

If something can't run locally (missing env vars, Docker not running, a third-party service), say exactly what's missing and continue with what can run. Never fake a result.

## 2. Does it work?

- Does the behavior match the intent, including edge cases the ticket implies?
- For bugs: does the original repro now pass?
- Do existing tests and checks pass (tests, typecheck, lint, format)?
- Across repos: do request/response shapes, enum/option values and error handling match on both sides?

## 3. How fast is it?

Measure the paths the change touched — don't profile the whole app. Where it's cheap, measure the same thing on the base branch too, so you can call it a regression or not.

- **API:** time the changed endpoints (`curl -w '%{time_total}'`, ~20 runs, report p50/p95). Count DB queries per request where you can; flag N+1 patterns.
- **SQL:** `EXPLAIN (ANALYZE, BUFFERS)` on new or changed queries against local data; flag sequential scans on big tables and missing indexes for new filters/joins.
- **Go CPU / memory:** if the API exposes pprof locally, take a profile while hitting the endpoint (`go tool pprof -top`, `-traces`). For hot functions, `go test -bench . -cpuprofile`.
- **Web:** server timing in the logs, number and size of requests, bundle size change (`next build` output), obvious extra re-renders or waterfalls.
- **Mobile:** time to show the changed screen, list scroll smoothness, extra network calls on mount, re-renders. Use a profiler trace if one is available.
- **Code-level:** unbounded loops or queries, missing pagination, work done per item that could be done once, things fetched but not used.

Report numbers, not impressions. If you couldn't measure something, say so.

## 4. Code quality

Spawn a fresh subagent per repo. Give it the diff, the intent and the repo's `AGENTS.md` — not your own conclusions — and ask it to find:

- **Correctness:** bugs, unhandled errors, race conditions, auth/RLS gaps, missing input validation.
- **Dead code:** unused functions, exports, components, files, flags, env vars, DB columns; code made unreachable by this change; leftover debug logs or commented-out code. Confirm with `grep` before reporting.
- **Bad code:** duplication of something that already exists in the repo, needless abstraction, unclear naming, functions doing too much, code that doesn't match the surrounding style, comments that only restate the code.
- **Tests:** missing tests for the changed behavior, tests that don't actually assert it.

Also run the repo's own linters, and these when available: `go vet` / `staticcheck` / `deadcode ./...` (Go), `npx knip` (TS unused files and exports).

Check every finding against the code yourself before reporting it. Drop anything you can't confirm.

## 5. Report

```
## Review: <what> (<repos>)

**Verdict:** ready / needs fixes / blocked

### Ran
<what was started and exercised, per repo; what couldn't run and why>

### Works
<pass/fail per behavior, with evidence>

### Performance
<numbers, base vs. branch where measured; regressions flagged>

### Findings
| # | Severity | Repo | file:line | Issue | Fix |
|---|---|---|---|---|---|
```

Severity: **blocker** (wrong behavior, data loss, security), **should fix** (bugs in edge cases, real perf regressions, dead code added by this change), **nit** (style, naming).

## 6. Fixing

- Called from `calda-mode`: fix blockers and should-fixes, then re-run the affected parts of steps 1–4. Mention nits you skipped.
- Called directly: report, then ask which findings to fix.
