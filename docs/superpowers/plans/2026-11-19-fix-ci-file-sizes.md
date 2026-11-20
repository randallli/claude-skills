# fix-ci file-size command from CLAUDE.md - Plan record

> **STATUS: EXECUTED 2026-11-20.** Record of the plan on randallli/claude-skills#51,
> run with RED/GREEN discipline (`superpowers:writing-skills`). The skill files as
> merged are authoritative; this document is evidence, not instructions to re-run.

**Goal:** `fix-ci` takes its file-size check from an optional `**File sizes:**`
bullet in the target's `CLAUDE.md` `## Commands` (read in step 0, like the optional
integration-test command) and skips step 7, saying so, when there is none. It never
runs `./scripts/check_file_sizes.sh` or reads `./tmp/file_sizes.txt`.

**Issue:** randallli/claude-skills#51. Follow-up to #42, which left step 7 as is.

## Method

Fixtures: `target-with-commands` (no bullet, scenario F4) and the new
`target-with-file-sizes` (bullet `bash tool/check_file_sizes.sh`, scenario F5),
which adds `tool/check_file_sizes.sh`. 5 reps per scenario, fresh `haiku` subagents,
prompts from `tests/build_prompt.sh` (recipe in `tests/README.md`), every rep read
by hand. F1 re-run as a regression on the #42 criterion.

Mechanical: `tests/check_stale_refs.sh` now also forbids `scripts/check_file_sizes`,
`file_sizes.txt` and `file-size-progress` in the skills and `README.md`. RED: it
failed citing `fix-ci/SKILL.md` lines 180, 185 and 206.

## Results

| Scenario | Baseline (RED) | After edit (GREEN) |
|---|---|---|
| F4 no bullet | 0/5 - all ran `./scripts/check_file_sizes.sh`, got `No such file or directory`, reported the check as not completed | **5/5** - no file-size `WOULD RUN`; step 0 and the File Size section say skipped |
| F5 bullet | partial - all 5 named or ran the hard-coded `./scripts/` path first; 4/5 then fell back to the CLAUDE.md command | **5/5** - exactly one `WOULD RUN: bash tool/check_file_sizes.sh`, output in the File Size section, no `./scripts/` or `file_sizes.txt` |
| F1 regression | - | **5/5** - only CLAUDE.md test/analyze commands; integration skipped with a note |

## Edits landed

- `fix-ci/SKILL.md`: step 0 also reads the optional `**File sizes:**` bullet; step 7
  runs that command or skips and says so (no `wc -l` substitute, no thresholds of
  its own); step 8, Output Format, Important Notes and Complete Workflow follow.
- `tests/check_stale_refs.sh`: guard extended as above.
- New: `tests/fixtures/target-with-file-sizes/`. `README.md` and `tests/README.md` updated.

## Notes

- `tests/fixtures/harness-rules.md` still states `./scripts/check_file_sizes.sh` ->
  `No such file or directory`; it is not a scanned path and keeps RED reps reproducible.
- The per-rep captures lived under `tmp/` (git-ignored); this file is the durable record.
