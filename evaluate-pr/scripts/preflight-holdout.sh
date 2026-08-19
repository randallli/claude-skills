#!/usr/bin/env bash
#
# preflight-holdout.sh <repo> — decide whether an independent holdout run is possible right now,
# and if not, name the exact reason (DarkFactoryDesign#97 Task 3).
#
# The evaluate-pr skill's independence from the code it's reviewing depends on two facts that are
# true by construction today (scripts/new-project.sh:123 HOLDOUT_ROLE_APPS, and
# scheduler/launchd-scheduler.sh:244's "token is scoped to the App's whole installation") but are
# never guaranteed to stay true. This script verifies them on the live box on every run and fails
# loudly the moment either stops holding — the alternative is silently degrading to a plain code-
# review bot with none of design §4's anti-gaming value.
#
# Usage: preflight-holdout.sh <repo>
#   stdout (only on success): a single machine-readable line, "holdout=ready qc=<org>/<repo>-qc
#   features=<n>"
#   stderr (only on failure): "holdout=blocked reason=<reason>"
#
# Exit codes:
#   0  ready       — installation covers both <repo> and <repo>-qc, and >=1 features/*.feature
#                    exists in the current checkout.
#   3  blocked     reason=qc-not-in-installation — the App installation this token belongs to
#                    does not include <repo>-qc.
#   4  blocked     reason=no-feature-files — installation is fine, but no BDD contract exists yet
#                    to derive an independent holdout from (design §7.1 sequencing — expected to
#                    fire on every <game> repo until the Specifier station lands).
#   5  blocked     reason=installation-query-failed — the `gh api` call failed or returned
#                    nothing; treat as blocked rather than guessing.
#
# ORG defaults to TripleLiDarkFactory and is overridable via DARKFACTORY_ORG (the same seam
# scheduler/test/helpers.bash already uses).
set -euo pipefail

REPO="${1:?Usage: preflight-holdout.sh <repo>}"
ORG="${DARKFACTORY_ORG:-TripleLiDarkFactory}"
QC_REPO="${REPO}-qc"

blocked() { # reason exit_code
  echo "holdout=blocked reason=${1}" >&2
  exit "$2"
}

installation_repos="$(gh api /installation/repositories --paginate --jq '.repositories[].name' 2>/dev/null)" || true
[[ -n "$installation_repos" ]] || blocked "installation-query-failed" 5

grep -qxF "$QC_REPO" <<<"$installation_repos" || blocked "qc-not-in-installation" 3

shopt -s nullglob
feature_files=(features/*.feature)
shopt -u nullglob
[[ "${#feature_files[@]}" -gt 0 ]] || blocked "no-feature-files" 4

echo "holdout=ready qc=${ORG}/${QC_REPO} features=${#feature_files[@]}"
