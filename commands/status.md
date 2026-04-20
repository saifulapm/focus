---
name: focus:status
description: "Show current Focus state — active plan, recent log entries, and memory summary."
user-invocable: true
---

Show the current Focus state for this project. Do the following:

1. **Plan status**: If `.focus/plan.md` exists, read it and show:
   - The goal and level (MEDIUM | LARGE)
   - Which tasks are done (checked) vs remaining (unchecked)
   - Whether a `## Handoff` section exists (ground truth for resuming)
   - Any `[NEEDS CLARIFICATION]` blockers

2. **Recent activity**: If `.focus/log.md` exists, show the last 10 entries (active-task trail).

3. **Memory (current state)**: If `.focus/memory.md` exists, show:
   - Principles
   - Open items (unchecked only)
   - Count of decisions in the Decisions table

4. **Journal (recent narrative)**: If `.focus/journal/` exists, list the three most recent entry files and show the last session summary from the newest file.

5. **No Focus**: If `.focus/` doesn't exist, say "No Focus state in this project. Focus will activate automatically when a MEDIUM or LARGE task is started."

Format the output cleanly. Be concise. Do not dump full file contents — summaries only.
