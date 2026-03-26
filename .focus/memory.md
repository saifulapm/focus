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

## Open Items
- [ ] Test on actual Cursor installation
- [ ] Test Codex symlink discovery
- [ ] Publish to npm/GitHub for real installs
- [ ] Consider adding Windsurf, Kilo, and other agents

## Last Session
- Date: 2026-03-26
- Task: Added multi-agent support (Claude Code, Cursor, Codex, OpenCode, Gemini CLI)
- Status: Complete
- Key files: .claude-plugin/plugin.json, .cursor-plugin/plugin.json, hooks/hooks.json, hooks/hooks-cursor.json, hooks/session-start, .codex/INSTALL.md, .opencode/plugins/focus.js, gemini-extension.json, GEMINI.md, install.sh, README.md
- Notes: All 7 phases complete. All JSON validates. OpenCode JS module loads. Install script auto-detects agents.
