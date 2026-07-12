#!/bin/bash
# Focus PreToolUse injector — throttled.
#
# Repeated identical context degrades attention and wastes tokens, so this
# does NOT fire on every tool call:
#   - The hook matcher (SKILL.md frontmatter) is Write|Edit|Bash only.
#   - A per-session counter in .focus/.toolcount.<session> throttles
#     injection to every 5th call. Keying on the hook's session_id keeps two
#     sessions in one checkout from corrupting each other's counter; stale
#     per-session files (idle >1 day) are swept opportunistically.
#   - The counter resets whenever plan.md changes — a plan edit (check-off,
#     handoff, new plan) is a checkpoint; the first call after it re-injects.
#   - At 40+ uncheckpointed calls it emits a handoff-budget warning.
#
# Injection content is the plan's Goal + the first unchecked task (current
# position), not the plan head. A pending ## Handoff gets a one-line pointer
# only — session-context.sh shows the full block at session start, and the
# resume procedure archives it to log.md after consumption.

[ -f .focus/plan.md ] || exit 0

# Sweep stale per-session counters (idle >1 day) so they don't accumulate.
find .focus -maxdepth 1 -type f -name '.toolcount.*' -mtime +1 -delete 2>/dev/null

# Per-session counter keyed on session_id (from the hook's stdin JSON). Falls
# back to a shared .toolcount when no session_id is available.
input=""
[ -t 0 ] || input=$(cat 2>/dev/null)
session_id=$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
sid8=$(printf '%s' "$session_id" | cut -c1-8)
count_file=".focus/.toolcount${sid8:+.$sid8}"

if [ ! -f "$count_file" ] || [ .focus/plan.md -nt "$count_file" ]; then
  count=0
else
  count=$(cat "$count_file" 2>/dev/null)
  case "$count" in ''|*[!0-9]*) count=0 ;; esac
fi
count=$((count + 1))
printf '%s' "$count" > "$count_file"

if [ $((count % 5)) -ne 1 ]; then
  # Off-cadence calls stay silent, except the budget warning (every 5th
  # call once 40 uncheckpointed calls are reached: 40, 45, 50, ...).
  if [ "$count" -ge 40 ] && [ $((count % 5)) -eq 0 ]; then
    echo "[focus] $count tool calls since the last plan checkpoint — consider /focus:handoff, or check off completed tasks in .focus/plan.md."
  fi
  exit 0
fi

if awk '/^[[:space:]]*```/ { f = !f; next } !f && /^## Handoff/ { found = 1; exit } END { exit !found }' .focus/plan.md 2>/dev/null; then
  echo '[focus] A ## Handoff is pending in .focus/plan.md. If you have not consumed it: read it, archive it to log.md, delete it from plan.md, then continue from its "Exact next action".'
  exit 0
fi

# Goal + Level + first task section that still has an unchecked box.
# Fence-aware: task Actions embed code blocks whose content can contain
# markdown headings and checkbox-shaped lines — inside ``` fences, lines only
# accumulate; they never trigger section boundaries or checkbox detection.
awk '
  function flush() {
    if (intask && has) { printf "%s", sec; found = 1 }
    intask = 0; sec = ""; has = 0
  }
  /^[[:space:]]*```/ { fence = !fence; if (intask) sec = sec $0 "\n"; next }
  fence              { if (intask) sec = sec $0 "\n"; next }
  /^## /       { flush(); if (found) exit }
  /^### Task / { flush(); if (found) exit; intask = 1 }
  intask       { sec = sec $0 "\n"; if ($0 ~ /^- \[ \]/) has = 1 }
  /^\*\*Goal:\*\*/  && !intask { print }
  /^\*\*Level:\*\*/ && !intask { print }
  END { flush() }
' .focus/plan.md | head -30
