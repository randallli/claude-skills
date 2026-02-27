# claude-skills

A standalone, version-controlled collection of [Claude Code skills](https://docs.anthropic.com/en/docs/claude-code/skills) — portable across machines via symlink.

## Setup

### First machine (clone)

```sh
git clone git@github.com:randallli/claude-skills.git ~/Documents/code/claude/skills
ln -s ~/Documents/code/claude/skills ~/.claude/skills
```

### This machine (already configured)

`~/.claude/skills` is a symlink to this repo.

## Structure

Each skill lives in its own directory with a `SKILL.md` file:

```
skills/
├── create-pr/
│   ├── SKILL.md
│   └── scripts/
│       └── run_tests.sh
├── merge-pr/
│   └── SKILL.md
└── your-skill/
    └── SKILL.md
```

Claude Code loads skills from `~/.claude/skills/` automatically. The skill's directory name becomes its invocation name (e.g., `/merge-pr`).

## Adding a skill

```sh
mkdir ~/Documents/code/claude/skills/my-skill
# Write the skill prompt to SKILL.md
git add my-skill/
git commit -m "Add my-skill"
```

`SKILL.md` is a plain markdown prompt. Claude receives it as instructions when the skill is invoked.

## Skills

| Skill | Description |
|-------|-------------|
| `create-pr` | Push branch, create PR immediately, then run tests/linter and push fixes |
| `merge-pr` | Squash-merge the most recent PR and create a new branch for continued development |
