Create a GitHub PR immediately, then run tests and linter locally. Push any fixes as follow-up commits to the PR.

## Workflow

1. **Push branch & create PR first:**
   - Push current branch: `git push -u origin <branch>`
   - Analyze changes: `git diff main...HEAD`
   - Derive the issue number `N` from the current branch name — the only two
     forms the factory mints are `agent/<role>/issue-<N>` and
     `issue-<N>/task-…`. If the branch name matches neither form, skip the
     rest of this step and say so in the summary rather than guessing a
     number.
   - Generate PR title and body, use project PR template if available.
     Include `Closes #<N>` in the PR body — this is the GitHub-native
     issue↔PR link, so merging the PR closes the work order and the
     relationship is visible in the UI.
   - Create PR: `gh pr create`
   - Advance the issue's label to reflect that the work order is now
     shippable: `gh issue edit <N> --add-label ready-for-review --remove-label
     agent-started`. **Only do this when the PR is not a draft.** A draft PR
     means the work order is still mid-flight — factory#30 opens one after the
     first real commit — and the scheduler deliberately ignores drafts when it
     reconciles this same transition, so advancing the label here would declare
     the work shippable before it is and strand the Builder mid-work-order. If
     this edit fails (for example the Builder's token lacks `issues: write` on
     this repo), report it and continue — the scheduler's own reconcile pass is
     the backstop for this transition.

2. **Launch tests and linter in the background** (use `run_in_background: true` on each Bash call — do NOT chain with `&&`). Both commands come from the target repo's `CLAUDE.md` `## Commands` section. `CLAUDE.md` is the only source — a CI workflow, README, or `scripts/` directory does not count.
   - **Tests:** Run the test command `CLAUDE.md` gives, for all tests. If `CLAUDE.md` gives no test command, run no tests and fill the Tests slot below with `skipped: no test command in CLAUDE.md`.
   - **Linter:** Run the analyze command `CLAUDE.md` gives. If `CLAUDE.md` gives no analyze command, run no linter and fill the Linter slot below with `skipped: no analyze command in CLAUDE.md`.
   - If `CLAUDE.md` gives neither command, skip steps 2–3 entirely and report the PR URL with the Summary Format below (the PR from step 1 stands).
   - **Report the PR URL to the user immediately** — don't wait for results

3. **When background tasks complete**, analyze results:
   - If failures found, fix them and re-run to verify
   - Push follow-up commits:
     - `git add <files>`
     - `git commit -m "fix: ..."`
     - `git push`

## Notes

- Create PR first so CI starts running in parallel with local validation
- Run tests and linter in background (`run_in_background: true`) — do NOT chain with `&&`
- Report PR URL to user immediately, then handle results when they arrive
- Follow-up commits appear in PR history for transparency
- Always run against the base branch (usually `main`)

## Summary Format

End with:

```
## PR Summary
- **PR:** <URL>
- **Tests:** X passing (+Y new) — or `skipped: no test command in CLAUDE.md`
- **Linter:** clean / N issues — or `skipped: no analyze command in CLAUDE.md`
- **Fixes pushed:** none / N commits
```

Always include the PR URL so the user doesn't have to scroll.
