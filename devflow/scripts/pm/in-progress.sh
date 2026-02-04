#!/bin/bash
echo "Finding in-progress work..."
echo ""
echo ""

echo "In Progress Work"
echo "================="
echo ""

found=0

# Check for in-progress tasks
if [ -d "devflow/epics" ]; then
  for epic_dir in devflow/epics/*/; do
    [ -d "$epic_dir" ] || continue
    epic_name=$(basename "$epic_dir")

    for task_file in "$epic_dir"/[0-9]*.md; do
      [ -f "$task_file" ] || continue

      status=$(grep "^status:" "$task_file" | head -1 | sed 's/^status: *//')
      if [ "$status" = "in-progress" ]; then
        task_name=$(grep "^name:" "$task_file" | head -1 | sed 's/^name: *//')
        task_num=$(basename "$task_file" .md)

        echo "Task #$task_num - $task_name"
        echo "   Epic: $epic_name"

        # Check for progress updates
        if [ -f "$epic_dir/updates/$task_num/progress.md" ]; then
          completion=$(grep "^completion:" "$epic_dir/updates/$task_num/progress.md" | head -1 | sed 's/^completion: *//')
          last_sync=$(grep "^last_sync:" "$epic_dir/updates/$task_num/progress.md" | head -1 | sed 's/^last_sync: *//')
          [ -n "$completion" ] && echo "   Progress: $completion"
          [ -n "$last_sync" ] && echo "   Last update: $last_sync"
        fi

        # Check for branch
        branch=$(grep "^branch:" "$epic_dir/updates/$task_num/progress.md" 2>/dev/null | head -1 | sed 's/^branch: *//')
        [ -n "$branch" ] && echo "   Branch: $branch"

        echo ""
        ((found++))
      fi
    done
  done
fi

# Show active epics
echo "Active Epics:"
active_epics=0
for epic_dir in devflow/epics/*/; do
  [ -d "$epic_dir" ] || continue
  [ -f "$epic_dir/epic.md" ] || continue

  status=$(grep "^status:" "$epic_dir/epic.md" | head -1 | sed 's/^status: *//')
  if [ "$status" = "in-progress" ] || [ "$status" = "active" ]; then
    epic_name=$(grep "^name:" "$epic_dir/epic.md" | head -1 | sed 's/^name: *//')
    progress=$(grep "^progress:" "$epic_dir/epic.md" | head -1 | sed 's/^progress: *//')
    [ -z "$epic_name" ] && epic_name=$(basename "$epic_dir")
    [ -z "$progress" ] && progress="0%"

    echo "   - $epic_name - $progress complete"
    ((active_epics++))
  fi
done
[ $active_epics -eq 0 ] && echo "   (none)"

echo ""
if [ $found -eq 0 ]; then
  echo "No active work items found."
  echo ""
  echo "Start work with: /pm:next"
else
  echo "Total active items: $found"
fi

exit 0
