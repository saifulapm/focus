# Memory

## Project Context
- This is "Focus" — a lean AI agent enhancement skill for Claude Code (v2)
- Target host: Claude Code only. Earlier iterations supported 5 hosts; scope reduced 2026-04-23.
- Repo structure:
  - `skills/focus/SKILL.md` — main skill (always loaded)
  - `skills/focus/scripts/` — 4 runtime scripts (check-complete, session-context, plan-tail, principles) + installer
  - `skills/focus/references/` — on-demand reference files (plans, debugging, memory, testing+review)
  - `commands/focus/` — namespaced slash commands (evaluate, handoff, status)
  - `tests/` — pure-shell test suite (run.sh + helpers + one file per script), CI via `.github/workflows/test.yml`
  - `.claude-plugin/` — plugin.json + marketplace.json (installable via `/plugin install focus@focus`)
  - `docs/improvement-plan-2026-06.md` — the 6-phase review that produced v2.1
  - Hooks live inline in SKILL.md frontmatter, dispatching to `scripts/` via `$CLAUDE_PLUGIN_ROOT` with `$HOME/.claude/` fallback
- Pure markdown + shell scripts, zero npm dependencies
- Installed to `~/.claude/skills/focus/` + `~/.claude/commands/focus/`

## Decisions
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-03-26 | plan.md and log.md gitignored, memory.md committed | plan/log are temporary per-task; memory persists across sessions |
| 2026-03-26 | Status command as separate commands/status.md | Follows Claude Code convention for slash commands |
| 2026-03-26 | Install script detects upgrades via existing SKILL.md | Simple file existence check, no version tracking needed |
| 2026-03-26 | Claude hooks use PascalCase, Cursor uses camelCase | Platform convention from Superpowers reference |
| 2026-03-26 | Shared session-start hook script with env var detection | CLAUDE_PLUGIN_ROOT vs CURSOR_PLUGIN_ROOT determines JSON format |
| 2026-03-26 | GEMINI.md = SKILL.md body without frontmatter | Gemini doesn't support hooks, just reads context file |
| 2026-03-26 | Codex uses symlink, not plugin | Codex discovers SKILL.md natively via ~/.agents/skills/ |
| 2026-03-26 | OpenCode uses JS plugin (CommonJS) | OpenCode requires JS module for config + system prompt hooks |
| 2026-04-23 | Slash commands live under `commands/focus/` (not flat `commands/`) | Claude Code derives slash names from filename paths, not frontmatter `name:`; subdirectory produces `/focus:<cmd>` namespace |
| 2026-04-23 | Any LARGE change to Focus itself MUST go through `.focus/plan.md` with atomic tasks + evaluator | v2 was built without dog-fooding its own rules; this guardrail prevents the blind spot recurring |
| 2026-04-23 | Scope reduced to Claude Code only | User workflow is Claude-only; maintenance cost of 5-host support not justified. Removed: Cursor / Codex / OpenCode / Gemini install paths, brief-mode evaluator, evaluator-brief.sh. |
| 2026-06-12 | PreToolUse injection throttled: every 5th Write/Edit/Bash call via `.focus/.toolcount`, counter resets on plan.md change, warns at 40+ | Repeated identical context degrades attention and wastes tokens (Anthropic article; planning-with-files v3 reached the same conclusion) |
| 2026-06-12 | Handoffs are read-once: archived to log.md and deleted from plan.md on resumption | A consumed handoff left in plan.md gets re-injected as stale resume state |
| 2026-06-12 | Hook discovery model: skill `description:` discovers Focus; hooks only surface state that exists | Per-prompt nag in non-Focus projects violated the lean principle |
| 2026-06-12 | Gated stop is opt-in (`.focus/mode` = `gated`), advisory stays default | "Focus never blocks" remains the principle; gating is a conscious per-project choice with cap + handoff exemption |
| 2026-06-12 | Evaluator re-verification mode: prior evaluator report scopes depth | Evaluator output isn't generator claims; full re-check of FAILED REQs, regression on VERIFIED |
| 2026-06-12 | Pure-shell test suite (`tests/run.sh`) + CI on ubuntu/macos | Scripts had caught-by-hand bugs twice before; bats would be a dependency |
| 2026-06-12 | Plugin packaging: same-repo plugin.json + marketplace.json (v2.1.0); hooks resolve scripts via CLAUDE_SKILL_DIR first | Plugin marketplace is Claude Code's distribution mechanism; old `$CLAUDE_PLUGIN_ROOT/scripts/` path was wrong for this layout |

## Principles
- **MUST** keep SKILL.md under ~500 lines; push depth into `skills/focus/references/*.md` as it grows.
- **MUST NOT** introduce npm runtime dependencies. Pure markdown + shell.
- **MUST** scale ceremony to task size — TRIVIAL/SMALL stay ceremony-free.
- **MUST NOT** mix session narrative and state — narrative goes in journal/, state in memory.md.
- **PREFER** scripts over inline shell in hook commands; hooks should be one-line dispatchers.

## Open Items
- [x] ~~Test on actual Cursor installation~~ — out of scope 2026-04-23 (Claude-only)
- [x] ~~Fix installer: `~/.agents/skills/focus/` is detected but never populated~~ — out of scope 2026-04-23 (Claude-only)
- [x] ~~Publish to GitHub for real installs~~ — done 2026-04-23 (v2 pushed)
- [ ] Publish to npm for `npx skills add`-style install
- [ ] Review hooks/instructions against current model capabilities every 3–6 months (next: 2026-09) — retire rules that compensate for weaknesses newer models no longer have
- [ ] Phase 5 follow-up: scripted test for run.sh's failure path; warning/injection co-location nit in plan-tail.sh
- [ ] Verify plugin install end-to-end (`/plugin marketplace add saifulapm/focus`) once pushed to GitHub
- [x] ~~Consider adding Windsurf, Kilo, and other agents~~ — out of scope 2026-04-23 (Claude-only)
- [x] ~~Run `/focus:evaluate` retroactively against v2 diff as dog-food~~ — done 2026-04-23. Verdict: CHANGES REQUESTED (1 blocker + 3 suggestions + 3 nits). Issues 1-3 fixed that session; Issues 4-7 (Gemini files, templates/, stale install hint paths, README 5-host over-claim) resolved by the Claude-only scope reduction.
- [x] ~~Clean up `skills/focus/templates/`~~ — done 2026-06-12 (improvement-plan Phase 6)
