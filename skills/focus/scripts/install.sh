#!/bin/bash
# Focus installer — detects and installs for all supported agents
# Usage: bash install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$(dirname "$SKILL_ROOT")")"

installed=""

# --- Claude Code ---
CLAUDE_DIR="$HOME/.claude"
if [ -d "$CLAUDE_DIR" ]; then
  SKILL_DIR="$CLAUDE_DIR/skills/focus"
  CMD_DIR="$CLAUDE_DIR/commands"

  if [ -f "$SKILL_DIR/SKILL.md" ]; then
    echo "[focus] Claude Code: Upgrading..."
  else
    echo "[focus] Claude Code: Installing..."
  fi

  mkdir -p "$SKILL_DIR/scripts" "$SKILL_DIR/templates" "$SKILL_DIR/references" "$CMD_DIR/focus"
  cp "$SKILL_ROOT/SKILL.md" "$SKILL_DIR/SKILL.md"
  for s in check-complete.sh evaluator-brief.sh session-context.sh plan-tail.sh principles.sh; do
    cp "$SCRIPT_DIR/$s" "$SKILL_DIR/scripts/$s"
    chmod +x "$SKILL_DIR/scripts/$s"
  done
  cp "$SKILL_ROOT/templates/"* "$SKILL_DIR/templates/" 2>/dev/null || true
  cp "$SKILL_ROOT/references/"*.md "$SKILL_DIR/references/" 2>/dev/null || true
  # Commands live under commands/focus/ so they appear as /focus:<name>.
  cp "$PROJECT_ROOT/commands/focus/"*.md "$CMD_DIR/focus/" 2>/dev/null || true
  # Legacy cleanup: remove un-namespaced copies from older installs to
  # prevent /<name> and /focus:<name> both resolving.
  for legacy in evaluate.md handoff.md status.md; do
    [ -f "$CMD_DIR/$legacy" ] && rm -f "$CMD_DIR/$legacy" && echo "[focus] Claude Code: removed legacy $CMD_DIR/$legacy"
  done

  installed="$installed Claude-Code"
fi

# --- Cursor ---
CURSOR_DIR="$HOME/.cursor"
if [ -d "$CURSOR_DIR" ]; then
  CURSOR_SKILL_DIR="$CURSOR_DIR/skills/focus"

  if [ -f "$CURSOR_SKILL_DIR/SKILL.md" ]; then
    echo "[focus] Cursor: Upgrading..."
  else
    echo "[focus] Cursor: Installing..."
  fi

  CURSOR_CMD_DIR="$CURSOR_DIR/commands"
  mkdir -p "$CURSOR_SKILL_DIR/scripts" "$CURSOR_SKILL_DIR/templates" "$CURSOR_SKILL_DIR/references" "$CURSOR_CMD_DIR/focus"
  cp "$SKILL_ROOT/SKILL.md" "$CURSOR_SKILL_DIR/SKILL.md"
  for s in check-complete.sh evaluator-brief.sh session-context.sh plan-tail.sh principles.sh; do
    cp "$SCRIPT_DIR/$s" "$CURSOR_SKILL_DIR/scripts/$s"
    chmod +x "$CURSOR_SKILL_DIR/scripts/$s"
  done
  cp "$SKILL_ROOT/templates/"* "$CURSOR_SKILL_DIR/templates/" 2>/dev/null || true
  cp "$SKILL_ROOT/references/"*.md "$CURSOR_SKILL_DIR/references/" 2>/dev/null || true
  cp "$PROJECT_ROOT/commands/focus/"*.md "$CURSOR_CMD_DIR/focus/" 2>/dev/null || true
  for legacy in evaluate.md handoff.md status.md; do
    [ -f "$CURSOR_CMD_DIR/$legacy" ] && rm -f "$CURSOR_CMD_DIR/$legacy" && echo "[focus] Cursor: removed legacy $CURSOR_CMD_DIR/$legacy"
  done

  installed="$installed Cursor"
fi

# --- Gemini CLI ---
GEMINI_DIR="$HOME/.gemini"
if [ -d "$GEMINI_DIR" ]; then
  echo "[focus] Gemini CLI: Installing..."
  # Gemini uses extensions installed via `gemini extensions install <repo>`
  # We can pre-copy the context file for manual setups
  mkdir -p "$GEMINI_DIR/extensions/focus"
  cp "$PROJECT_ROOT/GEMINI.md" "$GEMINI_DIR/extensions/focus/GEMINI.md" 2>/dev/null || true
  cp "$PROJECT_ROOT/gemini-extension.json" "$GEMINI_DIR/extensions/focus/gemini-extension.json" 2>/dev/null || true
  installed="$installed Gemini"
fi

# --- Summary ---
echo ""
if [ -n "$installed" ]; then
  echo "[focus] Installed for:$installed"
else
  echo "[focus] No supported agents detected. Install manually:"
  echo "  Claude Code: mkdir -p ~/.claude/skills/focus && cp SKILL.md there"
  echo "  Cursor:      mkdir -p ~/.cursor/skills/focus && cp SKILL.md there"
fi

# --- Show instructions for agents that need manual setup ---
CODEX_DIR="$HOME/.codex"
AGENTS_DIR="$HOME/.agents"
if [ -d "$CODEX_DIR" ] || [ -d "$AGENTS_DIR" ]; then
  echo ""
  echo "[focus] Codex detected — see .codex/INSTALL.md for symlink setup"
fi

if command -v opencode &>/dev/null; then
  echo ""
  echo "[focus] OpenCode detected — see .opencode/INSTALL.md for plugin setup"
fi

echo ""
echo "Done. Focus activates on your next session."
echo "Commands: /focus:status, /focus:evaluate, /focus:handoff"
