#!/bin/bash
# Regression test: removed and renamed skills stay gone. The factory loads
# skills from this repo at a pinned ref, so a dropped skill must not come back
# in the tree, and no tracked file may still name it.
#
#   upgrade-settings  renamed to promote-settings (#22)
#   evaluate-pr       v1's Evaluator, dropped by v2 (#64)
#
# Both checks read tracked state only (git ls-files, git grep), so an untracked
# leftover such as a .DS_Store in an old skill directory cannot fail them. A
# name's hyphen also matches `_` and a space. Excluded by path:
# docs/superpowers/ records past work, and this script and tests/README.md name
# the skills themselves.
# Takes no arguments (there is no single-file form); any argument is ignored.
set -u
cd "$(dirname "$0")/.." || exit 1
. tests/lib/forbid_refs.sh

REMOVED=(upgrade-settings evaluate-pr)

rc=0
for skill in "${REMOVED[@]}"; do
  if [ -z "$(git ls-files -- "$skill")" ]; then
    echo "✅ $skill/ is gone"
  else
    echo "❌ $skill/ is still tracked"; rc=1
  fi
  forbid_tracked_refs "references to the removed $skill skill" "${skill//-/[-_ ]}" \
    . ':!docs/superpowers' ':!tests/check_removed_skills.sh' ':!tests/README.md' || rc=1
done
exit $rc
