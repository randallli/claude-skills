# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Project context

counter_app is a tiny Flutter app with a single `Counter` class in `lib/counter.dart`
and its tests under `test/`. Follow Effective Dart naming: verbose, descriptive identifiers.

## Git & GitHub Tooling

- Prefer MCP GitHub tools; when none are available in the session, use `gh` and `git` via Bash.
- Keep the PR description merge-ready on every push.

## Commands

CI (`.github/workflows/`) is the source of truth; these mirror it.

- **Install deps:** `flutter pub get`
- **Test:** `flutter test` (single file: `flutter test <path>`, e.g. `flutter test test/counter_test.dart`)
- **Analyze:** `flutter analyze --no-fatal-infos` (CI's exact flags; must exit 0)
- **File sizes:** `bash tool/check_file_sizes.sh` (lines per Dart file under lib/ and test/; flag lib/ > 500, test/ > 800)
- **Format:** `dart format <changed files>` — format only files you touch; the repo is not format-clean, so do not gate on `dart format --set-exit-if-changed .`
- **Rive sources** (only when `rive_src/` or `assets/rive/` changes): `dart run tool/check_rive_sources.dart` (CI runs it; needs the `rive` CLI)
