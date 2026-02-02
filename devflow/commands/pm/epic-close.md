---
allowed-tools: Bash, Read, Write, LS
---

# Epic Close

Close an epic by marking it as completed and closing the associated GitHub issue.

## Usage
```
/pm:epic-close <feature_name>
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/datetime.md` - For getting real current date/time
- `devflow/rules/github-operations.md` - For GitHub CLI operations

## Preflight Checklist

Before proceeding, complete these validation steps.
Do not bother the user with preflight checks progress. Just do them and move on.

### 1. Verify Epic Exists
- Check if `.claude/epics/$ARGUMENTS/epic.md` exists
- If not found, tell user: "Epic not found: $ARGUMENTS"
- Stop execution if epic does not exist

### 2. Check Task Completion
- Read all task files in `.claude/epics/$ARGUMENTS/`
- Count open vs closed tasks
- If open tasks remain, warn user: "Warning: {count} tasks still open. Close epic anyway? (yes/no)"
- Only proceed with explicit confirmation if tasks are open

### 3. Check Repository Protection
- Follow `devflow/rules/github-operations.md` to verify remote is not a template repo

## Instructions

### 1. Read Epic State

Read `.claude/epics/$ARGUMENTS/epic.md`:
- Parse frontmatter for github URL, status, progress
- Get issue number from github field

### 2. Update Local Epic

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update epic frontmatter:
- Set `status: completed`
- Set `progress: 100%`
- Update `updated` field with current datetime

### 3. Close GitHub Issue

If epic has a GitHub issue:
```bash
# Extract issue number from github URL
issue_number=$(echo "{github_url}" | grep -o '/[0-9]*$' | tr -d '/')

# Close the epic issue
gh issue close "$issue_number" --comment "Epic completed. All tasks resolved."
```

### 4. Close Open Task Issues

For each task with a GitHub issue that is still open:
```bash
gh issue close "$task_issue_number" --comment "Closed as part of epic completion: $ARGUMENTS"
```

Update local task files:
- Set `status: closed`
- Update `updated` field

### 5. Generate Completion Summary

```
Epic Closed: $ARGUMENTS
================================

Status: Completed
Closed: {datetime}

Task Summary:
  Total tasks: {count}
  Completed: {completed_count}
  Closed without completion: {remaining_count}

GitHub:
  Epic issue: #{epic_number} - Closed
  Task issues closed: {count}

Artifacts:
  PRD: .claude/prds/$ARGUMENTS.md
  Spec: .claude/specs/$ARGUMENTS.md
  Plan: .claude/specs/$ARGUMENTS-plan.md
  Epic: .claude/epics/$ARGUMENTS/epic.md
```

## Important Notes

- Always confirm before closing if tasks are still open
- Update both local files and GitHub issues
- Preserve all artifacts for future reference
- Follow `devflow/rules/github-operations.md` for all GitHub operations
