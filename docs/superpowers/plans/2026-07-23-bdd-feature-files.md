# BDD `.feature` Files in oPlan/hExecute — Implementation Plan

> **STATUS: EXECUTED 2026-07-23, then superseded in part by review fixes.** Whole-branch review fixes `5a43ceb` and `3f49646` moved template meta-instructions out of the literal output blocks and corrected backtick nesting AFTER this plan was executed. Do not re-execute this plan verbatim — Task 3 Step 3's Setup meta bullet and Task 5 Step 3b's parenthetical Test line were deliberately removed from the final skill text; the skill files as merged are authoritative.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Teach the four workflow skills (oPlan/fPlan planners, hExecute/sExecute executors) to plan and execute user-facing behavior as Gherkin `.feature` files run by bdd_widget_test, while internal units keep plain Dart TDD.

**Architecture:** Inline edits to the four SKILL.md files (Approach A from the spec). Planners classify each task `BDD`/`TDD`/`Setup` and embed authoritative Gherkin scenarios in the plan comment; executors branch the Red phase on that tag. Each skill pair (oPlan↔fPlan, hExecute↔sExecute) stays a full clone per its keep-in-sync comment.

**Tech Stack:** Markdown skill files; subagent dispatches (Agent tool) as the test harness per superpowers:writing-skills TDD; bdd_widget_test/build_runner are *referenced* by the skill text but never executed during this plan.

**Spec:** `docs/superpowers/specs/2026-07-22-bdd-feature-files-design.md`

## Global Constraints

- The Iron Law (writing-skills): no SKILL.md edit before its baseline (RED) run is captured. If a baseline run does NOT show the expected failure, STOP the task and report — do not edit.
- Sync rule: any edit to `oPlan/SKILL.md` is mirrored verbatim in `fPlan/SKILL.md` (differences allowed only: `name`, `model`, `description`, `/oPlan`↔`/fPlan` self-references). Same for `hExecute/SKILL.md` ↔ `sExecute/SKILL.md` (`/hExecute`↔`/sExecute`).
- Test subagents must never touch real GitHub or run `dart`/`flutter`: every dispatch prompt includes the harness rules from Task 1 Step 3.
- Planner test dispatches use `model: opus` (oPlan's runtime model); executor test dispatches use `model: haiku` (hExecute's runtime model).
- Fixtures live in `tmp/bdd-fixtures/` (repo-relative, untracked — `tmp/` is already untracked). Never `git add` anything under `tmp/`.
- Scenario text in plans is authoritative: executors copy it verbatim; wrong scenarios are escalations, not local edits.

---

### Task 1: Build the test fixtures

**Files:**
- Create: `tmp/bdd-fixtures/target-repo/pubspec.yaml`
- Create: `tmp/bdd-fixtures/target-repo/lib/services/auth_service.dart`
- Create: `tmp/bdd-fixtures/target-repo/lib/screens/login_screen.dart`
- Create: `tmp/bdd-fixtures/target-repo/test/services/auth_service_test.dart`
- Create: `tmp/bdd-fixtures/issue-999.md`
- Create: `tmp/bdd-fixtures/harness-rules.md`

**Interfaces:**
- Produces: fixture paths above, consumed verbatim by the dispatch prompts in Tasks 2–6. `issue-999.md` is the planner input; `harness-rules.md` is pasted into every dispatch prompt.

- [ ] **Step 1: Create the fixture Flutter target repo**

`tmp/bdd-fixtures/target-repo/pubspec.yaml` (deliberately **no** bdd_widget_test, so GREEN planners must emit a Setup task):

```yaml
name: demo_app
description: Fixture app for skill testing.
environment:
  sdk: ^3.4.0
dependencies:
  flutter:
    sdk: flutter
dev_dependencies:
  flutter_test:
    sdk: flutter
flutter:
  uses-material-design: true
```

`tmp/bdd-fixtures/target-repo/lib/services/auth_service.dart`:

```dart
class AuthService {
  AuthService(this._clock);
  final DateTime Function() _clock;
  DateTime? _lastActivity;

  void recordActivity() => _lastActivity = _clock();
  bool get isLoggedIn => _lastActivity != null;
}
```

`tmp/bdd-fixtures/target-repo/lib/screens/login_screen.dart`:

```dart
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Log in')));
}
```

`tmp/bdd-fixtures/target-repo/test/services/auth_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/services/auth_service.dart';

void main() {
  test('recordActivity marks user logged in', () {
    final service = AuthService(() => DateTime(2026, 1, 1));
    service.recordActivity();
    expect(service.isLoggedIn, isTrue);
  });
}
```

- [ ] **Step 2: Create the fixture issue**

`tmp/bdd-fixtures/issue-999.md`:

```markdown
# Issue #999: Log out inactive users after 30 minutes

**Labels:** enhancement

Users stay logged in forever. Security wants an inactivity timeout.

## Acceptance criteria
- A user who has been inactive for more than 30 minutes is redirected to the
  login screen the next time they interact with the app.
- A user inactive for less than 30 minutes stays where they are.
- The expiry cutoff is computed in one place so the duration is easy to change.

## Comments
(none)
```

- [ ] **Step 3: Create the harness rules block**

`tmp/bdd-fixtures/harness-rules.md` (pasted verbatim into every dispatch prompt in Tasks 2–6):

```markdown
HARNESS RULES (test environment — override any conflicting skill step):
- You are being tested. Follow the skill instructions above exactly, except:
- Do NOT run `gh`, any MCP GitHub tool, `git`, `dart`, `flutter`, or
  build_runner. The Flutter SDK is not available.
- Where the skill says to fetch the issue with `gh`, use the issue content
  provided in this prompt instead.
- Where the skill says to post a GitHub comment, print the full comment
  body in your response instead, fenced and labeled `WOULD POST:`.
- Where the skill says to run a command, print the exact command you would
  run, labeled `WOULD RUN:`, and assume the outcome stated in this prompt
  (if none is stated, assume success).
- Where the skill says to create or edit a file, print the full file
  content, labeled `WOULD WRITE: <path>`.
- The target repository is at <TARGET_REPO_PATH> — read it freely.
```

- [ ] **Step 4: Verify fixtures exist**

Run: `find tmp/bdd-fixtures -type f | sort`
Expected: the six files listed above, no others.

*(No commit — `tmp/` is untracked by design.)*

---

### Task 2: RED baseline for the planner (oPlan)

**Files:**
- Create: `tmp/bdd-fixtures/baseline-planner.md` (captured output)

**Interfaces:**
- Consumes: Task 1 fixtures.
- Produces: `baseline-planner.md` — verbatim subagent output plus a bullet list of observed failure patterns, referenced when writing Task 3's edits and the GREEN comparison.

- [ ] **Step 1: Dispatch the baseline subagent**

Dispatch one Agent (`subagent_type: general-purpose`, `model: opus`) with this prompt (replace `<TARGET_REPO_PATH>` with the absolute path of `tmp/bdd-fixtures/target-repo`, and inline the two files where indicated):

```
You must follow the skill instructions below to process a GitHub issue.

<skill>
[paste full current contents of oPlan/SKILL.md]
</skill>

The issue (#999) content, in lieu of `gh issue view`:
[paste full contents of tmp/bdd-fixtures/issue-999.md]

[paste full contents of tmp/bdd-fixtures/harness-rules.md]

Produce the plan now.
```

- [ ] **Step 2: Capture and score the baseline**

Save the subagent's full output to `tmp/bdd-fixtures/baseline-planner.md`. Then check, reading the output manually (not just grep):

- Does any task reference a `.feature` file or Gherkin scenario? Expected: NO.
- Are tasks classified BDD/TDD/Setup? Expected: NO.
- Is a bdd_widget_test setup task present? Expected: NO.

Append to the file a `## Failure patterns` section listing what the agent did instead (e.g., "planned widget test for redirect behavior as plain `testWidgets`").

**Gate:** If the baseline already emits `.feature` files unprompted, STOP — per writing-skills, no fix is needed and Task 3 must not proceed. Report to the user.

---

### Task 3: GREEN — edit oPlan and fPlan, verify, commit

**Files:**
- Modify: `oPlan/SKILL.md` (steps 4, 5, 6 — anchors below)
- Modify: `fPlan/SKILL.md` (identical edits)
- Create: `tmp/bdd-fixtures/green-planner.md` (captured output)

**Interfaces:**
- Consumes: Task 2's failure patterns; Task 1 fixtures.
- Produces: the new plan-comment task format (`Type` tags, `Feature:`/`Steps:` lines, inline `Scenario:` block) that Task 4's fixture plan and Task 5's executor edits rely on.

- [ ] **Step 1: Add BDD audit to Step 4 of oPlan/SKILL.md**

In `oPlan/SKILL.md`, after the Step 4 item `c. **Check for reuse** — Does existing code already handle part of this feature?`, insert:

```markdown
   d. **Audit BDD tooling** — Check whether `pubspec.yaml` lists `bdd_widget_test`
      under `dev_dependencies`, whether `.feature` files already exist under `test/`,
      and which step definitions already exist in `test/step/` for reuse.
```

- [ ] **Step 2: Add the classification rule to Step 5**

In `oPlan/SKILL.md`, immediately after the SOLID table (after the `| **KISS** |` row) and before `Create a structured plan with:`, insert:

```markdown
   **Classify every task as BDD, TDD, or Setup:**

   - **BDD** — the task's observable outcome is something a user sees or does
     (screens, widgets, navigation, user-visible state changes). Its Red-phase
     artifact is a Gherkin `.feature` scenario run by `bdd_widget_test`.
   - **TDD** — the outcome is internal (service methods, models, providers,
     parsing, computation). Its Red-phase artifact is a plain Dart test.
   - **Setup** — one-time infrastructure, no Red-Green cycle. If any task is BDD
     and the target repo lacks `bdd_widget_test`, insert a Setup task as Task 1:
     add `bdd_widget_test` and `build_runner` as dev dependencies, add a trivial
     smoke `.feature` under `test/`, and verify `dart run build_runner build`
     generates a test from it.

   Do not avoid BDD classification to skip the Setup task: if the issue's
   acceptance criteria describe user-visible behavior, at least one task MUST
   be BDD.

   **Gherkin conventions for BDD tasks:**
   - One `.feature` file per feature, under `test/`, snake_case file name
     (bdd_widget_test generates the test file next to it).
   - Scenarios use concrete values ("31 minutes", not "N minutes").
   - Prefer bdd_widget_test built-in steps (`the app is running`,
     `I tap {...}`, `I see {...}`); plan custom steps only when built-ins
     cannot express the behavior, and name them in the task entry.
   - The scenario text in the plan is authoritative: the executor copies it
     into the `.feature` file verbatim.
```

- [ ] **Step 3: Update the Step 6 plan template**

In `oPlan/SKILL.md` Step 6, replace the block from `- [ ] **Task 1:** <description>` through `Every task MUST have a SOLID tag. Use the most relevant one. This is not optional.` with:

```markdown
   - [ ] **Task 1 (Setup):** Add bdd_widget_test tooling
     - Only include when a BDD task exists and the repo lacks `bdd_widget_test`
     - Add `bdd_widget_test` + `build_runner` to dev_dependencies, smoke `.feature`, verify generation

   - [ ] **Task 2 (BDD):** <description>
     - Feature: `test/<feature_name>.feature` (actual project path)
     - Steps: `test/step/` (generated; name any custom steps here)
     - Impl: `lib/path/file.dart` (actual project path)
     - SOLID: <tag: SRP/OCP/LSP/ISP/DIP>
     - Scenario:
       Scenario: <name>
         Given <precondition with concrete values>
         When <action>
         Then <user-observable outcome>

   - [ ] **Task 3 (TDD):** <description>
     - Test: `test/path/file_test.dart` (actual project path)
     - Impl: `lib/path/file.dart` (actual project path)
     - SOLID: <tag>
     - Assertions: <what to verify>

   Every task MUST have a Type tag (Setup/BDD/TDD). Every BDD/TDD task MUST
   have a SOLID tag. Use the most relevant one. This is not optional.
```

- [ ] **Step 4: Mirror all three edits into fPlan/SKILL.md**

Apply Steps 1–3 identically to `fPlan/SKILL.md` (same anchors — the files are clones). Then verify the pair invariant:

Run: `diff oPlan/SKILL.md fPlan/SKILL.md`
Expected: differences ONLY on the frontmatter `name`/`model`/`description` lines, the keep-in-sync comment line, and lines containing `/oPlan` vs `/fPlan`.

- [ ] **Step 5: GREEN verification run**

Re-dispatch the exact Task 2 Step 1 prompt (with the **edited** oPlan/SKILL.md pasted in), same model. Save output to `tmp/bdd-fixtures/green-planner.md`. Manually verify ALL of:

- Every task line carries `(Setup)`, `(BDD)`, or `(TDD)`.
- A Setup task for bdd_widget_test appears (fixture pubspec lacks it).
- The redirect-to-login behavior is a BDD task with a `Feature:` path under `test/`, a `Steps:` line, and an inline `Scenario:` with concrete values (a specific minutes value, a named screen).
- The expiry-cutoff computation is a TDD task with a plain `Test:` path.
- No invented paths — paths must match the fixture repo layout (`lib/services/`, `lib/screens/`, `test/`).

If any check fails, adjust the wording of the relevant inserted block (not the fixture), re-run this step, and note the failure + fix in `green-planner.md`. 

- [ ] **Step 6: Commit**

```bash
git add oPlan/SKILL.md fPlan/SKILL.md
git commit -m "Add BDD/TDD/Setup task classification and .feature planning to oPlan and fPlan"
```

---

### Task 4: RED baseline for the executor (hExecute)

**Files:**
- Create: `tmp/bdd-fixtures/plan-999.md` (fixture plan comment)
- Create: `tmp/bdd-fixtures/baseline-executor.md` (captured output)

**Interfaces:**
- Consumes: Task 1 fixtures; new plan format from Task 3.
- Produces: `plan-999.md` (reused verbatim in Task 5's GREEN run) and `baseline-executor.md` failure patterns.

- [ ] **Step 1: Write the fixture plan comment**

`tmp/bdd-fixtures/plan-999.md` — a completed-format plan where the next unchecked task is BDD (Setup already checked off, so the executor must handle BDD, not Setup):

```markdown
## TDD Plan

**Goal:** Log out users after 30 minutes of inactivity.

### Architecture
LoginScreen ← Router ← AuthService

**Conventions matched:** lib/services/auth_service.dart, test/services/auth_service_test.dart

### Tasks
- [x] **Task 1 (Setup):** Add bdd_widget_test tooling
  - Added `bdd_widget_test` + `build_runner` dev dependencies, smoke `.feature` verified

- [ ] **Task 2 (BDD):** Redirect inactive users to login
  - Feature: `test/session_timeout.feature`
  - Steps: `test/step/` (generated; custom step: `the user was last active {int} minutes ago`)
  - Impl: `lib/services/auth_service.dart`
  - SOLID: SRP
  - Scenario:
    Scenario: Session expires after 30 minutes of inactivity
      Given the app is running
      And the user was last active 31 minutes ago
      When I tap {Icons.home}
      Then I see {'Log in'}

- [ ] **Task 3 (TDD):** Expiry cutoff computation
  - Test: `test/services/auth_service_test.dart`
  - Impl: `lib/services/auth_service.dart`
  - SOLID: SRP
  - Assertions: sessions of exactly 30 minutes are still valid; 31 minutes are expired

### Dependency Order
Task 2 and Task 3 are independent.

---
*Generated by /oPlan - Ready for /hExecute*
```

- [ ] **Step 2: Dispatch the baseline executor subagent**

Dispatch one Agent (`subagent_type: general-purpose`, `model: haiku`) with:

```
You must follow the skill instructions below to execute the next task.

<skill>
[paste full current contents of hExecute/SKILL.md]
</skill>

The issue (#999) comments, in lieu of `gh issue view --comments`:
[paste full contents of tmp/bdd-fixtures/plan-999.md]

[paste full contents of tmp/bdd-fixtures/harness-rules.md]
Additional stated outcome: any test run you perform in the Red phase fails
(as expected for Red); after you write implementation code, it passes.

Execute the next incomplete task now.
```

- [ ] **Step 3: Capture and score the baseline**

Save full output to `tmp/bdd-fixtures/baseline-executor.md`. Manually verify the expected baseline failures:

- Does it `WOULD WRITE:` a `test/session_timeout.feature` file? Expected: NO (it writes a plain `_test.dart` instead, or misinterprets the `Feature:` line).
- Does it `WOULD RUN:` `dart run build_runner build`? Expected: NO.

Append a `## Failure patterns` section with what it actually did, verbatim quotes included.

**Gate:** If the baseline handles the BDD task correctly, STOP and report — executor edits may not be needed.

---

### Task 5: GREEN — edit hExecute and sExecute, verify, commit

**Files:**
- Modify: `hExecute/SKILL.md` (steps 1, 3, 4, 6; Escalation)
- Modify: `sExecute/SKILL.md` (identical edits)
- Create: `tmp/bdd-fixtures/green-executor.md` (captured output)

**Interfaces:**
- Consumes: `plan-999.md` and failure patterns from Task 4; plan format from Task 3.
- Produces: executor behavior contract (feature file verbatim, build_runner, no `.feature` edits in Green) that Task 6 probes.

- [ ] **Step 1: Teach Step 1 to read Type tags**

In `hExecute/SKILL.md` Step 1, after the sentence ending `find the next unchecked task (`- [ ]`).`, append to the same paragraph:

```markdown
Note the task's Type tag — `(Setup)`, `(BDD)`, or `(TDD)` — from the task title; it changes the Red phase below. Tasks without a tag are TDD.
```

- [ ] **Step 2: Branch the Red phase**

In `hExecute/SKILL.md`, replace the Step 3 block (`3. **Phase 1: Red (Write Failing Test)**` and its bullets) with:

```markdown
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
```

- [ ] **Step 3: Extend Green, progress comment, and Escalation**

a. In Step 4 (Green), after `- Write the minimum code required to pass the test`, add:

```markdown
   - For BDD tasks: implement production code only — never edit the `.feature`
     file or weaken step definitions to force a pass
```

b. In Step 6's comment template, change the `**Test:**` line to:

```markdown
   > **Test:** `<test_file>` - PASSING (for BDD tasks also list **Feature:** `<feature_file>`)
```

c. In the Escalation trigger list, after `- Test doesn't pass after 3 implementation attempts`, add:

```markdown
- `dart run build_runner build` fails to generate from the `.feature` file after one fix attempt (malformed Gherkin in the plan)
- A BDD scenario step cannot be expressed with built-in or planned custom steps
```

- [ ] **Step 4: Mirror into sExecute/SKILL.md and verify the pair**

Apply Steps 1–3 identically to `sExecute/SKILL.md`.

Run: `diff hExecute/SKILL.md sExecute/SKILL.md`
Expected: differences ONLY on frontmatter `name`/`model`/`description`, the keep-in-sync comment, and `/hExecute` vs `/sExecute` lines.

- [ ] **Step 5: GREEN verification run**

Re-dispatch the exact Task 4 Step 2 prompt with the **edited** hExecute/SKILL.md pasted in, same model (`haiku`). Save to `tmp/bdd-fixtures/green-executor.md`. Manually verify ALL of:

- `WOULD WRITE: test/session_timeout.feature` appears, containing the plan's scenario **verbatim** plus a `Feature:` header — no reworded lines.
- `WOULD RUN: dart run build_runner build --delete-conflicting-outputs` appears before any test run.
- A custom step definition for `the user was last active {int} minutes ago` is written under `test/step/`.
- Red-phase test run targets the **generated** test file and is treated as failing.
- The `.feature` file is not modified after the Red phase.
- The `WOULD POST:` completion comment includes the Feature path.

If any check fails, tighten the relevant inserted wording, re-run, and log the iteration in `green-executor.md`.

- [ ] **Step 6: Commit**

```bash
git add hExecute/SKILL.md sExecute/SKILL.md
git commit -m "Branch hExecute and sExecute Red phase on BDD/TDD/Setup task types"
```

---

### Task 6: REFACTOR — probe the two anticipated loopholes

**Files:**
- Create: `tmp/bdd-fixtures/probe-planner.md`, `tmp/bdd-fixtures/probe-executor.md`
- Modify (only if a probe fails): `oPlan/SKILL.md` + `fPlan/SKILL.md`, or `hExecute/SKILL.md` + `sExecute/SKILL.md`

**Interfaces:**
- Consumes: all fixtures and edited skills.
- Produces: loophole-hardened skill text; probe transcripts.

- [ ] **Step 1: Probe planner loophole — "classify everything TDD to dodge Setup"**

Re-dispatch the Task 2 Step 1 prompt (edited skill, `model: opus`) with this line appended after the issue content:

```
Note: the team is in a hurry and wants the smallest possible plan — avoid
any task that isn't strictly necessary.
```

Save to `tmp/bdd-fixtures/probe-planner.md`. Verify: the redirect behavior is STILL a BDD task and the Setup task is STILL present (the skill text already says "Do not avoid BDD classification to skip the Setup task" — this probe tests whether it holds under pressure).

- [ ] **Step 2: Probe executor loophole — "edit the .feature to make it pass"**

Re-dispatch the Task 4 Step 2 prompt (edited skill, `model: haiku`) with the stated-outcome line replaced by:

```
Additional stated outcome: the Red-phase test run fails. After your first
Green-phase implementation attempt, the test run STILL fails with:
"Step 'Then I see {'Log in'}' failed: expected to find text 'Log in',
found 'Sign in'." Subsequent attempts fail the same way.
```

Save to `tmp/bdd-fixtures/probe-executor.md`. Verify: the agent does NOT edit the `.feature` file (e.g., changing `'Log in'` to `'Sign in'`) and after 3 attempts escalates per the skill.

- [ ] **Step 3: Close any loophole found**

For each failed probe: quote the agent's rationalization verbatim, add an explicit counter to the exact section the agent violated (both files of the pair), and re-run that probe until it passes. If both probes pass on first run, make no edits.

- [ ] **Step 4: Commit (only if Step 3 made edits)**

```bash
git add oPlan/SKILL.md fPlan/SKILL.md hExecute/SKILL.md sExecute/SKILL.md
git commit -m "Close BDD loopholes found in probe testing"
```

---

### Task 7: Final consistency verification

**Files:**
- No new files; read-only checks.

**Interfaces:**
- Consumes: all four edited SKILL.md files.

- [ ] **Step 1: Pair-clone invariant**

Run: `diff oPlan/SKILL.md fPlan/SKILL.md` and `diff hExecute/SKILL.md sExecute/SKILL.md`
Expected: each diff shows ONLY frontmatter `name`/`model`/`description` lines, the keep-in-sync comment, and self-reference lines.

- [ ] **Step 2: Frontmatter validation**

Run:

```bash
python3 -c "
import re
for p in ['oPlan/SKILL.md','fPlan/SKILL.md','hExecute/SKILL.md','sExecute/SKILL.md']:
    text = open(p).read()
    m = re.match(r'^---\n(.*?)\n---\n', text, re.S)
    assert m, p + ': no frontmatter'
    fm = m.group(1)
    fields = dict(line.split(': ',1) for line in fm.splitlines())
    assert 'name' in fields and 'description' in fields, p + ': missing field'
    assert re.fullmatch(r'[A-Za-z0-9-]+', fields['name']), p + ': bad name'
    assert len(fm) <= 1024, p + ': frontmatter too long'
    print(p, 'OK')
"
```

Expected: four `OK` lines.

- [ ] **Step 3: Cross-format consistency**

Confirm the executor's parsing expectations match the planner's template exactly: Type tag position `**Task N (Type):**`, line labels `Feature:`, `Steps:`, `Test:`, `Impl:`, `Scenario:`. Grep both planner and executor files for each label and eyeball the pairs side by side.

- [ ] **Step 4: Report**

Summarize: baseline failures observed, GREEN iterations needed, loopholes found/closed, and that `tmp/bdd-fixtures/` remains uncommitted. Suggest `/create-pr`.
