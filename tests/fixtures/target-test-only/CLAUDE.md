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
- **Format:** `dart format <changed files>` — format only files you touch; the repo is not format-clean, so do not gate on `dart format --set-exit-if-changed .`
