#!/bin/bash
# Focus PreToolUse injector.
# Prints a short reminder of the active plan before every tool call.
# Handoff-aware: if a Handoff section exists, show it — that is the
# ground truth. Otherwise show the plan head (goal + first task).

[ -f .focus/plan.md ] || exit 0

if grep -q '^## Handoff' .focus/plan.md 2>/dev/null; then
  awk '
    /^## Handoff/ { in_h = 1; print; next }
    in_h && /^## / { in_h = 0 }
    in_h { print }
  ' .focus/plan.md
else
  head -20 .focus/plan.md
fi
