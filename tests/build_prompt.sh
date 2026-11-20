#!/bin/bash
# Build one subagent dispatch prompt for a skill scenario.
# Usage: bash tests/build_prompt.sh <skill-dir> <fixture-dir> <E|P|F|R> [issue-file] > prompt.md
#   skill-dir    hExecute | sExecute | create-pr | fix-ci | oPlan | fPlan
#   fixture-dir  tests/fixtures/target-with-commands (etc.); its parent directory
#                must hold harness-rules.md and the issue fixtures (issue-998.md
#                for E; issue-999.md and issue-997.md for R)
#   family       E = executor, P = create-pr, F = fix-ci, R = planner replan
#                (selects the outcome block)
#   issue-file   E and R only; default issue-998.md (E) or issue-999.md (R).
#                A path that does not exist as given is looked up under the
#                fixtures root. Its first line must be `# Issue #N ...`; N also
#                fills <ISSUE_NUM> in harness-rules.md (998 when no issue is used).
# Optional env vars (each a no-op when unset):
#   ARGS      invocation argument, rendered as Claude Code does: substituted for
#             $ARGUMENTS in SKILL.md, or appended as a final "ARGUMENTS: <ARGS>"
#             line when SKILL.md has no $ARGUMENTS and ARGS is non-empty.
#             Set-ness counts, so ARGS= (empty) is an invocation with no argument.
#   BRANCH    current branch stated in the harness rules. Unlike ARGS, empty
#             means unset: BRANCH= falls back to agent/builder/issue-<ISSUE_NUM>.
#   OUTCOMES  path to a file appended verbatim after the family's stated
#             outcomes. Pre-format it like the family blocks in harness-rules.md:
#             "  - " starts each outcome, deeper indent continues one.
set -eu
cd "$(dirname "$0")/.."
skill=$1; fixture=$2; family=$3; issue_file=${4:-}
issue_num=998   # <ISSUE_NUM> in harness-rules.md when no issue file is used (P, F)
fixture_abs=$(cd "$fixture" && pwd)
fixtures_root=$(dirname "$fixture_abs")

echo "You must follow the skill instructions below."
echo
echo "<skill>"
if [ "${ARGS+set}" = set ]; then
  if grep -q '\$ARGUMENTS' "$skill/SKILL.md"; then
    # Assign, then print: bash 3.2 keeps the replacement's quotes as literal
    # characters when the expansion sits inside a double-quoted word.
    content=$(<"$skill/SKILL.md")
    content=${content//\$ARGUMENTS/"$ARGS"}
    printf '%s\n' "$content"
  else
    cat "$skill/SKILL.md"
    if [ -n "$ARGS" ]; then echo "ARGUMENTS: $ARGS"; fi
  fi
else
  cat "$skill/SKILL.md"
fi
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
  [ -f "$issue_file" ] || issue_file="$fixtures_root/$issue_file"
  issue_num=$(sed -n '1s/^# Issue #\([0-9]*\).*/\1/p' "$issue_file")
  [ -n "$issue_num" ] || { echo "build_prompt.sh: $issue_file has no '# Issue #N' header" >&2; exit 1; }
  echo "The issue (#$issue_num) and its comments, in lieu of \`gh issue view $issue_num --comments\`:"
  echo
  cat "$issue_file"
  echo
fi
# Harness rules: common part, then only this family's outcome block.
# Placeholders are replaced with bash expansion, not sed, so `#` and `&` in a
# path or branch name are taken literally (the replacement is quoted, which
# bash 5.2+ needs to keep `&` literal). The trailing "x" keeps the block's final
# blank line, which command substitution would otherwise strip.
rules=$(awk -v fam="$family" '
  /^### / { keep = ($2 == fam) ; next }
  /<SCENARIO OUTCOMES>/ { next }
  keep == "" || keep { print }
' "$fixtures_root/harness-rules.md"; echo x)
rules=${rules%x}
branch=${BRANCH:-agent/builder/issue-$issue_num}
rules=${rules//<TARGET_REPO_PATH>/"$fixture_abs"}
rules=${rules//<BRANCH>/"$branch"}
rules=${rules//<ISSUE_NUM>/"$issue_num"}
printf '%s' "$rules"
if [ -n "${OUTCOMES:-}" ]; then
  cat "$OUTCOMES"
fi
echo
case $family in
  E) echo "Execute the next incomplete task now." ;;
  P) echo "Create the PR now." ;;
  F) echo "Fix CI now." ;;
  R) echo "Revise the plan now." ;;
esac
