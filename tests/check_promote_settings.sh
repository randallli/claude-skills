#!/bin/bash
# Regression test: the promote-settings skill exists and suggests /create-pr
# after a promotion. That its old name (#22) stays gone is checked by
# check_removed_skills.sh.
# Takes no arguments (there is no single-file form); any argument is ignored.
set -u
cd "$(dirname "$0")/.." || exit 1

rc=0
if [ -f promote-settings/SKILL.md ]; then
  echo "✅ promote-settings/SKILL.md exists"
else
  echo "❌ promote-settings/SKILL.md missing"; rc=1
fi
suggestion='> Settings promoted. Commit `.claude/settings.json`, then run `/create-pr` to share it with your team.'
if awk '/^## Post-Completion Suggestion$/{on=1;next} /^## /{on=0} on' promote-settings/SKILL.md | grep -qF -- "$suggestion"; then
  echo "✅ promote-settings suggests /create-pr under ## Post-Completion Suggestion"
else
  echo "❌ promote-settings/SKILL.md lacks the /create-pr suggestion under ## Post-Completion Suggestion"; rc=1
fi
exit $rc
