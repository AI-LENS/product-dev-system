---
allowed-tools: Bash, Read, LS
---

# Issue Show

Display issue details from local task file and GitHub.

## Usage
```
/pm:issue-show <issue_number>
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/github-operations.md` - For GitHub CLI operations

## Preflight Checklist

Before proceeding, complete these validation steps.
Do not bother the user with preflight checks progress. Just do them and move on.

### 1. Find Task File
- Search for `$ARGUMENTS.md` across all epic directories: `devflow/epics/*/$ARGUMENTS.md`
- If not found, tell user: "Task file not found for issue #$ARGUMENTS"
- If found in multiple epics, list them and ask which one

## Instructions

### 1. Read Local Task File

Read the task file and parse:
- Frontmatter: name, status, created, updated, github, depends_on, parallel, conflicts_with
- Body: Description, Acceptance Criteria, Technical Details, Dependencies, Effort Estimate, Definition of Done

### 2. Read GitHub Issue (if synced)

If the task has a `github` field with a URL:
```bash
issue_number=$ARGUMENTS
gh issue view "$issue_number" --json state,title,labels,body,assignees,comments,createdAt,updatedAt
```

### 3. Check for Progress Updates

Look for progress files:
```bash
epic_name=$(find devflow/epics -name "$ARGUMENTS.md" -exec dirname {} \; | head -1 | xargs basename)
ls devflow/epics/$epic_name/updates/$ARGUMENTS/ 2>/dev/null
```

### 4. Display Issue Details

```
Issue #$ARGUMENTS: {task_name}
================================

Local Status:
  Status: {status}
  Epic: {epic_name}
  Created: {created}
  Updated: {updated}
  Parallel: {yes/no}
  Dependencies: {depends_on list}
  Conflicts: {conflicts_with list}

GitHub Status:
  State: {open/closed}
  Labels: {label list}
  Assignees: {assignee list}
  Comments: {comment_count}
  URL: {github_url}

Description:
  {task description}

Acceptance Criteria:
  {checklist of criteria with status}

Effort:
  Size: {XS/S/M/L/XL}
  Hours: {estimate}

Progress:
  {stream updates if available, or "No progress updates yet"}

Actions:
  - Start work: /pm:issue-start $ARGUMENTS
  - Sync to GitHub: /pm:issue-sync $ARGUMENTS
  - Close: /pm:issue-close $ARGUMENTS
```

## Important Notes

- This is a read-only command
- Show both local and GitHub states, noting any discrepancies
- If GitHub state differs from local, warn the user
