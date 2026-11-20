#!/bin/bash
# Regression test: the upgrade-settings skill is named promote-settings, and no
# file outside history names the old name.
#
# docs/superpowers/ is excluded: it records past work, which names the old skill.
# tests/ is excluded because this check names the token itself.
# Takes no arguments (there is no single-file form); any argument is ignored.
set -u
cd "$(dirname "$0")/.." || exit 1
. tests/lib/forbid_refs.sh

rc=0
if [ -f promote-settings/SKILL.md ]; then
  echo "✅ promote-settings/SKILL.md exists"
else
  echo "❌ promote-settings/SKILL.md missing"; rc=1
fi
if [ ! -e upgrade-settings ]; then
  echo "✅ upgrade-settings/ is gone"
else
  echo "❌ upgrade-settings/ still exists"; rc=1
fi
forbid_refs "references to the old upgrade-settings name" 'upgrade-settings' \
  --exclude-dir=superpowers --exclude-dir=.git --exclude-dir=tmp --exclude-dir=tests . || rc=1
suggestion='> Settings promoted. Run `/create-pr` to share the updated `.claude/settings.json` with your team.'
if grep -qF -- "$suggestion" promote-settings/SKILL.md &&
  awk '/^## Post-Completion Suggestion$/{on=1;next} /^## /{on=0} on' promote-settings/SKILL.md | grep -qF -- "$suggestion"; then
  echo "✅ promote-settings suggests /create-pr under ## Post-Completion Suggestion"
else
  echo "❌ promote-settings/SKILL.md lacks the /create-pr suggestion under ## Post-Completion Suggestion"; rc=1
fi
exit $rc
