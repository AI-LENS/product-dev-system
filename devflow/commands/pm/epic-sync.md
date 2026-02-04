---
allowed-tools: Bash, Read, Write, LS, Task
---

# Epic Sync

Push epic and tasks to GitHub as issues.

## Usage
```
/pm:epic-sync <feature_name>
```

## Quick Check

```bash
# Verify epic exists
test -f devflow/epics/$ARGUMENTS/epic.md || echo "Epic not found. Run: /pm:epic-decompose $ARGUMENTS"

# Count task files
ls devflow/epics/$ARGUMENTS/*.md 2>/dev/null | grep -v epic.md | wc -l
```

If no tasks found: "No tasks to sync. Run: /pm:epic-decompose $ARGUMENTS"

## Instructions

### 0. Check Remote Repository

Follow `devflow/rules/github-operations.md` to ensure we're not syncing to a template repo:

```bash
# Check if remote origin is a protected template repository
remote_url=$(git remote get-url origin 2>/dev/null || echo "")
if [[ "$remote_url" == *"AI-LENS/Product-dev-system"* ]] || [[ "$remote_url" == *"AI-LENS/Product-dev-system.git"* ]] || [[ "$remote_url" == *"devflow-template"* ]]; then
  echo "ERROR: You're trying to sync with a template repository!"
  echo ""
  echo "To fix this:"
  echo "1. Create a new repository on GitHub"
  echo "2. Update your remote origin:"
  echo "   git remote set-url origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
  echo ""
  echo "Current remote: $remote_url"
  exit 1
fi
```

### 1. Create Epic Issue

#### First, detect the GitHub repository:
```bash
remote_url=$(git remote get-url origin 2>/dev/null || echo "")
REPO=$(echo "$remote_url" | sed 's|.*github.com[:/]||' | sed 's|\.git$||')
[ -z "$REPO" ] && REPO="user/repo"
echo "Creating issues in repository: $REPO"
```

Strip frontmatter and prepare GitHub issue body:
```bash
# Extract content without frontmatter
sed '1,/^---$/d; 1,/^---$/d' devflow/epics/$ARGUMENTS/epic.md > /tmp/epic-body-raw.md

# Remove "## Tasks Created" section and replace with Stats
awk '
  /^## Tasks Created/ {
    in_tasks=1
    next
  }
  /^## / && in_tasks {
    in_tasks=0
    if (total_tasks) {
      print "## Stats"
      print ""
      print "Total tasks: " total_tasks
      print "Parallel tasks: " parallel_tasks " (can be worked on simultaneously)"
      print "Sequential tasks: " sequential_tasks " (have dependencies)"
      if (total_effort) print "Estimated total effort: " total_effort " hours"
      print ""
    }
  }
  /^Total tasks:/ && in_tasks { total_tasks = $3; next }
  /^Parallel tasks:/ && in_tasks { parallel_tasks = $3; next }
  /^Sequential tasks:/ && in_tasks { sequential_tasks = $3; next }
  /^Estimated total effort:/ && in_tasks {
    gsub(/^Estimated total effort: /, "")
    total_effort = $0
    next
  }
  !in_tasks { print }
  END {
    if (in_tasks && total_tasks) {
      print "## Stats"
      print ""
      print "Total tasks: " total_tasks
      print "Parallel tasks: " parallel_tasks
      print "Sequential tasks: " sequential_tasks
      if (total_effort) print "Estimated total effort: " total_effort
    }
  }
' /tmp/epic-body-raw.md > /tmp/epic-body.md

# Determine epic type from content
if grep -qi "bug\|fix\|issue\|problem\|error" /tmp/epic-body.md; then
  epic_type="bug"
else
  epic_type="feature"
fi

# Create epic issue with labels
epic_number=$(gh issue create \
  --repo "$REPO" \
  --title "Epic: $ARGUMENTS" \
  --body-file /tmp/epic-body.md \
  --label "epic,epic:$ARGUMENTS,$epic_type" \
  --json number -q .number)
```

### 2. Create Task Sub-Issues

Check if gh-sub-issue is available:
```bash
if gh extension list | grep -q "yahsan2/gh-sub-issue"; then
  use_subissues=true
else
  use_subissues=false
  echo "gh-sub-issue not installed. Using fallback mode."
fi
```

### For Small Batches (< 5 tasks): Sequential Creation

```bash
task_count=$(ls devflow/epics/$ARGUMENTS/[0-9][0-9][0-9].md 2>/dev/null | wc -l)

if [ "$task_count" -lt 5 ]; then
  for task_file in devflow/epics/$ARGUMENTS/[0-9][0-9][0-9].md; do
    [ -f "$task_file" ] || continue
    task_name=$(grep '^name:' "$task_file" | sed 's/^name: *//')
    sed '1,/^---$/d; 1,/^---$/d' "$task_file" > /tmp/task-body.md

    if [ "$use_subissues" = true ]; then
      task_number=$(gh sub-issue create \
        --parent "$epic_number" \
        --title "$task_name" \
        --body-file /tmp/task-body.md \
        --label "task,epic:$ARGUMENTS" \
        --json number -q .number)
    else
      task_number=$(gh issue create \
        --repo "$REPO" \
        --title "$task_name" \
        --body-file /tmp/task-body.md \
        --label "task,epic:$ARGUMENTS" \
        --json number -q .number)
    fi
    echo "$task_file:$task_number" >> /tmp/task-mapping.txt
  done
fi
```

### For Larger Batches: Parallel Creation

Use Task tool for parallel creation:
```yaml
Task:
  description: "Create GitHub sub-issues batch {X}"
  subagent_type: "general-purpose"
  prompt: |
    Create GitHub sub-issues for tasks in epic $ARGUMENTS
    Parent epic issue: #$epic_number

    Tasks to process:
    - {list of 3-4 task files}

    For each task file:
    1. Extract task name from frontmatter
    2. Strip frontmatter using: sed '1,/^---$/d; 1,/^---$/d'
    3. Create sub-issue with: --label "task,epic:$ARGUMENTS"
    4. Record: task_file:issue_number

    Return mapping of files to issue numbers.
```

### 3. Rename Task Files and Update References

Build mapping of old numbers to new issue IDs:
```bash
> /tmp/id-mapping.txt
while IFS=: read -r task_file task_number; do
  old_num=$(basename "$task_file" .md)
  echo "$old_num:$task_number" >> /tmp/id-mapping.txt
done < /tmp/task-mapping.txt
```

Rename files and update all references:
```bash
while IFS=: read -r task_file task_number; do
  new_name="$(dirname "$task_file")/${task_number}.md"
  content=$(cat "$task_file")

  while IFS=: read -r old_num new_num; do
    content=$(echo "$content" | sed "s/\b$old_num\b/$new_num/g")
  done < /tmp/id-mapping.txt

  echo "$content" > "$new_name"
  [ "$task_file" != "$new_name" ] && rm "$task_file"

  repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
  github_url="https://github.com/$repo/issues/$task_number"
  current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  sed -i.bak "/^github:/c\github: $github_url" "$new_name"
  sed -i.bak "/^updated:/c\updated: $current_date" "$new_name"
  rm "${new_name}.bak"
done < /tmp/task-mapping.txt
```

### 4. Update Epic with Task List (Fallback Only)

If NOT using gh-sub-issue, add task list to epic issue body.

### 5. Update Epic File

Update frontmatter with GitHub URL and timestamp:
```bash
repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
epic_url="https://github.com/$repo/issues/$epic_number"
current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

sed -i.bak "/^github:/c\github: $epic_url" devflow/epics/$ARGUMENTS/epic.md
sed -i.bak "/^updated:/c\updated: $current_date" devflow/epics/$ARGUMENTS/epic.md
rm devflow/epics/$ARGUMENTS/epic.md.bak
```

Update Tasks Created section with real issue numbers.

### 6. Create Mapping File

Create `devflow/epics/$ARGUMENTS/github-mapping.md` with epic and task issue mappings.

### 7. Output

```
Synced to GitHub
  - Epic: #{epic_number} - {epic_title}
  - Tasks: {count} sub-issues created
  - Labels applied: epic, task, epic:{name}
  - Files renamed: 001.md -> {issue_id}.md
  - References updated: depends_on/conflicts_with now use issue IDs

Next steps:
  - Start parallel execution: /pm:epic-start $ARGUMENTS
  - Or work on single issue: /pm:issue-start {issue_number}
  - View epic: https://github.com/{owner}/{repo}/issues/{epic_number}
```

## Error Handling

Follow `devflow/rules/github-operations.md` for GitHub CLI errors.

If any issue creation fails:
- Report what succeeded
- Note what failed
- Don't attempt rollback (partial sync is fine)

## Important Notes

- Trust GitHub CLI authentication
- Don't pre-check for duplicates
- Update frontmatter only after successful creation
- Keep operations simple and atomic
