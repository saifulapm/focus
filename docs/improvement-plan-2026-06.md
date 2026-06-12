# Focus — Review & Improvement Plan (2026-06-12)

Sources: full read of Focus v2 (SKILL.md 449 lines, 4 references, 4 runtime scripts + installer, 3 commands), the Anthropic article "How Claude Code works in large codebases", and deep analysis of all 7 reference projects in `resources/` (planning-with-files, agent-kernel, BMAD-METHOD, spec-kit, superpowers, get-shit-done, agent-skills).

---

## Verdict

Focus's four pillars — adaptive ceremony, evaluator gate, handoff protocol, memory split — are validated by every reference project and the article. Nothing in the field does adaptive ceremony better. The biggest problems are **context economy** (the hooks inject far more repeated text than a "focus" tool should) and a **missing pillar**: Focus never uses subagents for research/exploration, which is the article's single biggest lever for large codebases — and the root cause of the context exhaustion that Focus's handoff protocol then has to fix.

---

## What Focus already gets right (keep, don't touch)

| Focus feature | Validated by |
|---|---|
| Adaptive ceremony (TRIVIAL→LARGE + escalation) | Unique. BMAD's quick-dev is the only analog; nobody scales ceremony this cleanly |
| Evaluator gate: fresh adversarial sub-agent, goal-backward, Exists/Substantive/Wired | GSD's verifier (best-in-class), superpowers' two-stage review, Anthropic's "generators grade themselves" finding |
| Handoff > compaction, committed to git | Anthropic article; stronger than GSD's `.continue-here.md` (which loses uncommitted work) |
| memory.md (state) vs journal/ (narrative) split | agent-kernel's knowledge/ vs notes/ — same conclusion reached independently |
| Principles with MUST/PREFER severity keywords | spec-kit's constitution, at a fraction of the weight |
| Atomic Task Schema + no-placeholders rule | superpowers' writing-plans, spec-kit's tasks |
| Anti-pattern lists naming rationalizations | superpowers' anti-rationalization tables (their most powerful mechanism) |
| 449-line SKILL.md + on-demand references | Article: progressive disclosure; "too much context degrades performance" |
| Pure markdown + shell, zero deps | agent-kernel philosophy |

---

## Mistakes & gaps (prioritized)

### P0 — Context economy (the irony: Focus pollutes context)

**1. PreToolUse hook fires on every tool call, including Read/Glob/Grep.**
`plan-tail.sh` injects up to 20 lines (or the entire `## Handoff` block — 40+ lines) before *every* matched tool call. A research phase with 30 reads injects ~600 duplicate lines. This is the planning-with-files v1 design that their v3 explicitly retired for strong models ("drops per-tool-call plan re-injection; injects at session start and phase transitions only"). The article's core warning: too much context degrades performance.
- Fix: narrow matcher to `Write|Edit|Bash`. Throttle: keep a counter in `.focus/.toolcount` and inject only every Nth call, or when `plan.md` mtime changed since last injection.
- Fix: inject the **goal + current unchecked task**, not `head -20` (which shows stale completed tasks once work progresses).

**2. Handoff block re-injected forever after resumption.**
Once a handoff exists, every tool call dumps it. The handoff is a read-once artifact. Fix: after the resuming agent internalizes it, move it to log.md (delete from plan.md) as the first resumption step; or inject only on the first call of a session.

**3. `session-context.sh` nags on every prompt in every project.**
The `[focus] IMPORTANT: Invoke the focus skill...` line prints on every UserPromptSubmit even when `.focus/` doesn't exist and even for non-coding questions. Fix: print the reminder only when `.focus/` exists or stay silent — the skill's `description:` already handles discovery. Everything else in the script is already properly guarded.

**4. The 2-Action Rule is tuned for weaker models.**
Flushing to log.md after every 2 reads constantly interrupts flow. This is exactly the article's "instructions that helped earlier models may constrain newer ones." Fix: relax to "at the end of each research question / every ~5 reads", or make it moot via P1-5 below. Add the article's "review config every 3–6 months" as a standing open item in memory.md.

### P1 — The missing pillar: subagents for context isolation

**5. LARGE research runs in the main context.**
The article's flagship pattern: *read-only subagent maps the subsystem, writes findings to a file, main agent reads conclusions only.* GSD's orchestrator keeps ~15% budget and gives subagents 100% fresh context. Focus instead burns main-window context on research and then needs handoffs to recover. Fix: LARGE step 3 (and optionally MEDIUM step 1) should dispatch Explore/Task subagents that write findings to `.focus/log.md` under `### Research`; the main agent never holds raw file dumps. This is the single highest-leverage change — it attacks the cause that the Handoff Protocol treats.

**6. No codebase-legibility guidance (CLAUDE.md).**
The article spends a third of its length on making codebases legible (lean layered CLAUDE.md, ignore files, codebase maps, scoped test commands). Focus says nothing, and `memory.md ## Project Context` quietly overlaps CLAUDE.md's role. Fix: (a) document the boundary — CLAUDE.md = conventions for *every* agent/session; memory.md = Focus state (decisions, open items, principles); (b) LARGE retro asks "did navigation friction suggest a CLAUDE.md update?"; (c) optionally a small reference file on legibility.

**7. Evaluator invocation is fragile.**
SKILL.md tells the generator to instruct the sub-agent: "Run the `/focus:evaluate` command" — but spawned sub-agents don't resolve slash commands. Fix: instruct it to **Read** `~/.claude/commands/focus/evaluate.md` (or `$CLAUDE_PLUGIN_ROOT` path) and follow it. One-line wording fix; prevents the evaluator silently freelancing its own procedure.

### P2 — Reliability & enforcement

**8. The ~40-tool-call handoff trigger is unmeasurable.** Agents can't count their own tool calls. Fix: `plan-tail.sh` already runs per tool call — have it increment `.focus/.toolcount` and emit one line at threshold: `[focus] 40+ tool calls on this plan — consider /focus:handoff`. Reset on handoff/plan creation. (planning-with-files proves hooks-as-counters works.)

**9. Opt-in gated stop.** Focus's "never block" stance is right as a default, but planning-with-files' gated mode (Stop hook blocks with a capped counter + stall detection) is the proven fix for "agent stopped with unchecked tasks". Add as opt-in (e.g., `.focus/mode` containing `gated`), advisory remains default.

**10. Memory-freshness reminder fires after 120 seconds.** Practically every stop triggers it → alarm fatigue. Fix: check "does today's journal file exist / was memory.md or journal touched this session" instead of a 2-minute mtime.

**11. Evaluator re-runs everything after CHANGES REQUESTED.** GSD's re-verification mode: re-check only FAILED REQs + quick regression on passed ones. Add to evaluate.md — saves a full re-evaluation per iteration.

**12. No de-escalation rule.** Escalation exists; the reverse (planned LARGE turns out SMALL — drop ceremony, note it) doesn't. One paragraph.

### P3 — Hardening & distribution

**13. Zero tests for the scripts.** The 2026-04-23 journal records that ad-hoc sandbox tests caught real awk/permission bugs — but none were committed. Add a small shell test suite (bats-core or plain sh + fixtures) covering: principles extraction, handoff extraction, checkbox counting, schema-gap detection, blocker detection incl. backtick-escaping. Add GitHub Actions CI.
**14. Package as a Claude Code plugin.** The article positions plugins as *the* distribution mechanism; hooks already reference `$CLAUDE_PLUGIN_ROOT`. Add `.claude-plugin/plugin.json` + marketplace entry; keep install.sh as fallback.
**15. Cleanups.** Delete orphaned `skills/focus/templates/gitignore` (known open item); have `session-context.sh` print the current datetime so agents stop guessing timestamps for log/journal entries.

---

## What NOT to adopt (deliberate, lean stays lean)

- **BMAD named personas / party mode** — ceremony without payoff for a solo workflow.
- **spec-kit's full spec→clarify→plan→analyze→tasks pipeline** — Focus's plan.md + self-review covers it at the right weight; adopting it would destroy adaptive ceremony.
- **planning-with-files SHA-256 plan attestation** — wrong threat model for a solo dev.
- **GSD wave-based parallel execution / worktrees** — powerful but a complexity cliff; revisit only if you start running multi-agent.
- **superpowers' unconditional TDD hard gate** — Focus's per-level testing policy is better calibrated.

---

## Execution plan

Per the 2026-04-23 decision in `.focus/memory.md`, this is LARGE work on Focus itself → it must go through `.focus/plan.md` with atomic tasks + evaluator gate.

| Phase | Items | Size |
|---|---|---|
| 1. Context economy | P0-1, P0-2, P0-3, P0-4 | MEDIUM (scripts + SKILL.md edits) |
| 2. Subagent research + evaluator fix | P1-5, P1-7 | MEDIUM (SKILL.md + references) |
| 3. Legibility guidance | P1-6 | SMALL/MEDIUM |
| 4. Reliability | P2-8 … P2-12 | MEDIUM |
| 5. Tests + CI | P3-13 | MEDIUM |
| 6. Plugin packaging + cleanups | P3-14, P3-15 | SMALL/MEDIUM |

Suggested order: 1 → 2 are the high-leverage phases; 3–6 can follow in any order. Each phase is one Focus plan with its own evaluator pass.
