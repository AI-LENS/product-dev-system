#!/bin/bash
echo "Loading epics..."
echo ""
echo ""

if [ ! -d ".claude/epics" ]; then
  echo "No epics directory found. Create your first epic with: /pm:epic-decompose <feature-name>"
  exit 0
fi

epic_dirs=$(ls -d .claude/epics/*/ 2>/dev/null || true)
if [ -z "$epic_dirs" ]; then
  echo "No epics found. Create your first epic with: /pm:epic-decompose <feature-name>"
  exit 0
fi

echo "Project Epics"
echo "=============="
echo ""

# Initialize categories
planning_epics=""
in_progress_epics=""
completed_epics=""

# Process all epics
for dir in .claude/epics/*/; do
  [ -d "$dir" ] || continue
  [ -f "$dir/epic.md" ] || continue

  # Extract metadata
  n=$(grep "^name:" "$dir/epic.md" | head -1 | sed 's/^name: *//')
  s=$(grep "^status:" "$dir/epic.md" | head -1 | sed 's/^status: *//' | tr '[:upper:]' '[:lower:]')
  p=$(grep "^progress:" "$dir/epic.md" | head -1 | sed 's/^progress: *//')
  g=$(grep "^github:" "$dir/epic.md" | head -1 | sed 's/^github: *//')

  # Defaults
  [ -z "$n" ] && n=$(basename "$dir")
  [ -z "$p" ] && p="0%"

  # Count tasks
  t=$(ls "$dir"/[0-9]*.md 2>/dev/null | wc -l | tr -d ' ')

  # Format output with GitHub issue number if available
  if [ -n "$g" ] && [ "$g" != " " ]; then
    i=$(echo "$g" | grep -o '/[0-9]*$' | tr -d '/')
    entry="   $n (#$i) - $p complete ($t tasks)"
  else
    entry="   $n - $p complete ($t tasks)"
  fi

  # Categorize by status
  case "$s" in
    planning|draft|"")
      planning_epics="${planning_epics}${entry}\n"
      ;;
    in-progress|in_progress|active|started)
      in_progress_epics="${in_progress_epics}${entry}\n"
      ;;
    completed|complete|done|closed|finished)
      completed_epics="${completed_epics}${entry}\n"
      ;;
    *)
      planning_epics="${planning_epics}${entry}\n"
      ;;
  esac
done

# Display categorized epics
echo "Planning:"
if [ -n "$planning_epics" ]; then
  echo -e "$planning_epics" | sed '/^$/d'
else
  echo "   (none)"
fi

echo ""
echo "In Progress:"
if [ -n "$in_progress_epics" ]; then
  echo -e "$in_progress_epics" | sed '/^$/d'
else
  echo "   (none)"
fi

echo ""
echo "Completed:"
if [ -n "$completed_epics" ]; then
  echo -e "$completed_epics" | sed '/^$/d'
else
  echo "   (none)"
fi

# Summary
echo ""
echo "Summary"
total=$(ls -d .claude/epics/*/ 2>/dev/null | wc -l | tr -d ' ')
tasks=$(find .claude/epics -name "[0-9]*.md" 2>/dev/null | wc -l | tr -d ' ')
echo "   Total epics: $total"
echo "   Total tasks: $tasks"

exit 0
