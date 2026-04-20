# Memory

## Project Context
- This is "Focus" — a lean AI agent enhancement skill
- Supports 5 agents: Claude Code, Cursor, Codex, OpenCode, Gemini CLI
- Structure: skills/focus/SKILL.md (main), hooks/, commands/, agent-specific dirs
- Pure markdown + shell scripts + 1 JS file (OpenCode plugin), zero npm dependencies
- Installed to ~/.claude/skills/focus/ (Claude Code), ~/.cursor/skills/focus/ (Cursor)

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

## Principles
- **MUST** keep SKILL.md under ~500 lines; push depth into `skills/focus/references/*.md` as it grows.
- **MUST NOT** introduce npm runtime dependencies. Pure markdown + shell, + the single JS file for OpenCode.
- **MUST** scale ceremony to task size — TRIVIAL/SMALL stay ceremony-free.
- **MUST NOT** mix session narrative and state — narrative goes in journal/, state in memory.md.
- **PREFER** scripts over inline shell in hook commands; hooks should be one-line dispatchers.

## Open Items
- [ ] Test on actual Cursor installation
- [ ] Test Codex symlink discovery
- [ ] Publish to npm/GitHub for real installs
- [ ] Consider adding Windsurf, Kilo, and other agents
