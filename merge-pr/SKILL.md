Squash and merge the most recent PR, then create a new branch for continued development.

## Steps

1. **Save current branch name**: `git branch --show-current` (save this for step 4)
2. **Check PR status**: `gh pr view <number> --json mergeable,reviewDecision`
3. **Merge**: `gh pr merge <number> --squash --delete-branch` with commit message including:
   - Summary of changes
   - Test stats (X passing, +Y new)
   - "Fixes #<issue>"
4. **Update master**: `git checkout master && git pull`
5. **Create new branch** (REQUIRED - do not stay on master):
   - Use the branch name saved from step 1
   - If it ends with `-N` (where N is a number), increment to `-N+1`
   - Otherwise, append `-2` to the branch name
   - `git checkout -b <new-branch-name>`
   - Leave branch clean (no initial commits)
6. **Delete old local branch** (the one saved in step 1):
   - `git branch -d <old-branch-name>`
   - Uses `-d` (safe delete, not `-D`) to prevent accidental deletion of unmerged work
   - If deletion fails (branch has unmerged changes), warn the user and skip

## Summary Format

```
## PR Merge Summary
- PR #XXX merged successfully
- Tests: X passing (+Y new)
- Old branch deleted: <old-branch-name>
- New branch: <branch-name>
- Ready for next task
```
