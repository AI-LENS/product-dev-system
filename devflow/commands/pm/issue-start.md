---
allowed-tools: Bash, Read, Write, LS
---

# Issue Start

Start work on an individual issue. Creates a branch and sets up worktree if needed.

## Usage
```
/pm:issue-start <issue_number>
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/datetime.md` - For getting real current date/time
- `devflow/rules/branch-operations.md` - For git branch operations
- `devflow/rules/agent-coordination.md` - For parallel work coordination

## Preflight Checklist

Before proceeding, complete these validation steps.
Do not bother the user with preflight checks progress. Just do them and move on.

### 1. Find Task File
- Search for `$ARGUMENTS.md` across all epic directories: `devflow/epics/*/$ARGUMENTS.md`
- If not found, tell user: "Task file not found for issue #$ARGUMENTS"
- Stop execution if not found

### 2. Check Task Status
- Read task frontmatter
- If status is "closed" or "completed": "Issue #$ARGUMENTS is already closed"
- If status is "in-progress": "Issue #$ARGUMENTS is already in progress. Continue anyway? (yes/no)"

### 3. Check Dependencies
- Read `depends_on` field from task frontmatter
- For each dependency, check if that task is closed/completed
- If unmet dependencies exist, warn: "Issue #$ARGUMENTS has unmet dependencies: {list}. Start anyway? (yes/no)"

### 4. Check for Uncommitted Changes
```bash
if [ -n "$(git status --porcelain)" ]; then
  echo "You have uncommitted changes. Please commit or stash them first."
fi
```

## Instructions

### 1. Determine Branch Strategy

Read the task's epic to find the epic branch:
```bash
epic_name=$(find devflow/epics -name "$ARGUMENTS.md" -exec dirname {} \; | head -1 | xargs basename)
```

Check if an epic branch exists:
```bash
if git branch -a | grep -q "epic/$epic_name"; then
  # Work in epic branch
  base_branch="epic/$epic_name"
else
  # Work in issue branch off main
  base_branch="main"
fi
```

### 2. Create Issue Branch

```bash
git checkout "$base_branch"
git pull origin "$base_branch" 2>/dev/null || true
git checkout -b "issue/$ARGUMENTS"
git push -u origin "issue/$ARGUMENTS"
echo "Created branch: issue/$ARGUMENTS from $base_branch"
```

### 3. Update Task Status

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update the task file:
- Set `status: in-progress`
- Update `updated` field with current datetime

### 4. Update GitHub Issue (if synced)

If the task has a `github` field:
```bash
gh issue edit "$ARGUMENTS" --add-label "in-progress" --add-assignee @me
```

### 5. Create Progress Tracking

Create progress directory and initial progress file:
```bash
mkdir -p devflow/epics/$epic_name/updates/$ARGUMENTS
```

Create `devflow/epics/$epic_name/updates/$ARGUMENTS/progress.md`:
```markdown
---
issue: $ARGUMENTS
started: [Current ISO date/time]
last_sync: [Current ISO date/time]
completion: 0%
branch: issue/$ARGUMENTS
---

# Progress: Issue #$ARGUMENTS

## Status
- Started: [datetime]
- Branch: issue/$ARGUMENTS
- Completion: 0%

## Work Log
- [datetime]: Started work on issue
```

### 6. Output

```
Issue #$ARGUMENTS Started
================================

Task: {task_name}
Epic: {epic_name}
Branch: issue/$ARGUMENTS
Base: {base_branch}

Dependencies:
  {dependency status}

Next steps:
  1. Read the task requirements in devflow/epics/{epic_name}/$ARGUMENTS.md
  2. Implement the changes
  3. Commit frequently with: "Issue #$ARGUMENTS: {description}"
  4. Sync progress: /pm:issue-sync $ARGUMENTS
  5. When done: /pm:issue-close $ARGUMENTS
```

## Important Notes

- Follow `devflow/rules/branch-operations.md` for all git operations
- Follow `devflow/rules/agent-coordination.md` if working in parallel
- Commit messages must reference the issue number
- Update progress tracking regularly
