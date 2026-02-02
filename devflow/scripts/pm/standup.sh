#!/bin/bash

echo "Daily Standup - $(date '+%Y-%m-%d')"
echo "================================"
echo ""

echo "Generating report..."
echo ""

echo "Today's Activity:"
echo "=================="
echo ""

# Find files modified today
recent_files=$(find .claude -name "*.md" -mtime -1 2>/dev/null)

if [ -n "$recent_files" ]; then
  prd_count=$(echo "$recent_files" | grep -c "/prds/" 2>/dev/null || echo 0)
  spec_count=$(echo "$recent_files" | grep -c "/specs/" 2>/dev/null || echo 0)
  epic_count=$(echo "$recent_files" | grep -c "/epic.md" 2>/dev/null || echo 0)
  task_count=$(echo "$recent_files" | grep -c "/[0-9]*.md" 2>/dev/null || echo 0)
  update_count=$(echo "$recent_files" | grep -c "/updates/" 2>/dev/null || echo 0)

  [ "$prd_count" -gt 0 ] 2>/dev/null && echo "  - Modified $prd_count PRD(s)"
  [ "$spec_count" -gt 0 ] 2>/dev/null && echo "  - Modified $spec_count spec(s)"
  [ "$epic_count" -gt 0 ] 2>/dev/null && echo "  - Updated $epic_count epic(s)"
  [ "$task_count" -gt 0 ] 2>/dev/null && echo "  - Worked on $task_count task(s)"
  [ "$update_count" -gt 0 ] 2>/dev/null && echo "  - Posted $update_count progress update(s)"
else
  echo "  No activity recorded today"
fi

echo ""
echo "Currently In Progress:"
in_progress_count=0
if [ -d ".claude/epics" ]; then
  for epic_dir in .claude/epics/*/; do
    [ -d "$epic_dir" ] || continue
    epic_name=$(basename "$epic_dir")

    for task_file in "$epic_dir"/[0-9]*.md; do
      [ -f "$task_file" ] || continue
      status=$(grep "^status:" "$task_file" | head -1 | sed 's/^status: *//')
      if [ "$status" = "in-progress" ]; then
        task_name=$(grep "^name:" "$task_file" | head -1 | sed 's/^name: *//')
        task_num=$(basename "$task_file" .md)
        completion=""
        if [ -f "$epic_dir/updates/$task_num/progress.md" ]; then
          completion=$(grep "^completion:" "$epic_dir/updates/$task_num/progress.md" | head -1 | sed 's/^completion: *//')
        fi
        echo "  - Issue #$task_num ($epic_name) - ${completion:-0%} complete"
        ((in_progress_count++))
      fi
    done
  done
fi
[ $in_progress_count -eq 0 ] && echo "  (none)"

echo ""
echo "Next Available Tasks:"
count=0
for epic_dir in .claude/epics/*/; do
  [ -d "$epic_dir" ] || continue
  for task_file in "$epic_dir"/[0-9]*.md; do
    [ -f "$task_file" ] || continue
    status=$(grep "^status:" "$task_file" | head -1 | sed 's/^status: *//')
    if [ "$status" != "open" ] && [ -n "$status" ]; then
      continue
    fi

    deps_line=$(grep "^depends_on:" "$task_file" | head -1)
    if [ -n "$deps_line" ]; then
      deps=$(echo "$deps_line" | sed 's/^depends_on: *//')
      deps=$(echo "$deps" | sed 's/^\[//' | sed 's/\]$//')
      deps=$(echo "$deps" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
      [ -z "$deps" ] && deps=""
    else
      deps=""
    fi

    if [ -z "$deps" ] || [ "$deps" = "depends_on:" ]; then
      task_name=$(grep "^name:" "$task_file" | head -1 | sed 's/^name: *//')
      task_num=$(basename "$task_file" .md)
      echo "  - #$task_num - $task_name"
      ((count++))
      [ $count -ge 3 ] && break 2
    fi
  done
done
[ $count -eq 0 ] && echo "  (none available)"

echo ""
echo "Quick Stats:"
total_tasks=$(find .claude/epics -name "[0-9]*.md" 2>/dev/null | wc -l | tr -d ' ')
open_tasks=$(find .claude/epics -name "[0-9]*.md" -exec grep -l "^status: *open" {} \; 2>/dev/null | wc -l | tr -d ' ')
closed_tasks=$(find .claude/epics -name "[0-9]*.md" -exec grep -l "^status: *closed" {} \; 2>/dev/null | wc -l | tr -d ' ')
echo "  Tasks: $open_tasks open, $in_progress_count in-progress, $closed_tasks closed, $total_tasks total"

# Recent git activity
echo ""
echo "Recent Commits:"
git log --oneline -5 2>/dev/null | while read line; do
  echo "  $line"
done

exit 0
