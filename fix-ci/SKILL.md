Automatically diagnose and fix CI failures on the current branch or latest PR.

## Overview

This command checks the CI status, identifies failing checks, and applies appropriate fixes. It handles common Flutter CI issues including test failures, analyzer warnings, and build problems.

## Incremental Fix Strategy

**IMPORTANT**: To keep PRs manageable and reviewable, apply fixes incrementally:

### PR Size Guidelines
- **Small PR** (✅ Preferred): < 15 issues or < 200 lines changed
- **Medium PR** (⚠️ Acceptable): 15-30 issues or 200-400 lines changed
- **Large PR** (❌ Split required): > 30 issues or > 400 lines changed

### When to Split Fixes
If analysis reveals many issues, group by type and create separate commits/PRs:

1. **Group 1: Critical blockers** (tests failing, build broken)
   - Fix immediately, commit, create PR
   - Merge before other fixes

2. **Group 2: Analyzer issues by pattern**
   - Commit 1: Line length violations
   - Commit 2: Cascade invocations
   - Commit 3: Const constructors
   - Commit 4: Remaining linting issues
   - Create single PR with all commits OR separate PRs if > 15 issues per type

3. **Group 3: Test improvements** (flaky tests, cleanup)
   - Separate PR after critical fixes merge

### Example: 50 Analyzer Issues
```
Instead of: 1 PR with 50 fixes
Do this:
  - PR #1: Fix 20 line length issues
  - PR #2: Fix 15 cascade invocations
  - PR #3: Fix 10 const constructors
  - PR #4: Fix 5 misc linting issues
```

## Steps

0. **Read the commands**
   Take the test command and the analyze command from the target repo's `CLAUDE.md` `## Commands` section. `CLAUDE.md` is the only source — a CI workflow, README, or `scripts/` directory does not count. If `CLAUDE.md` gives neither command, report "fix-ci needs a test and an analyze command in CLAUDE.md ## Commands" and stop. If it gives only one, say which is missing and skip that check in every step below. Also read the optional integration-test command: the `**Integration tests:**` bullet of the same section, if there is one; if there is none, integration tests are skipped in every step below and the summary says so. Also read the optional file-size command: the `**File sizes:**` bullet of the same section, if there is one; if there is none, the file-size check in step 7 is skipped and the summary says so. Every "test command", "analyze command", "integration-test command" and "file-size command" below means the command read here.

1. **Check CI Status**
   - Get latest CI run: `gh run list --limit 1 --json conclusion,status,workflowName,databaseId`
   - If on a branch with open PR: `gh pr view --json number,statusCheckRollup`
   - Identify which checks failed (test, analyze, build, integration-test)

   **Spending Limit Fallback:**
   If CI returns "spending limit" error or Actions are disabled:
   - Report: "GitHub Actions spending limit reached - running checks locally"
   - Skip CI status check and proceed directly to local diagnosis
   - Launch all checks in background (`run_in_background: true` — do NOT chain with &&):
     - Unit tests: the test command `CLAUDE.md` gives
     - Integration tests: the integration-test command from step 0, if there is one (otherwise skip integration tests and say so)
     - Analyzer: the analyze command `CLAUDE.md` gives
   - When all complete, read the analyzer output
   - Continue with normal fix workflow based on local results

2. **Diagnose Issues** (launch checks in background with `run_in_background: true` — do NOT chain with &&):
   - **Launch in background:**
     - the test command `CLAUDE.md` gives
     - the analyze command `CLAUDE.md` gives
     - the integration-test command from step 0, if there is one and integration tests failed (otherwise skip integration tests and say so)
   - **When results arrive:**
     - Read the analyzer output and count its issues
     - **Preview auto-fixes**: Run `dart fix --dry-run` to see how many issues can be auto-fixed
   - **Build failures**: Check for dependency or configuration issues
   - **Count total issues** to determine if splitting is needed (many may be auto-fixable)

3. **Apply Fixes (Incrementally)**

   **Step 3a: Run `dart fix` first (automated bulk fixes)**
   - Preview: `dart fix --dry-run` to see what it will change
   - Apply: `dart fix --apply` to apply all automatic fixes
   - This handles many analyzer issues automatically including:
     - `cascade_invocations`
     - `prefer_const_constructors` / `prefer_const_literals_to_create_immutables`
     - `unnecessary_new`
     - `prefer_collection_literals`
     - `avoid_single_cascade_in_expression_statements`
     - `unused_local_variable` (in some cases)
     - Many other lint rules from very_good_analysis
   - After running, re-check with the commands above to see remaining issues

   **Step 3b: Manual fixes for remaining analyzer issues**
   - `dart fix` does NOT handle these — fix manually:
     - `lines_longer_than_80_chars`: Break long lines appropriately
     - Complex refactoring-style fixes
     - Context-dependent fixes that require understanding intent
   - Verify with the commands above

   **Step 3c: Test failures**
   - Run tests to identify failing cases:
     - the test command `CLAUDE.md` gives
   - Check for:
     - Outdated golden files (regenerate with `flutter test --update-goldens`)
     - Race conditions in async tests
     - Missing mocks or test data
     - State cleanup issues between tests
   - Fix and verify with the same commands above

   **Step 3d: Build failures**
   - Check `pubspec.yaml` for dependency issues
   - Run `flutter pub get`
   - Check for platform-specific configuration issues

4. **Verify Fixes** (launch in background with `run_in_background: true`):
   - **Launch in background:**
     - the test command `CLAUDE.md` gives
     - the analyze command `CLAUDE.md` gives
   - **When both complete:**
     - Read the analyzer output and count its issues
   - Create summary of changes made
   - **Check if more fixes remain** - if yes, plan next incremental fix

5. **Commit and Push** (incrementally)

   **For small fix groups (< 15 issues):**
   ```bash
   git add -A
   git commit -m "Fix CI: [specific issue type] (X issues)"
   git push
   ```

   **For medium/large fix sets (> 15 issues):**
   ```bash
   # Fix first group (e.g., line length)
   git add [affected files]
   git commit -m "Fix CI: Line length violations (20 issues)"
   git push

   # Create PR for this group
   gh pr create --title "Fix line length violations (20 issues)"

   # After merge, create new branch for next group
   git checkout master && git pull
   git checkout -b fix/analyzer-cascades

   # Fix next group (e.g., cascades)
   # Repeat process
   ```

   **Always:**
   - Review changes before committing
   - Ensure each commit is logical and focused
   - Create descriptive commit messages
   - Keep PRs under 30 issues when possible

6. **Run Integration Tests** (automatically after CI fixes)

   After applying fixes and verifying CI passes, automatically run the
   integration-test command from step 0, if there is one (otherwise skip
   integration tests and say so).

   **What this checks:**
   - Full user workflows end-to-end
   - UI interactions work correctly
   - State management across screens
   - Navigation flows

   **If integration tests fail:**
   - Report which tests failed with details
   - Suggest fixes based on error patterns
   - May skip if platform requirements not met (report this)

   **Integration test considerations:**
   - Running `flutter test integration_test/` directly causes app restart failures between files on macOS; the project's integration-test command should run each file individually
   - Platform-specific tests can be skipped with note
   - Focus on tests that can run in current environment

7. **Check File Sizes** (automatically after integration tests)

   Run the file-size command from step 0, if there is one. If there is none,
   skip this step and say so in the summary (`File sizes: skipped, no
   **File sizes:** command in CLAUDE.md`). Do not substitute `wc -l`, a
   `scripts/` file, or any other command.

   Report what the command prints. Thresholds are the ones the command (or
   its `CLAUDE.md` bullet) states; fix-ci has none of its own.

   **If it flags large files:**
   - Report every flagged file with its line count
   - Suggest refactoring strategies (mixins, extraction, splitting)
   - Recommend creating a separate refactoring PR

8. **Final Summary and Next Steps**

   After all checks complete, provide comprehensive summary:
   - CI fixes applied and verified
   - Integration test results
   - File size analysis
   - Recommended next actions

## Usage Patterns

### Fix current branch CI
```bash
/fix-ci
```

### Fix specific PR's CI
```bash
/fix-ci --pr 467
```

### Iterative fixing workflow
```bash
# First run - diagnose all issues
/fix-ci

# Output shows 53 issues - TOO LARGE for single PR
# Command suggests splitting by type

# Fix first group only (line length - 20 issues)
# Manually fix those, commit, push, create PR, merge

# Second run - fix remaining issues
/fix-ci

# Output shows 33 issues remaining
# Fix next group (cascades - 15 issues)
# Commit, push, create PR, merge

# Repeat until all issues resolved
```

## Output Format

```
## CI Fix Summary

**Status**: [Issues found/No issues]
**PR Strategy**: [Single PR / Split into N PRs / Already merged]

### Issues Diagnosed
- Analyzer: X issues found
  - Line length: Y issues
  - Cascade invocations: Z issues
  - Const constructors: N issues
  - Other: M issues
- Tests: Y failures
- Build: [OK/Failed]

### Current Fix Group (1 of N)
- Fixed [specific issue type] in X files
- Lines changed: ~Y

### Fixes Applied
- `dart fix --apply`: Fixed 42 issues automatically
  - 15 const constructor fixes
  - 12 cascade invocation fixes
  - 8 unnecessary_new removals
  - 7 other automated fixes
- Manual fixes:
  - Broke 12 lines exceeding 80 characters
  - Fixed 3 complex refactoring issues

### Verification
- ✅ All 1,138 tests passing
- ✅ Flutter analyze: N issues remaining (X → N)
- ✅ Build successful

### Integration Tests
Running: the integration-test command from step 0 (or: skipped, none given)
- ✅ 6/6 test files passing (some tests skipped: device rotation)
- ⏱️ Duration: 45s
- 🎯 Coverage: Full user workflows validated

### File Size Analysis
Scanned lib/ and test/ directories:

**Files needing attention:**
- ⚠️ lib/presentation/game/game_screen.dart: 732 lines (approaching 600 limit)
- ❌ test/widget/game_screen_test.dart: 1,245 lines (exceeds 1,000 limit)

**Refactoring suggestions:**
- Extract tutorial listeners to separate mixin (game_screen.dart)
- Split game_screen_test.dart into:
  - game_screen_basic_test.dart (widgets, layout)
  - game_screen_tutorial_test.dart (tutorial integration)
  - game_screen_interaction_test.dart (user interactions)

**Good files (< limits):**
- ✅ lib/presentation/game/game_controller.dart: 407 lines
- ✅ test/unit/domain/well_test.dart: 654 lines

### Next Steps
✅ **This group**: Committed and pushed
⏭️ **Remaining**: N issues in M groups to fix
📝 **Recommendation**: [Create PR for this group / Continue with next group / File refactoring needed]

### PR Plan (if splitting)
- [ ] PR #1: Line length violations (20 issues) ← Current
- [ ] PR #2: Cascade invocations (15 issues)
- [ ] PR #3: Const constructors (10 issues)
- [ ] PR #4: Misc linting (5 issues)
- [ ] PR #5: Refactor large files (2 files over limits) ← Plan after CI clean

### Complete Status
- ✅ CI fixes applied
- ✅ Integration tests verified
- ⚠️ File size issues found (action needed)
```

## Important Notes

- **Spending limit fallback**: If GitHub Actions hit spending limit, runs tests/analysis locally
- **Automatic execution**: Command runs all checks automatically (CI fixes, integration tests, file size)
- **Keep PRs small**: Easier to review, faster to merge, less risk of conflicts
- **Incremental progress**: Fix and merge blockers first, then iterative improvements
- **Integration tests**: Run automatically after CI fixes; may skip if platform unavailable
- **Non-fixable issues**: Some CI failures may require manual investigation (e.g., API changes, environment issues)
- **Partial fixes**: The command will fix what it can and report what needs manual attention
- **Always verify**: After fixes, review changes before committing to ensure correctness
- **Group by type**: Related fixes in same commit/PR (all line length, all cascades, etc.)
- **One logical change per commit**: Makes history clear and enables easy reverts if needed
- **File size matters**: Large files (>500 lines) make Claude's Read/Edit tools less effective; automatically checked
- **Complete workflow**: Command executes all steps from diagnosis to final recommendations

## Common CI Issues and Solutions

| Issue | Solution |
|-------|----------|
| Spending limit reached | Run tests and analysis locally instead of CI |
| Analyzer warnings | Run `dart fix --apply` first, then manually fix remaining issues (line length, complex refactors) |
| Test timeout | Increase timeout or optimize slow tests |
| Golden file mismatch | Regenerate with `--update-goldens` |
| Dependency conflicts | Update `pubspec.yaml` and run `pub get` |
| Integration test fails | Use the integration-test command from step 0 (it should run each file individually on macOS) |
| Build cache issues | Run `flutter clean && flutter pub get` |
| Large files | Extract mixins, split into smaller focused files |

## Complete Workflow

The `/fix-ci` command automatically executes all these steps:

```
1. CI Fails (or need to verify code quality)
   ↓
2. Run /fix-ci (everything below is automatic)
   ↓
3. Check CI Status
   - Query GitHub Actions for failures
   - If "spending limit" error → Run locally instead
   - Identify which checks failed
   ↓
4. Diagnose Issues (via CI or locally)
   - Count and categorize all issues
   - Preview `dart fix --dry-run` to see auto-fixable count
   - Determine if splitting needed
   ↓
5. Run `dart fix` (automated bulk fixes)
   - Preview with --dry-run
   - Apply with --apply
   - Re-analyze to see what remains
   ↓
6. Apply Manual Fixes Incrementally
   - Fix remaining issues by type (< 30 per PR)
   - Verify after each group
   ↓
7. Commit and Push
   - Create descriptive commit
   - Push to trigger CI
   ↓
8. Verify CI Green ✅
   - Wait for CI to pass
   - Confirm all checks successful
   ↓
9. Run Integration Tests Automatically
   - Execute the integration-test command from step 0, if any
   - Report pass/fail/skip status
   ↓
10. Check File Sizes Automatically
    - Scan lib/ and test/ directories
    - Report files > 500/800 lines
   ↓
11. Generate Final Report
    - Summary of all fixes
    - Integration test results
    - File size recommendations
    - Next action items
   ↓
12. Done - Ready for next feature or refactoring
```

**Key point**: Steps 3-11 are all executed automatically by the command. You just run `/fix-ci` and get a complete report with all recommendations.
