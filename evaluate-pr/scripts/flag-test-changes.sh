#!/usr/bin/env bash
#
# flag-test-changes.sh — deterministic detection of the "Builder weakens or deletes tests"
# threat (DarkFactoryDesign#97 Task 4). Reads a unified diff on stdin (the skill pipes
# `gh pr diff <N>` in; tests pipe a static fixture — no network in either case) and classifies
# hunks. Renders no verdict; the evaluate-pr skill decides what to do with the flags.
#
# Protected paths match CODEOWNERS in tic-tac-toe exactly:
#   /packages/rules_engine/   any-depth-anchored-at-root production rules code
#   /**/test/                 a "test" directory at any depth
#   /**/features/             a "features" directory at any depth — the BDD contract layer
#
# Output: one line per flagged file, most-specific-classification-first per file:
#   DELETED <path>                    — a protected test file was removed entirely
#   WEAKENED <path> (-<removed>/+<added>)  — net-negative diff to a protected test file
#   CONTRACT <path>                   — any edit at all to a .feature file, regardless of sign
#   PROTECTED <path>                  — any edit at all under packages/rules_engine/
# Adding a brand-new test file (net-positive, zero deletions) is never flagged — that's not the
# threat this script exists to catch, and a classifier that cries wolf on it will be ignored.
#
# Exit 1 if anything was flagged, 0 otherwise (including empty stdin).
set -euo pipefail

is_contract() { [[ "$1" == features/* || "$1" == */features/* ]]; }
is_rules_engine() { [[ "$1" == packages/rules_engine/* ]]; }
is_test_dir() { [[ "$1" == test/* || "$1" == */test/* ]]; }

current_path=""
is_deleted=0
added=0
removed=0
flagged=0

flush() {
  [[ -n "$current_path" ]] || return 0
  if is_contract "$current_path"; then
    echo "CONTRACT ${current_path}"
    flagged=1
  elif is_rules_engine "$current_path"; then
    echo "PROTECTED ${current_path}"
    flagged=1
  elif is_test_dir "$current_path"; then
    if [[ "$is_deleted" -eq 1 ]]; then
      echo "DELETED ${current_path}"
      flagged=1
    elif [[ "$removed" -gt "$added" ]]; then
      echo "WEAKENED ${current_path} (-${removed}/+${added})"
      flagged=1
    fi
  fi
}

while IFS= read -r line || [[ -n "$line" ]]; do
  case "$line" in
    "diff --git "*)
      flush
      current_path=""
      is_deleted=0
      added=0
      removed=0
      ;;
    "deleted file mode"*)
      is_deleted=1
      ;;
    "--- "*)
      p="${line#--- }"
      [[ "$p" == "/dev/null" ]] || current_path="${p#a/}"
      ;;
    "+++ "*)
      p="${line#+++ }"
      [[ "$p" == "/dev/null" ]] || current_path="${p#b/}"
      ;;
    "+++"* | "---"*) : ;; # malformed/no-space header variants — ignore rather than misparse
    "+"*)
      added=$((added + 1))
      ;;
    "-"*)
      removed=$((removed + 1))
      ;;
  esac
done

flush

[[ "$flagged" -eq 0 ]]
