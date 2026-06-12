# Memory Management — Details

Load this file when writing to `.focus/memory.md` or `.focus/journal/*.md` at session end, or when migrating a legacy `## Last Session` section. SKILL.md has the one-paragraph summary of the split; this file has the full format, rules, and migration procedure.

---

Focus splits persistent memory into two kinds on purpose:

| File | Kind | Content | Mutation |
|------|------|---------|----------|
| `memory.md` | **Mutable state** — what is currently true | Principles, Decisions (active), Project Context, Open Items | Edited in place; old decisions struck through |
| `journal/YYYY-MM-DD.md` | **Immutable narrative** — what happened | Per-session summaries, retrospectives, observations | Append-only; never edited |

Why the split: mixing the two corrupts both. When "what happened in 2026-01-14" lives next to "what is currently true about auth", future agents can't tell which bullets are still load-bearing. Separating them means `memory.md` stays small and authoritative; the journal stays rich and historical.

## memory.md

### When to read
Session start: always, if it exists.

### When to write
- After architectural decisions (add to Decisions table — with date).
- When you discover important project patterns (add to Project Context).
- When the user states a guardrail (add to Principles).
- First session in a project: capture coding preferences under Project Context.
- Resolved open items: strike through, don't delete (so future sessions see it was once an open item).

### Contradiction resolution
When adding a decision that supersedes a previous one, mark the old decision with ~~strikethrough~~ and note what replaced it. Never leave contradictory decisions active.

### Pruning
At session start, if memory.md exceeds 150 lines: archive old decisions (>6 months and not referenced by any Principle) to `## Archive` at the bottom; remove resolved open items that have been struck through for >30 days.

### Format
```markdown
# Memory

## Project Context
- Stack: <auto-detected>
- Test runner: <detected>
- Key patterns: <observed conventions>

## Principles
- <project guardrails, using MUST / MUST NOT / PREFER / AVOID keywords>

## Decisions
| Date | Decision | Rationale |
|------|----------|-----------|
| YYYY-MM-DD | <what> | <why> |

## Open Items
- [ ] <thing that needs doing later>
```

Note: there is no `## Last Session` section in the new format. Session narrative lives in `journal/`.

### What NOT to put in memory.md
- Trivial facts the agent can discover by reading code.
- Things already in git history.
- Temporary debugging state.
- Per-session summaries — those go in journal/.
- "What I did today" — that goes in journal/.
- Stable project conventions every agent/session needs — those belong in CLAUDE.md (see below).

## memory.md vs CLAUDE.md

Both persist across sessions; they answer different questions.

| | CLAUDE.md | .focus/memory.md |
|---|---|---|
| Audience | Every Claude session in this repo, Focus or not | Focus's process state |
| Content | Stable conventions: build/test commands, architecture map, directory guide, code style | Decisions with rationale, principles, open items, evolving context |
| Loaded | Automatically, every session | By Focus at session start |
| Shape | Lean and layered (root for the big picture, subdirectory CLAUDE.md for local conventions) | Small and authoritative; pruned per the rules above |

**Promotion rule:** when a `Project Context` bullet stabilizes into something any agent needs ("tests run with `pnpm vitest`", "API handlers live in `src/routes/`"), move it to CLAUDE.md and delete it here. memory.md holds what is still in motion; CLAUDE.md holds what has settled.

**Navigation friction is a signal:** if research kept stumbling — wrong directory guesses, repeated greps for the same thing, misunderstood module boundaries — the fix is usually a CLAUDE.md line or a short codebase map, not a memory.md note. The LARGE retrospective asks this explicitly.

## journal/

### Format
One file per UTC date: `.focus/journal/YYYY-MM-DD.md`. Append-only. Never edit previous entries; only add new ones at the bottom of today's file.

Template for a session entry:
```markdown
## <HH:MM> — <one-line session summary>

- **Task:** <what was attempted> (<TRIVIAL|SMALL|MEDIUM|LARGE>)
- **Status:** <Complete | In Progress | Abandoned>
- **Files:** <touched>
- **Key decisions:** <any decisions worth remembering — also mirror to memory.md Decisions>
- **Notes:** <anything the next session needs to know; questions that surfaced; surprises>
```

LARGE retrospectives also go here:
```markdown
## Retro: <task name> (<date>)
- What went well: <1-2 points>
- What went poorly: <1-2 points>
- Change for next time: <1 actionable improvement>
```

### Rules
- One file per day. Append to today's file; never modify yesterday's.
- When reading on session start, read the **two most recent** files — usually sufficient for "what was the last thing".
- Journal is committed to git. The full history is the point.
- If today's file doesn't exist, create it with just the heading `# Journal — YYYY-MM-DD` then append the entry.

### Legacy migration
If an existing `memory.md` has a `## Last Session` section, on first session after upgrading:
1. Take the date from that section (or today if absent).
2. Append the section content to `journal/<that-date>.md` under a `## <HH:MM> — legacy entry` heading.
3. Delete the `## Last Session` section from `memory.md`.
4. Commit: `focus: migrate Last Session to journal/`.

## Log rules
`.focus/log.md` is **append-only**. Never edit or delete previous entries. Only append new entries at the bottom. Log is for the *active task*; when plan.md is deleted at task completion, log.md is deleted with it. Journal is what survives.
