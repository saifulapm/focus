#!/bin/bash
# Focus test runner — executes every tests/test-*.sh, aggregates results.
# Usage: bash tests/run.sh

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
failed=0
total=0

for f in "$TESTS_DIR"/test-*.sh; do
  [ -f "$f" ] || continue
  total=$((total + 1))
  echo "== $(basename "$f")"
  if ! bash "$f"; then
    failed=$((failed + 1))
  fi
  echo
done

if [ "$total" -eq 0 ]; then
  echo "No test files found in $TESTS_DIR"
  exit 1
fi
if [ "$failed" -gt 0 ]; then
  echo "FAIL: $failed of $total test file(s) failed"
  exit 1
fi
echo "All $total test file(s) passed."
