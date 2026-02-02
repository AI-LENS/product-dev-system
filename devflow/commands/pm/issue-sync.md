---
allowed-tools: Bash, Read, Write, LS
---

# Issue Sync

Sync issue progress to GitHub as a comment.

## Usage
```
/pm:issue-sync <issue_number>
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/datetime.md` - For getting real current date/time
- `devflow/rules/github-operations.md` - For GitHub CLI operations

## Preflight Checklist

Before proceeding, complete these validation steps.
Do not bother the user with preflight checks progress. Just do them and move on.

### 1. Find Task File
- Search for `$ARGUMENTS.md` across all epic directories: `.claude/epics/*/$ARGUMENTS.md`
- If not found, tell user: "Task file not found for issue #$ARGUMENTS"

### 2. Check Repository Protection
- Follow `devflow/rules/github-operations.md` to verify remote is not a template repo

### 3. Verify GitHub Sync
- Check that the task file has a `github` field
- If not synced, tell user: "Issue not synced to GitHub. Run /pm:epic-sync first"

## Instructions

### 1. Gather Progress Information

Read local state:
- Task file: `.claude/epics/{epic_name}/$ARGUMENTS.md`
- Progress file: `.claude/epics/{epic_name}/updates/$ARGUMENTS/progress.md`
- Stream files: `.claude/epics/{epic_name}/updates/$ARGUMENTS/stream-*.md`

Gather git information:
```bash
# Get recent commits for this issue
git log --oneline --grep="Issue #$ARGUMENTS" -10

# Get changed files in the issue branch
git diff --stat main...issue/$ARGUMENTS 2>/dev/null || git diff --stat HEAD~5..HEAD
```

### 2. Build Progress Comment

Create a progress comment for GitHub:

```markdown
## Progress Update - {datetime}

**Status:** {in-progress/blocked/review}
**Completion:** {percent}%
**Branch:** issue/$ARGUMENTS

### Recent Changes
{list of recent commits for this issue}

### Files Changed
{summary of files modified}

### Acceptance Criteria Progress
- [x] Criterion 1 - Done
- [ ] Criterion 2 - In progress
- [ ] Criterion 3 - Not started

### Blockers
{any blockers, or "None"}

### Next Steps
{what remains to be done}
```

### 3. Post Comment to GitHub

```bash
# Save comment to temp file
cat > /tmp/issue-progress.md << 'COMMENT'
{progress comment content}
COMMENT

# Post comment
gh issue comment "$ARGUMENTS" --body-file /tmp/issue-progress.md
```

### 4. Update Local Progress

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update progress file:
- Update `last_sync` field
- Update `completion` percentage
- Add entry to Work Log

### 5. Output

```
Issue #$ARGUMENTS Synced
  Completion: {percent}%
  GitHub comment posted
  Last sync: {datetime}

Next: Continue work or close with /pm:issue-close $ARGUMENTS
```

## Important Notes

- Always check repository protection before GitHub operations
- Post factual progress -- do not speculate on completion
- Include both successes and blockers
- Keep comments concise but informative
