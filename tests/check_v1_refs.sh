#!/bin/bash
# Regression test: no doc may describe the v1 Dark Factory promotion path.
# v2 loads the skills from a pinned clone of this repo (randallli/claude-skills#46);
# the v1 repo's skills/ directory, its skills/README.md and PR #25 are history.
# Takes no arguments (there is no single-file form); any argument is ignored.
set -u
cd "$(dirname "$0")/.."

out=$(grep -n 'TripleLiDarkFactory/factory\|factory/pull/25\|factory#25\|skills/README\.md\|factory/skills/' docs/remote-access.md README.md 2>&1)
rc=$?
case $rc in
  0) echo "❌ v1 promotion-path references:"; echo "$out"; exit 1 ;;
  1) echo "✅ no v1 promotion-path references"; exit 0 ;;
  *) echo "❌ grep failed ($rc):"; echo "$out"; exit "$rc" ;;
esac
