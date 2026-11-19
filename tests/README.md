# Tests for this skills repo

Two kinds of check live here.

## Mechanical checks

- `bash tests/check_stale_refs.sh` — the **test** command. Fails if `hExecute`,
  `sExecute`, `create-pr`, `fix-ci` or `README.md` name a project-local test or
  analyze script (`scripts/run_*`, `run_tests.sh`, `analyze_results`). The
  skills take those commands from the target repo's `CLAUDE.md` instead.
- `bash tests/check_sync.sh` — the **analyze** command. Fails if
  `hExecute/SKILL.md` and `sExecute/SKILL.md` differ anywhere other than
  frontmatter, the KEEP IN SYNC comment, and `/hExecute`↔`/sExecute`
  self-references.

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
   `bash tests/build_prompt.sh <skill-dir> tests/fixtures/<fixture> <E|P|F> > tmp/prompts/<scenario>.md`
   The prompt is: full `SKILL.md`, the fixture's `CLAUDE.md` as project
   instructions (as Claude Code loads it), the fixture issue (executor
   scenarios only), the harness rules with only that family's stated
   outcomes, and a one-line go instruction.
2. Dispatch with the Agent tool, `subagent_type: general-purpose`, and the
   skill's runtime model: `model: haiku` for `hExecute`, `create-pr`, `fix-ci`;
   `model: sonnet` for `sExecute`. The dispatch message tells the agent to read
   the prompt file in full and follow it.
3. Save every rep's full output. Score by reading, not grep: what did it
   `WOULD RUN:` for tests and analysis, which source did it cite, and did it
   `WOULD POST:` an escalation when `CLAUDE.md` gave no command?
4. 5 reps per scenario. Reps that diverge mean the wording is not binding.

Scenario families: **E** (executor: E1 with commands, E2 without, E3 test-only),
**P** (create-pr: P1/P2/P3), **F** (fix-ci: F1/F2/F3).
