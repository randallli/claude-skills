#!/bin/bash
# Build one subagent dispatch prompt for a skill scenario.
# Usage: bash tests/build_prompt.sh <skill-dir> <fixture-dir> <E|P|F|R> [issue-file] > prompt.md
#   skill-dir    hExecute | sExecute | create-pr | fix-ci | oPlan | fPlan
#   fixture-dir  tests/fixtures/target-with-commands (etc.); its parent directory
#                must hold issue-998.md and harness-rules.md
#   family       E = executor, P = create-pr, F = fix-ci, R = planner replan
#                (selects the outcome block)
#   issue-file   E and R only; default issue-998.md (E) or issue-999.md (R)
set -eu
cd "$(dirname "$0")/.."
skill=$1; fixture=$2; family=$3; issue_file=${4:-}
fixture_abs=$(cd "$fixture" && pwd)
fixtures_root=$(dirname "$fixture_abs")

echo "You must follow the skill instructions below."
echo
echo "<skill>"
cat "$skill/SKILL.md"
echo "</skill>"
echo
echo "<project-instructions path=\"CLAUDE.md\">"
cat "$fixture_abs/CLAUDE.md"
echo "</project-instructions>"
echo
if [ "$family" = E ] || [ "$family" = R ]; then
  if [ -z "$issue_file" ]; then
    if [ "$family" = R ]; then issue_file=issue-999.md; else issue_file=issue-998.md; fi
  fi
  case $issue_file in /*|tests/*) ;; *) issue_file="$fixtures_root/$issue_file" ;; esac
  issue_num=$(sed -n '1s/^# Issue #\([0-9]*\).*/\1/p' "$issue_file")
  echo "The issue (#$issue_num) and its comments, in lieu of \`gh issue view $issue_num --comments\`:"
  echo
  cat "$issue_file"
  echo
fi
# Harness rules: common part, then only this family's outcome block.
awk -v fam="$family" '
  /^### / { keep = ($2 == fam) ; next }
  /<SCENARIO OUTCOMES>/ { next }
  keep == "" || keep { print }
' "$fixtures_root/harness-rules.md" | sed "s#<TARGET_REPO_PATH>#$fixture_abs#"
echo
case $family in
  E) echo "Execute the next incomplete task now." ;;
  P) echo "Create the PR now." ;;
  F) echo "Fix CI now." ;;
  R) echo "Revise the plan now." ;;
esac
