#!/bin/bash
echo "Finding next tasks..."
echo ""
echo ""

echo "Next Available Tasks"
echo "====================="
echo ""

# Find tasks that are open and have no dependencies or whose dependencies are closed
found=0

for epic_dir in .claude/epics/*/; do
  [ -d "$epic_dir" ] || continue
  epic_name=$(basename "$epic_dir")

  for task_file in "$epic_dir"/[0-9]*.md; do
    [ -f "$task_file" ] || continue

    # Check if task is open
    status=$(grep "^status:" "$task_file" | head -1 | sed 's/^status: *//')
    if [ "$status" != "open" ] && [ -n "$status" ]; then
      continue
    fi

    # Check dependencies
    deps_line=$(grep "^depends_on:" "$task_file" | head -1)
    if [ -n "$deps_line" ]; then
      deps=$(echo "$deps_line" | sed 's/^depends_on: *//')
      deps=$(echo "$deps" | sed 's/^\[//' | sed 's/\]$//')
      deps=$(echo "$deps" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
      [ -z "$deps" ] && deps=""
    else
      deps=""
    fi

    # Check if all dependencies are satisfied
    all_deps_met=true
    if [ -n "$deps" ] && [ "$deps" != "depends_on:" ]; then
      for dep in $(echo "$deps" | sed 's/,/ /g'); do
        dep=$(echo "$dep" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        [ -z "$dep" ] && continue
        dep_file="$epic_dir$dep.md"
        if [ -f "$dep_file" ]; then
          dep_status=$(grep "^status:" "$dep_file" | head -1 | sed 's/^status: *//')
          if [ "$dep_status" != "closed" ] && [ "$dep_status" != "completed" ]; then
            all_deps_met=false
            break
          fi
        else
          all_deps_met=false
          break
        fi
      done
    fi

    if $all_deps_met; then
      task_name=$(grep "^name:" "$task_file" | head -1 | sed 's/^name: *//')
      task_num=$(basename "$task_file" .md)
      parallel=$(grep "^parallel:" "$task_file" | head -1 | sed 's/^parallel: *//')
      size=$(grep "^- Size:" "$task_file" | head -1 | sed 's/^- Size: *//' || echo "")

      echo "Ready: #$task_num - $task_name"
      echo "   Epic: $epic_name"
      [ "$parallel" = "true" ] && echo "   Can run in parallel"
      [ -n "$size" ] && echo "   Size: $size"
      echo ""
      ((found++))
    fi
  done
done

if [ $found -eq 0 ]; then
  echo "No available tasks found."
  echo ""
  echo "Suggestions:"
  echo "  - Check blocked tasks: /pm:blocked"
  echo "  - View all epics: /pm:epic-list"
  echo "  - Create a new PRD: /pm:prd-new <name>"
fi

echo ""
echo "Summary: $found tasks ready to start"

exit 0
