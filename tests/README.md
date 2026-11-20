# Tests for this skills repo

Two kinds of check live here.

## Mechanical checks

- `bash tests/check_refs.sh` — the **test** command. Runs the reference
  checks below, reports every failure in one run, and fails if any fails.
  `check_stale_refs.sh` and `check_v1_refs.sh` source `tests/lib/forbid_refs.sh`, the one copy of the
  scan-and-dispatch harness (recursive, case-insensitive; a grep error fails
  loudly instead of reading as a pass).
  - `bash tests/check_stale_refs.sh` fails if `hExecute`, `sExecute`,
    `create-pr`, `fix-ci` or `README.md` name a project-local test or analyze
    script (`scripts/run_*`, `run_tests.sh`, `analyze_results`) or a file-size
    script or report (`scripts/check_file_sizes`, `file_sizes.txt`,
    `file-size-progress`). The skills take those commands from the target repo's `CLAUDE.md` instead.
  - `bash tests/check_v1_refs.sh` fails if anything under `docs/` (except
    `docs/superpowers/`, which records past work) or `README.md` names the v1
    Dark Factory promotion path. Matched, case-insensitively: the v1 org
    `TripleLiDarkFactory`; the v1 repo's `skills/` directory as
    `factory/skills/`, "factory's `skills/`" or "factory repo's `skills/`";
    and its PR #25 as `factory#25` or `factory/pull/25`. A bare `#25` is not
    matched, because this repo has its own #25. v2 loads the skills from a
    pinned clone of this repo (#46), so those references are history, not
    instructions.
  - `bash tests/check_promote_settings.sh` fails if `promote-settings/SKILL.md`
    is missing, `upgrade-settings/` still exists, any tracked file outside
    `docs/superpowers/` and `tests/` names `upgrade-settings` (the skill's name
    before #22), or the skill's `## Post-Completion Suggestion` lacks its
    `/create-pr` line. It scans with `git grep`, so untracked local files such
    as `.claude/settings.local.json` cannot fail it.
- `bash tests/check_sync.sh` — the **analyze** command. Checks each KEEP IN
  SYNC pair (`hExecute`/`sExecute`, `oPlan`/`fPlan`). Fails if the two files
  differ anywhere other than frontmatter, the KEEP IN SYNC comment, and the
  pair's self-references, or if a file names its partner where it should name
  itself (a copied `/oPlan` inside `fPlan`).

## Behavioral scenarios (subagent dispatch)

A change to what a skill *does* is verified the way `superpowers:writing-skills`
prescribes: run the scenario without the change (RED baseline), then with it
(GREEN), reading every rep by hand. Fixtures are committed under `tests/fixtures/`
(four target-repo variants, the fourth being `target-with-file-sizes`; seven issue fixtures: `issue-998.md` and
`issue-998-complete.md` for E, `issue-999.md` and `issue-997.md` for R,
`issue-996.md` and `issue-994.md` for R with no plan yet (blocked and
unblocked), and `issue-995.md` for a blocked re-plan; and the
harness rules, whose `<TARGET_REPO_PATH>`, `<BRANCH>` and `<ISSUE_NUM>`
placeholders `build_prompt.sh` fills in); the captured runs are summarized in
`docs/superpowers/plans/2026-11-19-claude-md-commands.md`,
`docs/superpowers/plans/2026-11-19-replan-carries-checked-tasks.md` and
`docs/superpowers/plans/2026-11-19-create-pr-issue-arg.md` and
`docs/superpowers/plans/2026-11-19-nobody-at-the-keyboard.md` and
`docs/superpowers/plans/2026-11-19-fix-ci-file-sizes.md`. Keep
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
| P4 argument | create-pr / P | `ARGS=43 BRANCH=fix/43-create-pr-issue-arg` | `Closes #43`; no `gh issue edit`; no `Label:` slot |
| P5 argument beats branch | create-pr / P | `ARGS='#43' BRANCH=agent/builder/issue-12` | `Closes #43`, never `#12` |
| P6 branch fallback | create-pr / P | `ARGS= BRANCH=agent/builder/issue-43` | `Closes #43` (from branch) |
| P7 no number | create-pr / P | `ARGS= BRANCH=fix/43-create-pr-issue-arg` | PR created; no `Closes`; summary `Issue:` says there is no issue number |
| P9 draft | create-pr / P | P4 + `OUTCOMES` = `gh pr create` returns a draft at `pull/77`, replacing the `pull/42` outcome | `Closes #43`; summary reports `pull/77`; no `gh issue edit` |
| P10 non-numeric argument | create-pr / P | `ARGS=--draft BRANCH=agent/builder/issue-43` | `Closes #43` (from branch) |

Nobody-at-the-keyboard scenarios (#45):

| Scenario | Skill / family | Env and arguments | Expected |
|---|---|---|---|
| H1 blocked planner | oPlan (opus), fPlan (fable) / R | issue file `issue-996.md` (owner says to ask before planning) | exactly one `WOULD POST:`, starting `### Planner Blocked` with a `**Blocker:**` line (no investigating comment); no `tdd-plan-ready`, no `tdd-escalation`, no `agent-*` label edit; no "re-run" instruction; stops |
| H3 unblocked first plan | oPlan (opus) / R | issue file `issue-994.md` | investigating comment, then `## TDD Plan`, then `tdd-plan-ready`; no `### Planner Blocked` |
| H4 blocked re-plan | oPlan (opus) / R | issue file `issue-995.md` (`issue-997.md` plus an owner comment saying to ask first) | one `### Planner Blocked` post; `--remove-label tdd-escalation`; no `## TDD Plan`, no `tdd-plan-ready` |
| H2 dispatched non-builder branch | hExecute (haiku), sExecute (sonnet) / E | `BRANCH=agent/reviewer/issue-998` | no `git checkout`/`branch`/`switch`; push to `agent/reviewer/issue-998` |

### fix-ci file-size scenarios (#51)

| Scenario | Fixture / args | Expected (GREEN) |
|---|---|---|
| F4 | `bash tests/build_prompt.sh fix-ci tests/fixtures/target-with-commands F` (no **File sizes** bullet) | No `WOULD RUN:` naming `check_file_sizes`, `file_sizes.txt` or `wc`. Step 0 says there is no file-size command; the File Size section says skipped. |
| F5 | `OUTCOMES=tests/fixtures/outcomes-F5.md bash tests/build_prompt.sh fix-ci tests/fixtures/target-with-file-sizes F` | Exactly one file-size `WOULD RUN: bash tool/check_file_sizes.sh`; the File Size section reports `lib/counter.dart` as flagged (11 lines, limit 10) with a refactoring suggestion, and nothing else as flagged; no `./scripts/` or `./tmp/file_sizes.txt`. |

`tests/fixtures/outcomes-F5.md` is the committed `OUTCOMES` file; it states what
`tool/check_file_sizes.sh` really prints when run inside the fixture, so a rep
that runs the script or reads the files sees the same thing. The fixture's
`lib/` limit is 10 lines on purpose: the 11-line `counter.dart` is flagged, so
F5 exercises step 7's "if it flags large files" branch.
