#!/bin/bash
# Focus principles loader.
# Outputs the merged Principles set from:
#   1. .focus/memory.md (## Principles section)
#   2. .focus/principles.md (whole file, if present — for bigger projects)
#
# Prints nothing if no principles are declared. Used by session-context.sh,
# check-complete.sh, and invoked directly by the /focus:evaluate command.

has_any=0

if [ -f .focus/memory.md ]; then
  block=$(awk '
    /^## Principles/ { in_p = 1; next }
    in_p && /^## / { in_p = 0 }
    in_p && NF { print }
  ' .focus/memory.md)

  if [ -n "$block" ]; then
    echo "# Principles (from .focus/memory.md)"
    echo "$block"
    has_any=1
  fi
fi

if [ -f .focus/principles.md ]; then
  [ "$has_any" = 1 ] && echo
  echo "# Principles (from .focus/principles.md)"
  cat .focus/principles.md
  has_any=1
fi

exit 0
