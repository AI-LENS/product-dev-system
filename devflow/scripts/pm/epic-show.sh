#!/bin/bash

epic_name="$1"

if [ -z "$epic_name" ]; then
  echo "Please provide an epic name"
  echo "Usage: /pm:epic-show <epic-name>"
  exit 1
fi

echo "Loading epic..."
echo ""
echo ""

epic_dir=".claude/epics/$epic_name"
epic_file="$epic_dir/epic.md"

if [ ! -f "$epic_file" ]; then
  echo "Epic not found: $epic_name"
  echo ""
  echo "Available epics:"
  for dir in .claude/epics/*/; do
    [ -d "$dir" ] && echo "  - $(basename "$dir")"
  done
  exit 1
fi

# Display epic details
echo "Epic: $epic_name"
echo "================================"
echo ""

# Extract metadata
status=$(grep "^status:" "$epic_file" | head -1 | sed 's/^status: *//')
progress=$(grep "^progress:" "$epic_file" | head -1 | sed 's/^progress: *//')
github=$(grep "^github:" "$epic_file" | head -1 | sed 's/^github: *//')
created=$(grep "^created:" "$epic_file" | head -1 | sed 's/^created: *//')
updated=$(grep "^updated:" "$epic_file" | head -1 | sed 's/^updated: *//')
prd=$(grep "^prd:" "$epic_file" | head -1 | sed 's/^prd: *//')
spec=$(grep "^spec:" "$epic_file" | head -1 | sed 's/^spec: *//')
plan=$(grep "^plan:" "$epic_file" | head -1 | sed 's/^plan: *//')

echo "Metadata:"
echo "  Status: ${status:-planning}"
echo "  Progress: ${progress:-0%}"
[ -n "$github" ] && [ "$github" != " " ] && echo "  GitHub: $github"
echo "  Created: ${created:-unknown}"
[ -n "$updated" ] && echo "  Updated: $updated"
echo ""

# Show related artifacts
echo "Artifacts:"
[ -n "$prd" ] && echo "  PRD: $prd" || echo "  PRD: (none)"
[ -n "$spec" ] && echo "  Spec: $spec" || echo "  Spec: (none)"
[ -n "$plan" ] && echo "  Plan: $plan" || echo "  Plan: (none)"
echo ""

# Show tasks
echo "Tasks:"
task_count=0
open_count=0
in_progress_count=0
closed_count=0

for task_file in "$epic_dir"/[0-9]*.md; do
  [ -f "$task_file" ] || continue

  task_num=$(basename "$task_file" .md)
  task_name=$(grep "^name:" "$task_file" | head -1 | sed 's/^name: *//')
  task_status=$(grep "^status:" "$task_file" | head -1 | sed 's/^status: *//')
  parallel=$(grep "^parallel:" "$task_file" | head -1 | sed 's/^parallel: *//')
  deps=$(grep "^depends_on:" "$task_file" | head -1 | sed 's/^depends_on: *//')

  if [ "$task_status" = "closed" ] || [ "$task_status" = "completed" ]; then
    echo "  [x] #$task_num - $task_name"
    ((closed_count++))
  elif [ "$task_status" = "in-progress" ]; then
    echo "  [~] #$task_num - $task_name (in progress)"
    ((in_progress_count++))
  else
    extra=""
    [ "$parallel" = "true" ] && extra=" [parallel]"
    [ -n "$deps" ] && [ "$deps" != "[]" ] && extra="$extra (deps: $deps)"
    echo "  [ ] #$task_num - $task_name$extra"
    ((open_count++))
  fi

  ((task_count++))
done

if [ $task_count -eq 0 ]; then
  echo "  No tasks created yet"
  echo "  Run: /pm:epic-decompose $epic_name"
fi

echo ""
echo "Statistics:"
echo "  Total tasks: $task_count"
echo "  Open: $open_count"
echo "  In Progress: $in_progress_count"
echo "  Closed: $closed_count"
[ $task_count -gt 0 ] && echo "  Completion: $((closed_count * 100 / task_count))%"

# Next actions
echo ""
echo "Actions:"
[ $task_count -eq 0 ] && echo "  - Decompose into tasks: /pm:epic-decompose $epic_name"
[ -z "$github" ] && [ $task_count -gt 0 ] && echo "  - Sync to GitHub: /pm:epic-sync $epic_name"
[ -n "$github" ] && [ "$status" != "completed" ] && echo "  - Start work: /pm:epic-start $epic_name"
[ "$status" != "completed" ] && echo "  - View status: /pm:epic-status $epic_name"

exit 0
