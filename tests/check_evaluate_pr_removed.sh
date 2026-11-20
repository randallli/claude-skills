#!/bin/bash
# Regression test: the v1 evaluate-pr skill stays removed. v2 drops its holdout
# half and defers its review half (docs/specs v2 design §5, issue #64), and the
# factory loads skills from this repo at skills.ref, so the directory must not
# come back and no tracked file outside history may name it.
#
# Only tracked files are scanned (git grep), so untracked local state cannot
# fail it. Excluded by path: docs/superpowers/ records past work, which names
# the skill, and tests/ names the token itself.
# Takes no arguments (there is no single-file form); any argument is ignored.
set -u
cd "$(dirname "$0")/.." || exit 1

rc=0
if [ ! -e evaluate-pr ]; then
  echo "✅ evaluate-pr/ is gone"
else
  echo "❌ evaluate-pr/ still exists"; rc=1
fi
out=$(git grep -nI -i -e 'evaluate-pr' -- . ':!docs/superpowers' ':!tests' 2>&1)
case $? in
  0) echo "❌ references to evaluate-pr:"; echo "$out"; rc=1 ;;
  1) echo "✅ no references to evaluate-pr" ;;
  *) echo "❌ git grep failed:"; echo "$out"; rc=1 ;;
esac
exit $rc
