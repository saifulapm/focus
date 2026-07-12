# Handoff Protocol

Load this file when you emit or resume a handoff — SKILL.md's Handoff summary has the trigger list and the read-once resume contract; this file has the full format, the emitting procedure, and the anti-patterns.

**Why this exists.** Context windows are finite. Evidence from long-running harnesses is consistent: context *resets* — starting a fresh agent from a written handoff — outperform in-place compaction, which quietly drops details and triggers "context anxiety" (the agent hurrying toward completion because it senses the window filling). Focus handles exhaustion by design: it writes a compact, machine-readable handoff block to `plan.md`, then the next agent reads that block instead of the dying conversation.

## When to emit a handoff

Emit a handoff whenever **any** of these hold:

- **Tool-call budget:** the PreToolUse hook counts calls in `.focus/.toolcount.<session>` and warns at 40+ since the last plan.md change. Heed the warning — you cannot count your own tool calls reliably. (If you simply forgot to check off completed tasks, do that instead; it resets the counter.) Note the counter resets per task — it cannot catch cumulative session bloat; that's what the session-block trigger below is for.
- **Session-block boundary (Track Mode):** the last task of a session block just completed — always emit, even with budget to spare (Track Mode rule 6). Checking off tasks resets the tool counter, so a diligent session never trips it; block boundaries are the cumulative cap that keeps a session under the ~100k budget (hard ceiling 120k).
- **Natural boundary:** a LARGE plan's top-level task has just completed **and its due evaluation has run** (evaluate first per the Evaluator Gate's adaptive cadence, then hand off — a handoff never substitutes for or defers an evaluation that is due at this boundary), or a Track Mode session block finished (rule 6 — its reason value is `boundary`). Even with budget left, a handoff here gives the next task a clean slate.
- **User request:** the user types `/focus:handoff` or says "hand off".
- **Self-detected drift:** the 3-Question Self-Check fails even after re-reading plan.md and log.md. Do not push through — hand off.
- **Evaluator FAIL:** after an evaluator returns FAIL with a plan-level revision required, write the handoff so the next session picks up from the corrected plan, not the exhausted one.

Do **not** emit a handoff on every task completion. Small tasks inside MEDIUM plans can chain — handoff only when context is actually taxed or a natural reset point arrives.

## Handoff artifact

The handoff lives **at the bottom of `plan.md`**, in a `## Handoff` section, replaced each time. One section only — do not accumulate handoff history (that's what log.md is for).

Format:

```markdown
## Handoff

**Emitted:** <YYYY-MM-DD HH:MM>  **Reason:** <budget | boundary | user | drift | evaluator-fail>

**Current task:** Task N — <name>
**Current step:** <which checkbox in the task's sub-list, e.g., "Verify passes">
**Branch:** `<branch name>`  **Last commit:** `<sha> <subject>`

**Done so far:**
- Task 1 — <name> — committed as `<sha>`
- Task 2 — <name> — committed as `<sha>`
- Task 3 up to step 2 of 4 — not yet committed

**Exact next action:**
<one paragraph. Include the exact command to run, file to edit, or question to ask the human. A fresh agent must be able to act on this without rereading anything but plan.md and log.md.>

**Files in play:**
- `path/to/file.ext` — <what is half-done here, if anything>

**Recent verification:**
- `<cmd>` → <exit code, summary>  (run at <time>)

**Open questions for the human:**
- <question 1, if any — otherwise omit this section>

**Principles still in force:**
- <copy from memory.md / principles.md — the subset actually relevant to the remaining work>

**What NOT to do:**
- <approaches already tried and failed; load this from log.md. Keeps the next agent from retrying the same path.>
```

## Emitting a handoff — procedure

1. **Stop current work.** Do not start a new tool call after deciding to hand off.
2. **Flush log.md.** If there are unsummarized search results or error notes in conversation memory that are not yet in log.md, append them now.
3. **Write the handoff block** to the bottom of plan.md using the format above. Replace any existing `## Handoff` section — only the latest handoff is kept.
4. **Commit:** `git add -f .focus/plan.md .focus/log.md && git commit -m "focus: handoff at task <N> — <reason>"`. The `-f` is required — Session Start step 6 gitignores plan.md/log.md, and this commit is the one sanctioned exception; without `-f` the add fails as an ignored path. The commit makes the handoff durable across session boundaries, including crashes — durability comes before the announcement. **Track Mode: skip this commit entirely** (rule 4) — push the branch; on a device switch (or the user's request), commit the handoff block to `docs/plan/handoffs/<branch-slug>.md` on the work branch instead.
5. **Tell the user, verbatim** (adjust "committed" to "pushed" in Track Mode):
   ```
   Handoff written to .focus/plan.md (§Handoff) and committed.
   Recommend: /clear, then start a fresh session. The new agent will read the handoff and continue from the Exact next action.
   ```

## Resuming from a handoff

At session start, when `.focus/plan.md` exists:

1. **Read the `## Handoff` section first** — if present, it is your ground truth. Trust it over any other cue.
2. **Archive it immediately** — append the handoff block to log.md under `### Consumed handoff <YYYY-MM-DD HH:MM>`, then delete the `## Handoff` section from plan.md. A handoff is read-once: leaving it in plan.md makes the hooks keep re-injecting stale resume state for the rest of the session.
3. Read the rest of plan.md (Requirements, Design, task list) to understand the full scope.
4. Read the last ~20 lines of log.md — specifically for the "what NOT to do" items the handoff references.
5. Begin work at the **Exact next action**. Do not re-derive state from scratch. Do not re-verify tasks already marked with a commit sha in "Done so far" — trust the handoff.
6. If the handoff's Exact next action is unclear or impossible (e.g., a file it references doesn't exist), stop and ask the user. A handoff that won't execute is a bug in the previous session, not something to paper over.

## Anti-patterns

- Do **not** emit a handoff without a next-action sentence a fresh agent can execute literally. "Continue the refactor" is not a next action; "Edit `src/auth.ts` at line 42 — replace `validateToken` with `verifyJwt` per Task 3" is.
- Do **not** skip the commit (outside Track Mode, where rule 4 replaces it with a pushed branch / handoff file). An uncommitted handoff vanishes if the session crashes.
- Do **not** accumulate handoff history in plan.md. Only the current handoff; log.md keeps the trail.
- Do **not** resume a handoff while the previous context is still loaded. The whole point is a fresh start — use `/clear` or a new session.
- Do **not** leave a consumed handoff in plan.md. Archiving it to log.md is your first action after reading it — otherwise hooks re-inject it on every cycle.
- Do **not** leave a handoff in place after completing the plan. Delete plan.md (and with it the handoff) as part of the Completion Protocol.
