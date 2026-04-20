#!/bin/bash
# Focus completion checker — runs on Stop hook
# Warns if plan.md has unchecked phases, clarification blockers, or schema gaps

if [ ! -f .focus/plan.md ]; then
  exit 0
fi

# --- Unchecked phases ---
total=$(grep -c '^- \[' .focus/plan.md 2>/dev/null); total=${total:-0}
done=$(grep -c '^- \[x\]' .focus/plan.md 2>/dev/null); done=${done:-0}
incomplete=$((total - done))

if [ "$incomplete" -gt 0 ]; then
  echo ""
  echo "[focus] === INCOMPLETE PLAN ==="
  echo "[focus] $done/$total checkboxes complete. $incomplete remaining:"
  grep '^- \[ \]' .focus/plan.md 2>/dev/null | while read -r line; do
    echo "[focus]   $line"
  done
  echo "[focus] Verify all work is done before stopping."
  echo ""
fi

# --- Clarification blockers ---
blockers=$(grep -c '\[NEEDS CLARIFICATION' .focus/plan.md 2>/dev/null); blockers=${blockers:-0}
if [ "$blockers" -gt 0 ]; then
  echo "[focus] === CLARIFICATION BLOCKERS ==="
  echo "[focus] $blockers unresolved [NEEDS CLARIFICATION] marker(s) in plan.md."
  echo "[focus] Ask the human and resolve before executing further tasks."
  echo ""
fi

# --- Atomic schema gaps (task headings without all required fields) ---
task_count=$(grep -c '^### Task ' .focus/plan.md 2>/dev/null); task_count=${task_count:-0}
if [ "$task_count" -gt 0 ]; then
  # Count tasks missing any required field. Rough heuristic: a task section
  # is everything from its "### Task" heading to the next "### " or EOF.
  missing=$(awk '
    /^### Task / {
      if (in_task) check()
      in_task = 1; has_files = 0; has_action = 0; has_verify = 0
      has_done = 0; has_commit = 0; name = $0
      next
    }
    /^### / && in_task { check(); in_task = 0 }
    in_task {
      if ($0 ~ /^\*\*Files:\*\*/)     has_files = 1
      if ($0 ~ /^\*\*Action:\*\*/)    has_action = 1
      if ($0 ~ /^\*\*Verify:\*\*/)    has_verify = 1
      if ($0 ~ /^\*\*Done when:\*\*/) has_done = 1
      if ($0 ~ /^\*\*Commit:\*\*/)    has_commit = 1
    }
    END { if (in_task) check() }
    function check() {
      if (!(has_files && has_action && has_verify && has_done && has_commit)) {
        miss = ""
        if (!has_files)  miss = miss " Files"
        if (!has_action) miss = miss " Action"
        if (!has_verify) miss = miss " Verify"
        if (!has_done)   miss = miss " Done-when"
        if (!has_commit) miss = miss " Commit"
        printf "%s — missing:%s\n", name, miss
      }
    }
  ' .focus/plan.md)

  if [ -n "$missing" ]; then
    echo "[focus] === ATOMIC SCHEMA GAPS ==="
    echo "$missing" | while read -r line; do
      echo "[focus]   $line"
    done
    echo "[focus] Every task needs: Files, Action, Verify, Done when, Commit."
    echo ""
  fi
fi

# --- Principles reminder ---
# Only advisory — the evaluator is the enforcement point, not Stop.
# Fires only if principles are declared AND there are pending changes.
if [ -f .focus/plan.md ]; then
  dir="$(dirname "$0")"
  principles=$(bash "$dir/principles.sh" 2>/dev/null)
  if [ -n "$principles" ]; then
    dirty=$(git status --porcelain 2>/dev/null | head -1)
    base=""
    for cand in main master; do
      git rev-parse --verify "$cand" >/dev/null 2>&1 && base=$cand && break
    done
    diff_lines=0
    if [ -n "$base" ]; then
      mb=$(git merge-base HEAD "$base" 2>/dev/null || true)
      [ -n "$mb" ] && diff_lines=$(git diff --shortstat "$mb"...HEAD 2>/dev/null | wc -l | tr -d ' ')
    fi
    if [ -n "$dirty" ] || [ "$diff_lines" -gt 0 ]; then
      count=$(echo "$principles" | grep -cE '^-[^-]|^- ')
      echo "[focus] === PRINCIPLES ACTIVE ==="
      echo "[focus] ${count} principle(s) declared. Re-check the diff before ending the session:"
      echo "$principles" | grep -E '^- ' | sed 's/^/[focus]   /'
      echo ""
    fi
  fi
fi

# --- Handoff hygiene ---
if grep -q '^## Handoff' .focus/plan.md 2>/dev/null; then
  # If a handoff exists, check it has an "Exact next action" — the one field
  # a fresh agent cannot do without.
  if ! awk '/^## Handoff/,0' .focus/plan.md | grep -q '^\*\*Exact next action:\*\*'; then
    echo "[focus] === HANDOFF MISSING NEXT ACTION ==="
    echo "[focus] .focus/plan.md has a ## Handoff section but no 'Exact next action:' field."
    echo "[focus] Fix the handoff before ending the session, or a fresh agent will not know what to do."
    echo ""
  fi
fi

# --- Memory freshness reminder ---
if [ -f .focus/memory.md ]; then
  last_modified=$(stat -f %m .focus/memory.md 2>/dev/null || stat -c %Y .focus/memory.md 2>/dev/null || echo 0)
  now=$(date +%s)
  age=$((now - last_modified))
  if [ "$age" -gt 120 ]; then
    echo "[focus] Reminder: Update .focus/memory.md with session summary before stopping."
  fi
fi
