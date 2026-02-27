Create a GitHub PR immediately, then run tests and linter locally. Push any fixes as follow-up commits to the PR.

## Workflow

1. **Push branch & create PR first:**
   - Push current branch: `git push -u origin <branch>`
   - Analyze changes: `git diff main...HEAD`
   - Generate PR title and body, use project PR template if available
   - Create PR: `gh pr create`
   - **Report the PR URL to the user immediately**

2. **Run local tests:**
   - Use the project's test command (check CLAUDE.md, package.json scripts, Makefile, etc.)
   - Analyze failures, fix them, re-run to verify

3. **Run linter/analyzer:**
   - Use the project's lint command
   - Fix any issues, re-run to verify clean output

4. **Push follow-up commits (if fixes were made):**
   - `git add <files>`
   - `git commit -m "fix: ..."`
   - `git push`

## Notes

- Create PR first so CI starts running in parallel with local validation
- Run tests and linter as separate Bash calls — do NOT chain with `&&`
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
