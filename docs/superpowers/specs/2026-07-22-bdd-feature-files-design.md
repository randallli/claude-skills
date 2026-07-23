# BDD `.feature` Files in the oPlan → hExecute Workflow

**Date:** 2026-07-22
**Status:** Approved design, pending implementation
**Skills affected:** `oPlan`, `fPlan`, `hExecute`, `sExecute` (inline edits; each pair kept in sync per existing sync comments)

## Goal

Extend the two-phase TDD workflow so that user-facing behavior is specified as
Gherkin `.feature` files executed by a real BDD runner, while internal units keep
plain Dart TDD tests.

## Decisions (from brainstorming)

1. **Depth:** Real `.feature` files committed to the target repo and executed by a
   BDD runner — not Gherkin-formatted prose in the plan comment.
2. **Toolchain:** Standardize on **bdd_widget_test** (Dart/Flutter). It generates
   plain `flutter_test` files from `.feature` files via `build_runner`, so the
   existing `./scripts/run_tests.sh` flow in hExecute/sExecute keeps working.
3. **Scope:** **Hybrid.** Each task in a plan is classified:
   - **BDD task** — user-facing / widget-level behavior. Red phase artifact is a
     `.feature` scenario plus generated test and step definitions.
   - **TDD task** — internal unit (service, model, provider, utility). Red phase
     artifact is a plain Dart test, exactly as today.

## Changes to oPlan/SKILL.md and fPlan/SKILL.md

### Step 4 (Architectural Audit) — one addition

Audit the target repo for BDD tooling: does `pubspec.yaml` list `bdd_widget_test`?
Do `.feature` files already exist under `test/`? Note existing step-definition
conventions in `test/step/` for reuse.

### Step 5 (Design Test Plan) — classification rule

Add after the SOLID table:

- Classify every task **BDD** or **TDD**:
  - BDD when the task's observable outcome is something a user sees or does
    (screens, widgets, navigation, user-visible state changes).
  - TDD when the outcome is internal (service methods, models, providers,
    parsing, computation).
- If any task is BDD and the target repo lacks `bdd_widget_test`, insert a
  one-time **setup task** as Task 1: add `bdd_widget_test` and `build_runner` as
  dev dependencies, verify `dart run build_runner build` generates a test from a
  trivial smoke `.feature` file, and commit the config. Tag it `Type: Setup`
  (no Red-Green cycle; it is infrastructure).

### Step 6 (Plan template) — task entry format

Every task gains a `Type:` line. BDD tasks replace the `Test:` line with
`Feature:` + `Steps:` and include the scenario inline:

```
- [ ] **Task 2 (BDD):** Session timeout redirects to login
  - Feature: `test/session_timeout.feature`
  - Steps: `test/step/` (generated + custom)
  - Impl: `lib/services/auth_service.dart`
  - SOLID: SRP
  - Scenario:
    Scenario: Session expires after 30 minutes
      Given a user logged in 31 minutes ago
      When they make an API request
      Then they are redirected to the login screen

- [ ] **Task 3 (TDD):** Token expiry computation
  - Test: `test/services/token_expiry_test.dart`
  - Impl: `lib/services/token_expiry.dart`
  - SOLID: SRP
  - Assertions: <as today>
```

Scenario text in the plan is authoritative: the executor copies it into the
`.feature` file verbatim (plus `Feature:` header), it does not re-derive it.

### Gherkin conventions (inline in the plan skills)

- One `.feature` file per feature, under `test/`, snake_case matching the feature
  name (bdd_widget_test convention: generated test lands next to it).
- Scenarios use concrete values, not placeholders ("31 minutes", not "N minutes").
- Prefer reusing bdd_widget_test built-in steps (`the app is running`,
  `I tap {...}`, `I see {...}`); plan custom steps only when built-ins cannot
  express the behavior, and name them in the task entry.

## Changes to hExecute/SKILL.md and sExecute/SKILL.md

### Step 3 (Red) — branch on task type

- **TDD task:** unchanged.
- **Setup task:** no Red-Green cycle — perform the listed infrastructure steps,
  verify the smoke `.feature` generates and runs, commit, and post the progress
  comment.
- **BDD task:**
  1. Write the `.feature` file with the scenario copied verbatim from the plan.
  2. Run `dart run build_runner build --delete-conflicting-outputs` to generate
     the test and step stubs.
  3. Implement any custom step definitions in `test/step/` (arrange/act only —
     enough for the scenario to run, not to pass).
  4. Run `./scripts/run_tests.sh <generated_test_file>` and verify it FAILS.

### Step 4 (Green) and Step 5 (Refactor) — unchanged mechanics

Green implements production code until the generated test passes, via the same
`run_tests.sh`. Refactor may also clean up step definitions. The `.feature` file
itself is not edited during Green/Refactor; if the scenario is wrong, that is an
escalation (plan revision), not a local edit.

### Step 6 (Progress comment) — report the feature file

BDD task completion comments list `Feature:`, generated test, and `Impl:` paths.

### Escalation — two new triggers

- `build_runner` fails to generate from the `.feature` file after one fix attempt
  (malformed Gherkin in the plan → plan revision needed).
- The scenario as written cannot be expressed with available/custom steps.

## Sync rules

- oPlan ↔ fPlan and hExecute ↔ sExecute remain full clones with their existing
  keep-in-sync comments; all edits above are mirrored verbatim in both files of
  each pair.

## Testing plan (writing-skills RED → GREEN → REFACTOR)

Per the Iron Law, no skill edit ships without a failing test first.

1. **RED (baseline, before editing):**
   - Planner: dispatch a subagent with the current oPlan SKILL.md as its
     instructions against a fixture issue describing user-facing behavior with
     acceptance criteria. Expected baseline failure: plan contains only plain
     Dart unit tests, no task classification, no `.feature` files. Capture output
     verbatim.
   - Executor: dispatch a subagent with the current hExecute SKILL.md against a
     fixture plan containing a BDD-tagged task. Expected baseline failure: it
     writes a plain Dart test and ignores/mishandles the Feature/Steps lines.
2. **GREEN:** apply the edits above; re-run the same fixtures. Planner must emit
   Type tags, a `.feature` path + verbatim scenario for BDD tasks, and the setup
   task when the fixture repo lacks bdd_widget_test. Executor must produce the
   `.feature` file, run build_runner, and verify a failing generated test.
3. **REFACTOR:** capture any rationalizations or misreadings from GREEN runs
   (e.g., executor editing the `.feature` during Green, planner classifying
   everything as TDD to avoid setup) and add explicit counters; re-test.

Fixtures live in the skill-repo scratch space during testing; they are not
committed to the target project.

## Out of scope

- Migrating existing plain tests to BDD.
- Non-Dart toolchains (cucumber-js, pytest-bdd).
- Changes to create-pr / merge-pr / tagged-issues skills.
