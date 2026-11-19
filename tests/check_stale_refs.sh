#!/bin/bash
# Regression test: no skill may name a project-local test/analyze script.
# The test and analyze commands come from the target repo's CLAUDE.md.
set -u
cd "$(dirname "$0")/.."

if out=$(grep -rn 'scripts/run_\|run_tests\.sh\|analyze_results' hExecute sExecute create-pr fix-ci README.md); then
  echo "❌ stale script references:"
  echo "$out"
  exit 1
else
  echo "✅ no stale script references"
  exit 0
fi
