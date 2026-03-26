---
name: focus
description: "ALWAYS use this skill before starting ANY coding task — bug fix, feature, refactor, or any code change. Classifies task complexity, creates plans, tracks progress, handles failures, and manages cross-session memory."
user-invocable: true
hooks:
  UserPromptSubmit:
    - hooks:
        - type: command
          command: "echo '[focus] IMPORTANT: Invoke the focus skill before starting any coding work. Classify task complexity and follow the focus process.'; if [ -f .focus/memory.md ]; then echo ''; echo '=== [focus] Session Memory ==='; sed -n '/^## Last Session/,/^## /p' .focus/memory.md | head -15; echo ''; fi; if [ -f .focus/plan.md ]; then echo '=== [focus] Active Plan ==='; head -20 .focus/plan.md; echo ''; if [ -f .focus/log.md ]; then echo '=== [focus] Recent Log ==='; tail -10 .focus/log.md; echo ''; fi; echo '[focus] Continue from current phase. Read .focus/plan.md, .focus/log.md, and .focus/memory.md for full context.'; fi"
  PreToolUse:
    - matcher: "Write|Edit|Bash|Read|Glob|Grep"
      hooks:
        - type: command
          command: "if [ -f .focus/plan.md ]; then head -20 .focus/plan.md 2>/dev/null; fi"
  Stop:
    - hooks:
        - type: command
          command: "if [ -f .focus/plan.md ]; then incomplete=$(grep -c '^- \\[ \\]' .focus/plan.md 2>/dev/null || echo 0); if [ \"$incomplete\" -gt 0 ]; then echo \"[focus] WARNING: $incomplete unchecked phases in plan.md. Verify all work is complete before stopping.\"; fi; fi; if [ -f .focus/memory.md ]; then age=$(($(date +%s) - $(stat -f %m .focus/memory.md 2>/dev/null || stat -c %Y .focus/memory.md 2>/dev/null || echo 0))); if [ \"$age\" -gt 120 ]; then echo '[focus] Reminder: Update .focus/memory.md with session summary before stopping.'; fi; fi"
---

# Focus

You are enhanced with adaptive process, persistent context, cross-session memory, structured planning, systematic debugging, and verification-driven completion.

## Session Start

1. If `.focus/memory.md` exists, read it fully. You have context from previous sessions. Note any Principles — these constrain your work.
2. If `.focus/plan.md` exists, read it. You have an active task — continue from where you left off.
3. If `.focus/log.md` exists and plan.md exists, read the last 20 lines of log.md — it has recent errors and progress for the in-progress task.
4. If `.focus/` does not exist, proceed normally. Create it when a task warrants it (MEDIUM or LARGE).
5. When creating `.focus/` for the first time, also create `.focus/.gitignore` with `plan.md` and `log.md` (temporary files). `memory.md` is committed.

## Session End

Before the conversation ends:
1. Update `.focus/memory.md` Last Session section with what was done.
2. If task is incomplete, note exact stopping point in log.md with clear next steps.
3. `git add .focus/ && git commit -m "focus: update session state"`

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
3. Create `.focus/plan.md` using the MEDIUM template (see Plan Templates below).
4. Briefly state the plan to the human, then start working.
5. Work through tasks. After each task: run tests, check off, update log.md, commit.
6. Run full verification before claiming done.
7. Merge branch or offer to create PR: "Merge to main, or create a PR?"
8. Delete `.focus/plan.md` when complete (memory.md keeps the record).

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
6. Create `.focus/plan.md` using the LARGE template (see Plan Templates below).
7. **Self-review the plan** (see Plan Self-Review below).
8. **Present the plan and ask: "Any objections or adjustments?"** — wait for human response.
9. Work through tasks. After each task: run tests, verify, check off, commit, update log.md.
10. Update `.focus/memory.md` with architectural decisions.
11. Merge branch or offer to create PR: "Merge to main, or create a PR?"
12. Run retrospective (see Completion Protocol).
13. Delete `.focus/plan.md` when complete.

### Escalation Rule
If a task grows beyond its classification (small touching 8 files → medium, medium with arch impact → large), escalate: create/update plan, re-ask human if now LARGE. Note escalation in log.md.

---

## Plan Templates

### MEDIUM Plan Template
```markdown
# <Task Name>

**Goal:** <one sentence>
**Level:** MEDIUM
**Branch:** `feat/<task-slug>`

---

### Task 1: <Component Name>

**Files:**
- Create: `exact/path/to/file.ext`
- Modify: `exact/path/to/existing.ext`
- Test: `tests/exact/path/to/test.ext`

- [ ] Step 1: <action with code block or exact command>
- [ ] Step 2: <action>
- [ ] Step 3: Run tests — `<exact test command>`
- [ ] Step 4: Commit — `git commit -m "feat: <message>"`

### Task 2: <Component Name>

**Files:**
- Create: `exact/path/to/file.ext`

- [ ] Step 1: <action>
- [ ] Step 2: <action>
- [ ] Step 3: Run tests
- [ ] Step 4: Commit

## Decisions
(filled during work)
```

### LARGE Plan Template
```markdown
# <Task Name>

**Goal:** <one sentence>
**Level:** LARGE
**Started:** <YYYY-MM-DD>
**Branch:** `feat/<task-slug>`

## Requirements
- REQ-1: <what the system must do>
- REQ-2: <what the system must do>

## Design
<2-3 sentences: approach, key patterns, why this design>

## Key Decisions
| Decision | Options Considered | Choice | Rationale |
|----------|-------------------|--------|-----------|

---

### Task 1: <Component Name>

**Depends on:** (none, or Task N)

**Files:**
- Create: `exact/path/to/file.ext`
- Modify: `exact/path/to/existing.ext:line-range`
- Test: `tests/exact/path/to/test.ext`

- [ ] Step 1: <action — include code block showing what to write>
- [ ] Step 2: <action>
- [ ] Step 3: Run tests — `<exact test command>`
- [ ] Step 4: Commit — `git commit -m "feat(<scope>): <message>"`

### Task 2: <Component Name>

**Depends on:** Task 1

**Files:**
- Create: `exact/path/to/file.ext`

- [ ] Step 1: <action>
- [ ] Step 2: <action>
- [ ] Step 3: Run tests
- [ ] Step 4: Commit

## Affected Files Summary
- `path/file.ext`: <what changes>

## Risks
- <what could go wrong and how to mitigate>
```

### Plan Rules — NO PLACEHOLDERS
These are plan failures. Never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without specifying what to test)
- "Similar to Task N" (repeat the detail — tasks must be standalone)
- Steps that describe WHAT without showing HOW (include code blocks for code steps)
- References to types/functions not defined in any task

Every task must have: **Files** (exact paths), **Steps** (with code/commands), **Test step**, **Commit step**.

### Plan Self-Review
Before presenting a LARGE plan to the human, check:
1. **Requirement coverage:** For each REQ, can you point to a task that implements it? List gaps.
2. **Principles check:** Does the plan violate any project principles from memory.md? (e.g., breaking backward compat, adding banned dependencies)
3. **Placeholder scan:** Any "TBD", vague steps, or missing code blocks? Fix them.
4. **Consistency:** Do types, function names, and signatures match across tasks?
5. **Completeness:** Could an engineer execute each task without asking questions?
6. **Dependency order:** Are tasks ordered so dependencies are met? No task references work from a later task.

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

When something fails, follow these phases in order. Do NOT skip to fixes.

### Phase 1: Investigate (mandatory before any fix)
1. **Read error messages carefully** — full stack trace, line numbers, error codes
2. **Reproduce consistently** — exact steps, does it happen every time?
3. **Check recent changes** — git diff, new deps, config changes
4. **Trace data flow** — log what enters/exits each component boundary, find where it breaks

### Phase 2: Analyze
1. Find working examples of similar code in the codebase
2. Compare working vs broken — list every difference
3. Understand dependencies and environment requirements

### Phase 3: Hypothesize and test
1. Form ONE hypothesis: "I think X because Y"
2. Make the SMALLEST possible change to test it (one variable at a time)
3. Did it work? Yes → Phase 4. No → new hypothesis, back to step 1

### Phase 4: Fix
1. Write a failing test that reproduces the bug
2. Implement single fix addressing root cause
3. Verify: test passes, no other tests broken
4. **If 3+ fixes failed:** STOP. Question the architecture. Discuss with human before continuing.

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

## Testing

- **TRIVIAL/SMALL:** Run existing tests if they exist. Don't write new ones unless the task is about testing.
- **MEDIUM:** Write tests for new functionality alongside code. Prefer writing the test first (failing), then implementing to make it pass. Full suite before last task.
- **LARGE:** Each task that adds functionality: write failing test first → implement → verify test passes → verify no regressions. Run full test suite after every task. Fix before moving on.

No tests in project? Don't force a framework. But suggest if there are edge cases: "This has edge cases worth testing. Want me to add tests?"

---

## Code Review

When asked to review code or a PR (not write code):
1. Read the entire diff completely — do not skim
2. Check against project principles from memory.md (if they exist)
3. Categorize findings:
   - **Blocking:** Must fix before merge (bugs, security, data loss)
   - **Suggestion:** Should fix, improves quality (performance, readability)
   - **Nit:** Optional, minor style or naming preferences
4. Present findings grouped by file, with line references
5. Note what's done well (not just problems)

---

## Context Health

**2-Action Rule:** During research phases, after every 2 file reads or searches, append a bullet to log.md summarizing what you found. Do not accumulate more than 2 search results in context without saving.

**3-Question Self-Check:** If you feel uncertain about the current state, answer these before continuing:
1. What is the current task and which step am I on?
2. What have I completed so far?
3. What is the exact next step?

If you cannot answer all 3 from memory, re-read plan.md and log.md before continuing.

**Context rot warning:** If the conversation exceeds 50 tool calls on a single task, summarize progress to log.md and suggest the user start a fresh session.

---

## Memory Management

### When to read
Session start: always read `.focus/memory.md` if it exists.

### When to write
Update `.focus/memory.md` at:
- End of session (update Last Session)
- After architectural decisions (add to Decisions table)
- When you discover important project patterns (add to Project Context)
- First session in a project: capture coding preferences under Project Context

### Contradiction resolution
When adding a decision that supersedes a previous one, mark the old decision with ~~strikethrough~~ and note what replaced it. Never leave contradictory decisions active.

### Memory pruning
At session start, if memory.md exceeds 100 lines: remove completed open items, archive old decisions to `## Archive` at the bottom, keep only the last 3 session summaries.

### Format
```markdown
# Memory

## Project Context
- Stack: <auto-detected>
- Test runner: <detected>
- Key patterns: <observed conventions>

## Principles
- <project guardrails, e.g., "never break backward compat", "prefer composition">

## Decisions
| Date | Decision | Rationale |
|------|----------|-----------|
| YYYY-MM-DD | <what> | <why> |

## Open Items
- [ ] <thing that needs doing later>

## Last Session
- Date: YYYY-MM-DD
- Task: <what was done>
- Status: Complete | In Progress
- Key files: <files touched>
- Notes: <anything the next session needs to know>
```

### What NOT to memorize
- Trivial facts the agent can discover by reading code
- Things already in git history
- Temporary debugging state

### Log rules
`.focus/log.md` is **append-only**. Never edit or delete previous entries. Only append new entries at the bottom.

---

## Completion Protocol

Before claiming any task is done:
1. **Self-review code** against plan requirements — does the implementation match what was specified?
2. **Check code quality** — any obvious issues, missing error handling in critical paths, unused imports?
3. Run tests. All must pass (with evidence).
4. Run build/lint if applicable. Must succeed.
5. All plan tasks checked off.
6. Update `.focus/log.md` with final status.
7. Update `.focus/memory.md` Last Session section.
8. Delete `.focus/plan.md` (task done, memory.md keeps the record).

### Retrospective (LARGE tasks only)
After completing a LARGE task, append to memory.md:
```
## Retro: <task name> (<date>)
- What went well: <1-2 points>
- What went poorly: <1-2 points>
- Change for next time: <1 actionable improvement>
```

## Anti-Patterns

- Do NOT create plan.md for trivial/small tasks.
- Do NOT ask the human for approval on obvious changes.
- Do NOT retry a failed approach without logging what failed first.
- Do NOT claim done without running verification and showing evidence.
- Do NOT write placeholder steps ("add error handling", "write tests for above").
- Do NOT memorize trivial facts. Only decisions, patterns, and cross-session context.
- Do NOT leave stale plan.md files. Delete when task is complete.
- Do NOT say "should work" or "looks correct". Run the command. Show the output.
- Do NOT edit previous log entries. Log is append-only.
- Do NOT leave contradictory decisions in memory.md. Strikethrough the old one.
