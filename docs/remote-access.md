# Remote access to a headless machine

How to reach an always-on Mac (the mini) from a thin client — an iPad, a phone, or another
laptop — and run Claude Code there with this repo's skills.

Setting up the skills themselves is in the [README](../README.md#new-machine). This document
covers only *reaching* the machine. Do the README setup first; nothing here depends on it, and
nothing there depends on this.

> **`mini1` is user-operated.** Run these commands yourself in a terminal. Agents don't execute
> against that box — a Dark Factory convention, documented in `factory`'s `skills/README.md`
> (landing with [TripleLiDarkFactory/factory#25](https://github.com/TripleLiDarkFactory/factory/pull/25)).
> Everything below is written as copy-paste for a human.

## The shape of it

```
iPad (Blink) ──mosh over Tailscale──> mini ──> tmux ──> claude
```

Four layers, each solving one problem:

| Layer | Problem it solves |
|-----------|--------------------------------------------------------------|
| Tailscale | Reaching the machine from any network without port forwarding |
| SSH keys | Authenticating without a password |
| mosh | Surviving roaming between wifi and cellular |
| tmux | Surviving the client app being killed |

Skip any layer and you lose exactly that property. tmux without mosh works but reconnects
constantly; mosh without tmux drops your session when iOS evicts the app from memory.

## 1. Tailscale

Puts every device on one private network with stable IPs, so the remote machine is reachable
from home wifi, cellular, or someone else's network, with no port forwarding and no exposed
SSH port.

Install on both ends and log in to the same account:

```sh
brew install tailscale     # or the Mac App Store app
tailscale up
```

On iOS, install Tailscale from the App Store and sign in.

Verify every device is on the tailnet:

```sh
tailscale status
```

Each device gets a stable `100.x.y.z` address. Prefer the MagicDNS name (`mini1`) over the raw
IP — the IP is stable but the name is what you'll remember.

### Keep it awake

A machine that sleeps is not reachable. On the remote machine:

```sh
sudo pmset -a sleep 0 disksleep 0
```

Confirm with `pmset -g custom` — you want `sleep 0`. Leave `displaysleep` alone; the display
sleeping is fine and saves power.

## 2. SSH keys

Generate the key **on the client**, then install its public half on the remote machine. Private
keys never move between machines.

In Blink: `config` → Keys → new ed25519 key → copy the public key.

### Installing a public key — mind the trailing newline

`authorized_keys` is line-oriented, and sshd parses each line as `keytype base64 comment`. If
the file does not end in a newline, the next `>>` append lands on the *same line* as the
previous key. sshd then reads the second key as part of the first key's **comment** and
silently ignores it. The file looks correct, `wc -l` looks plausible, and your key just
doesn't work.

This is the single most common way key installation fails. Append safely:

```sh
mkdir -p ~/.ssh && chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys

# add a trailing newline only if the file lacks one
[ -s ~/.ssh/authorized_keys ] && [ -n "$(tail -c1 ~/.ssh/authorized_keys)" ] \
  && echo >> ~/.ssh/authorized_keys

echo 'ssh-ed25519 AAAA...your-public-key... blink@ipad' >> ~/.ssh/authorized_keys
```

Then verify — this is the check that catches the concatenation bug:

```sh
ssh-keygen -lf ~/.ssh/authorized_keys
```

You want **one output line per key**, each with a short, sane comment. A comment containing a
key type and a base64 blob means two keys are sharing a line. Fix by splitting them onto
separate lines.

Cross-check the count:

```sh
awk '{print NR": "$1"  fields="NF}' ~/.ssh/authorized_keys
```

Every line should have 3 fields (or 4 with options). A line with 5+ fields is two keys mashed
together.

## 3. mosh

SSH sessions die when your IP changes — walking out of wifi range onto cellular kills them.
mosh keeps the session alive across IP changes and reconnects automatically after a drop.

```sh
brew install mosh
```

mosh needs **UDP 60000–61000** open between client and server. Over Tailscale this already
works; Tailscale carries UDP and there is no firewall between tailnet peers.

Connect from Blink:

```sh
mosh mini1
```

If that fails with "command not found," the login shell isn't picking up Homebrew's path for
non-interactive invocations. Point mosh at the binary explicitly:

```sh
mosh --server=/opt/homebrew/bin/mosh-server mini1
```

Or set it once in the Blink host config so you don't retype it.

## 4. tmux

mosh handles the network moving. It does not handle iOS deciding to evict Blink from memory,
which will happen if you background it long enough. tmux runs the session on the *server*, so
the work continues regardless of what the client does.

```sh
brew install tmux
```

Add an attach-or-create helper to `~/.zshrc` on the remote machine:

```sh
cc() { tmux new-session -A -s claude; }
```

`-A` attaches to the session if it exists and creates it otherwise, so `cc` is the only command
you need — it does the right thing whether you're starting fresh or coming back.

Workflow: `mosh mini1`, then `cc`, then `claude`. When the iPad dies, closes, or you walk away,
reconnect with the same two commands and your session is exactly where you left it.

### A note on scrollback

tmux captures the scrollback, so Blink's native scroll gesture won't reach it. Use tmux copy
mode (`Ctrl-b [`, then arrows or Page Up, `q` to exit). Worth knowing before it confuses you
mid-session.

## Authentication in an SSH session

**This will bite you, and the error message doesn't explain it.** Skills and plugins install
fine over SSH, then `claude` fails with:

```
Not logged in · Please run /login
```

...even though the machine *is* logged in and has active sessions.

The cause: on macOS, Claude Code stores credentials in the **login keychain**, and an SSH
session runs in a non-GUI security session. macOS refuses keychain access that would require
user interaction, regardless of whether a console session has the keychain unlocked. You can
see it directly:

```sh
security find-generic-password -s "Claude Code-credentials" -w >/dev/null 2>&1; echo $?
```

Exit `36` is `errSecInteractionNotAllowed` — the credential exists and is simply unreachable
from this context. `security show-keychain-info` says the same thing in words: *"User
interaction is not allowed."*

### The fix: a token, not the keychain

Use a long-lived token, which lives in a file rather than the keychain and so has no GUI
dependency:

```sh
claude setup-token
```

It prints a URL to authorize in a browser. If it insists on a local browser, run it from a
GUI session on the machine (Screen Sharing) rather than over SSH — you only do this once.

This is the same pattern the headless Dark Factory agents already use: the `factory` account
authenticates from `~/.claude/.credentials.json` (mode `600`), not the keychain, which is
precisely why its launchd-driven sessions work unattended.

Verify from a *fresh* SSH session — not the one you set it up in:

```sh
ssh <host> 'claude -p "say ok"'
```

### Alternatives

- `ANTHROPIC_API_KEY` in the environment works, but bills as API usage rather than against a
  subscription. Different cost model — know which one you want.
- `security unlock-keychain ~/Library/Keychains/login.keychain-db` can unblock keychain reads
  for a session, but it prompts for your account password every time and doesn't survive
  reconnects. Fine for a one-off, wrong for a setup you'll use daily from an iPad.

## Other accounts on the same machine

Skills are per-account. Everything in this document and in the README sets up **one user's**
`~/.claude`. A second account on the same machine (`admin`, `factory`, …) has its own
`~/.claude` and gets nothing from your setup.

That isolation is deliberate, and on `mini1` it is load-bearing: the `factory` account does
**not** consume this repo. It symlinks `~/.claude/skills` at a checkout of
[`TripleLiDarkFactory/factory`](https://github.com/TripleLiDarkFactory/factory)'s `skills/`
directory, which holds *versioned copies* ported from here and guarded by a regression suite.
That repo's rule is "all GitHub Apps read this repo; only humans write to it."

**Do not point a factory account at this repo directly.** The port from here into
`factory/skills/` is the promotion gate — it's reviewed as a PR and tested, so an unfinished
skill edit can't silently change autonomous agent behavior mid-run. A direct symlink would
bypass that gate and create two sources of truth.

Bootstrap instructions for the `factory` user live in that repo's `skills/README.md`, not here.
That file lands with [TripleLiDarkFactory/factory#25](https://github.com/TripleLiDarkFactory/factory/pull/25);
until it merges, `factory/skills/` on `main` still holds only placeholder stubs, so the factory
agents have no real skill content yet.

One macOS detail worth knowing: home directories are `drwxr-x---` with group `staff`, and these
accounts share that group, so they **can** read each other's files. Cross-account symlinking is
therefore technically possible. Don't — it couples the accounts, breaks if permissions tighten,
and bypasses the gate above.

## Verification

Work outward from the network:

```sh
tailscale status | grep mini1              # on the tailnet?
ssh mini1 'echo ok'                        # key auth works, no password prompt?
ssh mini1 'ssh-keygen -lf ~/.ssh/authorized_keys'   # one line per key?
mosh mini1                                 # roams across networks?
```

Then inside the mosh session:

```sh
cc                                         # tmux attaches or creates
claude                                     # skills and plugins load
```

The real test for the last one is behavioral: detach, kill Blink entirely, reconnect, and
confirm you land back in the same session.

## Gotchas

- **A key that silently doesn't work** is almost always the trailing-newline bug in section 2.
  Check with `ssh-keygen -lf` before debugging anything else.
- **`mosh: command not found`** means Homebrew's path is missing for non-interactive shells.
  Use `--server=/opt/homebrew/bin/mosh-server`.
- **Session gone after reconnecting** means you ran `claude` outside tmux. mosh alone does not
  survive the client being killed.
- **Tailscale client/daemon version skew** (`brew` client newer than the running daemon) shows
  a warning on every command. Harmless, but `brew upgrade tailscale` and restart to clear it.
