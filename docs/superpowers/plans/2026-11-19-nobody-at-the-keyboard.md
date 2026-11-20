# "When nobody is at the keyboard" section — Plan record

> **STATUS: EXECUTED 2026-11-19.** Record of the TDD plan on
> randallli/claude-skills#45 (executed by `/sExecute 45`). The skill files as
> merged are authoritative; this document is evidence, not instructions to re-run.

**Goal:** `oPlan`, `fPlan`, `hExecute`, `sExecute` and `create-pr` each carry one
identical `## When nobody is at the keyboard` section. The planners gain a fixed
`### Escalation Required` comment for when they are blocked. `create-pr` no
longer swaps `agent-*` labels (the dispatchers already do).

## Method

Scenarios H1, H2 and the P/E/R regressions are listed in `tests/README.md`. Each
rep was one fresh `general-purpose` subagent at the skill's runtime model, told
to read a prompt built by `tests/build_prompt.sh`. Every rep was read by hand.
Prompts and captures are in `tmp/` (git-ignored). Rep counts were lower than
planned for several regression scenarios, noted below.

## Results

| Scenario | Baseline (RED) | After edit (GREEN) |
|---|---|---|
| H1 blocked planner (oPlan opus, fPlan fable) | 0/3 — each invented its own comment shape, none starting with a matchable heading; two told the reader to re-run or re-add `agent-should-plan` | 6/6 post a `### Escalation Required` comment with `**Blocker:**`, no label, no re-run instruction, then stop. 4/6 also posted the pre-existing "investigating" comment first, so "exactly one `WOULD POST:`" held 2/6; the escalation comment itself was single in 6/6 |
| R1/R2 replan regression (oPlan) | — | 1 rep each: `## TDD Plan` posted, `tdd-escalation` removed, `tdd-plan-ready` added. fPlan not run (differs only in self-references) |
| H2 executor on `agent/reviewer/issue-998` | 3/3 already stayed on the branch | 6/6 (haiku x3, sonnet x3): no checkout/branch/switch, push to the reviewer branch |
| E1, E4 regression (executors) | — | 1 rep per model each: E1 unchanged, E4 `WOULD INVOKE: /create-pr 998` |
| P4 create-pr, argument 43 | label swap instructed unconditionally | 1/1 `Closes #43`, no `gh issue edit`, no `Label:` slot |
| P9 draft PR | — | 1/1 PR created, no `gh issue edit`, no merge |
| P6, P7 regression | not run | not run: step 1's derivation text is unchanged apart from dropping the label-edit mention |

## Decision

`create-pr`'s `ready-for-review`/`agent-started` swap conflicted with the issue's
rule that only the dispatcher owns `agent-*` labels. It was deleted from step 1,
which also retired the `Label:` summary slot and scenarios P8 (label 403). P4,
P7 and P9 rows were updated.

## Contract-only lines

These rules had no failing baseline. They are kept because the issue makes them
the caller contract:

- Branch rule: never create, switch or delete a branch on an
  `agent/<role>/issue-<N>` or `issue-<N>/task-…` branch (H2 baseline 3/3).
- Never merge.
- Executors do not wait for an answer: they escalate and stop.
