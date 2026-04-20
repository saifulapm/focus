# Plan Templates & Self-Review

Load this file when creating or reviewing a `.focus/plan.md` (MEDIUM or LARGE). It is the detailed specification for the Atomic Task Schema, plan templates, clarification blockers, the no-placeholders rule, and the 9-item Plan Self-Review. SKILL.md references this file at the moments a plan is authored; nothing here is relevant until then.

---

Every task in a plan is **atomic**: one reviewer can execute it without asking questions, and one command can prove it worked.

## Atomic Task Schema (required structure for every task)

```markdown
### Task N: <short imperative name>

**Depends on:** (none, or Task M)
**Files:**
- Create: `exact/path/to/file.ext`
- Modify: `exact/path/to/existing.ext` (or `:line-range` if localized)
- Test: `tests/exact/path/to/test.ext`

**Action:**
<1-3 sentences describing the change, followed by code blocks showing exactly what to write. No prose substitutes for code.>

**Verify:** `<exact shell command that produces a pass/fail signal>`

**Done when:** <single observable criterion — e.g., "exit 0 and 24/24 tests pass", "GET /foo returns 200 with body matching schema X", "build succeeds and lint reports 0 errors">

**Commit:** `<conventional commit message>`

- [ ] Execute
- [ ] Verify passes
- [ ] Commit
```

The four required fields — **Action, Verify, Done when, Commit** — are what make the task atomic. A task missing any of them is not ready to execute. `Verify` must be a runnable command; `Done when` must be observable (not "it looks right"). One commit per task enables git-bisect recovery.

## MEDIUM Plan Template
```markdown
# <Task Name>

**Goal:** <one sentence>
**Level:** MEDIUM
**Branch:** `feat/<task-slug>`

## Requirements
- REQ-1: <what the system must do, phrased as an observable outcome>
- REQ-2: ...

---

<One or more atomic tasks using the schema above>

## Decisions
(filled during work)
```

## LARGE Plan Template
```markdown
# <Task Name>

**Goal:** <one sentence>
**Level:** LARGE
**Started:** <YYYY-MM-DD>
**Branch:** `feat/<task-slug>`

## Requirements
- REQ-1: <observable outcome>
- REQ-2: <observable outcome>

## Design
<2-3 sentences: approach, key patterns, why this design>

## Key Decisions
| Decision | Options Considered | Choice | Rationale |
|----------|-------------------|--------|-----------|

## Requirement → Task Map
| REQ | Covered by |
|-----|------------|
| REQ-1 | Task 1, Task 3 |

---

<Atomic tasks using the schema above, ordered by dependency>

## Affected Files Summary
- `path/file.ext`: <what changes>

## Risks
- <what could go wrong and how to mitigate>
```

## Clarification Blockers

If you do not have enough information to write any required field of a task, do **not** guess. Write:

```
[NEEDS CLARIFICATION: <exact question>]
```

inline where the unknown is. While any `[NEEDS CLARIFICATION]` marker exists in plan.md, execution is blocked. Ask the human all markers at once, then replace them before starting work.

## Plan Rules — NO PLACEHOLDERS
These are plan failures. Never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without specifying what to test)
- "Similar to Task N" (repeat the detail — tasks must be standalone)
- Steps that describe WHAT without showing HOW (include code blocks for code steps)
- References to types/functions not defined in any task
- `Verify:` that says "run tests" without the exact command
- `Done when:` that says "it works" or "looks correct" instead of an observable criterion

## Plan Self-Review
Before presenting a MEDIUM or LARGE plan to the human, check each item. Each failure is a plan defect — fix it before proceeding.

1. **Atomic schema:** Every task has **Files, Action, Verify, Done when, Commit**. No missing fields.
2. **Verify is runnable:** Every `Verify:` line is a shell command a human could paste — not a description.
3. **Done when is observable:** Every `Done when:` is a pass/fail signal, not a feeling.
4. **Requirement coverage:** For each REQ, point to the task(s) that implement it. List gaps. (LARGE: fill the Requirement → Task Map table.)
5. **No clarification blockers:** Zero `[NEEDS CLARIFICATION]` markers remain. If any exist, ask the human before presenting.
6. **Principles check:** Load the merged principles set (memory.md `## Principles` + optional `.focus/principles.md`). For each `MUST` / `MUST NOT` principle: does the plan clearly respect it? For each `PREFER` / `AVOID`: if the plan violates it, is there an explicit Decisions-table entry justifying the override? No silent overrides.
7. **Placeholder scan:** No "TBD", vague steps, or missing code blocks.
8. **Consistency:** Types, function names, and signatures match across tasks.
9. **Dependency order:** Tasks are ordered so dependencies are met. No task references work from a later task.
