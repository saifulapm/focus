# Focus

[![test](https://github.com/saifulapm/focus/actions/workflows/test.yml/badge.svg)](https://github.com/saifulapm/focus/actions/workflows/test.yml)

A lean harness for Claude Code. Stop losing context. Stop grading your own homework. Just focus.

![Focus demo](docs/demo.gif)

## Install

**Option A — plugin (recommended).** Inside Claude Code:

```
/plugin marketplace add saifulapm/focus
/plugin install focus@focus
```

**Option B — script.** Copies the skill to `~/.claude/skills/focus/` and commands to `~/.claude/commands/focus/`:

```bash
git clone https://github.com/saifulapm/focus.git
cd focus
bash skills/focus/scripts/install.sh
```

Both wire up the same skill, commands, and hooks. No npm, no runtime dependencies — pure markdown + shell.

## What it does

Focus fixes the failure modes that every long-running coding agent hits:

| Failure | Focus's answer |
|---|---|
| Agent loses the plan after a few tool calls | Hooks re-inject the plan's goal + current task at throttled intervals, with a 40-call handoff budget warning |
| Agent grades its own work and declares "done" on half-built code | **Evaluator gate** — a fresh sub-agent reads the plan + diff cold, runs the `Verify:` commands itself, and returns PASS / CHANGES / FAIL |
| A bad plan gets executed faithfully and still misses the goal | **Independent plan check** (LARGE) — a fresh sub-agent grades the plan before execution starts |
| Agent runs out of context and summarizes into a lossy blob | **Handoff protocol** — structured, committed, read-once `## Handoff` block; a fresh session resumes from its "Exact next action" |
| Agent forgets decisions between sessions | **Memory split** — `memory.md` (mutable state) + `journal/` (append-only narrative) persist across sessions |
| Agent silently scope-creeps on mid-task discoveries | **Deviation rules** — fix in-scope bugs inline, never auto-install packages, defer out-of-scope finds to Open Items |

And it scales ceremony to task size, so trivial work doesn't get enterprise treatment:

| Level | Example | Process |
|---|---|---|
| **TRIVIAL** | Fix typo, rename variable | Just do it. One log line. |
| **SMALL** | Add a function | 3-line plan. Do it. Verify. |
| **MEDIUM** | New API endpoint | Atomic plan with Verify/Done-when per task. Evaluator gate before done. |
| **LARGE** | Auth redesign | Research via read-only sub-agents → design options → plan → independent plan check → human approval → execute → per-task evaluator → retro. |

Tasks escalate mid-work if they grow — and de-escalate if they shrink.

## Context economy

Focus is engineered to leave your context window for *your* code, and its budgets are CI-enforced, not aspirational:

| Hook surface | Cost |
|---|---|
| First prompt of a session | One full state block (≤3.5 KB: principles, unchecked open items, recent journal, plan position) |
| **Every later prompt** | **≤200 bytes** (timestamp + plan pointer) |
| Plan re-injection | Goal + current task, every 5th Write/Edit/Bash call only |
| Stop check | Capped listings with overflow counts |

`/clear` issues a new session id, which brings the full block back — exactly when a fresh agent needs it. The caps live in `tests/test-context-budget.sh`; if a change makes any hook exceed its budget, CI fails.

## How a MEDIUM or LARGE task runs

1. **Classify** — Focus picks the level from scope signals.
2. **Research** (LARGE) — read-only sub-agents explore and return conclusions; raw file dumps never enter the main context.
3. **Plan** — `.focus/plan.md` with atomic tasks. Every task has: **Files, Action, Verify (runnable command), Done when (observable criterion), Commit**. Missing fields block execution; `[NEEDS CLARIFICATION]` markers block until answered.
4. **Self-review + independent plan check** — the 9-item checklist, then (LARGE) a fresh sub-agent adversarially grades the plan. Don't grade your own homework — plans included.
5. **Execute** — per task: Action → run `Verify:` → confirm `Done when:` → commit. One commit per atomic task enables git-bisect recovery.
6. **Evaluate** — a fresh sub-agent reads the plan and diff cold, verifies each requirement three levels deep (exists / substantive / wired), runs the verification commands itself, and returns a verdict. On CHANGES REQUESTED, the re-run uses **re-verification mode**: full re-check of failed REQs, regression check on passed ones.
7. **Merge or PR** — only after evaluator PASS.
8. **Archive** — the plan record (REQs, verdict, task → commit map) is appended to the journal before plan.md is deleted. Evidence survives; working files don't linger.

## Files Focus creates in your project

```
.focus/
  memory.md            # committed — principles, decisions, project context, open items
  journal/             # committed — one append-only file per day
    2026-04-20.md
  plan.md              # gitignored — active task's plan (archived to journal, then deleted)
  log.md               # gitignored — active task's tool-call trail
  .toolcount           # gitignored — hook counter for throttled injection + handoff budget
  .stopblocks          # gitignored — gated-mode block counter
  .lastsession         # gitignored — session id for once-per-session context injection
  mode                 # optional, committed — contains "gated" to enable the blocking Stop hook
  principles.md        # optional, committed — for projects that want principles isolated
```

Focus writes a `.focus/.gitignore` the first time it creates the directory.

## Commands

| Command | Purpose |
|---|---|
| `/focus:status` | Active plan, memory summary, recent journal |
| `/focus:evaluate` | Run an independent evaluator against the current branch |
| `/focus:handoff` | Emit a context-reset handoff so a fresh session can resume |

## Principles

Declare project-level guardrails in `memory.md` under `## Principles` (or in the optional `.focus/principles.md`). Focus surfaces them at plan creation, in the evaluator's check, and before you stop. Use strength keywords so the evaluator can calibrate:

```markdown
## Principles
- **MUST** keep public APIs backward-compatible through a full major version.
- **MUST NOT** add runtime npm dependencies without explicit approval.
- **PREFER** composition over inheritance.
- **AVOID** mocking the database in tests — use the real harness.
```

The evaluator treats `MUST` / `MUST NOT` violations as blockers.

## Gated mode (opt-in)

By default Focus never blocks — every check is advisory. Projects that want enforcement create `.focus/mode` containing `gated`: the Stop hook then blocks stopping while the plan has unchecked tasks (capped at 5 blocks per plan checkpoint; a written handoff always exempts).

## Design notes

Focus draws on Anthropic's harness-design research plus a cross-analysis of BMAD-METHOD, agent-kernel, get-shit-done, spec-kit, and superpowers. Three patterns the field has converged on:

- **Atomic, verifiable tasks** (GSD, spec-kit) — every task has a runnable Verify and an observable Done-when.
- **Independent evaluator** (Anthropic, superpowers) — a fresh agent grades the diff, not the generator.
- **Structured context reset** (Anthropic) — handoff artifacts beat in-place compaction.

What Focus adds: **adaptive ceremony** (TRIVIAL → LARGE with escalation/de-escalation), **CI-enforced context budgets**, and **one-command install** on Claude Code. The skill keeps its always-loaded surface under 500 lines, with depth pushed to on-demand reference files — and the harness itself is tested (`bash tests/run.sh`, 47 assertions covering every hook script, run on Linux and macOS in CI).

## License

MIT
