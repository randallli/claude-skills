#!/usr/bin/env bash
#
# review-round.sh <repo> <pr-number> — enforce policy.yml's review_rounds argue-loop cap
# (DarkFactoryDesign#97 Task 5). Counts prior CHANGES_REQUESTED reviews on the PR attributed to
# this skill's own App identity (not any other role's), so a Gatekeeper or human review never
# inflates the Evaluator's own round count.
#
# Retuning the cap is a policy.yml edit with no change to this script (OCP) — same knob
# scheduler/launchd-scheduler.sh's REVIEW_ROUNDS reads for the rest of the pipeline.
#
# Usage: review-round.sh <repo> <pr-number>
#   stdout: "round=<n> cap=<c>" when under the cap (exit 0), or
#           "round=<n> cap=<c> escalate=needs-human" when the cap is exceeded (exit 2)
#
# ORG defaults to TripleLiDarkFactory and is overridable via DARKFACTORY_ORG, matching
# preflight-holdout.sh and scheduler/test/helpers.bash's existing seam.
set -euo pipefail

REPO="${1:?Usage: review-round.sh <repo> <pr-number>}"
PR_NUMBER="${2:?Usage: review-round.sh <repo> <pr-number>}"
ORG="${DARKFACTORY_ORG:-TripleLiDarkFactory}"

# The App identity GitHub attributes reviews to for this role. Fixed, not a parameter: this
# script is evaluate-pr's own helper, never invoked on another role's behalf.
readonly EVALUATOR_LOGIN='darkfactory-evaluator[bot]'

DEFAULT_CAP=3
POLICY_FILE="${FACTORY_POLICY_FILE:-}"
cap=""
if [[ -n "$POLICY_FILE" && -f "$POLICY_FILE" ]]; then
  cap="$(yq -r '.review_rounds // ""' "$POLICY_FILE" 2>/dev/null || true)"
fi
[[ "$cap" =~ ^[0-9]+$ ]] || cap="$DEFAULT_CAP"

reviews_json="$(gh pr view "$PR_NUMBER" --repo "${ORG}/${REPO}" --json reviews 2>/dev/null || true)"
[[ -n "$reviews_json" ]] || reviews_json='{"reviews": []}'

prior="$(jq --arg login "$EVALUATOR_LOGIN" \
  '[.reviews[] | select(.author.login == $login and .state == "CHANGES_REQUESTED")] | length' \
  <<<"$reviews_json")"

round=$((prior + 1))

if [[ "$round" -gt "$cap" ]]; then
  echo "round=${round} cap=${cap} escalate=needs-human"
  exit 2
fi

echo "round=${round} cap=${cap}"
