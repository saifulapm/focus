#!/bin/bash
# Focus session context injector — runs on UserPromptSubmit.
#
# Context economy: the full state block is injected ONCE per session — the
# agent keeps it in context from the first prompt; re-sending it every
# prompt is pure duplication. Subsequent prompts get a 1-2 line refresh.
# Session identity comes from the hook's stdin JSON; /clear or a new
# session issues a new id, which brings the full block back.
#
# Silent in projects without .focus/ — skill discovery is the job of the
# skill's description field, not a per-prompt nag. The hook only surfaces
# state that actually exists.
#
# Handoff-aware: when plan.md contains a ## Handoff section, surface that
# section instead of the plan head — it is the ground truth for a resuming
# agent and the one block that must be complete.

[ -d .focus ] || exit 0

input=""
[ -t 0 ] || input=$(cat 2>/dev/null)
session_id=$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

now=$(date '+%Y-%m-%d %H:%M')

# --- Repeat prompt in the same session: 1-2 line refresh only ---
# Keyed per session (like .toolcount/.stopblocks): two concurrent sessions in
# one checkout (orchestrator + spawned foundation session) must not ping-pong
# a shared file, re-injecting the full block on every prompt. Stale keys and
# the legacy shared file are swept opportunistically.
find .focus -maxdepth 1 -type f -name '.lastsession*' -mtime +1 -delete 2>/dev/null
sid8=$(printf '%s' "$session_id" | cut -c1-8)
lastfile=".focus/.lastsession${sid8:+.$sid8}"
if [ -n "$session_id" ] && [ -f "$lastfile" ] \
   && [ "$session_id" = "$(cat "$lastfile" 2>/dev/null)" ]; then
  echo "[focus] Now: $now."
  if [ -f .focus/plan.md ]; then
    goal=$(grep -m1 '^\*\*Goal:\*\*' .focus/plan.md)
    echo "[focus] Active plan: ${goal#\*\*Goal:\*\* } — read .focus/plan.md if unsure of state."
  fi
  exit 0
fi
[ -n "$session_id" ] && printf '%s' "$session_id" > "$lastfile"

echo "[focus] Now: $now. Use this timestamp for log/journal entries. Invoke the focus skill before coding work."

# --- Memory: principles + UNCHECKED open items only (struck/done = noise) ---
dir="$(dirname "$0")"
principles=$(bash "$dir/principles.sh" 2>/dev/null)
open_items=""
if [ -f .focus/memory.md ]; then
  open_items=$(awk '
    /^## Open Items/ { in_o = 1; next }
    in_o && /^## /   { in_o = 0 }
    in_o             { print }
  ' .focus/memory.md | grep '^- \[ \]' | head -8)
fi
if [ -n "$principles" ] || [ -n "$open_items" ]; then
  echo
  echo '=== [focus] Memory (current state) ==='
  if [ -n "$principles" ]; then
    echo "$principles"
    echo
  fi
  if [ -n "$open_items" ]; then
    echo '## Open Items (unchecked)'
    echo "$open_items"
  fi
  echo
fi

# --- Journal: newest file tail; previous file headings only ---
if [ -d .focus/journal ]; then
  files=$(ls -1 .focus/journal/ 2>/dev/null | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$' | sort | tail -2)
  newest=$(echo "$files" | tail -1)
  prev=$(echo "$files" | head -1)
  if [ -n "$newest" ]; then
    echo '=== [focus] Recent journal (what happened last) ==='
    if [ -n "$prev" ] && [ "$prev" != "$newest" ]; then
      echo "--- .focus/journal/$prev (headings) ---"
      grep '^## ' ".focus/journal/$prev" | head -6
    fi
    echo "--- .focus/journal/$newest ---"
    tail -20 ".focus/journal/$newest"
    echo
  fi
fi

# --- Legacy: if memory.md still has ## Last Session, surface it and hint migration ---
if [ -f .focus/memory.md ] && grep -q '^## Last Session' .focus/memory.md 2>/dev/null; then
  echo '=== [focus] Legacy Last Session (migrate to journal/) ==='
  awk '
    /^## Last Session/ { in_s = 1; print; next }
    in_s && /^## / { in_s = 0 }
    in_s { print }
  ' .focus/memory.md | head -15
  echo '[focus] Migrate: move this block to journal/<date>.md, delete from memory.md, commit.'
  echo
fi

if [ -f .focus/plan.md ]; then
  # Check for a Handoff section — if present, it is the ground truth.
  # (Fence-aware: a ## Handoff inside a code block is documentation, not a handoff.)
  if awk '/^[[:space:]]*```/ { f = !f; next } !f && /^## Handoff/ { found = 1; exit } END { exit !found }' .focus/plan.md 2>/dev/null; then
    echo '=== [focus] HANDOFF — resuming from previous session ==='
    echo '[focus] This section is ground truth. Read it before anything else.'
    echo
    awk '
      /^[[:space:]]*```/ { fence = !fence; if (in_h) print; next }
      fence { if (in_h) print; next }
      /^## Handoff/ { in_h = 1; print; next }
      in_h && /^## / { in_h = 0 }
      in_h { print }
    ' .focus/plan.md
    echo
    echo '[focus] Start at "Exact next action". First archive the handoff to log.md and delete it from plan.md (read-once). Do not re-derive state. Do not re-verify tasks already recorded with a commit sha.'
  else
    echo '=== [focus] Active Plan ==='
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
  fi
  echo

  if [ -f .focus/log.md ]; then
    echo '=== [focus] Recent Log ==='
    tail -10 .focus/log.md
    echo
  fi

  echo '[focus] Continue from current phase. Read .focus/plan.md, .focus/log.md, and .focus/memory.md for full context.'
fi
