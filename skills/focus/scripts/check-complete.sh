#!/bin/bash
# Focus completion checker — runs on Stop hook
# Warns if plan.md has unchecked phases, clarification blockers, or schema gaps.
# Advisory by default; opt-in gated mode (.focus/mode containing "gated")
# blocks stopping while unchecked tasks remain — capped, handoff-exempt.

# Hook input arrives as JSON on stdin (contains stop_hook_active, session_id).
input=""
[ -t 0 ] || input=$(cat 2>/dev/null)

if [ ! -f .focus/plan.md ]; then
  exit 0
fi

# Per-session gated-mode block counter, keyed on session_id so two sessions in
# one checkout don't corrupt each other's .stopblocks. Falls back to a shared
# file when no session_id is available. Stale per-session files (idle >1 day)
# are swept opportunistically.
find .focus -maxdepth 1 -type f -name '.stopblocks.*' -mtime +1 -delete 2>/dev/null
session_id=$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
sid8=$(printf '%s' "$session_id" | cut -c1-8)

# Fence-aware handoff detection — a "## Handoff" inside a ``` code block is
# documentation (e.g. a task Action embedding the template), not a handoff.
has_handoff() {
  awk '/^[[:space:]]*```/ { f = !f; next } !f && /^## Handoff/ { found = 1; exit } END { exit !found }' .focus/plan.md 2>/dev/null
}

# Defect-stop / completion report detection — Track Mode's other sanctioned
# stop artifact (.focus/report.md, first line "STATUS: ..."). A defect stop
# (STATUS: BLOCKED) leaves unchecked tasks and NO handoff by design; the
# orchestrator dispatches on the report, so the stop must not be blocked.
has_report_status() {
  [ -f .focus/report.md ] && head -1 .focus/report.md 2>/dev/null | grep -q '^STATUS:'
}

# --- Unchecked phases ---
# Fence-aware: checkbox-shaped lines inside ``` code blocks (task Actions
# embed code) must not count as tasks.
total=$(awk '/^[[:space:]]*```/ { fence = !fence; next } !fence && /^- \[/ { n++ } END { print n + 0 }' .focus/plan.md 2>/dev/null); total=${total:-0}
done=$(awk '/^[[:space:]]*```/ { fence = !fence; next } !fence && /^- \[[xX]\]/ { n++ } END { print n + 0 }' .focus/plan.md 2>/dev/null); done=${done:-0}
incomplete=$((total - done))

if [ "$incomplete" -gt 0 ]; then
  if has_handoff; then
    # A handoff is the sanctioned way to stop mid-plan (session-block
    # boundaries, context budget) — don't imply the stop is wrong.
    echo ""
    echo "[focus] $done/$total tasks complete — handoff in place; stopping here is sanctioned. Next session resumes from plan.md §Handoff."
    echo ""
  elif has_report_status; then
    echo ""
    echo "[focus] $done/$total tasks complete — .focus/report.md carries a STATUS line; a defect-stop/report stop is sanctioned. The orchestrator dispatches on the report."
    echo ""
  else
    echo ""
    echo "[focus] === INCOMPLETE PLAN ==="
    echo "[focus] $done/$total checkboxes complete. $incomplete remaining:"
    awk '/^[[:space:]]*```/ { fence = !fence; next } !fence && /^- \[ \]/ { print }' .focus/plan.md 2>/dev/null | head -10 | while read -r line; do
      echo "[focus]   $line"
    done
    if [ "$incomplete" -gt 10 ]; then
      echo "[focus]   ...and $((incomplete - 10)) more"
    fi
    echo "[focus] Verify all work is done before stopping, or emit a handoff."
    echo ""
  fi
fi

# --- Clarification blockers ---
# Match real blockers while skipping mentions inside backtick code spans
# (e.g. a requirement description that documents the marker format itself).
# A real blocker: "[NEEDS CLARIFICATION: <question>]" inline in prose or a
# task field. A documentation mention: "`[NEEDS CLARIFICATION: ...]`" wrapped
# in backticks. Awk filters lines where the marker appears between backticks.
blockers=$(awk '
  /^[[:space:]]*```/ { fence = !fence; next }
  fence { next }
  /\[NEEDS CLARIFICATION:/ {
    line = $0
    # Remove any `...` spans; if the marker survives, it was unquoted.
    gsub(/`[^`]*`/, "", line)
    if (line ~ /\[NEEDS CLARIFICATION:/) count++
  }
  END { print count + 0 }
' .focus/plan.md 2>/dev/null); blockers=${blockers:-0}
if [ "$blockers" -gt 0 ]; then
  echo "[focus] === CLARIFICATION BLOCKERS ==="
  echo "[focus] $blockers unresolved [NEEDS CLARIFICATION] marker(s) in plan.md."
  echo "[focus] Ask the human and resolve before executing further tasks. (Track Mode: Ask-before-Task-N markers block only their own task.)"
  echo ""
fi

# --- Atomic schema gaps (task headings without all required fields) ---
task_count=$(grep -c '^### Task ' .focus/plan.md 2>/dev/null); task_count=${task_count:-0}
if [ "$task_count" -gt 0 ]; then
  # Count tasks missing any required field. Rough heuristic: a task section
  # is everything from its "### Task" heading to the next "### " or EOF.
  missing=$(awk '
    /^[[:space:]]*```/ { fence = !fence; next }
    fence { next }
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
if has_handoff; then
  # If a handoff exists, check it has an "Exact next action" — the one field
  # a fresh agent cannot do without.
  if ! awk '/^[[:space:]]*```/ { f = !f } !f && /^## Handoff/ { h = 1 } h' .focus/plan.md | grep -q '^\*\*Exact next action:\*\*'; then
    echo "[focus] === HANDOFF MISSING NEXT ACTION ==="
    echo "[focus] .focus/plan.md has a ## Handoff section but no 'Exact next action:' field."
    echo "[focus] Fix the handoff before ending the session, or a fresh agent will not know what to do."
    echo ""
  fi
fi

# --- Session-end journal reminder ---
# Skipped in Track Mode (rule 4 forbids journal/memory writes on work branches).
in_track=0
case "$PWD" in */.worktrees/*) in_track=1 ;; esac
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
case "$branch" in
  track/*|foundation) [ -f docs/plan/ROADMAP.md ] && in_track=1 ;;
esac
if [ "$in_track" -eq 0 ]; then
  today=$(date +%Y-%m-%d)
  if [ ! -f ".focus/journal/$today.md" ]; then
    echo "[focus] No journal entry for today — append a session entry to .focus/journal/$today.md before ending (see Session End)."
  fi
fi

# --- Gated mode (opt-in) ---
# Blocks stopping while unchecked tasks remain. Safeguards: never when the
# harness signals stop_hook_active (prevents loops), never when a ## Handoff
# exists (the sanctioned way to stop mid-plan), never when .focus/report.md
# carries a STATUS line (a defect stop / completion report — the other
# sanctioned stop; blocking it would push the agent to touch tasks it must
# not, or delete a possibly-committed .focus/mode), capped at 5 blocks per
# plan checkpoint (.stopblocks resets when plan.md changes — stall protection).
if [ -f .focus/mode ] && grep -q '^gated' .focus/mode 2>/dev/null \
   && [ "$incomplete" -gt 0 ] \
   && ! has_handoff \
   && ! has_report_status; then
  if echo "$input" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
    exit 0
  fi
  bf=".focus/.stopblocks${sid8:+.$sid8}"
  if [ ! -f "$bf" ] || [ .focus/plan.md -nt "$bf" ]; then
    blocks=0
  else
    blocks=$(cat "$bf" 2>/dev/null)
    case "$blocks" in ''|*[!0-9]*) blocks=0 ;; esac
  fi
  if [ "$blocks" -lt 5 ]; then
    echo $((blocks + 1)) > "$bf"
    echo "[focus] Gated mode: $incomplete unchecked task(s) in .focus/plan.md. Finish them, emit /focus:handoff, or — for a defect stop — write .focus/report.md with a 'STATUS:' first line. Never edit or remove .focus/mode yourself (it may be committed policy). (block $((blocks + 1))/5)" >&2
    exit 2
  fi
fi
