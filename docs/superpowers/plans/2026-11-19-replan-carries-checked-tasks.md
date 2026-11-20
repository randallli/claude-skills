# Replan carries checked tasks — Plan record

> **STATUS: EXECUTED 2026-11-19, all three tasks; recipe revised after PR #56 review** (see "Review revision" below).
> Evidence for randallli/claude-skills#41, not instructions to re-run. The skill
> files as merged are authoritative.

**Goal:** after a `tdd-escalation`, `/oPlan` carries every already-checked task
into the new `## TDD Plan` comment unchanged and still checked, revises only the
unfinished tasks, and names the kept tasks in a required Notes slot.

## Method

Scenarios R1 (`issue-999.md`: Tasks 1-2 checked, Task 3 escalated, author comment
inviting a full rethink) and R2 (`issue-997.md`: escalated at Task 1, nothing
checked), built by `tests/build_prompt.sh oPlan tests/fixtures/target-with-commands R [issue]`.
5 fresh `general-purpose` reps each, `model: opus`, dispatch message "read the
prompt file in full and follow it". Every rep read by hand. Pass criteria per rep:
(a) posted plan starts with `## TDD Plan`; (b) R1: Tasks 1 and 2 entries
unchanged, `- [x]`, before any `- [ ]`; (c) unchecked tasks address the blocker;
(d) Notes carries a `Kept from the previous plan:` line (R1: Task 1, Task 2;
R2: none). R2 additionally: no `- [x]`.

Deviation from the plan: (b) was checked by reading the posted bodies against
the v1 entries, not by `sed`+`diff`, because reps returned their output as
messages rather than files. Captures (full subagent transcripts) are under
`tmp/captures/` (git-ignored).

## Results

| Scenario | Baseline (RED) | After edit (GREEN) |
|---|---|---|
| R1 | 0/5 pass. All 5 kept Tasks 1-2 checked, but none had a Kept line (fail d); reps 1 and 4 also edited Task 2's entry (added a note / an Executor bullet) (fail b); all 5 headers were `## TDD Plan (revised after escalation)` | **5/5** |
| R2 | 0/5 pass. No task checked (correct), but no Notes line saying none were kept (fail d) | **5/5** |

One iteration; no REFACTOR pass needed. Reps converged on one shape: exact
`## TDD Plan` header, Tasks 1-2 copied verbatim and `- [x]`, Task 3 rewritten as
standalone plus a new `reset()` task, `**Kept from the previous plan:**` first line
under Notes. (Side finding, out of scope: reps disagree on whether to run
`git checkout` in Step 3 during a replan, and several flag the fixture's
`issue-998` branch name; not addressed here.)

## Failure classification (from RED)

Omission of a required element plus drift in a copied element, not discipline:
baseline reps already preserved checked tasks, but nothing required them to
say so and half re-worded Task 2. The fix is a recipe (locate previous plan,
list checked tasks, compose checked-first-unchanged, fill the slot) and a
required Notes slot, with no prohibitions. No rationalization counters added.

## Verbatim baseline notes

- R1 rep 4: "Executor: confirm this test is present on `agent/builder/issue-999`" (edit inside kept Task 2).
- R1 rep 1: appended a note under kept Task 2 about the test being absent from the checkout.
- R2 rep 5: "## TDD Plan (revised after /hExecute escalation)"; Notes had no kept-line.

## Mechanical checks

`bash tests/check_stale_refs.sh` and `bash tests/check_sync.sh` stay green.
Task 3 extended `check_sync.sh` to the oPlan/fPlan pair. Red: with fPlan
untouched it exited 1, showing only the Escalation Handling and Notes-slot
hunks. Green: after mirroring oPlan's edit, both pairs report in sync.

## fPlan smoke (R1, `model: fable`)

2/2 reps pass (a)-(d), scored by reading: exact `## TDD Plan` header, Tasks 1-2
carried over `- [x]` before any `- [ ]`, Task 3 rewritten to stand alone plus a new
`reset()` Task 4, first Notes line `**Kept from the previous plan:** Task 1, Task 2`.
Both reps converged on the same shape as oPlan's green reps.

> Rebase note (2026-11-19): #54 landed the same `check_sync.sh` extension to the oPlan/fPlan pair first; on rebase the branch took main's version (which also catches copied self-references). Task 3's Red/Green above describe the pre-rebase run.

## Review revision (PR #56)

The PR review asked for four changes to the recipe and three to the harness:
read the escalation blocker first; drop the `gh api` id/body calls (the body is
already in step 1's output); define the Notes slot for first plans
(`none (first plan)`) and for replans with nothing checked
(`none (no task was checked)`); say that revised tasks are numbered on from the
last kept task and that a kept task whose design must change is amended by a
new unfinished task, never edited. Harness: `<ISSUE_NUM>` placeholder in
`harness-rules.md` (filled by `build_prompt.sh`, 998 for P/F), a stated
`git rev-parse` outcome in the R block instead of the stale `git checkout`/
`git pull`, a guard on fixtures without a `# Issue #N` header, and a
file-exists fallback for the issue path.

GREEN re-run with the revised recipe and harness (opus, 5 reps each, read by hand):

| Scenario | After review revision |
|---|---|
| R1 (issue-999, Tasks 1-2 checked) | **5/5** — Tasks 1-2 verbatim `- [x]` first; revised tasks numbered 3, 4; Notes first line `Task 1, Task 2`; all five declined the "rethink the whole plan" comment for the checked tasks; one rep noted the fixture test file lacks Task 2's test and put that in Notes, not inside the kept entry |
| R2 (issue-997, nothing checked) | **5/5** — no `- [x]`; numbering from 1; Notes first line `none (no task was checked)` |

All ten used the stated `git rev-parse` outcome for `Planned against:`, so that line
is now scorable. No RED re-run: the baseline failure (no Kept line, drift in a
copied entry) is unchanged by these edits. Side finding, out of scope: the
`target-with-commands` fixture's `test/counter_test.dart` holds only Task 1's test
although Task 2 is checked in `issue-999.md`; reps notice and (correctly) do not act.

