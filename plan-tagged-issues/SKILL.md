---
name: plan-tagged-issues
description: Use when the user asks to plan, oPlan, or process GitHub issues tagged with the `agent-should-plan` label
---

# Plan Tagged Issues

Find open GitHub issues labeled `agent-should-plan` and dispatch a subagent to run `/oPlan` on each. Remove the label before dispatching so the issue isn't picked up twice.

## Steps

1. **List tagged issues:**
   ```bash
   gh issue list --label "agent-should-plan" --state open --json number,title,url --limit 50
   ```

2. **If none found:** Report "No issues tagged `agent-should-plan`." and stop.

3. **For each issue, in parallel (single message, multiple Agent calls):**

   a. Remove the label *first* (before dispatching) to prevent re-processing:
   ```bash
   gh issue edit <N> --remove-label "agent-should-plan"
   ```

   b. Dispatch a subagent (subagent_type: `claude`, **`isolation: "worktree"`**) with a prompt like:
   > Run the /oPlan skill on GitHub issue #<N> in <owner/repo> (title: "<title>"). Invoke the oPlan skill via the Skill tool with arg "<N>". Follow the skill's instructions exactly. Report back a brief summary (under 150 words) of what the plan covers and where it was posted.

4. **Report results:** One bullet per issue with the issue number, title, plan comment link, and branch created.

## Notes

- **`isolation: "worktree"` is required.** Each subagent runs `git checkout -b` — without per-agent worktrees, parallel runs race on branch checkout and clobber each other. The worktree is auto-cleaned if the agent makes no changes; otherwise the path/branch is returned in the agent's result.
- Remove the label *before* dispatching, not after — otherwise a second invocation of this skill (or a concurrent run) will re-plan the same issue.
- Dispatch issues in parallel when there's more than one; each /oPlan run is independent.
- If `gh issue edit` fails (e.g., label already removed), continue with dispatch anyway and note it in the report.
