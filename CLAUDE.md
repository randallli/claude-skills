# CLAUDE.md

This repo is a collection of Claude Code skills (Markdown prompts plus a few
shell scripts). See `README.md` for layout and `tests/README.md` for how skill
behavior is verified.

## Commands

- **Test:** `bash tests/check_stale_refs.sh` (mechanical regression test; changes to skill *behavior* are additionally verified by the subagent scenarios in `tests/README.md`)
- **Analyze:** `bash tests/check_sync.sh`
