#!/bin/bash
# Regression test: the upgrade-settings skill is named promote-settings, no
# tracked file outside history names the old name, and the skill suggests
# /create-pr after a promotion.
#
# Only tracked files are scanned (git grep), so untracked local state such as
# .claude/settings.local.json or a nested worktree cannot fail the check.
# Excluded by path: docs/superpowers/ records past work, which names the old
# skill, and tests/ names the token itself.
# Takes no arguments (there is no single-file form); any argument is ignored.
set -u
cd "$(dirname "$0")/.." || exit 1

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
out=$(git grep -nI -i -e 'upgrade-settings' -- . ':!docs/superpowers' ':!tests' 2>&1)
case $? in
  0) echo "❌ references to the old upgrade-settings name:"; echo "$out"; rc=1 ;;
  1) echo "✅ no references to the old upgrade-settings name" ;;
  *) echo "❌ git grep failed:"; echo "$out"; rc=1 ;;
esac
suggestion='> Settings promoted. Commit `.claude/settings.json`, then run `/create-pr` to share it with your team.'
if awk '/^## Post-Completion Suggestion$/{on=1;next} /^## /{on=0} on' promote-settings/SKILL.md | grep -qF -- "$suggestion"; then
  echo "✅ promote-settings suggests /create-pr under ## Post-Completion Suggestion"
else
  echo "❌ promote-settings/SKILL.md lacks the /create-pr suggestion under ## Post-Completion Suggestion"; rc=1
fi
exit $rc
