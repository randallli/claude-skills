#!/bin/bash
# Run Flutter tests with machine output to tmp/
# Usage: ./scripts/run_tests.sh [test_file]
#   test_file - optional path to specific test file or directory
#
# Options:
#   --fast    Exclude golden tests for faster feedback

set -e

# Use half of CPU cores (leaves headroom for other processes)
if [[ "$OSTYPE" == "darwin"* ]]; then
  CORES=$(sysctl -n hw.ncpu)
else
  CORES=$(nproc 2>/dev/null || echo 4)
fi
CONCURRENCY=$((CORES / 2))
# Minimum of 2
CONCURRENCY=$((CONCURRENCY < 2 ? 2 : CONCURRENCY))

# Check for --fast flag
EXCLUDE_TAGS=""
ARGS=()
for arg in "$@"; do
  if [[ "$arg" == "--fast" ]]; then
    EXCLUDE_TAGS="--exclude-tags golden"
  else
    ARGS+=("$arg")
  fi
done

mkdir -p ./tmp
flutter test --machine --concurrency="$CONCURRENCY" $EXCLUDE_TAGS "${ARGS[@]}" > ./tmp/test_results.json
echo "Test results saved to ./tmp/test_results.json (concurrency: $CONCURRENCY)"
