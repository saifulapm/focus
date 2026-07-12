#!/bin/bash
# Focus test runner — executes every tests/test-*.sh, aggregates results.
# Prints the live assertion total at the end (parsed from each file's
# "# <P> passed, <F> failed" line) so docs cite the runner, not a
# hand-maintained number. Usage: bash tests/run.sh

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
failed=0
total=0
assert_pass=0
assert_fail=0

for f in "$TESTS_DIR"/test-*.sh; do
  [ -f "$f" ] || continue
  total=$((total + 1))
  echo "== $(basename "$f")"
  out=$(bash "$f" 2>&1); rc=$?
  printf '%s\n' "$out"
  [ "$rc" -eq 0 ] || failed=$((failed + 1))
  # Each test file's finish() prints "# <P> passed, <F> failed".
  summary=$(printf '%s\n' "$out" | grep -E '^# [0-9]+ passed, [0-9]+ failed' | tail -1)
  if [ -n "$summary" ]; then
    p=$(printf '%s' "$summary" | sed -E 's/^# ([0-9]+) passed.*/\1/')
    fl=$(printf '%s' "$summary" | sed -E 's/.* ([0-9]+) failed.*/\1/')
    assert_pass=$((assert_pass + p))
    assert_fail=$((assert_fail + fl))
  fi
  echo
done

if [ "$total" -eq 0 ]; then
  echo "No test files found in $TESTS_DIR"
  exit 1
fi

echo "Assertions: $((assert_pass + assert_fail)) run, $assert_pass passed, $assert_fail failed."
if [ "$failed" -gt 0 ]; then
  echo "FAIL: $failed of $total test file(s) failed"
  exit 1
fi
echo "All $total test file(s) passed."
