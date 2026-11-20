#!/bin/bash
# Regression test: no doc may describe the v1 Dark Factory promotion path.
# v2 loads the skills from a pinned clone of this repo (randallli/claude-skills#46);
# the v1 repo's skills/ directory and its PR #25 are history.
#
# Matched (case-insensitively): the v1 org name; the v1 repo's skills/ directory
# as `factory/skills/`, "factory's `skills/`" or "factory repo's `skills/`"; and
# its PR #25 as `factory#25` or `factory/pull/25`. A bare `#25` is not matched:
# this repo has its own #25.
#
# docs/superpowers/ is excluded: it holds records of past work, which name the
# v1 path as history. tests/README.md names the tokens too and is not scanned.
# Takes no arguments (there is no single-file form); any argument is ignored.
set -u
cd "$(dirname "$0")/.." || exit 1
. tests/lib/forbid_refs.sh

forbid_refs "v1 promotion-path references" \
  'triplelidarkfactory\|factory/skills\|factory#25\|factory/pull/25\|factory\( repo\)\{0,1\}.s .skills/' \
  --exclude-dir=superpowers docs README.md
