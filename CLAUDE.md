# CLAUDE.md

This repo is a collection of Claude Code skills (Markdown prompts plus a few
shell scripts). See `README.md` for layout and `tests/README.md` for how skill
behavior is verified.

## Commands

- **Test:** `bash tests/check_refs.sh` (no single-file form: it runs every reference check, reports all of them, and its argument is ignored; changes to skill *behavior* are additionally verified by the subagent scenarios in `tests/README.md`)
- **Analyze:** `bash tests/check_sync.sh`
