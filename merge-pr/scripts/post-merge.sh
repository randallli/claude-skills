#!/usr/bin/env bash
# Post-merge: switch to worktree-safe branch, create new dev branch, delete old branch.
# Usage: post-merge.sh <old-branch-name>
set -euo pipefail

OLD_BRANCH="${1:?Usage: post-merge.sh <old-branch-name>}"

WORKTREE_NAME="$(basename "$(git rev-parse --show-toplevel)")"
git fetch origin

if git rev-parse --verify "$WORKTREE_NAME" >/dev/null 2>&1; then
  git checkout "$WORKTREE_NAME"
else
  git checkout -b "$WORKTREE_NAME" origin/main
fi
git pull

# Create new branch (increment suffix)
if [[ "$OLD_BRANCH" =~ ^(.*)-([0-9]+)$ ]]; then
  BASE="${BASH_REMATCH[1]}"
  NUM="${BASH_REMATCH[2]}"
  NEW_BRANCH="${BASE}-$((NUM + 1))"
else
  NEW_BRANCH="${OLD_BRANCH}-2"
fi
git checkout -b "$NEW_BRANCH"
echo "New branch: $NEW_BRANCH"

# Delete old local branch (safe delete)
if git branch -d "$OLD_BRANCH" 2>/dev/null; then
  echo "Deleted old branch: $OLD_BRANCH"
else
  echo "Warning: could not delete $OLD_BRANCH (may have unmerged changes)"
fi
