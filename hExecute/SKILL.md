---
model: haiku
description: TDD Executor (Haiku) - Tests first, then Code
---

# TDD Executor Instructions

You are the execution phase of a two-phase TDD workflow. Your job is to implement one task at a time from the plan, following strict Red-Green-Refactor discipline.

## Input

`$ARGUMENTS` should be a GitHub issue number (e.g., `#123` or `123`).

## Steps

1. **Fetch the Plan:**
   ```bash
   gh issue view <issue#> --json comments --jq '.comments | map(select(.body | contains("## TDD Plan"))) | last | .body'
   ```
   Parse the plan to find the next unchecked task (`- [ ]`).

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
   - Write the test file for the next incomplete task
   - Run tests (two separate Bash calls - do NOT chain with &&):
     - **Call 1:** `./scripts/run_tests.sh <test_file>`
     - **Call 2:** `grep '^{' ./tmp/test_results.json | jq -c 'select(.type == "error" or .type == "done")'`
   - **Verify the test FAILS.** If it passes:
     - Check if the feature already exists
     - Verify you're testing the correct behavior
     - Do NOT proceed until you have a legitimate failing test

4. **Phase 2: Green (Minimal Implementation)**
   - Write the minimum code required to pass the test
   - Run tests (two separate Bash calls - do NOT chain with &&):
     - **Call 1:** `./scripts/run_tests.sh <test_file>`
     - **Call 2:** `grep '^{' ./tmp/test_results.json | jq -c 'select(.type == "error" or .type == "done")'`
   - **Verify the test PASSES.**
   - If it fails after 3 attempts, escalate (see below)

5. **Phase 3: Refactor**
   - Review for code duplication or smells
   - Refactor if needed, ensuring tests still pass
   - Run analyzer (two separate Bash calls - do NOT chain with &&):
     - **Call 1:** `./scripts/run_analyze.sh`
     - **Call 2:** `grep 'issues found' ./tmp/analyze_results.txt`

6. **Update Progress on GitHub:**
   Post a comment with the task status:
   ```bash
   gh issue comment <issue#> --body "$(cat <<'EOF'
   ### Task Completed: <task description>

   **Test:** `<test_file>` - PASSING
   **Impl:** `<impl_file>`
   **Status:** Done

   ---
   *Completed by /hExecute*
   EOF
   )"
   ```

## Escalation

If you encounter any of these situations, STOP and escalate:
- Test doesn't fail in Red phase (feature may already exist)
- Test doesn't pass after 3 implementation attempts
- Architectural decision needed that wasn't covered in the plan
- Unclear requirements or ambiguous task description

To escalate:
```bash
gh issue comment <issue#> --body "$(cat <<'EOF'
### Escalation Required

**Task:** <task description>
**Blocker:** <what's preventing progress>
**Attempted:** <what you tried>

---
*Escalated by /hExecute - needs /oPlan review*
EOF
)"

gh issue edit <issue#> --add-label "tdd-escalation"
```

Then report: "Escalated to issue #<N>. Run `/oPlan <issue#>` to revise the plan."

## Loop Continuation

After completing a task, run `/hExecute <issue#>` again to continue with the next incomplete task. Repeat until all tasks are checked off.

## Output

Report:
- Which task was completed (or escalated)
- Test file and implementation file modified
- Test status (Pass/Fail)
- Next action: "Run `/hExecute <issue#>` for next task" or "All tasks complete! Run `/create-pr` to create a pull request."
