---
allowed-tools: Bash, Read, LS
---

# Epic Show

Display epic details including metadata and task list with status.

## Usage
```
/pm:epic-show <feature_name>
```

## Preflight Checklist

Before proceeding, complete these validation steps.
Do not bother the user with preflight checks progress. Just do them and move on.

### 1. Verify Epic Exists
- Check if `.claude/epics/$ARGUMENTS/epic.md` exists
- If not found, list available epics from `.claude/epics/`
- Tell user: "Epic not found: $ARGUMENTS. Available epics: {list}"

## Instructions

### 1. Read Epic Metadata

Read `.claude/epics/$ARGUMENTS/epic.md`:
- Parse frontmatter: name, status, created, updated, github, progress, prd, spec, plan
- Read the body content for overview and technical approach

### 2. Read All Task Files

For each task file in `.claude/epics/$ARGUMENTS/`:
- Parse frontmatter: name, status, depends_on, parallel, github
- Categorize by status: open, in-progress, closed/completed
- Build dependency graph

### 3. Display Epic Details

```
Epic: $ARGUMENTS
================================

Metadata:
  Status: {status}
  Progress: {progress}
  GitHub: {github_url or 'Not synced'}
  Created: {created}
  Updated: {updated}

Artifacts:
  PRD: {prd_path or 'None'}
  Spec: {spec_path or 'None'}
  Plan: {plan_path or 'None'}

Tasks:
  [checkmark] #{task_num} - {task_name} [parallel]
  [open] #{task_num} - {task_name} (blocked by: #{dep1}, #{dep2})
  [open] #{task_num} - {task_name} [parallel]

Statistics:
  Total tasks: {count}
  Open: {open_count}
  In Progress: {in_progress_count}
  Closed: {closed_count}
  Completion: {percent}%

Actions:
  - Decompose into tasks: /pm:epic-decompose $ARGUMENTS (if no tasks)
  - Sync to GitHub: /pm:epic-sync $ARGUMENTS (if not synced)
  - Start work: /pm:epic-start $ARGUMENTS (if synced)
  - View status: /pm:epic-status $ARGUMENTS
```

## Important Notes

- This is a read-only command -- it does not modify any files
- Show blocked tasks with their blocking dependencies
- Indicate parallel-safe tasks clearly
