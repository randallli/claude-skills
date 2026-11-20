#!/bin/bash
# Regression test: no skill may name a project-local test/analyze script.
# The test and analyze commands come from the target repo's CLAUDE.md.
# Takes no arguments (there is no single-file form); any argument is ignored.
set -u
cd "$(dirname "$0")/.." || exit 1
. tests/lib/forbid_refs.sh

forbid_refs "stale script references" 'scripts/run_\|run_tests\.sh\|analyze_results' \
  hExecute sExecute create-pr fix-ci README.md
