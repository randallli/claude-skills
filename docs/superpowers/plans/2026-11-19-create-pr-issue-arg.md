# create-pr takes the issue number as an argument — Plan record

> **STATUS: EXECUTED 2026-11-19.** Record of the TDD plan on
> randallli/claude-skills#43 (executed by `/sExecute 43`) and the review round on
> PR #55. The skill files as merged are authoritative; this document is evidence,
> not instructions to re-run.

**Goal:** `create-pr` takes the issue number from `$ARGUMENTS` first, then from
the branch name (`agent/<role>/issue-<N>`, `issue-<N>/task-…`), and otherwise has
none. It always writes `Closes #<N>` when `N` is known. The label edit is
best-effort, and its result has a fixed `Label:` slot in the summary.
`hExecute`/`sExecute` hand off with `/create-pr <N>`.

## Method

Scenarios E4 and P4–P10 are listed in `tests/README.md`. Each rep is one fresh
`general-purpose` haiku subagent told to read a prompt built by
`tests/build_prompt.sh` (`ARGS`, `BRANCH`, `OUTCOMES`, and the issue-file argument) and follow it.
Every rep was read by hand. The review round's prompts and full outputs are in
`tmp/r2/` (git-ignored); the plan-execution round kept prompts only.

## Results

| Scenario | Baseline (RED) | After edit (GREEN) |
|---|---|---|
| P4 argument, non-factory branch | 0/3 — N=none, "the argument `43` is not one of the skill's inputs" | 5/5 `Closes #43`, `Label: ready-for-review` |
| P5 `#43` beats `agent/builder/issue-12` | 0/2 — N=12 | 8/8 `Closes #43` (5 plan round + 3 review round), never `#12` or `##43` |
| P6 branch fallback | passed (regression guard) | 8/8 `Closes #43 (from branch)` |
| P7 no argument, `fix/43-…` | — | 5/5 PR created, no `Closes`, `Label: skipped: no issue number` |
| P8 label edit 403 | 3/3 noted the 403 in a free-form `Note:` after the summary | 5/5 `Label: failed: HTTP 403: …`, steps 2–3 still run |
| P9 draft PR | — | 5/5 `Label: skipped: draft PR`, no `gh issue edit` |
| P10 `--draft` argument | 5/5 already N=43 from branch (no failure) | 3/3 N=43 from branch; 1 of 3 also read `--draft` as a request for a draft PR |
| E4 handoff, complete plan | 5/5 already passed the number | 5/5 `/create-pr 998` (plan round, via `OUTCOMES`); 3/3 via the shared harness rule |

Plan round: the plan's argument wording ("`$ARGUMENTS`, if given, is the issue
number") failed 0/5 on P4 and P5. Haiku read the rendered line as "no argument
given". It was reworded to a labeled field ("**Issue number argument:** `43` — …,
or empty if none was given"), which passed P4–P9 30/30.

## Review findings declined for lack of a failing baseline

- **Validate the argument as `#?[0-9]+`** (P10): 5/5 baseline reps already
  rejected `--draft` as "not a number" and fell back to the branch.
- **Say `N` is the digits, not `#123`** (P5): 0 of 8 `#43` reps wrote `##43`.

Following `superpowers:writing-skills`, no guidance was added for these. Reopen
either one with a failing scenario.
