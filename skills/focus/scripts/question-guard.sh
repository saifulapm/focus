#!/bin/bash
# Focus question-guard — PreToolUse hook on AskUserQuestion.
#
# Track sessions are usually background sessions (`claude --bg`): a
# pending AskUserQuestion there is answerable only via `claude attach` /
# agent-view peek (documented harness behavior), so it stalls the track
# invisibly while the orchestrator's watch sees only a `blocked` label.
# Track Mode rule 3 routes every question through a question-stop report
# instead; this hook enforces that contract mechanically. Outside a track
# session it stays silent.
#
# Scope: TRACK SESSIONS ONLY — cwd inside .worktrees/, or branch track/*.
# The foundation branch is deliberately NOT matched (run-tracks role
# detection: a foundation branch is an orchestrator mode, not a track
# session — it runs in the main checkout where the same session owns the
# sanctioned interactive asks: spawn confirmations, genuinely missing
# inputs). Blocking those breaks the pipeline's consent flow.

in_track=0
case "$PWD" in */.worktrees/*) in_track=1 ;; esac
if [ "$in_track" -eq 0 ]; then
  case "$(git branch --show-current 2>/dev/null)" in
    track/*) in_track=1 ;;
  esac
fi
[ "$in_track" -eq 1 ] || exit 0

cat >&2 <<'EOF'
[focus] Track sessions forbid AskUserQuestion — a background session's question can only be answered by claude attach, so it stalls the wave. Do this instead (track-mode.md rule 3):
- Reversible, in-scope call with a defensible recommendation -> decide it yourself, record it in the report's decisions.
- Premise, contract, one-way door, or out-of-scope ruling -> question-stop: write .focus/report.md, first line "STATUS: BLOCKED — question: <one-line question>", body = full question + options + your recommended answer, then stop. The orchestrator answers and respawns you with the answer as authorization.
EOF
exit 2
