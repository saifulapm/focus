# Memory

## Project Context
- This is "Focus" — a lean AI agent enhancement skill for Claude Code (v2)
- Target host: Claude Code only. Earlier iterations supported 5 hosts; scope reduced 2026-04-23.
- Repo structure:
  - `skills/focus/SKILL.md` — main skill (always loaded)
  - `skills/focus/scripts/` — 4 runtime scripts (check-complete, session-context, plan-tail, principles) + installer
  - `skills/focus/references/` — on-demand reference files (plans, debugging, memory, testing+review)
  - `commands/focus/` — namespaced slash commands (evaluate, handoff, status)
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
- [x] ~~Consider adding Windsurf, Kilo, and other agents~~ — out of scope 2026-04-23 (Claude-only)
- [x] ~~Run `/focus:evaluate` retroactively against v2 diff as dog-food~~ — done 2026-04-23. Verdict: CHANGES REQUESTED (1 blocker + 3 suggestions + 3 nits). Issues 1-3 fixed that session; Issues 4-7 (Gemini files, templates/, stale install hint paths, README 5-host over-claim) resolved by the Claude-only scope reduction.
- [ ] Clean up `skills/focus/templates/` — contains only a `gitignore` file no longer referenced anywhere (evaluator Issue 5). (TRIVIAL)
