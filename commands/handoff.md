---
name: focus:handoff
description: "Emit a handoff block so a fresh session can resume cleanly. Use when context is near its limit, at natural boundaries, or when drift is detected."
user-invocable: true
---

Emit a Focus handoff per the Handoff Protocol in the focus skill.

Procedure:

1. **Verify an active plan exists.** If `.focus/plan.md` does not exist, tell the user "No active plan — nothing to hand off. Handoffs are only meaningful for MEDIUM or LARGE tasks." and stop.

2. **Flush log.md.** Append anything material from the current conversation that is not yet in log.md: recent errors, search findings, decisions, attempts that failed. Log is append-only — add new entries at the bottom.

3. **Write the `## Handoff` section at the bottom of `.focus/plan.md`**, replacing any existing handoff. Use the exact format from the focus skill's Handoff Protocol. Required fields:
   - Emitted timestamp + reason (budget | boundary | user | drift | evaluator-fail)
   - Current task and step (with file-path context)
   - Branch and last commit sha/subject
   - Done so far (bullets with commit shas)
   - **Exact next action** — a sentence a fresh agent can execute literally. Include the exact command, file, or question. If you cannot state it precisely, that is itself the next action ("ask human: X").
   - Files in play
   - Recent verification (last `Verify:` command + result)
   - Open questions for the human (omit if none)
   - Principles still in force (copy the subset from memory.md actually relevant to the remaining work)
   - What NOT to do (approaches already tried and failed, mined from log.md)

4. **Commit.** Run:
   ```
   git add .focus/plan.md .focus/log.md
   git commit -m "focus: handoff at task <N> — <reason>"
   ```
   The commit is essential — without it the handoff vanishes if the session crashes.

5. **Tell the user, verbatim:**
   ```
   Handoff written to .focus/plan.md (§Handoff) and committed.
   Recommend: /clear, then start a fresh session. The new agent will read the handoff and continue from the Exact next action.
   ```

6. **Stop.** Do not start new work. The next agent does that.

## Quality check before committing

Read your own handoff once. If a fresh agent with no conversation history would be unable to act on the "Exact next action" field, rewrite it until they could. This is the single most important field — everything else is context for it.
