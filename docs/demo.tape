# vhs tape — renders docs/demo.gif
# Re-render: create the fixture (see journal 2026-06-12), then `vhs docs/demo.tape`

Output docs/demo.gif

Set FontSize 15
Set Width 1020
Set Height 660
Set Padding 16
Set Theme "Catppuccin Mocha"
Set TypingSpeed 35ms
Set Shell bash

Hide
Type "cd /tmp/focus-demo && export PS1='\[\e[1;35m\]focus-demo\[\e[0m\] $ ' && clear"
Enter
Show

Type "# Focus — every session starts informed. Hooks inject your state:"
Enter
Sleep 800ms
Type "bash ~/.claude/skills/focus/scripts/session-context.sh"
Enter
Sleep 5s

Type "clear"
Enter
Type "# Every task is atomic: Files / Action / Verify / Done when / Commit"
Enter
Sleep 600ms
Type "sed -n '24,46p' .focus/plan.md"
Enter
Sleep 4.5s

Type "clear"
Enter
Type "# Before 'done': a fresh sub-agent evaluates the diff cold."
Enter
Type "# It runs your Verify commands itself. Self-review never counts."
Enter
Sleep 800ms
Type "cat evaluation.md"
Enter
Sleep 5s

Type "clear"
Enter
Type "# Stop grading your own homework. Just focus."
Enter
Sleep 2.5s
