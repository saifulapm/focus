#!/bin/bash
# Tests for scripts/principles.sh — section extraction and file merge.
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

# --- memory.md Principles section extracted, bounded by next section ---
sandbox
mkdir .focus
printf '# Memory\n\n## Principles\n- **MUST** a\n- **PREFER** b\n\n## Decisions\n- not-a-principle\n' > .focus/memory.md
out=$(bash "$SCRIPTS/principles.sh")
t_contains "memory.md principles header" "$out" "# Principles (from .focus/memory.md)"
t_contains "memory.md MUST line" "$out" "- **MUST** a"
t_contains "memory.md PREFER line" "$out" "- **PREFER** b"
t_missing  "stops at next ## section" "$out" "not-a-principle"

# --- .focus/principles.md merged after memory.md's set ---
printf -- '- **AVOID** c\n' > .focus/principles.md
out=$(bash "$SCRIPTS/principles.sh")
t_contains "principles.md header present" "$out" "# Principles (from .focus/principles.md)"
t_contains "principles.md content merged" "$out" "- **AVOID** c"
t_contains "memory.md set still first" "$out" "- **MUST** a"

# --- neither file: silent success ---
sandbox
out=$(bash "$SCRIPTS/principles.sh"); rc=$?
t "exit 0 with no files" "$rc" "0"
t "empty output with no files" "$out" ""

finish
