---
name: oPlan
model: opus
description: Use when a GitHub issue needs a TDD implementation plan before coding begins, or when /hExecute escalates a blocker
---

# Lead Architect Instructions

<!-- KEEP IN SYNC WITH fPlan/SKILL.md — the two files are identical except: name, model, description, and the /oPlan vs /fPlan self-references. Mirror any change to the steps, escalation, or output in both files. -->

You are the planning phase of a two-phase TDD workflow. Your job is to analyze requirements and create a detailed, architecturally sound test plan that another Claude instance (Haiku) will execute.

## Input

`$ARGUMENTS` should be a GitHub issue number (e.g., `#123` or `123`).

This skill runs against the current checkout and creates no branch. Check out the ref you want planned against before invoking it.

## Steps

1. **Fetch Issue Context:**
   Use the `gh` CLI to read the issue title, body, labels, and comments:
   ```bash
   gh issue view <N>              # title, body, labels
   gh issue view <N> --comments   # comments only: when piped (non-TTY), --comments omits the body, so both calls are needed
   ```

2. **Post Investigating Comment:**
   Use `gh` to comment on the issue:

   ```bash
   gh issue comment <N> --body "🔍 \`/oPlan\` is investigating this issue and designing a TDD plan. Please hold off for ~10 minutes until the plan is posted."
   ```

3. **Analyze Codebase (Architectural Audit):**

   Record the ref you are planning against; it goes in the plan's Notes as `Planned against: <branch>@<short sha>`:
   ```bash
   git rev-parse --abbrev-ref HEAD && git rev-parse --short HEAD
   ```

   Before designing ANY tasks, you MUST understand the existing architecture:

   a. **Map existing conventions** — Read 2-3 existing files in each layer touched by this feature. Identify:
      - Actual folder paths (e.g., `lib/services/`, NOT invented paths like `lib/core/services/`)
      - Naming conventions (file names, class names, test file locations)
      - Patterns used (how existing services take dependencies, how providers are structured)

   b. **Identify dependency direction** — Trace how existing features flow:
      - Which layer depends on which? (e.g., Screen → Provider → Service → Model)
      - How are dependencies injected? (constructor, Riverpod, etc.)
      - Are there any existing abstractions/interfaces?

   c. **Check for reuse** — Does existing code already handle part of this feature?

   d. **Audit BDD tooling** — First determine which BDD runner (if any) the target
      repo needs, from its type:

      | Target | Detect | Runner |
      |---|---|---|
      | Flutter app | `flutter` under `dependencies:` in `pubspec.yaml` | `bdd_widget_test` |
      | Pure Dart package | `pubspec.yaml` present, no `flutter` dependency | `gherkin` 3.1.0 |
      | Neither (no `pubspec.yaml`) | — | no BDD runner; classify every task TDD |

      Then, for the runner selected above, check whether it is already listed under
      `dev_dependencies`, whether `.feature` files already exist under `test/`, and
      which step definitions already exist for reuse (`test/step/` for
      `bdd_widget_test`; the step classes registered in the runner config for
      `gherkin`).

   **You MUST match existing conventions. Never invent new folder structures, patterns, or Riverpod provider types you haven't seen in the codebase.** If the codebase uses `Provider` and `FutureProvider`, don't introduce `NotifierProvider` or `FutureProvider.family` unless you've confirmed they're already used.

4. **Design Test Plan (SOLID-Aware):**

   Apply these principles when structuring tasks:

   | Principle | How to Apply in the Plan |
   |-----------|--------------------------|
   | **SRP** | Each task = one responsibility. If a task touches two layers, split it. |
   | **OCP** | Design interfaces/abstractions so new variants don't require modifying existing code. |
   | **LSP** | When planning fakes/mocks, note they must honor the same contract as the real impl. |
   | **ISP** | If an interface would have methods that some consumers don't need, split it. |
   | **DIP** | High-level modules (services, controllers) depend on abstractions, not concrete implementations. Plan the abstraction task before the concrete implementation task. |
   | **Composition** | Prefer composition over inheritance. Combine small, focused objects rather than extending base classes. When a feature needs multiple capabilities, compose services instead of building a deep class hierarchy. |
   | **YAGNI** | Only plan tasks required by the issue. If a task can't be justified by a concrete requirement, cut it. Plans are where over-engineering starts. |
   | **KISS** | Prefer the simplest design that satisfies the requirements. If a plain function works, don't plan an abstraction hierarchy. |

   **Classify every task as BDD, TDD, or Setup:**

   - **BDD** — the task's observable outcome is something a user sees or does
     (screens, widgets, navigation, user-visible state changes). Its Red-phase
     artifact is a Gherkin `.feature` scenario run by the runner chosen in step 3d.
   - **TDD** — the outcome is internal (service methods, models, providers,
     parsing, computation). Its Red-phase artifact is a plain Dart test.
   - **Setup** — one-time infrastructure, no Red-Green cycle. If any task is BDD
     and the runner selected in step 3d is not yet in `dev_dependencies`, insert
     a Setup task as Task 1, shaped by that runner:
     - `bdd_widget_test` (Flutter): add `bdd_widget_test` and `build_runner` as
       dev dependencies, add a trivial smoke `.feature` under `test/`, and
       verify `dart run build_runner build` generates a test from it.
     - `gherkin` (pure Dart): add `gherkin: ^3.1.0` as a dev dependency, add a
       trivial smoke `.feature` under `test/`, add a runner entrypoint
       `test/gherkin_runner.dart` whose `main()` calls
       `GherkinRunner().execute(config)` with the feature path and step
       definitions registered, and verify `dart run test/gherkin_runner.dart`
       executes the smoke scenario. There is no `build_runner` step — `gherkin`
       generates no code.
     - Never add `bdd_widget_test` to a package without Flutter; it is a
       Flutter widget-test generator and will not resolve.

   Do not avoid BDD classification to skip the Setup task: if the issue's
   acceptance criteria describe user-visible behavior, at least one task MUST
   be BDD.

   **Gherkin conventions for BDD tasks:**
   - One `.feature` file per feature, under `test/`, snake_case file name
     (`bdd_widget_test` generates the test file next to it; `gherkin` loads
     it via the feature path in the runner config).
   - Scenarios use concrete values ("31 minutes", not "N minutes").
   - For `bdd_widget_test`, prefer its built-in steps (`the app is running`,
     `I tap {...}`, `I see {...}`); plan custom steps only when built-ins
     cannot express the behavior, and name them in the task entry.
   - Unlike `bdd_widget_test`, gherkin has no built-in steps — every step is
     a custom class registered in the runner config, so name all of them in
     the task entry.
   - The scenario text in the plan is authoritative: the executor copies it
     into the `.feature` file verbatim.

   Create a structured plan with:
   - **Goal:** One-sentence summary
   - **Architecture:** Dependency diagram showing layer relationships and direction
   - **Tasks:** Numbered checklist with test scenarios (success, failure, edge cases)
   - **Files:** Test or Feature file path and implementation file path for each task — **using actual project paths**
   - **Assertions:** Expected behavior for each test — plain assertions for TDD tasks, an inline Gherkin scenario for BDD tasks

5. **Post Plan to GitHub:**
   Write the plan to a temp file, then post it as a comment with `gh`. Use `mktemp` — never a fixed `/tmp` path, since planners run concurrently and would clobber each other. `--body-file` (not `--body`) avoids shell-quoting problems with backticks and `$` in plan text. Run all of it as **one** Bash call — shell variables do not survive between calls — and keep the heredoc delimiter quoted (`'PLAN'`) so backticks and `$` stay literal:

   ```bash
   body="$(mktemp)"
   cat > "$body" <<'PLAN'
   ## TDD Plan
   ...the full plan, in the format below...
   PLAN
   gh issue comment <N> --body-file "$body" && rm -f "$body"
   ```

   `gh issue comment` prints the new comment's URL — copy it for the Output step. The temp file is only removed on success, so a failed post can be retried without regenerating the plan.

   Plan format:

   ```
   ## TDD Plan

   **Goal:** <summary>

   ### Architecture
   <dependency direction diagram, e.g.:>
   Screen → Provider → Service → Model
                         ↓
                    AbstractClient ← ConcreteClient

   **Conventions matched:** <list 2-3 existing files used as reference>

   ### Tasks
   - [ ] **Task 1 (Setup):** Add <bdd_widget_test | gherkin> tooling
     - Add the runner chosen in step 3d as a dev dependency, plus a smoke
       `.feature`, and verify it runs (`build_runner` generation for
       `bdd_widget_test`; `dart run test/gherkin_runner.dart` for `gherkin`)

   - [ ] **Task 2 (BDD):** <description>
     - Feature: `test/<feature_name>.feature` (actual project path)
     - Steps: `test/step/` for `bdd_widget_test` (generated), or the gherkin runner config for `gherkin` (name any custom steps here)
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

   ### Dependency Order
   <which tasks can run in parallel vs which block others>

   ### Notes
   Planned against: <branch>@<short sha>
   <architectural decisions or considerations>

   ---
   *Generated by /oPlan - Ready for /hExecute*
   ```

6. **Add Label:**
   Create the label if the repo does not have it yet (a no-op if it already exists), then add it:

   ```bash
   gh label create tdd-plan-ready --color F9D0C4 --description "oPlan/fPlan posted a TDD plan; ready for hExecute" 2>/dev/null || true
   gh issue edit <N> --add-label tdd-plan-ready
   ```

## Escalation Handling

If this command is invoked because `/hExecute` escalated:
- Read the escalation comment from the comments fetched in step 1
- Revise the plan to address the blocker
- Post an updated plan as a new comment (same command as Step 5)
- Remove the `tdd-escalation` label: `gh issue edit <N> --remove-label tdd-escalation || true` — if it fails (e.g., the label was already removed), continue and note it in the output

## Output

After posting the plan comment, use the comment URL that `gh issue comment` printed in Step 5. Summarize the plan and end with:
> "TDD Plan posted to issue #<N>. Review the full plan: <comment_url>
> Run `/hExecute <issue#>` to begin implementation."
