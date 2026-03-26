---
name: focus:status
description: "Show current Focus state — active plan, recent log entries, and memory summary."
user-invocable: true
---

Show the current Focus state for this project. Do the following:

1. **Plan status**: If `.focus/plan.md` exists, read it and show:
   - The goal
   - Which phases are done (checked) vs remaining (unchecked)
   - Any decisions made

2. **Recent activity**: If `.focus/log.md` exists, show the last 10 entries.

3. **Memory**: If `.focus/memory.md` exists, show:
   - Project context (stack, patterns)
   - Open items
   - Last session summary

4. **No Focus**: If `.focus/` doesn't exist, say "No Focus state in this project. Focus will activate automatically when a MEDIUM or LARGE task is started."

Format the output cleanly. Be concise.
