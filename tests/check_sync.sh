#!/bin/bash
# Analyze step for this repo. Each KEEP IN SYNC pair must be identical except for
# the frontmatter fields name, model, description and context (lines 1-6), the
# KEEP IN SYNC comment line, and the pair's /A <-> /B self-references.
#
# A normalized diff alone cannot see a self-reference copied from the other file
# (fPlan saying `/oPlan`), because both names normalize to the same token. So each
# file is also checked to name only itself outside the KEEP IN SYNC line.
set -u
cd "$(dirname "$0")/.."

# "<fileA> <fileB> <regex matching either self-reference>"
PAIRS=(
  "hExecute sExecute /[hs]Execute"
  "oPlan fPlan /[of]Plan"
)

normalize() {
  sed -E \
    -e '1,6{/^(name|model|description|context): /d;}' \
    -e '/^<!-- KEEP IN SYNC WITH/d' \
    -e "s#$2#/X#g" \
    "$1"
}

rc=0
for pair in "${PAIRS[@]}"; do
  read -r a b refs <<<"$pair"
  out=$(diff <(normalize "$a/SKILL.md" "$refs") <(normalize "$b/SKILL.md" "$refs") 2>&1)
  case $? in
    0) echo "✅ $a/SKILL.md and $b/SKILL.md are in sync" ;;
    1) echo "❌ $a/SKILL.md and $b/SKILL.md differ outside the allowed lines:"; echo "$out"; rc=1 ;;
    *) echo "❌ diff failed:"; echo "$out"; exit 2 ;;
  esac
  for f in "$a" "$b"; do
    if [ "$f" = "$a" ]; then other=$b; else other=$a; fi
    hits=$(grep -nE "(^|[^A-Za-z0-9])/$other([^A-Za-z0-9]|$)" "$f/SKILL.md" | grep -v 'KEEP IN SYNC WITH')
    if [ -n "$hits" ]; then
      echo "❌ $f/SKILL.md refers to /$other where it should say /$f:"; echo "$hits"; rc=1
    fi
  done
done
exit $rc
