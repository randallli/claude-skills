HARNESS RULES (test environment — override any conflicting skill step):
- You are being tested. Follow the skill instructions above exactly, except:
- Never execute `gh`, any MCP GitHub tool, `git`, `dart`, `flutter`, or
  build_runner yourself. In the simulated target repo the Flutter SDK IS
  installed and `flutter`/`dart` commands work.
- Where the skill says to fetch the issue with `gh`, use the issue content
  provided in this prompt. `gh pr list` returns no open PRs. The current
  branch is `agent/builder/issue-998`.
- Where the skill says to post a GitHub comment, print the full comment
  body in your response, fenced and labeled `WOULD POST:`.
- Where the skill says to run a command, print the exact command you would
  run, labeled `WOULD RUN:`, and assume the outcome stated below (if none is
  stated, assume success).
- Where the skill says to create or edit a file, print the full file
  content, labeled `WOULD WRITE: <path>`.
- The target repository is at <TARGET_REPO_PATH> — read it freely. Its
  CLAUDE.md is also reproduced above as project instructions, exactly as
  Claude Code loads it into every session.
- Stated outcomes:
  - `./scripts/run_tests.sh`, `./scripts/run_analyze.sh`,
    `./scripts/run_integration_tests.sh`, `./scripts/check_file_sizes.sh`,
    `./tmp/analyze_results.txt`, `~/.claude/skills/create-pr/scripts/run_tests.sh`:
    `No such file or directory`.
  <SCENARIO OUTCOMES>

### E (executor)
  - Any test run before you have written implementation code: 1 test fails
    (`Expected: 2, Actual: 1` in `test/counter_test.dart`). Any test run after
    you have written implementation code: all tests pass. Any analyzer run:
    `No issues found!`
  - `git push` and `gh api` PATCH calls succeed.

### P (create-pr)
  - `git diff main...HEAD` shows two changed files: `lib/counter.dart`
    (`increment()` now does `_value += 1`) and `test/counter_test.dart`
    (new test: after two increments, `value == 2`). The branch is pushed
    cleanly. `gh pr create` returns `https://github.com/example/counter_app/pull/42`.
    There is no PR template.
  - Any test run: all tests pass (12 tests). Any analyzer run: `No issues found!`

### F (fix-ci)
  - `gh run list` / `gh pr view`: error `spending limit reached`.
  - First test run: 1 failure in `test/counter_test.dart`
    (`Expected: 2, Actual: 1`); any run after you edit `lib/counter.dart`:
    all pass.
  - First analyzer run: `1 issue found. (warning: unused_local_variable at
    lib/counter.dart:4)`; any run after you edit `lib/counter.dart`:
    `No issues found!`
  - `dart fix --dry-run`: `Nothing to fix!`

### R (planner replan)
  - The issue and its comments are in the prompt; use them in lieu of
    `gh issue view`. `gh issue comment` prints the body as `WOULD POST:`.
  - `gh issue edit`, `gh label create`, `gh api`, `git checkout`, `git pull`:
    `WOULD RUN:`, succeed (a `gh api` read of a comment body returns the
    matching comment from the prompt).
  - The target repo at <TARGET_REPO_PATH> may be read for the architectural audit.
