#!/bin/bash
# The test command. Runs every reference check and reports all of them before
# exiting, so one run shows every failure instead of stopping at the first.
# Takes no arguments (there is no single-file form); any argument is ignored.
set -u
cd "$(dirname "$0")/.." || exit 1

rc=0
for check in tests/check_stale_refs.sh tests/check_v1_refs.sh; do
  bash "$check" || rc=1
done
exit $rc
