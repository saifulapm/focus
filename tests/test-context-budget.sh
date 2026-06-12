#!/bin/bash
# Context-budget regression tests — bloat is a CI failure, not a hope.
# Builds deliberately oversized .focus state and asserts every hook's
# output stays under its cap.
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

sandbox
mkdir -p .focus/journal

# memory.md: principles + 20 open items (12 unchecked)
{
  printf '# Memory\n\n## Principles\n'
  printf -- '- **MUST** keep public APIs backward-compatible through a full major version.\n'
  printf -- '- **MUST NOT** add runtime npm dependencies without explicit approval.\n'
  printf -- '- **PREFER** composition over inheritance.\n'
  printf '\n## Open Items\n'
  for i in $(seq 1 8); do printf -- '- [x] ~~resolved item %s with a fairly long explanation trailing it~~\n' "$i"; done
  for i in $(seq 1 12); do printf -- '- [ ] open item %s with a fairly long explanation trailing it\n' "$i"; done
} > .focus/memory.md

# Two journal files, 60 entries each (~6KB apiece)
for f in 2026-01-01 2026-01-02; do
  { printf '# Journal — %s\n' "$f"
    for i in $(seq 1 60); do
      printf '\n## %02d:00 — session entry %s\n- **Task:** something moderately descriptive that ran that day (MEDIUM)\n- **Notes:** a sentence of narrative that makes the file realistically heavy.\n' "$((i % 24))" "$i"
    done
  } > ".focus/journal/$f.md"
done

# plan.md with 10 atomic tasks (first one checked)
{
  printf '# Big Plan\n\n**Goal:** Ship the oversized feature\n**Level:** LARGE\n\n## Requirements\n- REQ-1: x\n\n---\n\n'
  for i in $(seq 1 10); do
    printf '### Task %s: do thing %s\n\n**Files:**\n- Modify: `src/file%s.ts`\n\n**Action:**\nEdit the thing.\n\n**Verify:** `true`\n\n**Done when:** exit 0\n\n**Commit:** `feat: thing %s`\n\n' "$i" "$i" "$i" "$i"
    if [ "$i" -eq 1 ]; then printf -- '- [x] Execute\n- [x] Verify passes\n- [x] Commit\n\n' ; else printf -- '- [ ] Execute\n- [ ] Verify passes\n- [ ] Commit\n\n'; fi
  done
} > .focus/plan.md

# --- session-context: full block capped, repeat prompt tiny ---
full=$(echo '{"session_id":"b1"}' | bash "$SCRIPTS/session-context.sh")
bytes=${#full}
t "full block under 3500 bytes (got $bytes)" "$((bytes <= 3500))" "1"
t_contains "full block keeps principles" "$full" "MUST NOT"
t_contains "full block keeps an open item" "$full" "open item 1"
t_contains "full block keeps plan position" "$full" "Task 2: do thing 2"
t_missing  "full block drops resolved items" "$full" "resolved item"

repeat=$(echo '{"session_id":"b1"}' | bash "$SCRIPTS/session-context.sh")
rbytes=${#repeat}
t "repeat prompt under 200 bytes (got $rbytes)" "$((rbytes <= 200))" "1"
t_contains "repeat prompt keeps plan pointer" "$repeat" "Active plan:"

# --- plan-tail: injection capped at 35 lines ---
rm -f .focus/.toolcount
lines=$(bash "$SCRIPTS/plan-tail.sh" | wc -l | tr -d ' ')
t "plan-tail injection <= 35 lines (got $lines)" "$((lines <= 35))" "1"

# --- check-complete: output capped at 40 lines ---
cclines=$(echo '{}' | bash "$SCRIPTS/check-complete.sh" 2>/dev/null | wc -l | tr -d ' ')
t "check-complete output <= 40 lines (got $cclines)" "$((cclines <= 40))" "1"

finish
