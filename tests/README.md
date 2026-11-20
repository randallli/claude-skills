# Tests for this skills repo

Two kinds of check live here.

## Mechanical checks

- `bash tests/check_stale_refs.sh` — the **test** command. Fails if `hExecute`,
  `sExecute`, `create-pr`, `fix-ci` or `README.md` name a project-local test or
  analyze script (`scripts/run_*`, `run_tests.sh`, `analyze_results`). The
  skills take those commands from the target repo's `CLAUDE.md` instead.
- `bash tests/check_sync.sh` — the **analyze** command. Checks each KEEP IN
  SYNC pair (`hExecute`/`sExecute`, `oPlan`/`fPlan`). Fails if the two files
  differ anywhere other than frontmatter, the KEEP IN SYNC comment, and the
  pair's self-references, or if a file names its partner where it should name
  itself (a copied `/oPlan` inside `fPlan`).

## Behavioral scenarios (subagent dispatch)

A change to what a skill *does* is verified the way `superpowers:writing-skills`
prescribes: run the scenario without the change (RED baseline), then with it
(GREEN), reading every rep by hand. Fixtures are committed under `tests/fixtures/`
(three target-repo variants, the fixture issue, and the harness rules); the
captured runs are summarized in
`docs/superpowers/plans/2026-11-19-claude-md-commands.md`. Keep prompts and
captures under `tmp/` (git-ignored).

Recipe, one fresh dispatch per rep:

1. Build the prompt:
   `bash tests/build_prompt.sh <skill-dir> tests/fixtures/<fixture> <E|P|F|R> [issue-file] > tmp/prompts/<scenario>.md`
   The prompt is: full `SKILL.md`, the fixture's `CLAUDE.md` as project
   instructions (as Claude Code loads it), the fixture issue (executor and
   replan scenarios only; optional 4th argument picks the issue file, default
   `issue-998.md` for E and `issue-999.md` for R), the harness rules with only that family's stated
   outcomes, and a one-line go instruction.
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
R2 with `issue-997.md`, escalated at Task 1 with nothing checked).
