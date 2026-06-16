---
name: execute-tagged-issues
description: Use when the user asks to execute, hExecute, or process GitHub issues tagged with the `agent-should-execute` label
---

# Execute Tagged Issues

Find open GitHub issues labeled `agent-should-execute` and dispatch a subagent to run `/hExecute` on each. Remove the label before dispatching so the issue isn't picked up twice.

## Steps

1. **List tagged issues:**
   ```bash
   gh issue list --label "agent-should-execute" --state open --json number,title,url --limit 50
   ```

2. **If none found:** Report "No issues tagged `agent-should-execute`." and stop.

3. **For each issue, in parallel (single message, multiple Agent calls):**

   a. Remove the label *first* (before dispatching) to prevent re-processing:
   ```bash
   gh issue edit <N> --remove-label "agent-should-execute"
   ```

   b. Dispatch a subagent (subagent_type: `claude`, **`isolation: "worktree"`**) with a prompt like:
   > Run the /hExecute skill on GitHub issue #<N> in <owner/repo> (title: "<title>"). Invoke the hExecute skill via the Skill tool with arg "<N>". Follow the skill's instructions exactly. Report back a brief summary (under 150 words) of what tasks were executed and the final state (PR opened, tests passing, blockers, etc.).

4. **Report results:** One bullet per issue with the issue number, title, PR link (if opened), and final state.

## Notes

- **`isolation: "worktree"` is required.** /hExecute edits files, runs tests, and commits on a per-issue branch. Without per-agent worktrees, parallel runs interleave edits on a single checkout and corrupt each other's work. The worktree is auto-cleaned if no changes were made; otherwise the path/branch is returned in the agent's result so you can push/PR from it.
- Remove the label *before* dispatching, not after — otherwise a second invocation of this skill (or a concurrent run) will re-execute the same issue.
- `/hExecute` requires a TDD plan already on the issue (from `/oPlan`). If the issue isn't planned yet, the subagent will report that as a blocker — relay it.
- Dispatch issues in parallel when there's more than one; each /hExecute run is independent (separate branches, separate worktrees).
- If `gh issue edit` fails (e.g., label already removed), continue with dispatch anyway and note it in the report.
