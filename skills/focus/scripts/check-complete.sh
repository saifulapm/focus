#!/bin/bash
# Focus completion checker — runs on Stop hook
# Warns if plan.md has unchecked phases

if [ ! -f .focus/plan.md ]; then
  exit 0
fi

total=$(grep -c '^- \[' .focus/plan.md 2>/dev/null || echo 0)
done=$(grep -c '^- \[x\]' .focus/plan.md 2>/dev/null || echo 0)
incomplete=$((total - done))

if [ "$incomplete" -gt 0 ]; then
  echo ""
  echo "[focus] === INCOMPLETE PLAN ==="
  echo "[focus] $done/$total phases complete. $incomplete remaining:"
  grep '^- \[ \]' .focus/plan.md 2>/dev/null | while read -r line; do
    echo "[focus]   $line"
  done
  echo "[focus] Verify all work is done before stopping."
  echo ""
fi

# Check if memory.md was updated this session
if [ -f .focus/memory.md ]; then
  last_modified=$(stat -f %m .focus/memory.md 2>/dev/null || stat -c %Y .focus/memory.md 2>/dev/null || echo 0)
  now=$(date +%s)
  age=$((now - last_modified))
  # If memory.md hasn't been updated in the last 2 minutes, remind
  if [ "$age" -gt 120 ]; then
    echo "[focus] Reminder: Update .focus/memory.md with session summary before stopping."
  fi
fi
