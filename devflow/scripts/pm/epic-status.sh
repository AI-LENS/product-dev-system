#!/bin/bash

echo "Getting status..."
echo ""
echo ""

epic_name="$1"

if [ -z "$epic_name" ]; then
  echo "Please specify an epic name"
  echo "Usage: /pm:epic-status <epic-name>"
  echo ""
  echo "Available epics:"
  for dir in devflow/epics/*/; do
    [ -d "$dir" ] && echo "  - $(basename "$dir")"
  done
  exit 1
fi

epic_dir="devflow/epics/$epic_name"
epic_file="$epic_dir/epic.md"

if [ ! -f "$epic_file" ]; then
  echo "Epic not found: $epic_name"
  echo ""
  echo "Available epics:"
  for dir in devflow/epics/*/; do
    [ -d "$dir" ] && echo "  - $(basename "$dir")"
  done
  exit 1
fi

echo "Epic Status: $epic_name"
echo "================================"
echo ""

# Extract metadata
status=$(grep "^status:" "$epic_file" | head -1 | sed 's/^status: *//')
progress=$(grep "^progress:" "$epic_file" | head -1 | sed 's/^progress: *//')
github=$(grep "^github:" "$epic_file" | head -1 | sed 's/^github: *//')

# Count tasks by status
total=0
open=0
in_progress=0
closed=0
blocked=0

for task_file in "$epic_dir"/[0-9]*.md; do
  [ -f "$task_file" ] || continue
  ((total++))

  task_status=$(grep "^status:" "$task_file" | head -1 | sed 's/^status: *//')

  if [ "$task_status" = "closed" ] || [ "$task_status" = "completed" ]; then
    ((closed++))
  elif [ "$task_status" = "in-progress" ]; then
    ((in_progress++))
  else
    # Check if blocked by dependencies
    deps=$(grep "^depends_on:" "$task_file" | head -1 | sed 's/^depends_on: *\[//' | sed 's/\]//')
    deps=$(echo "$deps" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

    if [ -n "$deps" ]; then
      has_open_dep=false
      for dep in $(echo "$deps" | sed 's/,/ /g'); do
        dep=$(echo "$dep" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        [ -z "$dep" ] && continue
        dep_file="$epic_dir/$dep.md"
        if [ -f "$dep_file" ]; then
          dep_status=$(grep "^status:" "$dep_file" | head -1 | sed 's/^status: *//')
          if [ "$dep_status" != "closed" ] && [ "$dep_status" != "completed" ]; then
            has_open_dep=true
          fi
        fi
      done
      if $has_open_dep; then
        ((blocked++))
      else
        ((open++))
      fi
    else
      ((open++))
    fi
  fi
done

# Display progress bar
if [ $total -gt 0 ]; then
  percent=$((closed * 100 / total))
  filled=$((percent / 5))
  empty=$((20 - filled))

  bar=""
  for i in $(seq 1 $filled); do bar="${bar}#"; done
  for i in $(seq 1 $empty); do bar="${bar}-"; done

  echo "Progress: [$bar] $percent%"
else
  echo "Progress: No tasks created"
fi

echo ""
echo "Breakdown:"
echo "  Total tasks: $total"
echo "  Completed: $closed"
echo "  In Progress: $in_progress"
echo "  Available: $open"
echo "  Blocked: $blocked"

[ -n "$github" ] && [ "$github" != " " ] && echo "" && echo "GitHub: $github"

# Show task details
if [ $total -gt 0 ]; then
  echo ""
  echo "Task Details:"
  for task_file in "$epic_dir"/[0-9]*.md; do
    [ -f "$task_file" ] || continue
    task_num=$(basename "$task_file" .md)
    task_name=$(grep "^name:" "$task_file" | head -1 | sed 's/^name: *//')
    task_status=$(grep "^status:" "$task_file" | head -1 | sed 's/^status: *//')

    case "$task_status" in
      closed|completed) icon="[x]" ;;
      in-progress) icon="[~]" ;;
      *) icon="[ ]" ;;
    esac

    echo "  $icon #$task_num - $task_name ($task_status)"
  done
fi

exit 0
