#!/bin/bash
# Tests for scripts/session-context.sh — silence without .focus/, datetime
# header, principles surfacing, journal tail, handoff display.
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

# --- no .focus/: zero output, exit 0 ---
sandbox
out=$(bash "$SCRIPTS/session-context.sh"); rc=$?
t "no .focus exit 0" "$rc" "0"
t "no .focus silent" "$out" ""

# --- datetime header + principles ---
sandbox
mkdir .focus
printf '# Memory\n\n## Principles\n- **MUST** x\n' > .focus/memory.md
out=$(bash "$SCRIPTS/session-context.sh")
t_contains "datetime header" "$(printf '%s' "$out" | head -1)" "Now: 20"
t_contains "principles surfaced" "$out" "- **MUST** x"

# --- recent journal shown (latest two files) ---
mkdir .focus/journal
printf '# Journal\nentry-one\n' > .focus/journal/2026-01-01.md
printf '# Journal\nentry-two\n' > .focus/journal/2026-01-02.md
out=$(bash "$SCRIPTS/session-context.sh")
t_contains "journal block present" "$out" "Recent journal"
t_contains "newest journal file shown" "$out" "2026-01-02"
t_contains "journal content shown" "$out" "entry-two"

# --- plan without handoff: Active Plan head ---
printf '# P\n\n**Goal:** G\n' > .focus/plan.md
out=$(bash "$SCRIPTS/session-context.sh")
t_contains "active plan shown" "$out" "Active Plan"
t_contains "plan goal shown" "$out" "**Goal:** G"

# --- plan with handoff: handoff is ground truth ---
printf '# P\n\n**Goal:** G\n\n## Handoff\n\n**Exact next action:** do X\n' > .focus/plan.md
out=$(bash "$SCRIPTS/session-context.sh")
t_contains "handoff banner" "$out" "HANDOFF"
t_contains "handoff content shown" "$out" "**Exact next action:** do X"
t_missing  "plan head suppressed when handoff" "$out" "Active Plan"

finish
