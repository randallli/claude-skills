# Tests for this skills repo

Two kinds of check live here.

## Mechanical checks

- `bash tests/check_refs.sh` — the **test** command. Runs both reference
  checks below, reports every failure in one run, and fails if either fails.
  Both checks source `tests/lib/forbid_refs.sh`, the one copy of the
  scan-and-dispatch harness (recursive, case-insensitive; a grep error fails
  loudly instead of reading as a pass).
  - `bash tests/check_stale_refs.sh` fails if `hExecute`, `sExecute`,
    `create-pr`, `fix-ci` or `README.md` name a project-local test or analyze
    script (`scripts/run_*`, `run_tests.sh`, `analyze_results`). The skills
    take those commands from the target repo's `CLAUDE.md` instead.
  - `bash tests/check_v1_refs.sh` fails if anything under `docs/` (except
    `docs/superpowers/`, which records past work) or `README.md` names the v1
    Dark Factory promotion path. Matched, case-insensitively: the v1 org
    `TripleLiDarkFactory`; the v1 repo's `skills/` directory as
    `factory/skills/`, "factory's `skills/`" or "factory repo's `skills/`";
    and its PR #25 as `factory#25` or `factory/pull/25`. A bare `#25` is not
    matched, because this repo has its own #25. v2 loads the skills from a
    pinned clone of this repo (#46), so those references are history, not
    instructions.
- `bash tests/check_sync.sh` — the **analyze** command. Checks each KEEP IN
  SYNC pair (`hExecute`/`sExecute`, `oPlan`/`fPlan`). Fails if the two files
  differ anywhere other than frontmatter, the KEEP IN SYNC comment, and the
  pair's self-references, or if a file names its partner where it should name
  itself (a copied `/oPlan` inside `fPlan`).

## Behavioral scenarios (subagent dispatch)

A change to what a skill *does* is verified the way `superpowers:writing-skills`
prescribes: run the scenario without the change (RED baseline), then with it
(GREEN), reading every rep by hand. Fixtures are committed under `tests/fixtures/`
(three target-repo variants; four issue fixtures: `issue-998.md` and
`issue-998-complete.md` for E, `issue-999.md` and `issue-997.md` for R; and the
harness rules, whose `<TARGET_REPO_PATH>`, `<BRANCH>` and `<ISSUE_NUM>`
placeholders `build_prompt.sh` fills in); the captured runs are summarized in
`docs/superpowers/plans/2026-11-19-claude-md-commands.md`,
`docs/superpowers/plans/2026-11-19-replan-carries-checked-tasks.md` and
`docs/superpowers/plans/2026-11-19-create-pr-issue-arg.md`. Keep
prompts and captures under `tmp/` (git-ignored).

Recipe, one fresh dispatch per rep:

1. Build the prompt:
   `bash tests/build_prompt.sh <skill-dir> tests/fixtures/<fixture> <E|P|F|R> [issue-file] > tmp/prompts/<scenario>.md`
   The prompt is: full `SKILL.md`, the fixture's `CLAUDE.md` as project
   instructions (as Claude Code loads it), the fixture issue (executor and
   replan scenarios only; optional 4th argument picks the issue file, default
   `issue-998.md` for E and `issue-999.md` for R), the harness rules with only that family's stated
   outcomes, and a one-line go instruction.
   Optional env vars (semantics in the script header): `ARGS` (invocation
   argument, `$ARGUMENTS`), `BRANCH` (current branch), `OUTCOMES` (file of
   extra stated outcomes, pre-formatted as `  - ` bullets).
2. Dispatch with the Agent tool, `subagent_type: general-purpose`, and the
   skill's runtime model: `model: haiku` for `hExecute`, `create-pr`, `fix-ci`;
   `model: sonnet` for `sExecute`; `model: opus` for `oPlan` and `model: fable`
   for `fPlan` (family R). The dispatch message tells the agent to read
   the prompt file in full and follow it.
3. Save every rep's full output. Score by reading, not grep: what did it
   `WOULD RUN:` for tests and analysis, which source did it cite, and did it
   `WOULD POST:` an escalation when `CLAUDE.md` gave no command?
4. 5 reps per scenario. Reps that diverge mean the wording is not binding.

Scenario families: **E** (executor: E1 with commands, E2 without, E3 test-only),
**P** (create-pr: P1/P2/P3), **F** (fix-ci: F1/F2/F3), **R** (planner replan
after a `tdd-escalation`: R1 with `issue-999.md`, Tasks 1-2 already checked;
R2 with `issue-997.md`, escalated at Task 1 with nothing checked). All use
`target-with-commands` unless named otherwise.

Issue-number scenarios (#43). Each row is the env vars and arguments for
`build_prompt.sh`:

| Scenario | Skill / family | Env and arguments | Expected |
|---|---|---|---|
| E4 handoff | hExecute / E | `ARGS=998`, issue file `issue-998-complete.md` | `WOULD INVOKE: /create-pr 998` |
| P4 argument | create-pr / P | `ARGS=43 BRANCH=fix/43-create-pr-issue-arg` | `Closes #43`; label edit on 43 |
| P5 argument beats branch | create-pr / P | `ARGS='#43' BRANCH=agent/builder/issue-12` | `Closes #43`, never `#12` |
| P6 branch fallback | create-pr / P | `ARGS= BRANCH=agent/builder/issue-43` | `Closes #43` (from branch) |
| P7 no number | create-pr / P | `ARGS= BRANCH=fix/43-create-pr-issue-arg` | PR created; no `Closes`; `Label: skipped: no issue number` |
| P8 label 403 | create-pr / P | P4 + `OUTCOMES` = `gh issue edit` fails with HTTP 403 | `Closes #43`; `Label: failed: …`; steps 2–3 still run |
| P9 draft | create-pr / P | P4 + `OUTCOMES` = `gh pr create` returns a draft | `Closes #43`; `Label: skipped: draft PR` |
| P10 non-numeric argument | create-pr / P | `ARGS=--draft BRANCH=agent/builder/issue-43` | `Closes #43` (from branch) |
