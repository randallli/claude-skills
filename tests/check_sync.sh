#!/bin/bash
# Analyze step for this repo: hExecute/SKILL.md and sExecute/SKILL.md must be
# identical except for frontmatter (name, model, description, context), the
# KEEP IN SYNC comment line, and /hExecute <-> /sExecute self-references.
set -u
cd "$(dirname "$0")/.."

normalize() {
  sed -E \
    -e '/^(name|model|description|context): /d' \
    -e '/^<!-- KEEP IN SYNC WITH/d' \
    -e 's#/[hs]Execute#/XExecute#g' \
    "$1"
}

if out=$(diff <(normalize hExecute/SKILL.md) <(normalize sExecute/SKILL.md)); then
  echo "✅ hExecute/SKILL.md and sExecute/SKILL.md are in sync"
  exit 0
else
  echo "❌ hExecute/SKILL.md and sExecute/SKILL.md differ outside the allowed lines:"
  echo "$out"
  exit 1
fi
