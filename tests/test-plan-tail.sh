#!/bin/bash
# Tests for scripts/plan-tail.sh — throttle cadence, counter reset,
# current-task selection, handoff pointer, budget warning.
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

PLAN='# T

**Goal:** G
**Level:** MEDIUM

### Task 1: A

- [x] Execute

### Task 2: B

- [ ] Execute

## Decisions
'

# --- no plan: silent, exit 0 ---
sandbox
out=$(bash "$SCRIPTS/plan-tail.sh"); rc=$?
t "no plan exit 0" "$rc" "0"
t "no plan silent" "$out" ""

# --- call 1 injects Goal + first UNCHECKED task ---
sandbox
mkdir .focus
printf '%s' "$PLAN" > .focus/plan.md
out=$(bash "$SCRIPTS/plan-tail.sh")
t_contains "call 1 injects goal" "$out" "**Goal:** G"
t_contains "call 1 shows current task" "$out" "### Task 2: B"
t_missing  "checked task skipped" "$out" "### Task 1: A"
t_missing  "later sections not injected" "$out" "## Decisions"

# --- calls 2-5 silent, call 6 injects, counter = 6 ---
quiet=""
for i in 2 3 4 5; do quiet="$quiet$(bash "$SCRIPTS/plan-tail.sh")"; done
t "calls 2-5 silent" "$quiet" ""
out=$(bash "$SCRIPTS/plan-tail.sh")
t_contains "call 6 injects again" "$out" "### Task 2: B"
t "counter reads 6" "$(cat .focus/.toolcount)" "6"

# --- backdated counter (plan newer) resets and re-injects ---
touch -t 202601010000 .focus/.toolcount
out=$(bash "$SCRIPTS/plan-tail.sh")
t "counter reset to 1" "$(cat .focus/.toolcount)" "1"
t_contains "reset call re-injects" "$out" "### Task 2: B"

# --- pending handoff: exactly one pointer line ---
sandbox
mkdir .focus
printf '%s\n## Handoff\n\n**Exact next action:** x\n' "$PLAN" > .focus/plan.md
out=$(bash "$SCRIPTS/plan-tail.sh")
t_contains "handoff pointer text" "$out" "## Handoff is pending"
t "handoff pointer is one line" "$(printf '%s' "$out" | grep -c .)" "1"

# --- budget warning at 40 uncheckpointed calls ---
sandbox
mkdir .focus
printf '%s' "$PLAN" > .focus/plan.md
touch -t 202601010000 .focus/plan.md
printf '39' > .focus/.toolcount
out=$(bash "$SCRIPTS/plan-tail.sh")
t_contains "budget warning at call 40" "$out" "consider /focus:handoff"

finish
