#!/bin/bash
# Focus evaluator brief generator.
# Produces .focus/evaluator-brief.md — a self-contained handoff for a fresh
# evaluator session on hosts without sub-agent dispatch (Codex, Gemini, OpenCode).
#
# Usage: bash evaluator-brief.sh
# Output: writes .focus/evaluator-brief.md, prints its path.

set -e

if [ ! -f .focus/plan.md ]; then
  echo "[focus] No .focus/plan.md — nothing to evaluate." >&2
  exit 1
fi

BRIEF=.focus/evaluator-brief.md

# Determine base branch for diff.
BASE=""
for candidate in main master; do
  if git rev-parse --verify "$candidate" >/dev/null 2>&1; then
    BASE=$candidate
    break
  fi
done

if [ -z "$BASE" ]; then
  echo "[focus] Could not find main or master branch — evaluator will need to pick its own base." >&2
fi

MERGE_BASE=""
if [ -n "$BASE" ]; then
  MERGE_BASE=$(git merge-base HEAD "$BASE" 2>/dev/null || true)
fi

{
  echo "# Focus Evaluator Brief"
  echo
  echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Base branch: ${BASE:-unknown}"
  echo "Current branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
  echo
  echo "## Instructions to the evaluator"
  echo
  echo "You are the Focus evaluator. Read the full /focus:evaluate command definition, then use the plan and diff below as your inputs. Run each task's \`Verify:\` command fresh yourself — do not trust the generator's claims. Return the verdict in the format specified by /focus:evaluate."
  echo
  echo "## Plan"
  echo
  echo '```markdown'
  cat .focus/plan.md
  echo '```'
  echo
  echo "## Diff against $BASE"
  echo
  if [ -n "$MERGE_BASE" ]; then
    echo '```diff'
    git diff "$MERGE_BASE"...HEAD
    echo '```'
  else
    echo "_(Could not compute diff — run \`git diff\` manually.)_"
  fi
  echo
  echo "## Files changed"
  echo
  if [ -n "$MERGE_BASE" ]; then
    git diff --name-status "$MERGE_BASE"...HEAD | sed 's/^/- /'
  fi
  echo
  echo "## Principles in force"
  echo
  principles=$(bash "$(dirname "$0")/principles.sh" 2>/dev/null)
  if [ -n "$principles" ]; then
    echo "$principles"
  else
    echo "_(none declared)_"
  fi
} > "$BRIEF"

echo "$BRIEF"
