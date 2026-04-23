# Focus

A lean harness for Claude Code. Stop losing context. Stop grading your own homework. Just focus.

## Install

```bash
git clone https://github.com/saifulapm/focus.git
cd focus
bash skills/focus/scripts/install.sh
```

The installer copies the skill to `~/.claude/skills/focus/`, commands to `~/.claude/commands/focus/`, and wires up the hooks. No npm, no runtime dependencies — pure markdown + shell.

## What it does

Focus fixes four failure modes that every long-running coding agent hits:

| Failure | Focus's answer |
|---|---|
| Agent loses the plan after a few tool calls | Hooks re-inject the active plan before every tool call |
| Agent grades its own work and declares "done" on half-built code | **Evaluator gate** — a fresh sub-agent reads the plan + diff cold and returns PASS / CHANGES / FAIL |
| Agent runs out of context and summarizes into a lossy blob | **Handoff protocol** — structured `## Handoff` block written to plan.md before context exhaustion; a fresh session resumes from it |
| Agent forgets decisions between sessions | **Memory split** — `memory.md` (mutable state) + `journal/` (append-only narrative) persist across sessions |

And it scales ceremony to task size, so trivial work doesn't get enterprise treatment:

| Level | Example | Process |
|---|---|---|
| **TRIVIAL** | Fix typo, rename variable | Just do it. One log line. |
| **SMALL** | Add a function | 3-line plan. Do it. Verify. |
| **MEDIUM** | New API endpoint | Atomic plan with Verify/Done-when for each task. Evaluator gate before done. |
| **LARGE** | Auth redesign | Research → design options → spec → human approval → execute → per-task evaluator → retro. |

Tasks escalate mid-work if they turn out bigger than expected.

## How a MEDIUM or LARGE task runs

1. **Classify** — Focus picks the level based on scope signals.
2. **Plan** — writes `.focus/plan.md` with atomic tasks. Every task has: **Files, Action, Verify (runnable command), Done when (observable criterion), Commit (conventional message)**. Missing fields block execution.
3. **Clarify** — any `[NEEDS CLARIFICATION: ...]` marker blocks execution until the human answers.
4. **Self-review** — 9-item plan checklist catches placeholders, missing tests, principle violations, scope creep.
5. **Execute** — per task: run Action → run Verify → confirm Done-when → commit. One commit per atomic task enables git-bisect recovery.
6. **Evaluate** — a fresh sub-agent reads the plan and diff cold, verifies each requirement is actually implemented in the code, returns PASS / CHANGES REQUESTED / FAIL. Self-verification does not count.
7. **Merge or PR** — only after evaluator PASS.
8. **Journal** — appends a session entry to `.focus/journal/YYYY-MM-DD.md` so the next session starts informed.

## Files Focus creates in your project

```
.focus/
  memory.md            # committed — principles, decisions, project context, open items
  journal/             # committed — one append-only file per day
    2026-04-20.md
  plan.md              # gitignored — active task's plan (deleted on completion)
  log.md               # gitignored — active task's tool-call trail
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

You can declare project-level guardrails in `memory.md` under `## Principles` (or in the optional `.focus/principles.md`). Focus surfaces them at plan creation, in the evaluator's check, and as an advisory before you stop. Use strength keywords so the evaluator can calibrate:

```markdown
## Principles
- **MUST** keep public APIs backward-compatible through a full major version.
- **MUST NOT** add runtime npm dependencies without explicit approval.
- **PREFER** composition over inheritance.
- **AVOID** mocking the database in tests — use the real harness.
```

The evaluator treats `MUST` / `MUST NOT` violations as blockers. Focus itself never blocks a commit — enforcement lives in the evaluator, not the hooks.

## Design notes

Focus draws on Anthropic's harness-design research plus a cross-analysis of BMAD-METHOD, agent-kernel, get-shit-done, spec-kit, and superpowers. Three patterns the field has converged on:

- **Atomic, verifiable tasks** (from GSD and spec-kit) — every task has a runnable Verify and an observable Done-when.
- **Independent evaluator** (from Anthropic and superpowers) — a fresh agent grades the diff, not the generator.
- **Structured context reset** (from Anthropic) — handoff artifacts beat in-place compaction.

What Focus adds: **adaptive ceremony** (TRIVIAL → LARGE, with escalation) and **one-skill install** on Claude Code. The other harnesses each implement one or two of these patterns but at much higher complexity. Focus keeps the skill under 500 lines of always-loaded context, with depth pushed to on-demand reference files.

## License

MIT
