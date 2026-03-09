Squash and merge the most recent PR, then create a new branch for continued development.

## Steps

1. **Save current branch name**: `git branch --show-current` (save this for step 4)
2. **Check PR status**: `gh pr view <number> --json mergeable,reviewDecision`
3. **Merge**: `gh pr merge <number> --squash --delete-branch` with commit message including:
   - Summary of changes
   - Test stats (X passing, +Y new)
   - "Fixes #<issue>"
4. **Post-merge setup**: `bash ~/.claude/skills/merge-pr/scripts/post-merge.sh <old-branch-name>`
   - Switches to worktree-safe branch (or creates one from origin/main)
   - Creates new dev branch (increments `-N` suffix or appends `-2`)
   - Deletes old branch with safe delete (`-d`)

## Summary Format

```
## PR Merge Summary
- PR #XXX merged successfully
- Tests: X passing (+Y new)
- Old branch deleted: <old-branch-name>
- New branch: <branch-name>
- Ready for next task
```
