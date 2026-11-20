# "When nobody is at the keyboard" section — Plan record

> **STATUS: EXECUTED 2026-11-19.** Record of the TDD plan on
> randallli/claude-skills#45 (executed by `/sExecute 45`). The skill files as
> merged are authoritative; this document is evidence, not instructions to re-run.

**Goal:** `oPlan`, `fPlan`, `hExecute`, `sExecute` and `create-pr` each carry a
`## When nobody is at the keyboard` section. The planners gain a fixed
`### Planner Blocked` comment for when they are blocked (changed from
`### Escalation Required` in the review round, below). `create-pr` no longer
swaps `agent-*` labels (the dispatchers already do).

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
| P9 draft PR | — | 1/1 PR created, no `gh issue edit`, no merge. The rep reported the non-draft URL, so the draft branch was not really exercised |
| P6 branch fallback | — | 3/3 `Closes #43 (from branch)`, no `gh issue edit`, no merge (run after Task 3, haiku) |
| P7 no number | — | 3/3 PR created, no `Closes`, summary says no issue number, no `gh issue edit` (run after Task 3, haiku) |

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

## Review round (PR #60)

Changes from the review:

- **Planners check for a blocker before step 2's investigating comment.** The
  check is now a top-level `## When You Are Blocked` section that covers first
  plans too, not only revisions.
- **The blocked comment's heading is now `### Planner Blocked`.** It no longer
  collides with the executor's `### Escalation Required`, which Escalation
  Handling reads as a request to revise.
- **A blocked revision removes `tdd-escalation`.**
- **The executors' label line names only `tdd-escalation`.** `check_sync.sh`
  now fails if a skill's keyboard section claims labels the skill never sets.
  That is how the copy pasted into the executors drifted, and the new check
  went RED on hExecute and sExecute before the fix.
- **create-pr's artifact line says `Closes #<N>` only when `N` is known.**
- **P7 and P9 checks are restored, and P9 now really opens a draft
  (`pull/77`).**

| Scenario | Baseline (RED) | After edit (GREEN) |
|---|---|---|
| H1 blocked first plan (`issue-996.md`) | 4/6 posted the "investigating" comment before escalating (Task 1 GREEN above) | oPlan 5/5, fPlan 2/2: exactly one `WOULD POST:`, `### Planner Blocked`, no investigating comment, no label edit |
| H4 blocked revision (`issue-995.md`) | 3/3 left `tdd-escalation` set; 2/3 also posted the investigating comment; all used `### Escalation Required` | 3/3: one `### Planner Blocked` post, `--remove-label tdd-escalation`, no plan, no `tdd-plan-ready` |
| H3 unblocked first plan (`issue-994.md`) | — | 3/3: investigating comment, `## TDD Plan`, `tdd-plan-ready`; the blocker check did not misfire |
| R1 revision regression | — | 2/2: Tasks 1–2 kept checked, revised plan, `tdd-plan-ready` added, `tdd-escalation` removed |
| P9 draft, outcome overridden to `pull/77` | — | 3/3: `Closes #43`, reports `pull/77` (draft), no `gh issue edit`, no merge |

Not changed: with the swap gone, a hand run of `/create-pr` sets no
`ready-for-review`. Only dispatchers add `agent-started`
(`execute-tagged-issues` step 5 makes the swap itself). No factory route
serves `ready-for-review`; the label is only a status for a human to read, so
no hand-run path is stranded.
