---
name: focus
description: "ALWAYS use this skill before starting ANY coding task — bug fix, feature, refactor, or any code change. Classifies task complexity, creates plans, tracks progress, handles failures, and manages cross-session memory."
user-invocable: true
hooks:
  UserPromptSubmit:
    - hooks:
        - type: command
          command: "s=session-context.sh; d=skills/focus/scripts; for p in \"${CLAUDE_PLUGIN_ROOT:-}/$d\" \"${CLAUDE_PROJECT_DIR:-}/.claude/$d\" \".claude/$d\" \"$HOME/.claude/$d\"; do [ -x \"$p/$s\" ] && exec bash \"$p/$s\"; done; exit 0"
  PreToolUse:
    - matcher: "Write|Edit|Bash"
      hooks:
        - type: command
          command: "s=plan-tail.sh; d=skills/focus/scripts; for p in \"${CLAUDE_PLUGIN_ROOT:-}/$d\" \"${CLAUDE_PROJECT_DIR:-}/.claude/$d\" \".claude/$d\" \"$HOME/.claude/$d\"; do [ -x \"$p/$s\" ] && exec bash \"$p/$s\"; done; exit 0"
  Stop:
    - hooks:
        - type: command
          command: "s=check-complete.sh; d=skills/focus/scripts; for p in \"${CLAUDE_PLUGIN_ROOT:-}/$d\" \"${CLAUDE_PROJECT_DIR:-}/.claude/$d\" \".claude/$d\" \"$HOME/.claude/$d\"; do [ -x \"$p/$s\" ] && exec bash \"$p/$s\"; done; exit 0"
---

# Focus

Adaptive process, persistent context, cross-session memory, structured planning, verification-driven completion. This body is the always-loaded hot path; depth lives in `references/*.md` per the **Reference Loading Rules** below.

## Session Start

1. If `.focus/memory.md` exists, read it fully — **mutable state**; its Principles constrain your work.
2. If `.focus/journal/` exists, read the **two most recent** (by date) — **immutable narrative**; context, not current state.
3. If `.focus/plan.md` exists, read it. A `## Handoff` section is **ground truth** (resume rules in `references/handoff-protocol.md`) — trust its "Exact next action". Otherwise read the whole plan, run **Reconcile on resume** (below), and continue from the first unchecked task.
4. If `.focus/log.md` and plan.md both exist, read log.md's last ~20 lines — recent errors, "what NOT to do", in-progress state.
5. If `.focus/` doesn't exist, proceed normally; create it when a task warrants it (MEDIUM/LARGE).
6. Ensure `.focus/.gitignore` lists `plan.md`, `log.md`, `report.md`, `gate-report.md`, `gate-findings.md`, `.toolcount*`, `.lastsession*`, `.stopblocks*` — write it when creating `.focus/`, rewrite it when its list is stale. `memory.md` and `journal/` are committed.
7. **Legacy migration:** if `memory.md` has a `## Last Session` section (old format), migrate it to `journal/` once, silently (procedure in `references/memory.md`).

### Reconcile on resume (non-handoff)

Checkboxes can lie (commit then crash before check-off, or check off then revert). Before continuing an existing plan.md, reconcile to git, bounded to the last 30 commits:

1. Run `git log --oneline -n 30`.
2. **Last checked task:** if its `Commit:` subject is absent, the checkbox is ahead of the code — uncheck it and all checked tasks after it; resume from the earliest.
3. **First unchecked task:** if its `Commit:` subject DOES appear, the work landed unrecorded — check it off and advance.
4. Note any correction in log.md, then continue.

## Session End

1. **Append** today's entry to `.focus/journal/<YYYY-MM-DD>.md` (create if absent) — append-only, never edit past entries.
2. **Update `.focus/memory.md`** only if state changed: new decisions, principles, open items; strike resolved ones. Never write "Last Session" (that's journal's job).
3. If incomplete, note the exact stopping point + next steps in log.md.
4. `git add .focus/ && git commit -m "focus: session <YYYY-MM-DD> — <summary>"`

## Track Mode

Ship-pipeline work arrives pre-planned — detect **Track Mode** when cwd is inside `.worktrees/`, the branch is `track/*` / `foundation` **with** `docs/plan/ROADMAP.md`, or the task executes a `docs/plan/tracks/*.md` brief or ROADMAP Phase 0 — it replaces the MEDIUM/LARGE planning ceremony. On detection, **read `references/track-mode.md` before planning** — the brief IS the plan; don't re-plan, commit directly on the current branch.

---

## Classify Every Task

Classify before starting — this determines your process.

### TRIVIAL
Single file, <10 words, typo/rename/version-bump/flag/import. **Just do it, commit,** append one line to `.focus/log.md`: `- [YYYY-MM-DD HH:MM] TRIVIAL: <what>`.

### SMALL
1-3 files, clear path, no arch decisions, <5 tool calls. Append a 3-line plan to log.md (`### [ts] SMALL: <task>` then `Plan: 1)… 2)… 3)…`); do the work, run tests, commit; append `Result: Done. Files: <list>`.

### MEDIUM
3-10 files, some decisions, may read existing code:
1. Read affected code; learn the patterns.
2. Branch `git checkout -b feat/<slug>` (or main/assigned — record `Branch:`+`Base:`, skip step 9's PR offer).
3. Create `.focus/plan.md` from the MEDIUM template (`references/plans.md`); every task meets the Atomic Task Schema.
4. Run Plan Self-Review; resolve `[NEEDS CLARIFICATION]` markers with the human first.
5. Briefly state the plan to the human, then start.
6. Per task: Action → run the task's `Verify:` → confirm `Done when:` → commit (task's `Commit:`) → check off → update log.md.
7. Run full verification before claiming done.
8. Invoke the evaluator (Evaluator Gate); clear `CHANGES REQUESTED` / `FAIL` before proceeding.
9. Merge branch, or offer a PR: "Merge to main, or create a PR?"
10. **Complete:** archive the plan record (Goal, REQs + final status, evaluator verdict, task → commit shas) to today's journal, then delete plan.md + log.md. Full checklist + gated mode: `references/plans.md`.

### LARGE
10+ files, arch decisions, cross-cutting, needs research — MEDIUM's execute/complete steps plus upstream ceremony:
1. Ask 3-5 clarifying questions, one at a time (purpose, constraints, preferences, trade-offs); skip to step 3 if already specific.
2. Capture preferences (style, naming, error handling, testing) to memory.md Project Context if not already there.
3. Research — **delegate, don't accumulate:** read-only sub-agents return compact findings you append to log.md `### Research`; read directly only files you'll edit (`references/plans.md`).
4. Generate 2-3 design options with trade-offs; recommend; wait.
5. Branch `git checkout -b feat/<slug>` (or main/assigned — record `Branch:`+`Base:`, skip step 13's PR offer).
6. Create `.focus/plan.md` from the LARGE template (`references/plans.md`); fill the Requirement → Task Map.
7. Self-review the plan (10-item checklist, `references/plans.md`); resolve `[NEEDS CLARIFICATION]` first.
8. Independent plan check: a fresh sub-agent grades plan.md against that checklist; fix defects before presenting.
9. Present the plan, ask "Any objections or adjustments?", and wait.
10. Execute per task (MEDIUM step 6); update log.md.
11. Evaluate on the adaptive cadence (Evaluator Gate); clear `CHANGES REQUESTED` / `FAIL` before continuing.
12. Update memory.md with architectural decisions.
13. Merge branch, or offer a PR.
14. **Complete:** run the retrospective, then archive the plan record to today's journal and delete plan.md + log.md (`references/plans.md`).

### Escalation / De-escalation
**Escalate** when a task grows past its class (small → 8 files, medium → arch impact): update the plan, re-ask the human if now LARGE, note it. **De-escalate** when it collapses below its class: finish under the lighter level, delete plan.md if unwarranted, note it. The evaluator gate is waived only below MEDIUM — never de-escalate to dodge a failing evaluator.

### Discovered Work (deviation rules)
Handle mid-execution discoveries by rule, noting each in log.md: (1) **bug blocking the task** → fix inline; (2) **missing correctness/security on the touched path** → add inline; (3) **new package needed** → never auto-install (supply-chain risk), ask the human; (4) **out-of-scope** → don't fix it, add to memory.md Open Items; (5) **architectural change** → stop and escalate.

---

## Atomic Task Schema

**Every plan task uses the Atomic Task Schema:** required fields are **Files, Action, Verify, Done when, Commit**. Optional **Skills** — invoke (Skill tool) before the task, in every mode. A task missing any required field is not ready to execute. `Verify` must be a runnable command; `Done when` must be an observable signal (not "looks right"). One commit per task (enables git-bisect recovery).

**Before execution:** if any required field can't be filled without guessing, write `[NEEDS CLARIFICATION: <question>]` in place. Any such marker blocks execution until resolved with the human (Track Mode's per-task `Ask before Task N` markers block only their own task).

**Before presenting a MEDIUM/LARGE plan:** run the 10-item Plan Self-Review. **Read `references/plans.md`** — templates, no-placeholders rule, Self-Review checklist, LARGE research, Completion Protocol.

---

## Evaluator Gate

Generators grading their own work overwhelmingly return "looks good". The evaluator is a **fresh, adversarial** sub-agent that reads the plan and diff cold, runs each `Verify:` itself, and returns PASS / CHANGES REQUESTED / FAIL / UNCERTAIN.

**When to invoke.**
- **MEDIUM:** once, before marking the plan complete.
- **LARGE — adaptive cadence.** After a top-level task, evaluate **immediately** if its diff touches **≥3 files** OR any of its sub-tasks needed a `Verify:` retry; otherwise **defer** and batch-evaluate after **every 2** top-level tasks. **Always** evaluate at plan completion, regardless of the last batch.
- **TRIVIAL / SMALL:** skip.

**Read `references/evaluator.md`** to spawn the evaluator and act on its verdict — locating `evaluate.md` across installs, re-verification mode after CHANGES REQUESTED, and the generator anti-patterns.

---

## Principles

Project constraints live in `memory.md`'s `## Principles` (plus optional `.focus/principles.md`, merged by `principles.sh`). Lead each with **MUST / MUST NOT / PREFER / AVOID**. They surface at plan creation (Self-Review item 6), are enforced by the evaluator (MUST/MUST NOT = blockers; PREFER/AVOID need a justifying Decisions entry), and are advisory at stop. Add or supersede in memory.md (strikethrough the old line) — **never silently remove one**. **Read `references/principles.md`** to add, edit, or review a principle.

---

## Verification Protocol

**Iron Law: NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE.** Before claiming any task, phase, or the full work done: (1) **identify** the command that proves the claim (test/build/lint); (2) **run** it fresh this message; (3) **read** the full output, exit code, and failure count; (4) **confirm** — YES → state it with evidence ("24/24, exit 0"); NO → state the actual status ("3 failing: [names]").

**Red flags — STOP if you catch yourself** saying "should work" / "looks correct", claiming done without running the command this message, or trusting a previous run.

---

## Failure Handling

1. **Log before retry.** On failure, append an `### Error [timestamp]` entry to `.focus/log.md` BEFORE retrying — What, Error, Attempt #, Hypothesis, Next.
2. **Never repeat an approach.** Attempt 2 must differ from attempt 1; read your log for what you tried.
3. **Three strikes → ask.** After 3 failed attempts, list the three approaches + why each failed, propose a fourth, proceed unless redirected.
4. **Rollback on regression.** Broke passing tests? Uncommitted → `git stash`; committed → `git revert <sha>`. Log it, tell the human, ask retry-or-debug.

**When a `Verify:` fails or behavior is unexpected**, run the four-phase Investigate → Analyze → Hypothesize → Fix procedure (one variable at a time) — **read `references/debugging.md`**. After 3+ failed fixes, question the architecture with the human.

---

## Human Steering

**Proceed on silence** — TRIVIAL/SMALL: just do it; MEDIUM: state the plan briefly, then start (human can interrupt); LARGE: present the plan and **wait**. **Always ask** for destructive operations (deleting files, dropping tables, force push), ambiguous requirements, or trade-offs to weigh. **Never ask about** code style, test framework, or file organization — follow existing conventions.

---

## Testing & Code Review

**TRIVIAL/SMALL:** run existing tests if present; don't add new ones. **MEDIUM/LARGE:** tests are part of the work — prefer test-first, verify no regressions. **Code review** (not writing code): read the diff end-to-end and categorize findings **Blocking / Suggestion / Nit**. **Read `references/testing-and-review.md`** for real-test criteria and the review procedure.

---

## Handoff

A **read-once** `## Handoff` block at the bottom of `.focus/plan.md` lets a fresh session resume from its **Exact next action**, not a dying conversation. Emit one — and **read `references/handoff-protocol.md`** for format + procedure — when any countable trigger fires: PreToolUse warns at **40+ tool calls** since the last plan.md change; a **Track Mode session block's last task** completed (always); a **LARGE top-level task** completed and its due evaluation ran (evaluate first); the user says **`/focus:handoff`**; the **3-Question Self-Check** fails after re-reading plan.md/log.md; or an evaluator returns **FAIL** needing a plan revision. **Resuming:** the section is ground truth — archive it to log.md, delete it from plan.md (read-once), then act on Exact next action; don't re-derive state or re-verify tasks already recorded with a commit sha.

---

## Memory & Context Health

**memory.md** = mutable state (Principles, Decisions, Project Context, Open Items); **journal/`YYYY-MM-DD`.md** = immutable append-only narrative; **log.md** = active-task scratch, deleted with plan.md. Load-bearing: never mix state and narrative, never write "Last Session" into memory.md, never edit past journal/log entries, never delete log.md mid-task. Stable conventions belong in CLAUDE.md, not memory.md. **Read `references/memory.md`** for formats, pruning, and legacy migration.

**Research Flush Rule:** flush findings to log.md after each research question or every ~5 reads — conclusions only; raw contents are disposable.

**3-Question Self-Check:** uncertain? Answer (1) current task/step, (2) done so far, (3) next step. Can't from memory → re-read plan.md/log.md; still can't → hand off and start fresh.

---

## Reference Loading Rules

| When | Read |
|------|------|
| Track Mode detected (see the triggers above) — **before planning** | `references/track-mode.md` |
| Emitting or resuming a handoff (triggers above, or a `## Handoff` at session start) | `references/handoff-protocol.md` |
| Creating/reviewing a MEDIUM/LARGE plan, or completing one | `references/plans.md` |
| Spawning the evaluator or acting on its verdict | `references/evaluator.md` |
| Adding, editing, or reviewing a principle | `references/principles.md` |
| A `Verify:` fails or behavior is unexpected | `references/debugging.md` |
| Writing tests (MEDIUM/LARGE), or reviewing a PR | `references/testing-and-review.md` |
| Writing memory.md/journal at session end, pruning, or migrating | `references/memory.md` |

---

## Anti-Patterns

- Do NOT use Claude Code's built-in plan mode (EnterPlanMode). Write plans directly to `.focus/plan.md`; Focus manages its own planning.
- Do NOT claim done without running the task's `Verify:` and confirming `Done when:`; never say "should work" / "looks correct" — run it, show output.
- Do NOT skip the Evaluator Gate on MEDIUM/LARGE, and do NOT write its verdict yourself — spawn a fresh agent or declare the plan uncompletable.
- Do NOT write placeholder steps, retry a failed approach without logging what failed first, or ask approval for obvious changes.
- Do NOT edit previous log/journal entries (append-only); strikethrough superseded decisions rather than deleting; do NOT leave a stale plan.md — delete it at completion.
