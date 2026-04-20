# Testing & Code Review

Load this file when writing tests for a MEDIUM/LARGE task, or when the user asks for a code review (not code changes). For TRIVIAL/SMALL tasks the inline testing rule in SKILL.md is sufficient.

---

## Testing

- **TRIVIAL/SMALL:** Run existing tests if they exist. Don't write new ones unless the task is about testing.
- **MEDIUM:** Write tests for new functionality alongside code. Prefer writing the test first (failing), then implementing to make it pass. Full suite before last task.
- **LARGE:** Each task that adds functionality: write failing test first → implement → verify test passes → verify no regressions. Run full test suite after every task. Fix before moving on.

**No tests in project?** Don't force a framework. But suggest if there are edge cases: *"This has edge cases worth testing. Want me to add tests?"*

**What counts as a test here:**
- A `Verify:` command in a task that runs an existing test suite counts.
- A test whose assertion is just "it compiles" or "exit 0 from build" is weak — prefer an assertion on observable behavior.
- A test written after the implementation without first seeing it fail is untrusted — re-run against a mutant (toggle the fix) to confirm it actually detects the bug.

---

## Code Review

When asked to review code or a PR (not write code):

1. **Read the entire diff** completely — do not skim.
2. **Check against principles** — load via `scripts/principles.sh`. Treat `MUST / MUST NOT` violations as Blocking.
3. **Categorize findings:**
   - **Blocking:** must fix before merge (bugs, security, data loss, `MUST/MUST NOT` principle violations)
   - **Suggestion:** should fix, improves quality (performance, readability, `PREFER/AVOID` violations without a justifying decision)
   - **Nit:** optional, minor style or naming preferences
4. **Present findings grouped by file, with line references.**
5. **Note what's done well** — not just problems. Calibrates the reviewer signal.
6. If a Focus plan is active (`.focus/plan.md`), **check the diff against the plan's Requirements** — scope creep is a legitimate review finding.

### Review anti-patterns

- Do not review the commit message as a substitute for the diff.
- Do not approve code you have not read end-to-end.
- Do not bury blockers in a list of nits — they should be called out at the top.
- Do not suggest rewrites that weren't asked for. The review question is "is this mergeable?", not "is this how I would have written it?"
