#!/bin/bash
# Focus session context injector — runs on UserPromptSubmit / session-start.
#
# Prints a compact context block so the agent sees active-plan state even if
# it hasn't re-invoked the skill yet. Handoff-aware: when plan.md contains a
# ## Handoff section, surface that section instead of the plan head, because
# the handoff is the ground truth for a resuming agent.

echo '[focus] IMPORTANT: Invoke the focus skill before starting any coding work. Classify task complexity and follow the focus process.'

if [ -f .focus/memory.md ]; then
  echo
  echo '=== [focus] Memory (current state) ==='
  # Show Principles + Open Items — the two sections most load-bearing for
  # a fresh session. Skip Project Context (usually long) and full Decisions
  # table; agent will read the full file if needed.
  awk '
    /^## Principles/      { section = "p"; print; next }
    /^## Open Items/      { section = "o"; print; next }
    /^## /                { section = "" }
    section               { print }
  ' .focus/memory.md | head -30
  echo
fi

# --- Journal: show the most recent entries (up to 2 days) ---
if [ -d .focus/journal ]; then
  latest=$(ls -1 .focus/journal/ 2>/dev/null | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$' | sort | tail -2)
  if [ -n "$latest" ]; then
    echo '=== [focus] Recent journal (what happened last) ==='
    for f in $latest; do
      echo "--- .focus/journal/$f ---"
      tail -30 ".focus/journal/$f"
    done
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
  if grep -q '^## Handoff' .focus/plan.md 2>/dev/null; then
    echo '=== [focus] HANDOFF — resuming from previous session ==='
    echo '[focus] This section is ground truth. Read it before anything else.'
    echo
    awk '
      /^## Handoff/ { in_h = 1; print; next }
      in_h && /^## / { in_h = 0 }
      in_h { print }
    ' .focus/plan.md
    echo
    echo '[focus] Start at "Exact next action". Do not re-derive state. Do not re-verify tasks already recorded with a commit sha.'
  else
    echo '=== [focus] Active Plan ==='
    head -20 .focus/plan.md
  fi
  echo

  if [ -f .focus/log.md ]; then
    echo '=== [focus] Recent Log ==='
    tail -10 .focus/log.md
    echo
  fi

  echo '[focus] Continue from current phase. Read .focus/plan.md, .focus/log.md, and .focus/memory.md for full context.'
fi
