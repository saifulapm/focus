# Memory

## Project Context
- This is "Focus" — a lean AI agent enhancement skill (v2)
- Supports 5 agents: Claude Code, Cursor, Codex, OpenCode, Gemini CLI
- Repo structure:
  - `skills/focus/SKILL.md` — main skill (always loaded)
  - `skills/focus/scripts/` — 5 runtime scripts + installer
  - `skills/focus/references/` — on-demand reference files (plans, debugging, memory, testing+review)
  - `commands/focus/` — namespaced slash commands (evaluate, handoff, status)
  - Hooks live inline in SKILL.md frontmatter, dispatching to `scripts/` via `$CLAUDE_PLUGIN_ROOT` with fallbacks
- Pure markdown + shell scripts + 1 JS file (OpenCode plugin), zero npm dependencies
- Installed to `~/.claude/skills/focus/` + `~/.claude/commands/focus/` (Claude Code), same for Cursor under `~/.cursor/`

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

## Principles
- **MUST** keep SKILL.md under ~500 lines; push depth into `skills/focus/references/*.md` as it grows.
- **MUST NOT** introduce npm runtime dependencies. Pure markdown + shell, + the single JS file for OpenCode.
- **MUST** scale ceremony to task size — TRIVIAL/SMALL stay ceremony-free.
- **MUST NOT** mix session narrative and state — narrative goes in journal/, state in memory.md.
- **PREFER** scripts over inline shell in hook commands; hooks should be one-line dispatchers.

## Open Items
- [ ] Test on actual Cursor installation
- [ ] Fix installer: `~/.agents/skills/focus/` is detected but never populated — currently just prints a hint about `.codex/INSTALL.md`. Should install the skill files the same way it does for Claude Code + Cursor. (MEDIUM)
- [x] ~~Publish to GitHub for real installs~~ — done 2026-04-23 (v2 pushed)
- [ ] Publish to npm for `npx skills add`-style install
- [ ] Consider adding Windsurf, Kilo, and other agents
- [ ] Run `/focus:evaluate` retroactively against v2 diff as dog-food (in-progress this session)
