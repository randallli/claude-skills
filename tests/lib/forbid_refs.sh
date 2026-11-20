# shellcheck shell=bash
# Shared harness for the "no file under these paths may name X" checks.
# Source it, then call:
#
#   forbid_refs "<what>" "<grep BRE pattern>" [grep options...] <paths...>
#
# Scans the paths recursively and case-insensitively. grep's exit code is
# dispatched rather than trusted: 0 (a match) fails the check and prints the
# lines, 1 (no match) passes, and anything else (a missing path, a bad
# pattern) fails loudly instead of reading as a pass.
forbid_refs() {
  local what=$1 pattern=$2
  shift 2
  local out rc
  out=$(grep -rni -e "$pattern" "$@" 2>&1)
  rc=$?
  case $rc in
    0) echo "❌ $what:"; echo "$out"; return 1 ;;
    1) echo "✅ no $what"; return 0 ;;
    *) echo "❌ grep failed ($rc):"; echo "$out"; return "$rc" ;;
  esac
}
