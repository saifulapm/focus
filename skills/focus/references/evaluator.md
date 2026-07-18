# Evaluator Gate — Invocation & Verdicts

Load this file when you are about to spawn the evaluator or act on its verdict. SKILL.md's Evaluator Gate has the *why* and the *when* (including the LARGE adaptive cadence); this file has the spawn mechanics, verdict handling, and anti-patterns.

The evaluator is a **fresh, adversarial** reader of the plan and the diff, with no memory of how the work got made. Your own verification is input to it, not a substitute.

## How to invoke

Spawn a fresh sub-agent using Claude Code's Agent / Task primitive. Sub-agents cannot resolve slash commands — point it at the command **file**, and locate it first (the path differs by install): try `.claude/commands/focus/evaluate.md` (project-vendored — the only path that exists on a fresh clone/VPS), then `~/.claude/commands/focus/evaluate.md`; if both absent (plugin install), find it with `find ~/.claude/plugins -name evaluate.md -path '*focus*' 2>/dev/null | head -1`.

Then tell the sub-agent: *"Read `<verified absolute path>` and follow its procedure exactly against the current branch. Return the verdict exactly in its specified format. You have no prior context — read `.focus/plan.md` and the diff yourself, and run each task's `Verify:` command fresh."* Do not freelance the format; the generator needs a predictable structure to machine-read the verdict.

## What to do with the verdict

- **PASS** — proceed to merge (Track Mode: to the ready-to-merge report — Track Mode rule 3 still forbids merging). Record any evaluator suggestions in log.md for next-session follow-up.
- **CHANGES REQUESTED** — address every blocker issue. Re-invoke the evaluator after fixes (fresh agent every time), including the **prior evaluator report verbatim** in its prompt so it can run prior-report mode (full re-check of FAILED REQs, regression check on VERIFIED ones). Never include your own summary of the fixes. Do not argue with the evaluator; treat its report as the source of truth until you can show the diff refutes it.
- **FAIL** — the plan itself is wrong, not just the code. Update plan.md, note the escalation in log.md, consider whether the task has become LARGE, then continue.
- **UNCERTAIN** — the evaluator asked a specific question. Answer it in plan.md or log.md, then re-invoke.

## Anti-patterns for the generator

- Do **not** prompt the evaluator with a summary of what was built — let it read the diff cold.
- Do **not** re-invoke the same evaluator instance after a FAIL. Context contamination defeats the purpose. Use a fresh agent every time.
- Do **not** accept a PASS that skipped running `Verify:` commands — the evaluator must have command output in its report.
- Do **not** self-grant PASS by writing the evaluator's verdict yourself. If sub-agent spawn fails, tell the human the plan cannot be marked complete without human review, rather than freelancing the verdict.
