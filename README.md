# Focus

The distilled wisdom of 8 AI agent frameworks in one skill file.

**3 files. 1 skill. Zero dependencies.**

## What It Does

Focus makes AI coding agents reliably better by solving 5 problems:

1. **Context persistence** — Hooks re-inject your plan before every tool call (read, write, search, execute). The agent never loses track of the goal.
2. **Adaptive process** — A typo fix gets zero ceremony. A database redesign gets a real plan with human review. Auto-detected, not configured.
3. **Cross-session memory** — The agent remembers decisions, patterns, and open items across sessions. Git-backed markdown.
4. **Failure handling** — Log before retry. Never repeat the same approach. Three strikes = ask the human. Rollback on regression.
5. **Human steering** — "Here's my plan. Any objections?" Proceed on silence. Ask only when genuinely uncertain.

## Install

### Claude Code (recommended)

```bash
# Plugin install (when published)
/plugin install focus

# Manual install
git clone https://github.com/saifulapm/focus.git /tmp/focus
bash /tmp/focus/skills/focus/scripts/install.sh
```

### Cursor

```bash
git clone https://github.com/saifulapm/focus.git /tmp/focus
bash /tmp/focus/skills/focus/scripts/install.sh
```

The installer auto-detects Cursor and installs to `~/.cursor/skills/focus/`.

### Codex

```bash
git clone https://github.com/saifulapm/focus.git ~/.codex/focus
mkdir -p ~/.agents/skills
ln -s ~/.codex/focus/skills ~/.agents/skills/focus
```

Restart Codex. See [.codex/INSTALL.md](.codex/INSTALL.md) for details.

### OpenCode

Add to your `opencode.json`:

```json
{
  "plugin": ["focus@git+https://github.com/saifulapm/focus.git"]
}
```

Restart OpenCode. See [.opencode/INSTALL.md](.opencode/INSTALL.md) for details.

### Gemini CLI

```bash
gemini extensions install https://github.com/saifulapm/focus
```

Or manually copy `GEMINI.md` + `gemini-extension.json` to `~/.gemini/extensions/focus/`.

### Auto-Detect All Agents

```bash
bash skills/focus/scripts/install.sh
```

The installer detects which agents are available and installs for all of them.

## How It Works

Focus classifies every task into 4 levels:

| Level | Example | Process |
|-------|---------|---------|
| **Trivial** | Fix typo, rename variable | Just do it. One-line log entry. |
| **Small** | Add a utility function | 3-line plan in log. Do it. Commit. |
| **Medium** | New API endpoint with tests | Create plan with 2-4 phases. Brief mention, then start. |
| **Large** | Database migration, auth redesign | Plan with 4-7 phases. **Ask human before starting.** |

Tasks can **escalate** mid-work. A "small" fix that touches 10 files automatically becomes "medium" — the agent creates a plan and continues.

## Project Files

When Focus activates, it creates `.focus/` in your project:

```
.focus/
├── plan.md      # Active task: goal, phases, checkboxes (gitignored)
├── log.md       # What happened, errors, resolutions (gitignored)
└── memory.md    # Cross-session: decisions, patterns, open items (committed)
```

- `plan.md` is temporary — deleted when the task is done
- `log.md` is append-only — full history of work
- `memory.md` persists across sessions — committed to git

## Supported Agents

| Agent | Integration | Hooks | Install Method |
|-------|------------|-------|----------------|
| **Claude Code** | Skill + Plugin | Full (3 hooks) | `install.sh` or `/plugin install` |
| **Cursor** | Skill + Plugin | Full (3 hooks) | `install.sh` auto-detects |
| **Codex** | Skill (symlink) | None (SKILL.md only) | Symlink to `~/.agents/skills/` |
| **OpenCode** | JS Plugin | System prompt injection | Plugin in `opencode.json` |
| **Gemini CLI** | Extension | Context file injection | `gemini extensions install` |

## What Makes It Different

| | Focus | Others |
|---|---|---|
| **Size** | ~250 lines of instructions | 500-3,000+ lines |
| **Files** | 3 | 7-50+ |
| **Dependencies** | None | Node.js, Python, npm packages |
| **Process** | Adapts to task | One-size-fits-all |
| **Subagents** | None (one agent does the work) | 3-16 subagent types |
| **Agents** | 5 (Claude, Cursor, Codex, OpenCode, Gemini) | 1-30+ |
| **Install** | Copy 2 files or run script | npm install, configure, setup |

## Built From

Focus distills the best ideas from:

- **Planning with Files** — Hook-based context re-injection (PreToolUse pattern)
- **Agent Kernel** — Git-backed markdown memory (state vs narrative separation)
- **Get-Shit-Done** — Complexity routing (trivial/quick/full classification)
- **Superpowers** — Verification-before-completion, failure escalation, multi-agent support patterns
- **Plannotator** — Plan review gate (for large tasks only)
- **Spec Kit** — Multi-agent command registration patterns
- **BMAD-METHOD** — Phase-based workflow structure
- **Supermemory** — Cross-session memory concepts

Without their complexity.

## License

MIT
