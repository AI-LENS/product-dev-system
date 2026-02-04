#!/bin/bash
echo "Finding blocked tasks..."
echo ""
echo ""

echo "Blocked Tasks"
echo "=============="
echo ""

found=0

for epic_dir in devflow/epics/*/; do
  [ -d "$epic_dir" ] || continue
  epic_name=$(basename "$epic_dir")

  for task_file in "$epic_dir"/[0-9]*.md; do
    [ -f "$task_file" ] || continue

    # Check if task is open
    status=$(grep "^status:" "$task_file" | head -1 | sed 's/^status: *//')
    if [ "$status" != "open" ] && [ -n "$status" ]; then
      continue
    fi

    # Check for dependencies
    deps_line=$(grep "^depends_on:" "$task_file" | head -1)
    if [ -n "$deps_line" ]; then
      deps=$(echo "$deps_line" | sed 's/^depends_on: *//')
      deps=$(echo "$deps" | sed 's/^\[//' | sed 's/\]$//')
      deps=$(echo "$deps" | sed 's/,/ /g')
      deps=$(echo "$deps" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
      [ -z "$deps" ] && deps=""
    else
      deps=""
    fi

    if [ -n "$deps" ] && [ "$deps" != "depends_on:" ]; then
      # Check if any dependency is still open
      has_open_dep=false
      open_deps=""
      for dep in $deps; do
        dep=$(echo "$dep" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        [ -z "$dep" ] && continue
        dep_file="$epic_dir$dep.md"
        if [ -f "$dep_file" ]; then
          dep_status=$(grep "^status:" "$dep_file" | head -1 | sed 's/^status: *//')
          if [ "$dep_status" != "closed" ] && [ "$dep_status" != "completed" ]; then
            has_open_dep=true
            open_deps="$open_deps #$dep"
          fi
        else
          has_open_dep=true
          open_deps="$open_deps #$dep(missing)"
        fi
      done

      if $has_open_dep; then
        task_name=$(grep "^name:" "$task_file" | head -1 | sed 's/^name: *//')
        task_num=$(basename "$task_file" .md)

        echo "Blocked: #$task_num - $task_name"
        echo "   Epic: $epic_name"
        echo "   Waiting for:$open_deps"
        echo ""
        ((found++))
      fi
    fi
  done
done

if [ $found -eq 0 ]; then
  echo "No blocked tasks found!"
  echo ""
  echo "All tasks with dependencies are either completed or in progress."
else
  echo "Total blocked: $found tasks"
fi

exit 0
