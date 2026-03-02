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

1. **Check CI Status**
   - Get latest CI run: `gh run list --limit 1 --json conclusion,status,workflowName,databaseId`
   - If on a branch with open PR: `gh pr view --json number,statusCheckRollup`
   - Identify which checks failed (test, analyze, build, integration-test)

   **Spending Limit Fallback:**
   If CI returns "spending limit" error or Actions are disabled:
   - Report: "GitHub Actions spending limit reached - running checks locally"
   - Skip CI status check and proceed directly to local diagnosis
   - Run all checks locally (use separate Bash calls - do NOT chain with &&):
     - Unit tests **Call 1:** `./scripts/run_tests.sh `
     - Unit tests **Call 2:** `grep '^{' ./tmp/test_results.json | jq -c 'select(.type == "error" or .type == "done")'`
     - Integration tests: `./scripts/run_integration_tests.sh` (runs each test file individually)
     - Analyzer **Call 1:** `./scripts/run_analyze.sh `
     - Analyzer **Call 2:** `grep 'issues found' ./tmp/analyze_results.txt`
   - Continue with normal fix workflow based on local results

2. **Diagnose Issues** (use separate Bash calls - do NOT chain with &&)
   - **Test failures**:
     - **Call 1:** `./scripts/run_tests.sh `
     - **Call 2:** `grep '^{' ./tmp/test_results.json | jq -c 'select(.type == "error" or .type == "done")'`
   - **Analyzer issues**:
     - **Call 1:** `./scripts/run_analyze.sh `
     - **Call 2:** `grep 'issues found' ./tmp/analyze_results.txt`
   - **Preview auto-fixes**: Run `dart fix --dry-run` to see how many issues can be auto-fixed
   - **Build failures**: Check for dependency or configuration issues
   - **Integration test failures**: Note that these may require specific setup
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
   - After running, re-check with two-step pattern to see remaining issues

   **Step 3b: Manual fixes for remaining analyzer issues**
   - `dart fix` does NOT handle these — fix manually:
     - `lines_longer_than_80_chars`: Break long lines appropriately
     - Complex refactoring-style fixes
     - Context-dependent fixes that require understanding intent
   - Verify with two-step pattern

   **Step 3c: Test failures** (use separate Bash calls - do NOT chain with &&)
   - Run tests to identify failing cases:
     - **Call 1:** `./scripts/run_tests.sh `
     - **Call 2:** `grep '^{' ./tmp/test_results.json | jq -c 'select(.type == "error" or .type == "done")'`
   - Check for:
     - Outdated golden files (regenerate with `flutter test --update-goldens`)
     - Race conditions in async tests
     - Missing mocks or test data
     - State cleanup issues between tests
   - Fix and verify with same two-step pattern

   **Step 3d: Build failures**
   - Check `pubspec.yaml` for dependency issues
   - Run `flutter pub get`
   - Check for platform-specific configuration issues

4. **Verify Fixes** (use separate Bash calls - do NOT chain with &&)
   - Run tests to ensure all tests pass:
     - **Call 1:** `./scripts/run_tests.sh `
     - **Call 2:** `grep '^{' ./tmp/test_results.json | jq -c 'select(.type == "error" or .type == "done")'`
   - Run analyzer to confirm issues reduced/eliminated:
     - **Call 1:** `./scripts/run_analyze.sh `
     - **Call 2:** `grep 'issues found' ./tmp/analyze_results.txt`
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

   After applying fixes and verifying CI passes, automatically run:
   ```bash
   ./scripts/run_integration_tests.sh
   ```

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
   - Uses the provided script which runs each test file individually (required for macOS)
   - Running `flutter test integration_test/` directly causes app restart failures between files on macOS
   - Platform-specific tests can be skipped with note
   - Focus on tests that can run in current environment

7. **Check File Sizes** (automatically after integration tests)

   Run the file size checking script:
   ```bash
   ./scripts/check_file_sizes.sh
   ```

   Then parse the results:
   ```bash
   cat ./tmp/file_sizes.txt
   ```

   **File size thresholds** (from CLAUDE.md):
   - **Source files (lib/)**: Report if > 500 lines, warn if > 600
   - **Test files**: Report if > 800 lines, warn if > 1,000

   **Report format:**
   ```
   Large files found:
   - lib/presentation/game/game_screen.dart: 732 lines (⚠️ Approaching limit)
   - test/widget/game_screen_test.dart: 1,245 lines (❌ Exceeds limit)

   Refactoring suggestions:
   - Extract mixins for game_screen.dart
   - Split game_screen_test.dart into multiple files
   ```

   **If large files found:**
   - Report all files exceeding thresholds
   - Suggest refactoring strategies (mixins, extraction, splitting)
   - Link to `docs/file-size-progress.md` for examples
   - Recommend creating separate refactoring PR

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
Running: `./scripts/run_integration_tests.sh`
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
| Integration test fails | Use `./scripts/run_integration_tests.sh` (runs each file individually on macOS) |
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
   - Execute: ./scripts/run_integration_tests.sh
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
