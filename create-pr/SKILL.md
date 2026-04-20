Create a GitHub PR immediately, then run tests and linter locally. Push any fixes as follow-up commits to the PR.

## Workflow

1. **Push branch & create PR first:**
   - Push current branch: `git push -u origin <branch>`
   - Analyze changes: `git diff main...HEAD`
   - Generate PR title and body, use project PR template if available
   - Create PR: `gh pr create`
   - **Report the PR URL to the user immediately**

2. **Launch tests and linter in the background** (use `run_in_background: true` on each Bash call — do NOT chain with `&&`):
   - **Tests:** If the project has `./scripts/run_tests.sh`, use it. Otherwise, run: `bash ~/.claude/skills/create-pr/scripts/run_tests.sh`
   - **Linter:** Use the project's lint command
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
- **Tests:** X passing (+Y new)
- **Linter:** clean / N issues
- **Fixes pushed:** none / N commits
```

Always include the PR URL so the user doesn't have to scroll.
