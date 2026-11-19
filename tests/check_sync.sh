#!/bin/bash
# Analyze step for this repo: hExecute/SKILL.md and sExecute/SKILL.md must be
# identical except for the frontmatter fields name, model, description and
# context (lines 1-6), the KEEP IN SYNC comment line, and /hExecute <-> /sExecute
# self-references.
set -u
cd "$(dirname "$0")/.."

normalize() {
  sed -E \
    -e '1,6{/^(name|model|description|context): /d;}' \
    -e '/^<!-- KEEP IN SYNC WITH/d' \
    -e 's#/[hs]Execute#/XExecute#g' \
    "$1"
}

out=$(diff <(normalize hExecute/SKILL.md) <(normalize sExecute/SKILL.md) 2>&1)
rc=$?
case $rc in
  0) echo "✅ hExecute/SKILL.md and sExecute/SKILL.md are in sync"; exit 0 ;;
  1) echo "❌ hExecute/SKILL.md and sExecute/SKILL.md differ outside the allowed lines:"; echo "$out"; exit 1 ;;
  *) echo "❌ diff failed ($rc):"; echo "$out"; exit "$rc" ;;
esac
