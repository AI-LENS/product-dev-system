---
allowed-tools: Bash, Read, Write, LS
---

# Issue Close

Close an issue locally and on GitHub.

## Usage
```
/pm:issue-close <issue_number>
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/datetime.md` - For getting real current date/time
- `devflow/rules/github-operations.md` - For GitHub CLI operations

## Preflight Checklist

Before proceeding, complete these validation steps.
Do not bother the user with preflight checks progress. Just do them and move on.

### 1. Find Task File
- Search for `$ARGUMENTS.md` across all epic directories: `devflow/epics/*/$ARGUMENTS.md`
- If not found, tell user: "Task file not found for issue #$ARGUMENTS"

### 2. Check Task Status
- If already closed: "Issue #$ARGUMENTS is already closed"

### 3. Check Repository Protection
- Follow `devflow/rules/github-operations.md` to verify remote is not a template repo

## Instructions

### 1. Verify Acceptance Criteria

Read the task file and check acceptance criteria:
- List all acceptance criteria
- Ask user to confirm completion: "Are all acceptance criteria met? (yes/no)"
- If user says no, ask which criteria are incomplete
- Allow user to close anyway with explicit confirmation

### 2. Update Local Task File

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update the task file:
- Set `status: closed`
- Update `updated` field with current datetime

### 3. Close GitHub Issue

If the task has a `github` field:
```bash
# Build closing comment with completion summary
cat > /tmp/issue-close.md << 'CLOSE'
## Issue Completed

**Closed:** {datetime}

### Acceptance Criteria
- [x] Criterion 1
- [x] Criterion 2
- [x] Criterion 3

### Summary
{brief summary of what was implemented}
CLOSE

# Close with comment
gh issue close "$ARGUMENTS" --comment "$(cat /tmp/issue-close.md)"
```

### 4. Update Progress File

Update `devflow/epics/{epic_name}/updates/$ARGUMENTS/progress.md`:
- Set `completion: 100%`
- Update `last_sync` field
- Add closing entry to Work Log

### 5. Check Epic Progress

After closing the task:
- Read all tasks in the epic
- Calculate new epic completion percentage
- Update epic frontmatter `progress` field
- Check if all tasks are now closed
  - If yes, suggest: "All tasks complete! Close the epic with: /pm:epic-close {epic_name}"

### 6. Check for Unblocked Tasks

After closing this task:
- Find tasks that had this issue in their `depends_on` list
- If any are now unblocked (all dependencies met), report: "Tasks now unblocked: #{task_nums}"

### 7. Output

```
Issue #$ARGUMENTS Closed
================================

Task: {task_name}
Epic: {epic_name}
Closed: {datetime}

Epic Progress: {new_percent}% ({closed}/{total} tasks)

{If all tasks done}: All tasks complete! Close epic: /pm:epic-close {epic_name}
{If unblocked tasks}: Tasks now unblocked: {list}
{If remaining tasks}: Next available task: /pm:next
```

## Important Notes

- Always verify acceptance criteria before closing
- Update both local files and GitHub
- Recalculate epic progress after closing
- Report newly unblocked tasks
