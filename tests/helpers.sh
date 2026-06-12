#!/bin/bash
# Shared assertions for Focus script tests. Source from tests/test-*.sh.
# No dependencies — bash, coreutils, awk/grep only.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="$REPO_ROOT/skills/focus/scripts"
PASS=0
FAIL=0

t() { # t <description> <actual> <expected>
  if [ "$2" = "$3" ]; then
    PASS=$((PASS + 1)); echo "ok - $1"
  else
    FAIL=$((FAIL + 1)); echo "not ok - $1 (expected '$3', got '$2')"
  fi
}

t_contains() { # t_contains <description> <haystack> <needle>
  case "$2" in
    *"$3"*) PASS=$((PASS + 1)); echo "ok - $1" ;;
    *) FAIL=$((FAIL + 1)); echo "not ok - $1 (output does not contain '$3')" ;;
  esac
}

t_missing() { # t_missing <description> <haystack> <needle>
  case "$2" in
    *"$3"*) FAIL=$((FAIL + 1)); echo "not ok - $1 (output unexpectedly contains '$3')" ;;
    *) PASS=$((PASS + 1)); echo "ok - $1" ;;
  esac
}

sandbox() { # fresh temp dir per scenario; scripts resolve .focus/ from cwd
  SANDBOX="$(mktemp -d)"
  cd "$SANDBOX" || exit 1
}

finish() {
  echo "# $PASS passed, $FAIL failed"
  [ "$FAIL" -eq 0 ]
}
