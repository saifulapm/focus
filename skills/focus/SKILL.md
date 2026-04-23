---
name: focus
description: "ALWAYS use this skill before starting ANY coding task — bug fix, feature, refactor, or any code change. Classifies task complexity, creates plans, tracks progress, handles failures, and manages cross-session memory."
user-invocable: true
hooks:
  UserPromptSubmit:
    - hooks:
        - type: command
          command: "s=session-context.sh; for p in \"${CLAUDE_PLUGIN_ROOT:-}/scripts/$s\" \"$HOME/.claude/skills/focus/scripts/$s\"; do [ -n \"$p\" ] && [ -x \"$p\" ] && bash \"$p\" && break; done"
  PreToolUse:
    - matcher: "Write|Edit|Bash|Read|Glob|Grep"
      hooks:
        - type: command
          command: "s=plan-tail.sh; for p in \"${CLAUDE_PLUGIN_ROOT:-}/scripts/$s\" \"$HOME/.claude/skills/focus/scripts/$s\"; do [ -n \"$p\" ] && [ -x \"$p\" ] && bash \"$p\" && break; done"
  Stop:
    - hooks:
        - type: command
          command: "s=check-complete.sh; for p in \"${CLAUDE_PLUGIN_ROOT:-}/scripts/$s\" \"$HOME/.claude/skills/focus/scripts/$s\"; do [ -n \"$p\" ] && [ -x \"$p\" ] && bash \"$p\" && break; done"
---

# Focus

You are enhanced with adaptive process, persistent context, cross-session memory, structured planning, systematic debugging, and verification-driven completion.

## Session Start

1. If `.focus/memory.md` exists, read it fully. This is **mutable state** — current principles, decisions, project context, open items. Note any Principles — these constrain your work.
2. If `.focus/journal/` exists, read the **two most recent files** (by filename date). This is **immutable narrative** — what happened in recent sessions. Use it to understand "what was the last person doing" without trusting it for current state.
3. If `.focus/plan.md` exists, read it.
   - If it contains a `## Handoff` section, **that section is your ground truth** — see the Handoff Protocol's "Resuming from a handoff" rules. Do not re-derive state from the rest of plan.md or log.md; trust the handoff's "Exact next action".
   - Otherwise, read the whole plan and continue from the first unchecked task.
4. If `.focus/log.md` exists and plan.md exists, read the last ~20 lines of log.md — recent errors, "what NOT to do" items, progress for the in-progress task.
5. If `.focus/` does not exist, proceed normally. Create it when a task warrants it (MEDIUM or LARGE).
6. When creating `.focus/` for the first time, also create `.focus/.gitignore` with `plan.md` and `log.md` (temporary files). `memory.md` and `journal/` are committed.
7. **Legacy migration:** if `memory.md` has a `## Last Session` section, that's the old format. Move its contents to `journal/<YYYY-MM-DD>.md` (using the date from the section if present, else today), then delete the section from memory.md. Do this once per project, silently.

## Session End

Before the conversation ends:
1. **Append today's entry** to `.focus/journal/<YYYY-MM-DD>.md` — what was done this session. Never edit previous entries; only append. Create the file if it doesn't exist.
2. **Update `.focus/memory.md`** only if state actually changed: new decisions (add to Decisions table), new principles (add to Principles), new open items, resolved open items (strike through). Do NOT write "Last Session" — that belongs in journal.
3. If task is incomplete, note exact stopping point in log.md with clear next steps.
4. `git add .focus/ && git commit -m "focus: session <YYYY-MM-DD> — <short summary>"`

---

## Classify Every Task

Before starting work, classify the task. This determines your process.

### TRIVIAL
**Signals:** single file, described in under 10 words, fix typo, rename, bump version, toggle flag, add import.
**Process:** Just do it. Commit. Append one line to `.focus/log.md` (create if needed):
```
- [YYYY-MM-DD HH:MM] TRIVIAL: <what you did>
```

### SMALL
**Signals:** 1-3 files, clear implementation path, no architectural decisions, under 5 tool calls.
**Process:**
1. Append a 3-line plan to `.focus/log.md`:
   ```
   ### [YYYY-MM-DD HH:MM] SMALL: <task name>
   Plan: 1) <step> 2) <step> 3) <step>
   ```
2. Do the work. Run tests. Commit.
3. Append result: `Result: Done. Files: <list>`

### MEDIUM
**Signals:** 3-10 files, some decisions to make, may need to read existing code. New feature, module refactor, add API endpoint.
**Process:**
1. **Read existing code** in affected areas. Understand patterns and conventions.
2. Create a feature branch: `git checkout -b feat/<task-slug>`
3. Create `.focus/plan.md` using the MEDIUM template (see Plan Templates, and `references/plans.md`). Every task must satisfy the Atomic Task Schema.
4. **Run Plan Self-Review.** Resolve any `[NEEDS CLARIFICATION]` markers by asking the human before presenting.
5. Briefly state the plan to the human, then start working.
6. Work through tasks in order. For each task: execute Action → run the task's `Verify:` command → confirm `Done when:` holds → commit using the task's `Commit:` message → check off → update log.md.
7. Run full verification before claiming done.
8. **Invoke the evaluator** (see Evaluator Gate below). Address any `CHANGES REQUESTED` or `FAIL` verdict before proceeding. Do not skip this step — your own verification is input to the evaluator, not a substitute for it.
9. Merge branch or offer to create PR: "Merge to main, or create a PR?"
10. Delete `.focus/plan.md` when complete (memory.md keeps the record).

### LARGE
**Signals:** 10+ files, architectural decisions, cross-cutting concerns, needs research. Database migration, new subsystem, major refactor.
**Process:**
1. **Ask 3-5 clarifying questions** — one at a time. Focus on: purpose, constraints, preferences, trade-offs. If the user's request is already specific, skip to step 3.
2. **Capture preferences** (if not already in memory.md): Ask about coding style, naming conventions, error handling philosophy, testing preferences. Save to memory.md under Project Context so this persists across sessions.
3. **Research the codebase:**
   - Read existing code in affected areas
   - Identify patterns, conventions, dependencies
   - Find constraints (what can't change, what breaks if you touch it)
   - **2-Action Rule:** After every 2 file reads or searches, append a bullet to log.md summarizing what you found. Do not accumulate more than 2 results without saving.
   - Document full findings in `.focus/log.md` under `### Research [date]`
4. **Generate 2-3 design options** with trade-offs for the key architectural decision. Present to human with a recommendation. Wait for input.
5. Create a feature branch: `git checkout -b feat/<task-slug>`
6. Create `.focus/plan.md` using the LARGE template (see `references/plans.md`). Every task must satisfy the Atomic Task Schema, and the Requirement → Task Map must be filled.
7. **Self-review the plan** (the 9-item checklist in `references/plans.md`). Resolve any `[NEEDS CLARIFICATION]` markers before presenting.
8. **Present the plan and ask: "Any objections or adjustments?"** — wait for human response.
9. Work through tasks in order. For each task: execute Action → run the task's `Verify:` command → confirm `Done when:` holds → commit using the task's `Commit:` message → check off → update log.md.
10. **After each top-level task (and before marking the full plan complete), invoke the evaluator** (see Evaluator Gate below). LARGE plans tend to silently drift from requirements; per-task evaluation catches drift early. Address any `CHANGES REQUESTED` or `FAIL` verdict before continuing.
11. Update `.focus/memory.md` with architectural decisions.
12. Merge branch or offer to create PR: "Merge to main, or create a PR?"
13. Run retrospective (see Completion Protocol).
14. Delete `.focus/plan.md` when complete.

### Escalation Rule
If a task grows beyond its classification (small touching 8 files → medium, medium with arch impact → large), escalate: create/update plan, re-ask human if now LARGE. Note escalation in log.md.

---

## Plan Templates

**Every plan task uses the Atomic Task Schema:** required fields are **Files, Action, Verify, Done when, Commit**. A task missing any of these is not ready to execute. `Verify` must be a runnable command; `Done when` must be an observable signal (not "looks right"). One commit per task.

**Before execution:** if any required field can't be filled without guessing, write `[NEEDS CLARIFICATION: <question>]` in place. Any such marker blocks execution until resolved with the human.

**Before presenting a MEDIUM/LARGE plan:** run the 9-item Plan Self-Review.

**Read `skills/focus/references/plans.md`** when creating or reviewing a plan — it has the full MEDIUM and LARGE templates, the no-placeholders rule, and the Self-Review checklist.

---

## Evaluator Gate

**Why this exists.** When asked to evaluate their own work, generators overwhelmingly return "looks good" — a result reproduced across Anthropic's harness experiments and every reference harness Focus draws from. Self-verification is necessary but not sufficient. The evaluator is a **fresh, adversarial** reader of the plan and the diff, with no memory of how the work got made.

**When to invoke.**
- **MEDIUM:** once, before marking the plan complete.
- **LARGE:** after each top-level task, and once before marking the plan complete.
- **TRIVIAL / SMALL:** skip. Not worth the overhead.

**How to invoke** — use the first mode your host supports:

1. **Sub-agent mode (preferred — Claude Code, Cursor).** Spawn a fresh sub-agent using the host's Agent / Task primitive. Tell it: *"Run the `/focus:evaluate` command against the current branch. Return the verdict exactly in the specified format. You have no prior context — read `.focus/plan.md` and the diff yourself."*

2. **Brief mode (Codex, OpenCode, Gemini, or fallback).** Run the `evaluator-brief.sh` script that ships with the skill. Resolve its path via the same lookup the hooks use: `${CLAUDE_PLUGIN_ROOT:-}/scripts/evaluator-brief.sh`, then fall back to `$HOME/.claude/skills/focus/scripts/`, `$HOME/.cursor/skills/focus/scripts/`, or `$HOME/.agents/skills/focus/scripts/` — whichever your host installs to. The script writes `.focus/evaluator-brief.md` in the current project — a self-contained handoff with the plan, diff, and principles. Tell the human: *"Paste `.focus/evaluator-brief.md` into a fresh session and run `/focus:evaluate`, then paste the verdict back."* This is weaker than sub-agent mode — the evaluator still has human-loop latency — but preserves the key property: the evaluator has no memory of the generator's reasoning.

In either mode, the evaluator's output format is defined in `commands/focus/evaluate.md` (the `/focus:evaluate` command). Do not freelance the format; the generator needs a predictable structure to machine-read the verdict.

**What to do with the verdict.**
- **PASS** — proceed to merge. Record any evaluator suggestions in log.md for next-session follow-up.
- **CHANGES REQUESTED** — address every blocker issue. Re-invoke the evaluator after fixes (fresh agent / fresh brief). Do not argue with the evaluator; treat its report as the source of truth until you can show the diff refutes it.
- **FAIL** — the plan itself is wrong, not just the code. Update plan.md, note the escalation in log.md, consider whether the task has become LARGE, then continue.
- **UNCERTAIN** — the evaluator asked a specific question. Answer it in plan.md or log.md, then re-invoke.

**Anti-patterns for the generator:**
- Do **not** prompt the evaluator with a summary of what was built — let it read the diff cold.
- Do **not** re-invoke the same evaluator instance after a FAIL. Context contamination defeats the purpose. Use a fresh agent / fresh session every time.
- Do **not** accept a PASS that skipped running `Verify:` commands — the evaluator must have command output in its report.
- Do **not** self-grant PASS by writing the evaluator's verdict yourself. If sub-agent and brief mode are both unavailable, tell the human the plan cannot be marked complete without human review.

---

## Principles Gate

Principles are project-level constraints — "never break backward compat", "no new npm dependencies", "prefer composition over inheritance". They outlive any one task. Focus treats them as **first-class inputs to plan creation and evaluation**, not decoration.

### Where principles live

- `memory.md` `## Principles` section — primary home, always loaded.
- `.focus/principles.md` (optional) — separate file for larger projects that want principles isolated from project context. If present, it is **merged** with memory.md's section, not overriding it.

The `scripts/principles.sh` loader reads both and prints the merged set. `session-context.sh`, `plan-tail.sh`, `evaluator-brief.sh`, and the Stop hook all use this loader — principles surface consistently.

### Recommended format

Lead each principle with a strength keyword so both humans and evaluators can gauge it:

```markdown
## Principles
- **MUST NOT** add runtime npm dependencies without explicit approval.
- **MUST** keep public APIs backward-compatible through a full major version.
- **PREFER** composition over inheritance; inheritance requires a decision entry.
- **AVOID** tests that mock the database — use the test harness at `tests/db.ts`.
```

Plain bullets without keywords are fine too — Focus just loses the severity signal.

### When principles are surfaced

1. **Plan creation** (MEDIUM/LARGE): the session-context hook prints the Principles block before any tool call. Plan Self-Review explicitly checks for violations (item 6 in that list).
2. **Evaluator run**: `evaluator-brief.sh` includes principles as a dedicated section; the `/focus:evaluate` command checks the diff against them and treats violations as blocker issues. The evaluator is the primary enforcement point.
3. **Before stop** (advisory): `check-complete.sh` reminds the generator principles are active if there are pending changes. One-line nudge, not enforcement.

### When principles change

Principles are added/edited in **memory.md** like any other state:
- New principle stated by user → append with the MUST / MUST NOT / PREFER keyword, add to memory.md during the session.
- Principle superseded → strikethrough the old line; add the new one with a decision entry explaining the change.
- Never silently edit or remove a principle: future sessions need to see the transition.

### What principles are NOT

- Not a replacement for code review — principles cover recurring project-wide constraints, not per-diff quality.
- Not a build-time gate — Focus will never block a commit because of a principle. The decision to override is always the human's; Focus just makes sure the decision is conscious.
- Not a dumping ground — 20 principles is too many for an agent to weigh. Aim for 3–7. Everything else is Project Context or a Decision.

### Anti-patterns

- Do **not** write principles that can't be checked against a diff ("write clean code"). Either make it specific enough to check, or put it in Project Context.
- Do **not** bury principles in prose inside Project Context — use the dedicated section so the loader finds them.
- Do **not** accept an evaluator PASS that ignored a principle violation. That's a calibration failure — flag it in log.md and fix the evaluator's next brief.
- Do **not** silently violate a principle "just this once". If the task requires it, add a decision entry saying so.

---

## Verification Protocol

**Iron Law: NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE.**

Before claiming any task, phase, or the full work is done:

1. **IDENTIFY** — What command proves this claim? (test, build, lint)
2. **RUN** — Execute the full command fresh (not from memory)
3. **READ** — Read complete output, check exit code, count failures
4. **CONFIRM** — Does output confirm the claim?
   - YES → State claim WITH evidence: "Tests pass (24/24, exit 0)"
   - NO → State actual status: "3 tests failing: [names]"

**Red flags — STOP if you catch yourself:**
- Saying "should work", "looks correct", "seems fine"
- Claiming done without running the command THIS message
- Trusting a previous run (run it again)
- Expressing satisfaction before verification ("Great!", "Perfect!")

---

## Systematic Debugging

Summary: **Investigate → Analyze → Hypothesize → Fix**, one variable at a time. Do NOT skip to fixes. If 3+ fixes failed in a row, question the architecture with the human.

**Read `skills/focus/references/debugging.md`** when a `Verify:` fails or behavior is unexpected — it has the full four-phase procedure and debugging anti-patterns.

---

## Failure Handling

### Rule 1: Log before retry
When something fails, append to `.focus/log.md` BEFORE trying again:
```
### Error [YYYY-MM-DD HH:MM]
- What: <what you tried>
- Error: <what happened>
- Attempt: <number>
- Hypothesis: <why it failed>
- Next: <what you'll try differently and why>
```

### Rule 2: Never repeat the same approach
Attempt 2 must differ from attempt 1. Read your log to see what you already tried.

### Rule 3: Three strikes, ask the human
After 3 failed attempts:
```
I've tried 3 approaches for <step>:
1. <approach 1> — failed because <reason>
2. <approach 2> — failed because <reason>
3. <approach 3> — failed because <reason>

I'd try <approach 4> next. Proceeding unless you redirect.
```

### Rule 4: Rollback on regression
If your changes break passing tests: `git stash`, log it, tell the human, ask whether to retry or debug.

---

## Human Steering

**Principle: proceed on silence.**

- **TRIVIAL / SMALL:** No checkpoint. Just do it.
- **MEDIUM:** State the plan briefly, then start. Human can interrupt.
- **LARGE:** Present plan and **wait for response** before starting.

**Always ask regardless of level when:**
- Destructive operations (deleting files, dropping tables, force push)
- Ambiguous requirements (two valid interpretations)
- Trade-offs the human should weigh

**Never ask about:**
- Code style decisions (follow existing patterns)
- Which test framework (use what's already there)
- File organization (follow existing conventions)

---

## Testing & Code Review

- **TRIVIAL/SMALL:** run existing tests if present; don't add new ones.
- **MEDIUM/LARGE:** tests are part of the work — prefer test-first, verify no regressions.
- **Code review (not writing code):** read the diff end-to-end; categorize as Blocking / Suggestion / Nit.

**Read `skills/focus/references/testing-and-review.md`** when writing tests for a MEDIUM/LARGE task or when asked to review a PR — it has the per-level testing rules, what counts as a real test, and the review procedure with anti-patterns.

---

## Context Health

**2-Action Rule:** During research phases, after every 2 file reads or searches, append a bullet to log.md summarizing what you found. Do not accumulate more than 2 search results in context without saving.

**3-Question Self-Check:** If you feel uncertain about the current state, answer these before continuing:
1. What is the current task and which step am I on?
2. What have I completed so far?
3. What is the exact next step?

If you cannot answer all 3 from memory, re-read plan.md and log.md before continuing. If you still cannot answer after re-reading, emit a Handoff (see below) and ask the user to start a fresh session.

---

## Handoff Protocol

**Why this exists.** Context windows are finite. Evidence from long-running harnesses is consistent: context *resets* — starting a fresh agent from a written handoff — outperform in-place compaction, which quietly drops details and triggers "context anxiety" (the agent hurrying toward completion because it senses the window filling). Focus handles exhaustion by design: it writes a compact, machine-readable handoff block to `plan.md`, then the next agent reads that block instead of the dying conversation.

### When to emit a handoff

Emit a handoff whenever **any** of these hold:

- **Tool-call budget:** you have done ~40+ tool calls on the current task since plan.md was created (or since the last handoff).
- **Natural boundary:** a LARGE plan's top-level task has just completed — even if you have budget left, a handoff here gives the evaluator and the next task a clean slate.
- **User request:** the user types `/focus:handoff` or says "hand off".
- **Self-detected drift:** the 3-Question Self-Check above fails even after re-reading plan.md and log.md. Do not push through — hand off.
- **Evaluator FAIL:** after an evaluator returns FAIL with a plan-level revision required, write the handoff so the next session picks up from the corrected plan, not the exhausted one.

Do **not** emit a handoff on every task completion. Small tasks inside MEDIUM plans can chain — handoff only when context is actually taxed or a natural reset point arrives.

### Handoff artifact

The handoff lives **at the bottom of `plan.md`**, in a `## Handoff` section, replaced each time. One section only — do not accumulate handoff history (that's what log.md is for).

Format:

```markdown
## Handoff

**Emitted:** <YYYY-MM-DD HH:MM>  **Reason:** <budget | boundary | user | drift | evaluator-fail>

**Current task:** Task N — <name>
**Current step:** <which checkbox in the task's sub-list, e.g., "Verify passes">
**Branch:** `<branch name>`  **Last commit:** `<sha> <subject>`

**Done so far:**
- Task 1 — <name> — committed as `<sha>`
- Task 2 — <name> — committed as `<sha>`
- Task 3 up to step 2 of 4 — not yet committed

**Exact next action:**
<one paragraph. Include the exact command to run, file to edit, or question to ask the human. A fresh agent must be able to act on this without rereading anything but plan.md and log.md.>

**Files in play:**
- `path/to/file.ext` — <what is half-done here, if anything>

**Recent verification:**
- `<cmd>` → <exit code, summary>  (run at <time>)

**Open questions for the human:**
- <question 1, if any — otherwise omit this section>

**Principles still in force:**
- <copy from memory.md / principles.md — the subset actually relevant to the remaining work>

**What NOT to do:**
- <approaches already tried and failed; load this from log.md. Keeps the next agent from retrying the same path.>
```

### Emitting a handoff — procedure

1. **Stop current work.** Do not start a new tool call after deciding to hand off.
2. **Flush log.md.** If there are unsummarized search results or error notes in conversation memory that are not yet in log.md, append them now.
3. **Write the handoff block** to the bottom of plan.md using the format above. Replace any existing `## Handoff` section — only the latest handoff is kept.
4. **Tell the user plainly:**
   ```
   Handoff written to .focus/plan.md (§Handoff). Context is near its useful limit.
   Recommend: /clear, then start a fresh session. The new agent will pick up from the handoff.
   ```
5. **Commit:** `git add .focus/plan.md .focus/log.md && git commit -m "focus: handoff at task N"`. The commit is essential — it makes the handoff durable across session boundaries, including crashes.

### Resuming from a handoff

At session start, when `.focus/plan.md` exists:

1. **Read the `## Handoff` section first** — if present, it is your ground truth. Trust it over any other cue.
2. Read the rest of plan.md (Requirements, Design, task list) to understand the full scope.
3. Read the last ~20 lines of log.md — specifically for the "what NOT to do" items the handoff references.
4. Begin work at the **Exact next action**. Do not re-derive state from scratch. Do not re-verify tasks already marked with a commit sha in "Done so far" — trust the handoff.
5. If the handoff's Exact next action is unclear or impossible (e.g., a file it references doesn't exist), stop and ask the user. A handoff that won't execute is a bug in the previous session, not something to paper over.

### Anti-patterns

- Do **not** emit a handoff without a next-action sentence a fresh agent can execute literally. "Continue the refactor" is not a next action; "Edit `src/auth.ts` at line 42 — replace `validateToken` with `verifyJwt` per Task 3" is.
- Do **not** skip the commit. An uncommitted handoff vanishes if the session crashes.
- Do **not** accumulate handoff history in plan.md. Only the current handoff; log.md keeps the trail.
- Do **not** resume a handoff while the previous context is still loaded. The whole point is a fresh start — use `/clear` or a new session.
- Do **not** leave a handoff in place after completing the plan. Delete plan.md (and with it the handoff) as part of the Completion Protocol.

---

## Memory Management

Focus keeps two persistent files plus a per-task scratchpad:

| File | Kind | Content |
|------|------|---------|
| `memory.md` | **Mutable state** (edited) | Principles, Decisions, Project Context, Open Items |
| `journal/YYYY-MM-DD.md` | **Immutable narrative** (append-only) | Per-session summaries, retrospectives |
| `log.md` | **Active-task scratch** (append-only) | Research findings, errors, attempts — deleted with plan.md when the task completes |

The split is load-bearing: mixing state and narrative in one file means future agents can't tell which bullets still describe reality. Never write "Last Session" into memory.md; never edit past journal entries; never delete log.md mid-task.

**Read `skills/focus/references/memory.md`** when writing to memory.md or journal/ at session end, when pruning, or when migrating a legacy `## Last Session` section — it has the formats, field templates, and the migration procedure.

---

## Completion Protocol

Before claiming any task is done:
1. **Self-review code** against plan requirements — does the implementation match what was specified?
2. **Check code quality** — any obvious issues, missing error handling in critical paths, unused imports?
3. Run tests. All must pass (with evidence).
4. Run build/lint if applicable. Must succeed.
5. All plan tasks checked off.
6. **MEDIUM/LARGE only: Invoke the evaluator** (see Evaluator Gate). Only a PASS verdict permits completion. CHANGES REQUESTED or FAIL sends you back to step 1 after fixes.
7. Update `.focus/log.md` with final status (include the evaluator verdict summary).
8. Append a session entry to `.focus/journal/<YYYY-MM-DD>.md`.
9. Update `.focus/memory.md` only if state changed (new principle / decision / open item).
10. Delete `.focus/plan.md` and `.focus/log.md` (task done; the journal keeps the record).

### Retrospective (LARGE tasks only)
After completing a LARGE task, append to today's journal file (`.focus/journal/<YYYY-MM-DD>.md`):
```
## Retro: <task name> (<date>)
- What went well: <1-2 points>
- What went poorly: <1-2 points>
- Change for next time: <1 actionable improvement>
```

## Anti-Patterns

- Do NOT use Claude Code's built-in plan mode (EnterPlanMode). Write plans directly to `.focus/plan.md` using the templates above. Focus manages its own planning.
- Do NOT create plan.md for trivial/small tasks.
- Do NOT write a task without all five required fields (Files, Action, Verify, Done when, Commit).
- Do NOT start execution while any `[NEEDS CLARIFICATION]` marker remains in plan.md.
- Do NOT ask the human for approval on obvious changes.
- Do NOT retry a failed approach without logging what failed first.
- Do NOT claim done without running the task's `Verify:` command and confirming its `Done when:` criterion.
- Do NOT skip the Evaluator Gate on MEDIUM/LARGE plans. Your own "looks good" is not a verdict.
- Do NOT write the evaluator's report yourself. Either spawn a fresh agent, generate a brief for the human, or declare the plan uncompletable.
- Do NOT write placeholder steps ("add error handling", "write tests for above").
- Do NOT memorize trivial facts. Only decisions, patterns, and cross-session context.
- Do NOT leave stale plan.md files. Delete when task is complete.
- Do NOT say "should work" or "looks correct". Run the command. Show the output.
- Do NOT edit previous log entries. Log is append-only.
- Do NOT edit previous journal entries. Journal is append-only; the history is the point.
- Do NOT write session summaries or "Last Session" into memory.md. Session narrative goes in journal/.
- Do NOT leave contradictory decisions in memory.md. Strikethrough the old one.
