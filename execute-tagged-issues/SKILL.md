---
name: execute-tagged-issues
description: Use when the user asks to execute, hExecute, or process GitHub issues tagged with the `agent-should-execute` label
---

# Execute Tagged Issues

Find open GitHub issues labeled `agent-should-execute` and dispatch a subagent to run the executor the plan recommends (`/hExecute` or `/sExecute`) on each. As each issue moves through the pipeline, update its labels: remove `agent-should-execute` and add `agent-started` when work begins, then swap `agent-started` for `ready-for-review` when the subagent finishes successfully.

## Steps

1. **List tagged issues:**
   ```bash
   gh issue list --label "agent-should-execute" --state open --json number,title,url --limit 50
   ```

2. **If none found:** Report "No issues tagged `agent-should-execute`." and stop.

3. **Ensure the status labels exist** (no-op if already present):
   ```bash
   gh label create "agent-started" --color FBCA04 --description "Agent is actively executing this issue" 2>/dev/null || true
   gh label create "ready-for-review" --color 0E8A16 --description "Agent finished; ready for human review" 2>/dev/null || true
   ```

4. **For each issue, prepare first, then dispatch all at once.** Steps a and b run per issue and finish before any dispatch (their Bash calls for several issues can share one message); step c then sends every Agent call in one message. Dispatching before b has returned would leave `<executor>` unresolved or guessed.

   a. Swap the labels *first* (before dispatching) — remove `agent-should-execute` to prevent re-processing, and add `agent-started` to mark it in progress:
   ```bash
   gh issue edit <N> --remove-label "agent-should-execute" --add-label "agent-started"
   ```

   b. Read the recommended executor from the issue's most recent plan comment. One Bash call (shell variables do not survive between calls); the `startswith("## TDD Plan")` predicate and `tail -1` are the same ones `/hExecute` step 1 uses, so dispatcher and executor read the same comment. The script prints exactly one line:
   ```bash
   plan_id=$(gh api repos/{owner}/{repo}/issues/<N>/comments --paginate \
     --jq '.[] | select(.body | startswith("## TDD Plan")) | .id' | tail -1)
   if [ -z "$plan_id" ]; then echo "NO_PLAN"; else
     body=$(gh api "repos/{owner}/{repo}/issues/comments/$plan_id" --jq .body) || { echo "API_ERROR"; exit 1; }
     executor=$(printf '%s\n' "$body" | grep -A2 '^### Recommended Executor' | grep -oE '/[hs]Execute' | head -1)
     echo "${executor:-DEFAULT /hExecute}"
   fi
   ```
   Act on that line:
   - `/hExecute` or `/sExecute`: dispatch it in step c.
   - `DEFAULT /hExecute`: the plan has no `### Recommended Executor` section (posted before #58, or the section is malformed). Dispatch `/hExecute`, and say in step 6 that it was the default, not a recommendation, so a plan that meant Sonnet and got Haiku is visible.
   - `NO_PLAN`: the issue has no `## TDD Plan` comment. Do **not** dispatch; treat it as blocked in step 5 and report "no plan; run `/oPlan <N>` first".
   - `API_ERROR` (the second `gh api` failed; its stderr is on screen): do **not** dispatch; report the error for that issue and continue with the others.

   c. Once every issue's step b has returned, dispatch one subagent per issue in a single message (subagent_type: `claude`, **`isolation: "worktree"`**) with a prompt like, where `<executor>` is the value from `b.`:
   > Run the <executor> skill on GitHub issue #<N> in <owner/repo> (title: "<title>"). Invoke the <executor without the slash> skill via the Skill tool with arg "<N>". Follow the skill's instructions exactly. Report back a brief summary (under 150 words) of what tasks were executed and the final state (PR opened, tests passing, blockers, etc.).

5. **When each subagent finishes, update its issue's labels based on the outcome:**

   - **Completed successfully** (the subagent reports all tasks done with no blocker or escalation — a PR may or may not have been opened; don't gate on the PR) — swap `agent-started` for `ready-for-review`:
     ```bash
     gh issue edit <N> --remove-label "agent-started" --add-label "ready-for-review"
     ```
   - **Blocked or escalated** (e.g. the executor escalated to `/oPlan`, tests failing, `NO_PLAN` or `API_ERROR` in step b so nothing was dispatched) — leave `agent-started` in place (do **not** mark ready-for-review) and surface the blocker in the report.

6. **Report results:** One bullet per issue with the issue number, title, PR link (if opened), final state, which executor was dispatched (and `defaulted to /hExecute: no Recommended Executor section` when step b printed `DEFAULT`), and which status label it now carries.

## Notes

- **`isolation: "worktree"` is required.** The executor edits files, runs tests, and commits on a per-issue branch. Without per-agent worktrees, parallel runs interleave edits on a single checkout and corrupt each other's work. The worktree is auto-cleaned if no changes were made; otherwise the path/branch is returned in the agent's result so you can push/PR from it.
- Remove `agent-should-execute` *before* dispatching, not after — otherwise a second invocation of this skill (or a concurrent run) will re-execute the same issue. Adding `agent-started` at the same time gives a visible "in progress" signal while the subagent runs.
- Only apply `ready-for-review` on a clean completion. A blocked/escalated issue keeps `agent-started` so it's clear it still needs attention rather than review.
- A blocked/escalated issue leaves the auto-execute queue: `agent-should-execute` was already removed at dispatch, and the issue keeps `agent-started` (plus any `tdd-escalation` the subagent added), so a later sweep won't re-pick it. This is intended — escalations need `/oPlan` revision (and a re-tag with `agent-should-execute`) before they're eligible to run again.
- The executor requires a TDD plan already on the issue (from `/oPlan`). Step b finds out first (`NO_PLAN`) and skips the dispatch; report it as a blocker. If a plan appears later without a `### Recommended Executor` section, the subagent itself may still report a missing-plan blocker — relay that too.
- Dispatch issues in parallel when there's more than one; each executor run is independent (separate branches, separate worktrees).
- If `gh issue edit` fails (e.g., label already removed), continue with dispatch anyway and note it in the report.
- The recommendation lives in the plan comment, not in a label: the planners set only `tdd-plan-ready` and `tdd-escalation`, and a replan can change the recommendation by posting a new plan without any label swap.
