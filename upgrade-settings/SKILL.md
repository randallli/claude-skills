Upgrade permissions from `.claude/settings.local.json` to `.claude/settings.json` (project-level settings).

## Purpose

Promotes local-only permissions to team-wide availability by merging them into the project settings file. This is useful when you've tested permissions locally and want to make them available to all team members.

## Workflow

### Phase 1: Validation

1. **Check for local settings**: Verify `.claude/settings.local.json` exists
2. **Check for project settings**: Verify `.claude/settings.json` exists
3. **Parse both files**: Ensure both are valid JSON

If local settings doesn't exist, report that there's nothing to upgrade and exit.

### Phase 2: Merge Permissions

1. **Extract permissions** from both files:
   - `allow` arrays
   - `deny` arrays
   - `ask` arrays

2. **Merge logic**:
   - Combine local permissions with project permissions
   - Remove duplicates (keep unique entries only)
   - Maintain alphabetical order within each category for readability
   - Preserve any other settings in project file (non-permissions keys)

3. **Identify new additions**:
   - Track which permissions are being added from local to project
   - Report these to the user

### Phase 3: Write and Cleanup

1. **Update project settings**:
   - Write merged permissions to `.claude/settings.json`
   - Maintain JSON formatting (2-space indent)
   - Ensure valid JSON structure

2. **Remove local settings**:
   - Delete `.claude/settings.local.json` file
   - Confirm deletion

3. **Report changes**:
   - List permissions added to each category (allow/deny/ask)
   - Show total counts before and after
   - Confirm successful upgrade

## Output Format

```
## Settings Upgrade Summary

### Permissions Added to Project Settings

**Allow List**:
- Bash(new-command:*)
- Bash(another-command:*)

**Deny List**:
- (none)

**Ask List**:
- (none)

### Statistics
- **Before**: 67 allow, 0 deny, 1 ask
- **After**: 69 allow, 0 deny, 1 ask
- **Added**: 2 new permissions

### Files Modified
- Updated: `.claude/settings.json`
- Removed: `.claude/settings.local.json`

### Next Steps
- Commit the updated settings.json to share with your team
- Local-only testing complete - permissions now team-wide
```

## Edge Cases

- **No local settings**: Report nothing to upgrade, exit gracefully
- **Duplicate permissions**: Remove duplicates, report as already present
- **Empty local settings**: Report nothing to add
- **Invalid JSON**: Report error and don't modify files

## Best Practices

- Review permissions before upgrading to ensure they're appropriate for the whole team
- Test permissions locally first before promoting to project level
- Commit settings.json changes with a clear message explaining what was added
- Use this after validating that local permissions work as expected
