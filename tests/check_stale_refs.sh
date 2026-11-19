#!/bin/bash
# Regression test: no skill may name a project-local test/analyze script.
# The test and analyze commands come from the target repo's CLAUDE.md.
# Takes no arguments (there is no single-file form); any argument is ignored.
set -u
cd "$(dirname "$0")/.."

out=$(grep -rn 'scripts/run_\|run_tests\.sh\|analyze_results' hExecute sExecute create-pr fix-ci README.md 2>&1)
rc=$?
case $rc in
  0) echo "❌ stale script references:"; echo "$out"; exit 1 ;;
  1) echo "✅ no stale script references"; exit 0 ;;
  *) echo "❌ grep failed ($rc):"; echo "$out"; exit "$rc" ;;
esac
