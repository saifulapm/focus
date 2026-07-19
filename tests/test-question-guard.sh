#!/bin/bash
# question-guard.sh scope tests — the guard fires ONLY in track sessions
# (worktree cwd or track/* branch). The foundation branch is an
# orchestrator mode (spawn confirmations must reach the human): regression
# for the 2026-07-20 foundation false-positive.
. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

GUARD="$SCRIPTS/question-guard.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# --- worktree cwd: blocked (exit 2, question-stop instructions) ---
mkdir -p "$TMP/repo/.worktrees/track-01-x"
out=$(cd "$TMP/repo/.worktrees/track-01-x" && bash "$GUARD" 2>&1); rc=$?
t "worktree cwd blocks (exit 2)" "$rc" "2"
t_contains "worktree cwd names question-stop" "$out" "STATUS: BLOCKED — question:"

# --- track/* branch (no .worktrees in path): blocked ---
mkdir -p "$TMP/trackrepo"
git -C "$TMP/trackrepo" init -q -b "track/02-y"
out=$(cd "$TMP/trackrepo" && bash "$GUARD" 2>&1); rc=$?
t "track/* branch blocks (exit 2)" "$rc" "2"

# --- foundation branch + ROADMAP: NOT blocked (orchestrator mode) ---
mkdir -p "$TMP/found/docs/plan"
git -C "$TMP/found" init -q -b foundation
touch "$TMP/found/docs/plan/ROADMAP.md"
out=$(cd "$TMP/found" && bash "$GUARD" 2>&1); rc=$?
t "foundation branch passes (exit 0)" "$rc" "0"
t "foundation branch stays silent" "$out" ""

# --- plain repo on main: NOT blocked ---
mkdir -p "$TMP/plain"
git -C "$TMP/plain" init -q -b main
out=$(cd "$TMP/plain" && bash "$GUARD" 2>&1); rc=$?
t "main branch passes (exit 0)" "$rc" "0"

# --- non-git dir: NOT blocked ---
mkdir -p "$TMP/nogit"
out=$(cd "$TMP/nogit" && bash "$GUARD" 2>&1); rc=$?
t "non-git dir passes (exit 0)" "$rc" "0"

finish
