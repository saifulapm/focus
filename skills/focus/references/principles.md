# Principles Gate — Details

Load this file when adding, editing, or reviewing a principle, or when a plan's Self-Review reaches the principles check (item 6). SKILL.md's Principles summary has the load-bearing contract (where they live, the keyword scale, the three enforcement points, the never-silently-remove rule); this file is the full gate.

Principles are project-level constraints — "never break backward compat", "no new npm dependencies", "prefer composition over inheritance". They outlive any one task. Focus treats them as **first-class inputs to plan creation and evaluation**, not decoration.

## Where principles live

- `memory.md` `## Principles` section — primary home, always loaded.
- `.focus/principles.md` (optional) — separate file for larger projects that want principles isolated from project context. If present, it is **merged** with memory.md's section, not overriding it.

The `scripts/principles.sh` loader reads both and prints the merged set. `session-context.sh` and the Stop hook use this loader — principles surface consistently.

## Recommended format

Lead each principle with a strength keyword so both humans and evaluators can gauge it:

```markdown
## Principles
- **MUST NOT** add runtime npm dependencies without explicit approval.
- **MUST** keep public APIs backward-compatible through a full major version.
- **PREFER** composition over inheritance; inheritance requires a decision entry.
- **AVOID** tests that mock the database — use the test harness at `tests/db.ts`.
```

Plain bullets without keywords are fine too — Focus just loses the severity signal.

## When principles are surfaced

1. **Plan creation** (MEDIUM/LARGE): the session-context hook prints the Principles block before any tool call. Plan Self-Review explicitly checks for violations (item 6 in that list).
2. **Evaluator run**: the `/focus:evaluate` command loads principles via `principles.sh` and checks the diff against them — MUST/MUST NOT violations are blockers; PREFER/AVOID violations are issues requiring a justifying Decisions entry. The evaluator is the primary enforcement point.
3. **Before stop** (advisory): `check-complete.sh` reminds the generator principles are active if there are pending changes. One-line nudge, not enforcement.

## When principles change

Principles are added/edited in **memory.md** like any other state:
- New principle stated by user → append with the MUST / MUST NOT / PREFER keyword, add to memory.md during the session.
- Principle superseded → strikethrough the old line; add the new one with a decision entry explaining the change.
- Never silently edit or remove a principle: future sessions need to see the transition.

## What principles are NOT

- Not a replacement for code review — principles cover recurring project-wide constraints, not per-diff quality.
- Not a build-time gate — Focus will never block a commit because of a principle. The decision to override is always the human's; Focus just makes sure the decision is conscious.
- Not a dumping ground — 20 principles is too many for an agent to weigh. Aim for 3–7. Everything else is Project Context or a Decision.

## Anti-patterns

- Do **not** write principles that can't be checked against a diff ("write clean code"). Either make it specific enough to check, or put it in Project Context.
- Do **not** bury principles in prose inside Project Context — use the dedicated section so the loader finds them.
- Do **not** accept an evaluator PASS that ignored a principle violation. That's a calibration failure — flag it in log.md and fix the evaluator's next brief.
- Do **not** silently violate a principle "just this once". If the task requires it, add a decision entry saying so.
