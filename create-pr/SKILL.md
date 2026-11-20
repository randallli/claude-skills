Create a GitHub PR immediately, then run tests and linter locally. Push any fixes as follow-up commits to the PR.

**Issue number argument:** `$ARGUMENTS` — the GitHub issue number this PR closes (e.g. `#123` or `123`), or empty if none was given.

## Workflow

1. **Push branch & create PR first:**
   - Push current branch: `git push -u origin <branch>`
   - Analyze changes: `git diff main...HEAD`
   - Determine the issue number `N`, in this order:
     1. If the **Issue number argument** at the top of this file is not empty,
        that number is `N` — even if the branch name suggests another number.
     2. Otherwise derive `N` from the branch name. Only two forms count:
        `agent/<role>/issue-<N>` and `issue-<N>/task-…`.
     3. Otherwise there is no `N`: write no `Closes` line, skip the label edit,
        and say so in the summary rather than guessing a number.
   - Generate PR title and body, use project PR template if available.
     When `N` is known, the body MUST contain `Closes #<N>`. This is the
     GitHub-native issue↔PR link that both the factory and the human read,
     and merging the PR closes the issue.
   - Create PR: `gh pr create`
   - Best-effort, and only when `N` is known: advance the issue's label to reflect that the work order is now
     shippable: `gh issue edit <N> --add-label ready-for-review --remove-label
     agent-started`. **Only do this when the PR is not a draft.** A draft PR
     means the work order is still mid-flight — factory#30 opens one after the
     first real commit — and the scheduler deliberately ignores drafts when it
     reconciles this same transition, so advancing the label here would declare
     the work shippable before it is and strand the Builder mid-work-order. If
     this edit fails (for example the Builder's token lacks `issues: write` on
     this repo), a failed label edit is not a failed PR. Record it in the summary's **Label:** slot and continue to step 2 — the scheduler's own reconcile pass is
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
- **Issue:** Closes #<N> (from argument | from branch) / none — no issue number
- **Label:** ready-for-review / failed: <error> / skipped: draft PR / skipped: no issue number
- **Tests:** X passing (+Y new) — or `skipped: no test command in CLAUDE.md`
- **Linter:** clean / N issues — or `skipped: no analyze command in CLAUDE.md`
- **Fixes pushed:** none / N commits
```

Always include the PR URL so the user doesn't have to scroll.
