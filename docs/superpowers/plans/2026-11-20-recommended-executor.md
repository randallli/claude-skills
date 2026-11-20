# Recommended executor — Plan record

> **STATUS: EXECUTED 2026-11-20, all five tasks.**
> Evidence for #58, not instructions to re-run. The skill files as merged are authoritative.

**Goal:** `/oPlan` and `/fPlan` name the executor that should run each plan
(`/hExecute` or `/sExecute`) with a one-line reason, in a fixed
`### Recommended Executor` section, the footer and the closing output, and
`execute-tagged-issues` dispatches that executor instead of always `/hExecute`.

## Method

Scenarios built by `tests/build_prompt.sh <skill> tests/fixtures/target-with-commands R <issue>`:
X1 (`issue-994.md`, single-file fix, expect `/hExecute`), X2 (`issue-993.md`,
cross-layer persistence, expect `/sExecute`), X3 (`issue-999.md`, replan after a
`/hExecute` escalation, expect `/sExecute`). RED: X2 built from
`git show origin/main:oPlan/SKILL.md` (a copy under `tmp/baseline/`), 3 reps.
GREEN: 5 fresh `general-purpose` reps each of X1, X2, X3 (`model: opus`, oPlan),
plus 2 reps of X2 built from `fPlan` (`model: fable`). Dispatch message: "Read
tmp/prompts/<file> in full and follow it." Criteria per rep, scored by reading
the report: (a) the `WOULD POST:` body starts `## TDD Plan`; (b) exactly one
`### Recommended Executor` heading, next line a backticked executor plus a
reason; (c) the expected executor; (d) footer `Ready for /<same executor>`;
(e) closing line `Run /<same executor> <N>` plus the reason; (f) X3: Tasks 1-2
`- [x]` first and `**Kept from the previous plan:** Task 1, Task 2`; (g)
`tdd-plan-ready` added, and for X3 `tdd-escalation` removed. Per-rep notes are in
`tmp/captures/` (git-ignored). Reps return reports rather than raw files, so
some reps were scored from the report's summary of the posted body; those are
marked in the captures.

## Results

| Scenario | Baseline (RED) | After edit (GREEN) |
|---|---|---|
| X1 simple first plan (oPlan) | not run | **5/5** name `/hExecute` in section, footer, closing line |
| X2 cross-layer first plan (oPlan) | 0/3: no section, footer `Ready for /hExecute`, closing `Run /hExecute 993`, no reason | **5/5** name `/sExecute`; reasons cite layer-spanning tasks, the `Counter` constructor change and async persistence |
| fPlan smoke of X2 (fable) | not run | **2/2** |
| X3 replan after `/hExecute` escalation (oPlan) | not run | **5/5** name `/sExecute` citing the escalation; Tasks 1-2 kept `- [x]`; Kept line present; `tdd-escalation` removed |

No wording iteration was needed.

## Failure classification (from RED)

Omission, not discipline: the baseline planner has no step that asks for an
executor, so every rep produced the fixed footer and nothing else, even for a
5-6 task plan across model, store and screen layers.

## Verbatim baseline notes

- X2 RED rep: "The plan does not recommend an executor (hExecute or sExecute). The skill text in this prompt has no step asking for one."
- X2 RED rep: "No executor recommendation. The skill text in this 'red' prompt has no step for one, so the output names no executor."

## Caveats

- Scored from reports, not raw bodies; three X1 reps, one X3 rep (a2f1, whose
  report also mentions telling the executor to check Task 2's test, placement
  unclear) and two X2 reps (a480, a117) were scored from summaries.
- One fPlan rep leaked the template line "Every task MUST have a Type tag..."
  into the plan body. Unrelated to the executor recommendation; not addressed.
- Reps often classify issue-994 and issue-999 as TDD-only despite wording about
  user-visible behavior, since the fixture has no UI. Out of scope.

## Mechanical checks

`bash tests/check_stale_refs.sh`, `bash tests/check_refs.sh` and
`bash tests/check_sync.sh` are green.
