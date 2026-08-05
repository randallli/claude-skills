# claude-skills

A standalone, version-controlled collection of [Claude Code skills](https://docs.anthropic.com/en/docs/claude-code/skills) — portable across machines via symlink.

## Setup

### This machine (already configured)

`~/.claude/skills` is a symlink to this repo.

<a id="new-machine"></a>

### New machine

Four steps. Skills alone aren't a full setup — the plugins carry a lot of the workflow, and
without git auth you can't pull updates.

**1. GitHub access.** Give the machine its own key rather than copying one; a per-machine key
can be revoked independently and works unattended (cron, headless agents) where a forwarded
agent can't.

```sh
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "$(whoami)@$(scutil --get LocalHostName)"
gh ssh-key add ~/.ssh/id_ed25519.pub    # or paste it into github.com/settings/keys
```

Seed the host key, and *verify the fingerprint* rather than trusting whatever answers:

```sh
ssh-keyscan -t ed25519 github.com 2>/dev/null >> ~/.ssh/known_hosts
ssh-keygen -lf <(ssh-keyscan -t ed25519 github.com 2>/dev/null)
```

That must print `SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU`. If it doesn't, stop —
something is intercepting the connection. Confirm access with `ssh -T git@github.com`.

**2. Clone and symlink.**

```sh
git clone git@github.com:randallli/claude-skills.git ~/Documents/code/claude/skills
ln -s ~/Documents/code/claude/skills ~/.claude/skills
```

**3. Install plugins.** Skills and plugins are separate systems — cloning this repo installs
neither the marketplace nor the plugins.

```sh
claude plugin marketplace add anthropics/claude-plugins-official
claude plugin install superpowers@claude-plugins-official
claude plugin install commit-commands@claude-plugins-official
claude plugin install swift-lsp@claude-plugins-official
```

These install at user scope (`~/.claude/plugins`) and update per-machine, so each box can move
at its own pace.

**4. Verify.**

```sh
readlink ~/.claude/skills     # -> ~/Documents/code/claude/skills
ls ~/.claude/skills           # the skill directories
claude plugin list            # the three plugins, enabled
```

Then start `claude` and confirm the skills appear. A running session won't pick up a
newly-created skills symlink — start a fresh one.

### Staying current

```sh
git -C ~/Documents/code/claude/skills pull
```

Skills are read from disk per session, so a pull takes effect the next time `claude` starts.

### Remote and headless machines

Reaching an always-on machine from an iPad or another laptop — Tailscale, mosh, tmux, SSH key
hygiene — is in [`docs/remote-access.md`](docs/remote-access.md). That document also explains
why a second account on the same machine (such as a Dark Factory `factory` user) must **not**
symlink at this repo directly.

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
| `oPlan` | Lead Architect (Opus) — analyze a GitHub issue and post a TDD plan as a GitHub comment |
| `hExecute` | TDD Executor (Haiku) — implement one task at a time from an oPlan TDD plan using Red-Green-Refactor |
| `fix-ci` | Diagnose and fix CI failures incrementally — handles Flutter test failures, analyzer warnings, and build issues |
