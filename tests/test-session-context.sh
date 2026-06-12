#!/bin/bash
# Tests for scripts/session-context.sh — silence without .focus/, datetime
# header, principles surfacing, journal display, handoff display, and
# session-once injection (full block on new session id, refresh on repeat).
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

# --- no .focus/: zero output, exit 0 (guard runs before stdin read) ---
sandbox
out=$(echo '{"session_id":"t1"}' | bash "$SCRIPTS/session-context.sh"); rc=$?
t "no .focus exit 0" "$rc" "0"
t "no .focus silent" "$out" ""

# --- datetime header + principles + unchecked-only open items ---
sandbox
mkdir .focus
printf '# Memory\n\n## Principles\n- **MUST** x\n\n## Open Items\n- [x] ~~done-item~~\n- [ ] live-item\n' > .focus/memory.md
out=$(echo '{"session_id":"t2"}' | bash "$SCRIPTS/session-context.sh")
t_contains "datetime header" "$(printf '%s' "$out" | head -1)" "Now: 20"
t_contains "principles surfaced" "$out" "- **MUST** x"
t_contains "unchecked open item shown" "$out" "live-item"
t_missing  "struck open item hidden" "$out" "done-item"

# --- repeat prompt same session: tiny refresh; new session: full again ---
out=$(echo '{"session_id":"t2"}' | bash "$SCRIPTS/session-context.sh")
t "repeat is refresh-only" "$(printf '%s' "$out" | grep -c 'Principles')" "0"
t_contains "refresh has datetime" "$out" "Now: 20"
out=$(echo '{"session_id":"t2b"}' | bash "$SCRIPTS/session-context.sh")
t_contains "new session id restores full block" "$out" "- **MUST** x"

# --- journal: newest file tail + previous file headings only ---
mkdir .focus/journal
printf '# Journal\n\n## 09:00 — first day entry\nbody-one\n' > .focus/journal/2026-01-01.md
printf '# Journal\n\n## 10:00 — second day entry\nbody-two\n' > .focus/journal/2026-01-02.md
out=$(echo '{"session_id":"t3"}' | bash "$SCRIPTS/session-context.sh")
t_contains "journal block present" "$out" "Recent journal"
t_contains "newest journal content shown" "$out" "body-two"
t_contains "previous journal headings shown" "$out" "first day entry"
t_missing  "previous journal body hidden" "$out" "body-one"

# --- plan without handoff: goal + first unchecked task ---
printf '# P\n\n**Goal:** G\n\n### Task 1: A\n\n- [x] Execute\n\n### Task 2: B\n\n- [ ] Execute\n' > .focus/plan.md
out=$(echo '{"session_id":"t4"}' | bash "$SCRIPTS/session-context.sh")
t_contains "active plan shown" "$out" "Active Plan"
t_contains "plan goal shown" "$out" "**Goal:** G"
t_contains "current task shown" "$out" "Task 2: B"
t_missing  "checked task hidden" "$out" "Task 1: A"

# --- plan with handoff: handoff is ground truth ---
printf '# P\n\n**Goal:** G\n\n## Handoff\n\n**Exact next action:** do X\n' > .focus/plan.md
out=$(echo '{"session_id":"t5"}' | bash "$SCRIPTS/session-context.sh")
t_contains "handoff banner" "$out" "HANDOFF"
t_contains "handoff content shown" "$out" "**Exact next action:** do X"
t_missing  "plan head suppressed when handoff" "$out" "Active Plan"

finish
