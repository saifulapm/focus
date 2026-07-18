#!/bin/bash
# Focus question-guard — PreToolUse hook on AskUserQuestion.
#
# Track Mode sessions are usually background sessions (`claude --bg`): a
# pending AskUserQuestion there is answerable only via `claude attach` /
# agent-view peek (documented harness behavior), so it stalls the track
# invisibly while the orchestrator's watch sees only a `blocked` label.
# Track Mode rule 3 routes every question through a question-stop report
# instead; this hook enforces that contract mechanically. Outside Track
# Mode it stays silent.
#
# Detection mirrors references/track-mode.md: cwd inside .worktrees/, or
# branch track/* , or branch foundation with docs/plan/ROADMAP.md present.

in_track=0
case "$PWD" in */.worktrees/*) in_track=1 ;; esac
if [ "$in_track" -eq 0 ]; then
  branch=$(git branch --show-current 2>/dev/null)
  case "$branch" in
    track/*) in_track=1 ;;
    foundation) [ -f docs/plan/ROADMAP.md ] && in_track=1 ;;
  esac
fi
[ "$in_track" -eq 1 ] || exit 0

cat >&2 <<'EOF'
[focus] Track Mode forbids AskUserQuestion — a background session's question can only be answered by claude attach, so it stalls the wave. Do this instead (track-mode.md rule 3):
- Reversible, in-scope call with a defensible recommendation -> decide it yourself, record it in the report's decisions.
- Premise, contract, one-way door, or out-of-scope ruling -> question-stop: write .focus/report.md, first line "STATUS: BLOCKED — question: <one-line question>", body = full question + options + your recommended answer, then stop. The orchestrator answers and respawns you with the answer as authorization.
EOF
exit 2
