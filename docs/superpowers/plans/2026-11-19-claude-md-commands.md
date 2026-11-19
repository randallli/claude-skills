# Test and analyze commands from the target's CLAUDE.md — Plan record

> **STATUS: EXECUTED 2026-11-19.** This is the record of the v4 plan on
> randallli/claude-skills#42, run inline per `superpowers:executing-plans` with
> `superpowers:writing-skills` RED/GREEN discipline. The skill files as merged are
> authoritative; this document is evidence, not instructions to re-run.

**Goal:** `hExecute`, `sExecute`, `create-pr` and `fix-ci` take their test and
analyze commands from the target repo's `CLAUDE.md` `## Commands` section and from
nowhere else. When a command is missing, executors escalate in the phase that needs
it, `create-pr` marks the slot `skipped:` (stops local validation only when both are
missing), and `fix-ci` reports and stops (or skips the one missing check).

**Issue:** randallli/claude-skills#42. **Motivation:** tripleli/VisualTimers has no
`scripts/` directory; the skills hard-coded `./scripts/run_tests.sh`,
`./scripts/run_analyze.sh` and `grep 'issues found' ./tmp/analyze_results.txt`.

## Method

Fixture target repo (`tests/fixtures/`, committed) in three variants:
`target-with-commands` (CLAUDE.md `## Commands` copied from tripleli/VisualTimers#126's
shape: Install deps, Test, Analyze, Format, Rive sources), `target-without-commands`
(no `## Commands` section), `target-test-only` (Test but no Analyze). All three
contain `.github/workflows/ci.yml` running `flutter test --concurrency=4 --coverage`
and `flutter analyze --no-fatal-infos` as the tempting alternative source, and no
`scripts/` directory. (Nested workflow files are inert; GitHub only runs
`.github/workflows/` at the repo root.)

Each scenario = one fresh `general-purpose` subagent at the skill's runtime model
(`haiku` for hExecute/create-pr/fix-ci, `sonnet` for sExecute) given: the full
SKILL.md, the fixture's CLAUDE.md as project instructions, the fixture issue
(executors only), and harness rules (`WOULD RUN:` / `WOULD WRITE:` / `WOULD POST:`
with stated outcomes; `./scripts/run_*` → `No such file or directory`; Red test run
fails, post-implementation run passes). Prompts built by `tests/build_prompt.sh`;
recipe in `tests/README.md`. Every rep read by hand against the plan's command
criterion: (a) nothing under `./scripts/run_*` or the create-pr fallback script;
(b) every test/analyze run is exactly a CLAUDE.md command (flags intact, nothing
from `ci.yml`); (c) Format/Rive never used as test or analyze.

Deviation from plan v4: the dispatch message tells the subagent to read the prompt
file rather than inlining ~6k tokens per dispatch. Same content reaches the model.

Mechanical checks: `bash tests/check_stale_refs.sh` (test; grep for stale script
references) and `bash tests/check_sync.sh` (analyze; hExecute↔sExecute pair diff).

## Results

| Scenario | Fixture | Baseline (RED) | After edit (GREEN) |
|---|---|---|---|
| E1 hExecute | with-commands | 0/5 — all ran `./scripts/run_tests.sh` first, then fell back to CLAUDE.md | **5/5** |
| E2 hExecute | without-commands | 3 escalated (on the missing *script*), 2 guessed `flutter test` + `flutter analyze` | **5/5** escalate in Red naming the missing CLAUDE.md test command |
| E3 hExecute | test-only | — | **5/5** Red/Green with `flutter test <file>`, escalate in Refactor |
| E1s/E2s sExecute (sonnet) | with / without | — | **2/2** smoke |
| P1 create-pr | with-commands | 0/5 — ran both script paths before CLAUDE.md | **5/5** |
| P2 create-pr | without-commands | 0/5 — 3 guessed a test cmd (2 from `ci.yml`), 5 guessed an analyzer | **5/5** both slots `skipped:`, nothing run |
| P3 create-pr | test-only | — | **5/5** `flutter test`, Linter `skipped:` |
| F1 fix-ci | with-commands | 0/5 — scripts first (twice per run); 2 took `ci.yml` flags | **5/5** |
| F2 fix-ci | without-commands | 0/5 — all guessed (`flutter test` + `dart analyze` ×4) | **5/5** stop at step 0 |
| F3 fix-ci | test-only | — | **5/5** only `flutter test`; analyze skipped and said so in step 0 |

Total GREEN: 47/47 scored reps (45 haiku + 2 sonnet smoke) across 9 scenarios; baseline 0/30 on the command criterion. One iteration per skill; no REFACTOR pass was needed.

## Failure classification (from RED)

**Condition-dependent**, not discipline. No baseline rep evaluated "does CLAUDE.md
give the command?" — with commands present, CLAUDE.md was reached only as a fallback
after the script failed; without them, no rep mentioned CLAUDE.md at all. The fix is
therefore a two-branch conditional keyed to CLAUDE.md in every place a command is
run, plus a sentence naming CLAUDE.md as the only source (because 4 baseline reps took
commands or flags from `ci.yml`). No rationalization counters were added.

## Verbatim baseline rationalizations

Executor (E1/E2):
- "Fallback: the project CLAUDE.md gives the test command as `flutter test <path>`."
- "the script is missing, so I used the Flutter SDK directly to get the Red verification the skill requires. The harness says Flutter is installed."
- "The skill has no fallback for this case and it is not an escalation trigger, so I continued."
- "I did not substitute `flutter test`, because that is not the skill's command." (escalated for the wrong reason)

create-pr (P1/P2):
- "The skill's test step therefore produced nothing usable. The project CLAUDE.md is the source of truth for test commands and lists `flutter test`, so I used that. This is a deliberate deviation from the skill's fallback, and I am flagging it."
- "`.github/workflows/ci.yml` defines the project's own commands: `flutter analyze --no-fatal-infos` and `flutter test --concurrency=4 --coverage`. I used these as the project lint and test commands."
- "project's lint command: the CLAUDE.md names none and ./scripts/run_analyze.sh is absent, so the standard Flutter analyzer is used"

fix-ci (F1/F2):
- "the skill's script-based path cannot run, so I used the CI commands from ci.yml and the CLAUDE.md commands, with CI's exact flags."
- "Because the scripts are missing, I ran the underlying tools directly to get the diagnosis. This is a deviation from the skill, which has no such fallback, and I flag it as one."
- "the wrapper scripts are missing, so I use the toolchain commands they would wrap"

## Verbatim GREEN evidence

- E1: "I used `flutter test test/counter_test.dart`, not ./scripts/run_tests.sh, because the scripts do not exist in the target repo." / "Escalation check: CLAUDE.md gives the test command … and the analyze command …, so no escalation is needed."
- E2 Blocker: "CLAUDE.md gives no test command (Red/Green) and no analyze command (Refactor). It is the only source for these commands; scripts/ and CI workflows do not count."
- E3 Blocker: "CLAUDE.md gives no analyze command, so the Refactor phase cannot run its analyze check. CLAUDE.md's Commands section lists only install deps, test, and format. CI and scripts do not count as sources."
- P2: "I did not look at `scripts/` or the CI config, because the skill says those do not count."
- P3: "Format is not an analyze command, so I did not substitute it."
- F1: "Step 0, read commands from CLAUDE.md ## Commands: test = `flutter test`; analyze = `flutter analyze --no-fatal-infos`; integration-test = none given, so integration tests are skipped and I say so."
- F2: "fix-ci stopped at Step 0 (Read the commands). No WOULD RUN, WOULD WRITE, or WOULD POST blocks were produced"
- F3: "the CI workflow mentions an analyzer, but the skill says CLAUDE.md is the only source, so I did not use it." / "Analyzer issues are unknown, not zero, because the analyzer did not run."

## Edits landed

- `hExecute/SKILL.md`, `sExecute/SKILL.md` (identical): Red TDD / Red BDD step 4 / Green → "Run the test command `CLAUDE.md` gives, on `<file>`. If `CLAUDE.md` gives no test command, escalate"; Refactor → analyze command from CLAUDE.md, escalate if none; new Escalation bullet (CLAUDE.md is the only source); KEEP IN SYNC comment no longer mentions scripts.
- `create-pr/SKILL.md`: step 2 lead-in names CLAUDE.md `## Commands` as the only source; per-command Tests/Linter conditionals with `skipped:` slots; "neither" bullet; Summary Format slots. `create-pr/scripts/run_tests.sh` deleted.
- `fix-ci/SKILL.md`: new step 0 (read both commands; neither → report and stop; one → skip that check); every `./scripts/run_tests.sh` / `run_analyze.sh` / `analyze_results.txt` reference replaced; integration tests keyed to an optional CLAUDE.md command; "the scripts above" → "the commands above". Step 7's `check_file_sizes.sh` left as is (follow-up issue randallli/claude-skills#51).
- `README.md`: tree no longer lists `scripts/run_tests.sh`; new "Target repo requirements" section; `sExecute` added to the skills table.
- New: `CLAUDE.md` (this repo's `## Commands`), `.gitignore` (`tmp/`), `tests/check_stale_refs.sh`, `tests/check_sync.sh`, `tests/build_prompt.sh`, `tests/README.md`.

## Harness notes for future runs

- The F-family stated outcomes (`unused_local_variable at lib/counter.dart:4`, a failing increment test) do not match the fixture files on disk; most fix-ci reps flagged the mismatch and proceeded on the stated outcome. It did not affect command choice, and was kept identical between RED and GREEN for comparability. Tighten if fix-ci is re-tested for anything other than command sourcing.
- The fixture's CLAUDE.md line "CI (`.github/workflows/`) is the source of truth; these mirror it" (copied from VisualTimers#126) is what led 4 baseline reps to `ci.yml`. The GREEN wording held against it; keep the line in the fixture.
- The fixtures are committed under `tests/fixtures/`; the per-rep captures (baseline-*.md, green-*.md, prompts) lived under `tmp/` and are git-ignored, so this file is the durable record of them.

## Review fixes (PR #52, 2026-11-19)

A high-effort code review on the PR produced ten findings; all were verified and fixed:

1. **Escalating in Phase 3 discarded Red/Green work.** Both executors now read the test *and* analyze command in step 1 (before `git checkout -B`) and escalate there if either is missing; Red/Green/Refactor/Setup refer to "the test/analyze command from step 1". This replaces plan v4's per-phase rule for executors. The README's per-command rule was updated to match.
2. **"fix every issue it reports"** was an unstated new obligation on pre-existing lint. Now: "fix the issues it reports in the files this task changed".
3. **fix-ci's optional integration-test command had no bullet and contradicted the README.** Step 0 now also reads an optional `**Integration tests:**` bullet; the README documents it as optional and `fix-ci`-only.
4. **Fixtures were git-ignored**, so the RED/GREEN recipe was not reproducible from a clone. Fixtures moved to `tests/fixtures/`; `tests/build_prompt.sh` resolves `issue-998.md` and `harness-rules.md` relative to the fixture's parent instead of hard-coding `tmp/`.
5. **`check_stale_refs.sh` read a grep error as a pass.** Exit codes are now dispatched: 0 → fail (matches), 1 → pass, ≥2 → fail loudly (verified by renaming `sExecute/`).
6. **`check_sync.sh` normalized too widely.** Frontmatter deletion is restricted to lines 1-6; `diff` exit codes are dispatched the same way.
7. README cited VisualTimers#125 (the issue) where the record cited #126 (the PR). Both now say #126.
8. This repo's `CLAUDE.md` test command has no single-file form; it says so now, and the README notes it.
9. The Setup task's "verify a test was generated … and passes" named no command; it now runs the test command from step 1.
10. `hExecute`'s KEEP IN SYNC comment omitted `context: fork`; it now matches `sExecute`'s.

Re-verification after the edits (fresh haiku reps, same fixtures, prompts built from `tests/fixtures/`):

| Scenario | Result |
|---|---|
| E1 hExecute with-commands | **5/5** — `flutter test <file>` Red/Green, `flutter analyze --no-fatal-infos`, no scripts, reached Refactor |
| E2 hExecute without-commands | **5/5** — escalated in step 1 before writing anything; Blocker names the missing CLAUDE.md commands |
| E3 hExecute test-only | **5/5** — escalated in step 1 naming the missing analyze command; no Red/Green work done or discarded |
| E1s sExecute (sonnet smoke) | **1/1** |
| F1 fix-ci with-commands (step 0 wording changed) | **5/5** — step 0 read Test, Analyze and the absent Integration-tests bullet; only CLAUDE.md commands ran; integration skipped with a note |

`create-pr` was not re-run: its skill text did not change in the review pass.
