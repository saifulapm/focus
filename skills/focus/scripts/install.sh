#!/bin/bash
# Focus installer — Claude Code only.
# Usage: bash install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$(dirname "$SKILL_ROOT")")"

CLAUDE_DIR="$HOME/.claude"
if [ ! -d "$CLAUDE_DIR" ]; then
  echo "[focus] No ~/.claude/ directory found. Install Claude Code first, or install manually:"
  echo "  mkdir -p ~/.claude/skills/focus && cp SKILL.md there"
  exit 1
fi

SKILL_DIR="$CLAUDE_DIR/skills/focus"
CMD_DIR="$CLAUDE_DIR/commands"

if [ -f "$SKILL_DIR/SKILL.md" ]; then
  echo "[focus] Claude Code: Upgrading..."
else
  echo "[focus] Claude Code: Installing..."
fi

mkdir -p "$SKILL_DIR/scripts" "$SKILL_DIR/templates" "$SKILL_DIR/references" "$CMD_DIR/focus"
cp "$SKILL_ROOT/SKILL.md" "$SKILL_DIR/SKILL.md"
for s in check-complete.sh session-context.sh plan-tail.sh principles.sh; do
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

echo ""
echo "Done. Focus activates on your next session."
echo "Commands: /focus:status, /focus:evaluate, /focus:handoff"
