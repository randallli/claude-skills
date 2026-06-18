---
name: execute-tagged-issues
description: Use when the user asks to execute, hExecute, or process GitHub issues tagged with the `agent-should-execute` label
---

# Execute Tagged Issues

Find open GitHub issues labeled `agent-should-execute` and dispatch a subagent to run `/hExecute` on each. As each issue moves through the pipeline, update its labels: remove `agent-should-execute` and add `agent-started` when work begins, then swap `agent-started` for `ready-for-review` when the subagent finishes successfully.

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

4. **For each issue, in parallel (single message, multiple Agent calls):**

   a. Swap the labels *first* (before dispatching) — remove `agent-should-execute` to prevent re-processing, and add `agent-started` to mark it in progress:
   ```bash
   gh issue edit <N> --remove-label "agent-should-execute" --add-label "agent-started"
   ```

   b. Dispatch a subagent (subagent_type: `claude`, **`isolation: "worktree"`**) with a prompt like:
   > Run the /hExecute skill on GitHub issue #<N> in <owner/repo> (title: "<title>"). Invoke the hExecute skill via the Skill tool with arg "<N>". Follow the skill's instructions exactly. Report back a brief summary (under 150 words) of what tasks were executed and the final state (PR opened, tests passing, blockers, etc.).

5. **When each subagent finishes, update its issue's labels based on the outcome:**

   - **Completed successfully** (all tasks done / PR opened, no blocker) — swap `agent-started` for `ready-for-review`:
     ```bash
     gh issue edit <N> --remove-label "agent-started" --add-label "ready-for-review"
     ```
   - **Blocked or escalated** (e.g. `/hExecute` escalated to `/oPlan`, tests failing, missing plan) — leave `agent-started` in place (do **not** mark ready-for-review) and surface the blocker in the report.

6. **Report results:** One bullet per issue with the issue number, title, PR link (if opened), final state, and which status label it now carries.

## Notes

- **`isolation: "worktree"` is required.** /hExecute edits files, runs tests, and commits on a per-issue branch. Without per-agent worktrees, parallel runs interleave edits on a single checkout and corrupt each other's work. The worktree is auto-cleaned if no changes were made; otherwise the path/branch is returned in the agent's result so you can push/PR from it.
- Remove `agent-should-execute` *before* dispatching, not after — otherwise a second invocation of this skill (or a concurrent run) will re-execute the same issue. Adding `agent-started` at the same time gives a visible "in progress" signal while the subagent runs.
- Only apply `ready-for-review` on a clean completion. A blocked/escalated issue keeps `agent-started` so it's clear it still needs attention rather than review.
- `/hExecute` requires a TDD plan already on the issue (from `/oPlan`). If the issue isn't planned yet, the subagent will report that as a blocker — relay it.
- Dispatch issues in parallel when there's more than one; each /hExecute run is independent (separate branches, separate worktrees).
- If `gh issue edit` fails (e.g., label already removed), continue with dispatch anyway and note it in the report.
