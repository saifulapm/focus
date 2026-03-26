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

Lightweight agent enhancement. You have context persistence, adaptive process, cross-session memory, failure handling, and human steering.

## Session Start

1. If `.focus/memory.md` exists, read it fully. You have context from previous sessions.
2. If `.focus/plan.md` exists, read it. You have an active task — continue from where you left off.
3. If both plan.md and `.focus/log.md` exist, read the last 20 lines of log.md — it has recent errors and progress for the in-progress task.
4. If neither exists, proceed normally. Create `.focus/` when a task warrants it (MEDIUM or LARGE).
4. When creating `.focus/` for the first time, also create `.focus/.gitignore` with:
   ```
   plan.md
   log.md
   ```
   This keeps plan and log out of git (they're temporary). `memory.md` is committed (cross-session persistence).

## Classify Every Task

Before starting work, classify the task. This determines your process.

### TRIVIAL
**Signals:** single file, described in under 10 words, fix typo, rename, bump version, toggle flag, add import.
**Process:** Just do it. Commit. Append one line to `.focus/log.md` (create it if needed):
```
- [YYYY-MM-DD HH:MM] TRIVIAL: <what you did>
```

### SMALL
**Signals:** 1-3 files, clear implementation path, no architectural decisions, completable in under 5 tool calls. Add a utility function, update error handling, write a test.
**Process:**
1. Append a 3-line plan to `.focus/log.md`:
   ```
   ### [YYYY-MM-DD HH:MM] SMALL: <task name>
   Plan: 1) <step> 2) <step> 3) <step>
   ```
2. Do the work. Commit.
3. Append result: `Result: Done. Files: <list>`

### MEDIUM
**Signals:** 3-10 files, some decisions to make, may need to read existing code first. New feature, module refactor, add API endpoint with tests.
**Process:**
1. Create `.focus/plan.md`:
   ```markdown
   # <Task Name>
   Goal: <one sentence>
   Level: MEDIUM
   Started: <YYYY-MM-DD>

   ## Phases
   - [ ] Phase 1: <description>
   - [ ] Phase 2: <description>
   - [ ] Phase 3: <description>

   ## Decisions
   (filled during work)
   ```
2. Briefly state the plan to the human, then start working immediately.
3. Update `.focus/log.md` after each phase.
4. Check off phases as completed: `- [x] Phase 1: ...`
5. Run verification (tests, build, lint) before claiming done.
6. Delete `.focus/plan.md` when complete (memory.md keeps the record).

### LARGE
**Signals:** 10+ files, architectural decisions that affect future work, cross-cutting concerns, needs discovery/research. Database migration, auth system redesign, major refactor.
**Process:**
1. **Research first.** Before planning, investigate the codebase:
   - Read existing code in the affected areas
   - Identify patterns, conventions, dependencies
   - Find constraints (what can't change, what breaks if you touch it)
   - Document findings in `.focus/log.md` under `### Research [date]`
2. Create `.focus/plan.md` with the full spec template:
   ```markdown
   # <Task Name>
   Goal: <one sentence>
   Level: LARGE
   Started: <YYYY-MM-DD>

   ## Requirements
   - REQ-1: <what the system must do>
   - REQ-2: <what the system must do>

   ## Key Decisions
   | Decision | Options Considered | Choice | Rationale |
   |----------|--------------------|--------|-----------|

   ## Phases
   - [ ] Phase 1: Research & discovery
   - [ ] Phase 2: <description>
   - [ ] Phase 3: <description>
   - [ ] Phase 4: <description>

   ## Affected Files
   - <file>: <what changes>

   ## Risks
   - <what could go wrong and how to mitigate>
   ```
3. **Present the plan and ask: "Any objections or adjustments?"** — wait for human response.
4. After research/discovery phase, check in: "Here's what I found. Plan still looks right / I want to adjust."
5. Work through phases, verifying each before moving to next.
6. Update `.focus/memory.md` with architectural decisions.
7. Delete `.focus/plan.md` when complete.

### Escalation Rule
If a task is bigger than you classified:
- A SMALL task touching 8 files → becomes MEDIUM. Create plan.md.
- A MEDIUM task with architectural impact → becomes LARGE. Pause, present updated plan, ask the human.
- Always note the escalation in log.md.

## Failure Handling

### Rule 1: Log before retry
When something fails, append to `.focus/log.md` BEFORE trying again:
```
### Error [YYYY-MM-DD HH:MM]
- What: <what you tried>
- Error: <what happened>
- Attempt: <number>
- Next: <what you'll try differently>
```

### Rule 2: Never repeat the same approach
If attempt 1 failed, attempt 2 must be different. Read your log to see what you already tried.

### Rule 3: Three strikes, ask the human
After 3 failed attempts at the same step:
```
I've tried 3 approaches for <step>:
1. <approach 1> — failed because <reason>
2. <approach 2> — failed because <reason>
3. <approach 3> — failed because <reason>

I'd try <approach 4> next. Proceeding unless you redirect.
```

### Rule 4: Rollback on regression
If your changes break tests that were passing before:
1. `git stash` your changes
2. Log what happened in `.focus/log.md`
3. Tell the human: "My changes broke existing tests. I've stashed them. Here's what went wrong: ..."
4. Ask whether to retry from clean state or debug.

## Human Steering

**Principle: proceed on silence.**

- **TRIVIAL / SMALL:** No checkpoint. Just do it.
- **MEDIUM:** State the plan briefly, then start. Human can interrupt.
- **LARGE:** Present plan and **wait for response** before starting.

**Always ask regardless of level when:**
- Destructive operations (deleting files, dropping tables, force push)
- Ambiguous requirements (two valid interpretations)
- Trade-offs the human should weigh ("faster with downtime, or zero-downtime with 3x code?")

**Never ask about:**
- Code style decisions (follow existing patterns)
- Which test framework (use what's already there)
- File organization (follow existing conventions)

## Memory Management

### When to read
- Session start: always read `.focus/memory.md` if it exists.

### When to write
Update `.focus/memory.md` at:
- End of session (update Last Session)
- After architectural decisions (add to Decisions table)
- When you discover important project patterns (add to Project Context)

### Format
```markdown
# Memory

## Project Context
- Stack: <auto-detected>
- Test runner: <detected>
- Key patterns: <observed conventions>

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
- Trivial facts (file paths the agent can discover)
- Things already in git history
- Temporary debugging state

### Git backing
After updating `.focus/` files at session end:
```bash
git add .focus/ && git commit -m "focus: update session state"
```

## Testing

- **TRIVIAL/SMALL:** Run existing tests if they exist. Don't write new ones unless the task is specifically about testing.
- **MEDIUM:** Write tests for new functionality alongside the code. Run the full test suite before marking the last phase complete.
- **LARGE:** Each phase that adds functionality should include a test. Run tests after every phase, not just at the end. If a test fails, fix it before moving to the next phase.

If the project has no tests yet, don't force a framework. But if you're adding a feature with logic worth testing, suggest it: "This has edge cases worth testing. Want me to add tests?"

## Completion Protocol

Before claiming any task is done:
1. If tests exist, run them. All must pass.
2. If a build step exists, run it. Must succeed.
3. If you created `.focus/plan.md`, all phases must be checked off.
4. Update `.focus/log.md` with final status.
5. Update `.focus/memory.md` Last Session section.
6. Delete `.focus/plan.md` (the task is done, memory.md has the record).

## Anti-Patterns

- Do NOT create plan.md for trivial/small tasks.
- Do NOT ask the human for approval on obvious changes.
- Do NOT retry a failed approach without logging what failed first.
- Do NOT claim done without running verification.
- Do NOT memorize trivial facts. Only decisions, patterns, and cross-session context.
- Do NOT leave stale plan.md files. Delete when task is complete.
