# Systematic Debugging

Load this file when a task's `Verify:` fails, when tests regress, or when behavior does not match expectations. SKILL.md's inline Failure Handling (log before retry / 3-strikes / rollback) is always in effect; this file is the deeper procedure for the investigation itself — read it when you cannot state a specific hypothesis for why something broke.

---

When something fails, follow these phases in order. Do NOT skip to fixes.

## Phase 1: Investigate (mandatory before any fix)
1. **Read error messages carefully** — full stack trace, line numbers, error codes.
2. **Reproduce consistently** — exact steps, does it happen every time?
3. **Check recent changes** — `git diff`, new deps, config changes.
4. **Trace data flow** — log what enters/exits each component boundary, find where it breaks.

## Phase 2: Analyze
1. Find working examples of similar code in the codebase.
2. Compare working vs broken — list every difference.
3. Understand dependencies and environment requirements.

## Phase 3: Hypothesize and test
1. Form ONE hypothesis: "I think X because Y".
2. Make the SMALLEST possible change to test it (one variable at a time).
3. Did it work? Yes → Phase 4. No → new hypothesis, back to step 1.

## Phase 4: Fix
1. Write a failing test that reproduces the bug.
2. Implement a single fix addressing the root cause.
3. Verify: test passes, no other tests broken.
4. **If 3+ fixes failed:** STOP. Question the architecture. Discuss with human before continuing.

---

## Anti-patterns while debugging

- Do not change multiple variables in one step — you cannot attribute the outcome.
- Do not "fix it and see" without a hypothesis — that is guessing, not debugging.
- Do not skip reproducing the bug first; a fix for something you can't reproduce can't be verified.
- Do not silence a symptom to make the test pass (catch-and-ignore, flag-off). Root cause or ask the human.
