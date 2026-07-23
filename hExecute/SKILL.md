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
   Use `gh issue view <N> --comments` to read the issue comments. Find the most recent comment containing `## TDD Plan` and parse it to find the next unchecked task (`- [ ]`).

   Note the task's Type tag — `(Setup)`, `(BDD)`, or `(TDD)` — from the task title; it changes the Red phase below. Tasks without a tag are TDD.

2. **Create/Switch to Task Branch:**
   Create a branch name from the issue number and task description:
   - Format: `issue-<N>/task-<M>-<short-description>`
   - Example: `issue-123/task-1-add-cell-serialization`

   ```bash
   # Check if branch exists, create if not, then switch to it
   git checkout -B issue-<N>/task-<M>-<short-description>
   ```

   Branch naming rules:
   - Lowercase, hyphens for spaces
   - Keep description under 30 chars
   - Strip special characters

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

6. **Update Progress on GitHub:**
   Use MCP GitHub tools to post a comment on the issue. For BDD tasks, add a `**Feature:** `<feature_file>`` line directly under the **Test:** line:
   > ### Task Completed: \<task description\>
   >
   > **Test:** `<test_file>` - PASSING
   > **Impl:** `<impl_file>`
   > **Status:** Done
   >
   > ---
   > *Completed by /hExecute*

## Escalation

If you encounter any of these situations, STOP and escalate:
- Test doesn't fail in Red phase (feature may already exist)
- Test doesn't pass after 3 implementation attempts
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
- Next action: "Run `/hExecute <issue#>` for next task" or "All tasks complete! Run `/create-pr` to create a pull request."
