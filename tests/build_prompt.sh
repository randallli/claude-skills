#!/bin/bash
# Build one subagent dispatch prompt for a skill scenario.
# Usage: bash tests/build_prompt.sh <skill-dir> <fixture-dir> <E|P|F> > prompt.md
#   skill-dir    hExecute | sExecute | create-pr | fix-ci
#   fixture-dir  tmp/cmd-fixtures/target-with-commands (etc.)
#   family       E = executor, P = create-pr, F = fix-ci  (selects the outcome block)
set -eu
cd "$(dirname "$0")/.."
skill=$1; fixture=$2; family=$3
fixture_abs=$(cd "$fixture" && pwd)

echo "You must follow the skill instructions below."
echo
echo "<skill>"
cat "$skill/SKILL.md"
echo "</skill>"
echo
echo "<project-instructions path=\"CLAUDE.md\">"
cat "$fixture/CLAUDE.md"
echo "</project-instructions>"
echo
if [ "$family" = E ]; then
  echo "The issue (#998) and its comments, in lieu of \`gh issue view 998 --comments\`:"
  echo
  cat tmp/cmd-fixtures/issue-998.md
  echo
fi
# Harness rules: common part, then only this family's outcome block.
awk -v fam="$family" '
  /^### / { keep = ($2 == fam) ; next }
  /<SCENARIO OUTCOMES>/ { next }
  keep == "" || keep { print }
' tmp/cmd-fixtures/harness-rules.md | sed "s#<TARGET_REPO_PATH>#$fixture_abs#"
echo
case $family in
  E) echo "Execute the next incomplete task now." ;;
  P) echo "Create the PR now." ;;
  F) echo "Fix CI now." ;;
esac
