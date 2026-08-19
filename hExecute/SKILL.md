---
name: hExecute
model: haiku
description: Execute TDD tasks from an oPlan plan on a GitHub issue, one task at a time using Red-Green-Refactor discipline
---

<!-- KEEP IN SYNC WITH sExecute/SKILL.md — the two files are identical except: name, model, description, and the /hExecute vs /sExecute self-references. Mirror any change to the steps, escalation, scripts, or output in both files. -->

# TDD Executor Instructions

You are the execution phase of a two-phase TDD workflow. Your job is to implement one task at a time from the plan, following strict Red-Green-Refactor discipline.

## Input

`$ARGUMENTS` should be a GitHub issue number (e.g., `#123` or `123`).

## Steps

1. **Fetch the Plan:**
   Before doing anything else, check whether a ready PR already exists for
   this issue: `gh pr list --state open --json number,isDraft,headRefName`
   and match the head branch against `agent/<role>/issue-<N>` or
   `issue-<N>/task-…` — the two forms the factory mints. If a matching PR has
   `isDraft: false`, the work is already shipped: report the PR and **stop**
   — do not open another PR, do not invoke `/create-pr`, and do not start a
   Red-Green-Refactor cycle. **A draft PR is not a stop condition** — it
   means the work is still in flight, so continue to the plan below as
   normal.

   Use `gh issue view <N> --comments` to read the issue comments. Find the most recent comment whose body **starts with** `## TDD Plan` and parse it to find the next unchecked task (`- [ ]`). `startswith`, not `contains` — and the same predicate as the id query below, deliberately: if the two disagreed you would read one comment and check a box in another.

   Also record that comment's id — reading the body via `gh issue view --comments` does not
   surface it, and the last step below needs it to `PATCH` the same comment back:

   ```bash
   gh api repos/{owner}/{repo}/issues/<N>/comments --paginate \
     --jq '.[] | select(.body | startswith("## TDD Plan")) | .id' | tail -1
   ```

   `startswith`, not `contains` — a comment that merely mentions "## TDD Plan" partway through
   its body (a re-review, an escalation) must never be mistaken for the plan itself. Take the
   last match, consistent with "the most recent" above.

   **If every task in the plan is already checked (`- [x]`), the work order is done — this is not this step's job to repeat.** Invoke `/create-pr` now and stop: do not start another Red-Green-Refactor cycle, and do not just report "run `/create-pr`" as text without calling it. `/create-pr` is staged into this same worktree specifically for this handoff.

   Note the task's Type tag — `(Setup)`, `(BDD)`, or `(TDD)` — from the task title; it changes the Red phase below. Tasks without a tag are TDD.

2. **Stay on the Worktree's Branch:**
   One branch per work order, not one per task — do not mint a new branch for
   each task. Re-derive the current branch at the start of every task; nothing
   persists it between tasks, since each task runs in its own `claude -p`
   process:

   ```bash
   git rev-parse --abbrev-ref HEAD
   ```

   The worktree was already placed on the work order's branch before this
   skill started — `ensure_worktree` puts scheduler-dispatched runs on
   `agent/<role>/issue-<N>`. If instead a human is running this skill directly
   with no scheduler dispatch (so there is no `<role>` to derive), pin the
   fallback literally to `agent/builder/issue-<N>` — a human running
   `/hExecute` is doing the Builder's job by definition, and this is one of
   the two branch shapes `create-pr` and the scheduler both recognise:

   ```bash
   git checkout -B agent/builder/issue-<N>
   ```

   Called on the branch you are already on, with no start-point, `git
   checkout -B <branch>` is a safe no-op — it does not reset anything. Do
   **not** invent a per-task `issue-<N>/task-<M>-<short-description>` branch;
   that shape is still recognised on PRs opened before this task landed, but
   it is no longer minted.

3. **Phase 1: Red (Write Failing Test)**

   Branch on the task's Type tag:

   **TDD task:**
   - Write the test file for the task
   - Run tests: `./scripts/run_tests.sh <test_file>` (prints summary automatically)
   - **Verify the test FAILS.** If it passes:
     - Check if the feature already exists
     - Verify you're testing the correct behavior
     - Do NOT proceed until you have a legitimate failing test

   **Setup task:** No Red-Green cycle. Perform the listed infrastructure steps
   (dev dependencies, smoke `.feature`), run
   `dart run build_runner build --delete-conflicting-outputs`, verify a test was
   generated from the smoke feature and passes, then skip to step 6.

   **BDD task:**
   1. Create the `.feature` file at the planned `Feature:` path. Copy the
      scenario from the plan **verbatim** — add only a `Feature: <name>` header
      line. Do not rewrite, "improve", or re-derive the scenario.
   2. Run `dart run build_runner build --delete-conflicting-outputs` to generate
      the test and step stubs.
   3. Implement any custom step definitions in `test/step/` — arrange/act only,
      just enough for the scenario to run, not to pass.
   4. Run tests: `./scripts/run_tests.sh <generated_test_file>` and **verify it
      FAILS.**

   After Red, the `.feature` file is frozen: if the scenario seems wrong or a
   step cannot be expressed, escalate — do not edit the `.feature` file.

4. **Phase 2: Green (Minimal Implementation)**
   - Write the minimum code required to pass the test
   - For BDD tasks: implement production code only — never edit the `.feature`
     file or weaken step definitions to force a pass
   - Run tests: `./scripts/run_tests.sh <test_file>` (for BDD tasks, the generated test file; prints summary automatically)
   - **Verify the test PASSES.**
   - If it fails after 3 attempts, escalate (see below)

5. **Phase 3: Refactor**
   - Review for code duplication or smells
   - Refactor if needed, ensuring tests still pass
   - Run analyzer (two separate Bash calls - do NOT chain with &&):
     - **Call 1:** `./scripts/run_analyze.sh`
     - **Call 2:** `grep 'issues found' ./tmp/analyze_results.txt`

6. **Commit and Push:**
   After Phase 3 passes, commit and push immediately — this is what makes the task's work
   survive the worktree being deleted, so a retry never has to redo it:

   ```bash
   git add -A
   git commit -m "task <M>/<total>: <short task description>"
   git push -u origin <branch>
   ```

   Include the task index (`task <M>/<total>:`) in the commit message — a progress signal
   independent of the plan comment's checkbox (Step 7), so `git log` still shows how far the
   work order got even if that comment is ever mangled.

   **If the push fails, escalate — do not continue to the next task.** An unpushed commit is
   exactly the invisible state this issue is about.

7. **Update Progress on GitHub:**
   Use MCP GitHub tools to post a comment on the issue. For BDD tasks, add a **Feature:** `<feature_file>` line directly under the **Test:** line. **Branch:** and **PR:** make the work locatable from the issue alone — always include both, even though nothing else in this step reads them back. Use the branch re-derived in Step 2. A PR does not exist yet at this point in the loop (`/create-pr` only runs once every task is checked off), so **PR:** is always the literal `none yet` here — write the line rather than omitting it, so its absence is visible rather than ambiguous:
   > ### Task Completed: \<task description\>
   >
   > **Test:** `<test_file>` - PASSING
   > **Impl:** `<impl_file>`
   > **Branch:** `<branch>`
   > **PR:** none yet
   > **Status:** Done
   >
   > ---
   > *Completed by /hExecute*

8. **Check Off the Task in the Plan:**
   Flip this task's checkbox in the plan comment from `- [ ]` to `- [x]` — this is what lets a
   re-dispatch resume instead of restarting at Task 1. Match on the task's title text, not its
   index — a plan revision renumbers:

   ```bash
   body="$(mktemp)"   # never a fixed /tmp path: executors run concurrently and would clobber
   gh api repos/{owner}/{repo}/issues/comments/<plan_comment_id> --jq .body > "$body"
   # edit "$body": flip only this task's `- [ ]` to `- [x]` by matching its title text,
   # leave every other line byte-identical
   gh api --method PATCH repos/{owner}/{repo}/issues/comments/<plan_comment_id> \
     -F body=@"$body"
   rm -f "$body"
   ```

   Use `-F` (capital), not `-f` — `gh api`'s lowercase `-f`/`--raw-field` never dereferences
   `@path`, it sets the field to that literal string. `-f "body=@$body"` silently
   corrupts the comment to the literal text `@/tmp/...`; only `-F`/`--field` reads the file.

   Do **not** rewrite, reformat, or re-wrap the rest of the comment — a `PATCH` that reflows the
   plan destroys the record every later dispatch reads.

   **If the PATCH fails, escalate — do not continue to the next task.** An unchecked box after
   this step is indistinguishable from an unstarted task on the next dispatch.

## Escalation

If you encounter any of these situations, STOP and escalate:
- Test doesn't fail in Red phase (feature may already exist)
- Test doesn't pass after 3 implementation attempts
- `git push` fails after Phase 3 (Step 6)
- `PATCH` against the plan comment fails (Step 8)
- `dart run build_runner build` fails to generate from the `.feature` file after one fix attempt (malformed Gherkin in the plan)
- A BDD scenario step cannot be expressed with built-in or planned custom steps
- Architectural decision needed that wasn't covered in the plan
- Unclear requirements or ambiguous task description

To escalate, use MCP GitHub tools to:

1. Post a comment on the issue:
   > ### Escalation Required
   >
   > **Task:** \<task description\>
   > **Blocker:** \<what's preventing progress\>
   > **Attempted:** \<what you tried\>
   >
   > ---
   > *Escalated by /hExecute - needs /oPlan review*

2. Add the `tdd-escalation` label to the issue.

Then report: "Escalated to issue #<N>. Run `/oPlan <issue#>` to revise the plan."

## Loop Continuation

After completing a task, run `/hExecute <issue#>` again to continue with the next incomplete task. Repeat until all tasks are checked off.

## Output

Report:
- Which task was completed (or escalated)
- Test file and implementation file modified
- Test status (Pass/Fail)
- Next action: "Run `/hExecute <issue#>` for next task" — or, if this run invoked `/create-pr` because the plan was already complete, report that PR's outcome instead (see `/create-pr`'s own Summary Format).
