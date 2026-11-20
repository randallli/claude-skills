# shellcheck shell=bash
# Shared harness for the "no file under these paths may name X" checks.
# Source it, then call:
#
#   forbid_refs "<what>" "<grep BRE pattern>" [grep options...] <paths...>
#   forbid_tracked_refs "<what>" "<grep BRE pattern>" <pathspecs...>
#
# forbid_refs scans the paths recursively; forbid_tracked_refs scans only
# tracked files (git grep), so untracked local state cannot fail it. Both are
# case-insensitive. grep's exit code is dispatched rather than trusted: 0 (a
# match) fails the check and prints the lines, 1 (no match) passes, and
# anything else (a missing path, a bad pattern) fails loudly instead of
# reading as a pass.
forbid_refs() {
  local what=$1 pattern=$2
  shift 2
  local out rc
  out=$(grep -rni -e "$pattern" "$@" 2>&1)
  rc=$?
  _forbid_dispatch "$what" "$rc" "$out"
}

forbid_tracked_refs() {
  local what=$1 pattern=$2
  shift 2
  local out rc
  out=$(git grep -nI -i -e "$pattern" -- "$@" 2>&1)
  rc=$?
  _forbid_dispatch "$what" "$rc" "$out"
}

_forbid_dispatch() {
  case $2 in
    0) echo "❌ $1:"; echo "$3"; return 1 ;;
    1) echo "✅ no $1"; return 0 ;;
    *) echo "❌ grep failed ($2):"; echo "$3"; return "$2" ;;
  esac
}
