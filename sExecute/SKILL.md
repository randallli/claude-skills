---
name: sExecute
model: sonnet
description: Execute TDD tasks from an oPlan plan on a GitHub issue, one task at a time using Red-Green-Refactor discipline (Sonnet variant for more complex tasks)
---

<!-- MOSTLY IN SYNC WITH hExecute/SKILL.md. Intentional divergence: sExecute has the "Set Up an Isolated Workspace (worktree)" step (Step 2); hExecute does not. Mirror any OTHER change to the steps, escalation, scripts, or output in both files, and keep name/model/description and the /hExecute vs /sExecute self-references distinct. -->

# TDD Executor Instructions

You are the execution phase of a two-phase TDD workflow. Your job is to implement one task at a time from the plan, following strict Red-Green-Refactor discipline.

## Input

`$ARGUMENTS` should be a GitHub issue number (e.g., `#123` or `123`).

## Steps

1. **Fetch the Plan:**
   Use `gh issue view <N> --comments` to read the issue comments. Find the most recent comment containing `## TDD Plan` and parse it to find the next unchecked task (`- [ ]`).

2. **Set Up an Isolated Workspace (worktree):**
   Before writing any test or implementation files, make sure this run has its **own git worktree** so it can't interleave edits with other runs (or with your main checkout). Run this step on every invocation — it's a no-op once the worktree exists.

   **REQUIRED SUB-SKILL:** Use superpowers:using-git-worktrees for the mechanics (isolation detection, native-tool-vs-git fallback, `.worktrees/` ignore verification). Apply these sExecute-specific rules on top of it:

   - **Already isolated → skip creation.** If the sub-skill's Step 0 detects you're already in a linked worktree — e.g. you were dispatched by `/execute-tagged-issues` with `isolation: "worktree"` — do NOT create another. Work in place and continue to the next step.
   - **One worktree per issue, reused across tasks and loop iterations.** Scope the worktree to the issue (path `.worktrees/issue-<N>`) so every task for issue #<N>, and every later `/sExecute <issue#>` continuation, shares the same worktree. Reuse it if it already exists; only create it the first time:
     ```bash
     # Standalone run (not already in a worktree): create the issue worktree once, reuse thereafter
     WT=".worktrees/issue-<N>"
     git worktree list --porcelain | grep -qE "/issue-<N>\$" || git worktree add "$WT" -b "issue-<N>/work"
     cd "$WT"
     ```
   - Do all remaining steps (branch, Red, Green, Refactor, commit) **inside this worktree**.

3. **Create/Switch to Task Branch:**
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

4. **Phase 1: Red (Write Failing Test)**
   - Write the test file for the next incomplete task
   - Run tests: `./scripts/run_tests.sh <test_file>` (prints summary automatically)
   - **Verify the test FAILS.** If it passes:
     - Check if the feature already exists
     - Verify you're testing the correct behavior
     - Do NOT proceed until you have a legitimate failing test

5. **Phase 2: Green (Minimal Implementation)**
   - Write the minimum code required to pass the test
   - Run tests: `./scripts/run_tests.sh <test_file>` (prints summary automatically)
   - **Verify the test PASSES.**
   - If it fails after 3 attempts, escalate (see below)

6. **Phase 3: Refactor**
   - Review for code duplication or smells
   - Refactor if needed, ensuring tests still pass
   - Run analyzer (two separate Bash calls - do NOT chain with &&):
     - **Call 1:** `./scripts/run_analyze.sh`
     - **Call 2:** `grep 'issues found' ./tmp/analyze_results.txt`

7. **Update Progress on GitHub:**
   Use MCP GitHub tools to post a comment on the issue:
   > ### Task Completed: \<task description\>
   >
   > **Test:** `<test_file>` - PASSING
   > **Impl:** `<impl_file>`
   > **Status:** Done
   >
   > ---
   > *Completed by /sExecute*

## Escalation

If you encounter any of these situations, STOP and escalate:
- Test doesn't fail in Red phase (feature may already exist)
- Test doesn't pass after 3 implementation attempts
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
   > *Escalated by /sExecute - needs /oPlan review*

2. Add the `tdd-escalation` label to the issue.

Then report: "Escalated to issue #<N>. Run `/oPlan <issue#>` to revise the plan."

## Loop Continuation

After completing a task, run `/sExecute <issue#>` again to continue with the next incomplete task. The continuation reuses the same `.worktrees/issue-<N>` worktree (Step 2), so all tasks for the issue land in one isolated workspace. Repeat until all tasks are checked off.

## Output

Report:
- Which task was completed (or escalated)
- Test file and implementation file modified
- Test status (Pass/Fail)
- The worktree path in use (`.worktrees/issue-<N>`, or "already-isolated workspace" if Step 2 was skipped)
- Next action: "Run `/sExecute <issue#>` for next task" or "All tasks complete! Run `/create-pr` **from the worktree** (`.worktrees/issue-<N>`) to push and open a pull request."
