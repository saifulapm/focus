#!/bin/bash
# Tests for scripts/check-complete.sh — advisory warnings, backtick-aware
# blocker detection, schema gaps, journal reminder, gated mode.
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

cc() { echo "${1:-{\}}" | bash "$SCRIPTS/check-complete.sh" 2>stderr.txt; }

# --- no plan: silent, exit 0 ---
sandbox
out=$(cc); rc=$?
t "no plan exit 0" "$rc" "0"
t "no plan silent" "$out" ""

# --- incomplete plan: warning with remaining count ---
sandbox
mkdir .focus
printf '**Goal:** G\n\n- [x] one\n- [ ] two\n- [ ] three\n' > .focus/plan.md
out=$(cc)
t_contains "incomplete warning" "$out" "INCOMPLETE PLAN"
t_contains "remaining count" "$out" "1/3 checkboxes complete. 2 remaining"

# --- blockers: unquoted counts, backticked documentation mention does not ---
printf '**Goal:** G\n\n- [ ] x\n[NEEDS CLARIFICATION: which db?]\n' > .focus/plan.md
out=$(cc)
t_contains "unquoted blocker detected" "$out" "CLARIFICATION BLOCKERS"
printf '**Goal:** G\n\n- [ ] x\nUse the `[NEEDS CLARIFICATION: ...]` marker format.\n' > .focus/plan.md
out=$(cc)
t_missing "backticked mention ignored" "$out" "CLARIFICATION BLOCKERS"

# --- atomic schema gaps name the missing fields ---
printf '**Goal:** G\n\n### Task 1: A\n\n**Files:**\n- x\n\n**Action:**\ndo\n\n- [ ] Execute\n' > .focus/plan.md
out=$(cc)
t_contains "schema gap section" "$out" "ATOMIC SCHEMA GAPS"
t_contains "missing fields named" "$out" "missing: Verify Done-when Commit"

# --- journal reminder: fires without today's file, silent with it ---
printf '**Goal:** G\n\n- [x] done\n' > .focus/plan.md
out=$(cc)
t_contains "journal reminder fires" "$out" "No journal entry for today"
mkdir -p .focus/journal && touch ".focus/journal/$(date +%Y-%m-%d).md"
out=$(cc)
t_missing "journal reminder silent" "$out" "No journal entry"

# --- gated mode ---
sandbox
mkdir .focus
printf '**Goal:** G\n\n### Task 1: A\n\n- [ ] Execute\n' > .focus/plan.md
echo gated > .focus/mode

cc >/dev/null; rc=$?
t "gated blocks (exit 2)" "$rc" "2"
t_contains "block counter message" "$(cat stderr.txt)" "block 1/5"
t "stopblocks reads 1" "$(cat .focus/.stopblocks)" "1"

cc '{"stop_hook_active": true}' >/dev/null; rc=$?
t "stop_hook_active exempt" "$rc" "0"

printf '5' > .focus/.stopblocks
touch -t 202601010000 .focus/plan.md   # plan older than counter: no reset, at any future date
cc >/dev/null; rc=$?
t "5-block cap allows stop" "$rc" "0"

rm .focus/.stopblocks
printf '\n## Handoff\n\n**Exact next action:** x\n' >> .focus/plan.md
cc >/dev/null; rc=$?
t "handoff exempts gating" "$rc" "0"

sandbox
mkdir .focus
printf '**Goal:** G\n\n- [ ] x\n' > .focus/plan.md
cc >/dev/null; rc=$?
t "advisory default exit 0" "$rc" "0"

# --- per-session gated block counter keyed on session_id ---
sandbox
mkdir .focus
printf '**Goal:** G\n\n### Task 1: A\n\n- [ ] Execute\n' > .focus/plan.md
echo gated > .focus/mode
echo '{"session_id":"11112222aaaa"}' | bash "$SCRIPTS/check-complete.sh" >/dev/null 2>stderr.txt; rc=$?
t "gated blocks per session (exit 2)" "$rc" "2"
t "per-session stopblocks file created" "$(cat .focus/.stopblocks.11112222)" "1"
t "no shared stopblocks when session_id present" "$([ -f .focus/.stopblocks ] && echo present || echo absent)" "absent"

# --- stale per-session stopblocks (idle >1 day) swept ---
printf '5' > .focus/.stopblocks.staleses
touch -t 202601010000 .focus/.stopblocks.staleses
echo '{"session_id":"33334444bbbb"}' | bash "$SCRIPTS/check-complete.sh" >/dev/null 2>stderr.txt
t "stale session stopblocks deleted" "$([ -f .focus/.stopblocks.staleses ] && echo present || echo absent)" "absent"

finish
