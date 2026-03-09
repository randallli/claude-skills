#!/usr/bin/env bash
# Post-merge: create new dev branch from origin/main, delete old branch.
# Usage: post-merge.sh <old-branch-name>
set -euo pipefail

OLD_BRANCH="${1:?Usage: post-merge.sh <old-branch-name>}"

git fetch origin
git branch -f main origin/main 2>/dev/null || true

# Create new branch (increment suffix)
if [[ "$OLD_BRANCH" =~ ^(.*)-([0-9]+)$ ]]; then
  BASE="${BASH_REMATCH[1]}"
  NUM="${BASH_REMATCH[2]}"
  NEW_BRANCH="${BASE}-$((NUM + 1))"
else
  NEW_BRANCH="${OLD_BRANCH}-2"
fi
git checkout -b "$NEW_BRANCH" origin/main
echo "New branch: $NEW_BRANCH"

# Delete old local branch (safe delete)
if git branch -d "$OLD_BRANCH" 2>/dev/null; then
  echo "Deleted old branch: $OLD_BRANCH"
else
  echo "Warning: could not delete $OLD_BRANCH (may have unmerged changes)"
fi
