#!/bin/bash
# Run Flutter tests with machine output to tmp/
# Usage: ./scripts/run_tests.sh [test_file]
#   test_file - optional path to specific test file or directory
#
# Options:
#   --fast    Exclude golden tests for faster feedback

set -eo pipefail

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

# Run tests, capturing raw output. Filter to valid JSON lines only.
# Allow test failures (non-zero exit) so we can still parse and summarize results.
flutter test --machine --concurrency="$CONCURRENCY" $EXCLUDE_TAGS "${ARGS[@]}" | grep '^{' > ./tmp/test_results.json || true

# Guard against empty output (e.g., compilation error, missing flutter)
if [ ! -s ./tmp/test_results.json ]; then
  echo "ERROR: No test output captured. Check for compilation errors." | tee ./tmp/test_summary.txt
  exit 1
fi

# Generate human-readable summary from the clean JSON
jq -r '
def count(f): [.[] | select(f)] | length;

count(.type == "testDone" and .result == "success") as $passed |
count(.type == "testDone" and .result == "failure") as $failed |
count(.type == "testDone" and .result == "error") as $errored |
count(.type == "testStart" and .test.metadata.skip == true) as $skipped |
($passed + $failed + $errored) as $total |
([.[] | select(.type == "done")] | first) as $done |
($done.success // false) as $success |
(($done.time // 0) / 1000 * 10 | round / 10) as $seconds |

# Map test IDs to names
([.[] | select(.type == "testStart")] | map({(.test.id | tostring): .test.name}) | add // {}) as $names |

# Collect error messages
[.[] | select(.type == "error")] as $errors |

if $success then
  "✅ All \($total) tests passed (\($skipped) skipped) in \($seconds)s"
else
  "❌ \($failed + $errored) failed, \($passed) passed, \($skipped) skipped (\($total) total) in \($seconds)s\n\n" +
  ([.[] | select(.type == "testDone" and .result != "success") |
    .testID | tostring | . as $id | $names[$id] // "unknown test" |
    "  FAIL: " + .
  ] | join("\n")) +
  if ($errors | length) > 0 then
    "\n\n" + ($errors | map(
      "  ERROR in \($names[.testID | tostring] // "unknown test"):\n    " +
      (.error | gsub("\n"; "\n    "))
    ) | join("\n\n"))
  else "" end
end
' -s ./tmp/test_results.json > ./tmp/test_summary.txt

cat ./tmp/test_summary.txt
