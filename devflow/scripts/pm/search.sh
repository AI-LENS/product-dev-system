#!/bin/bash

query="$1"

if [ -z "$query" ]; then
  echo "Please provide a search query"
  echo "Usage: /pm:search <query>"
  exit 1
fi

echo "Searching for '$query'..."
echo ""
echo ""

echo "Search results for: '$query'"
echo "=============================="
echo ""

total_matches=0

# Search in PRDs
if [ -d "devflow/prds" ]; then
  echo "PRDs:"
  results=$(grep -l -i "$query" devflow/prds/*.md 2>/dev/null)
  if [ -n "$results" ]; then
    for file in $results; do
      name=$(basename "$file" .md)
      matches=$(grep -c -i "$query" "$file")
      echo "  - $name ($matches matches)"
      ((total_matches += matches))
    done
  else
    echo "  No matches"
  fi
  echo ""
fi

# Search in Specs
if [ -d "devflow/specs" ]; then
  echo "Specs:"
  results=$(grep -l -i "$query" devflow/specs/*.md 2>/dev/null)
  if [ -n "$results" ]; then
    for file in $results; do
      name=$(basename "$file" .md)
      matches=$(grep -c -i "$query" "$file")
      echo "  - $name ($matches matches)"
      ((total_matches += matches))
    done
  else
    echo "  No matches"
  fi
  echo ""
fi

# Search in Epics
if [ -d "devflow/epics" ]; then
  echo "Epics:"
  results=$(find devflow/epics -name "epic.md" -exec grep -l -i "$query" {} \; 2>/dev/null)
  if [ -n "$results" ]; then
    for file in $results; do
      epic_name=$(basename $(dirname "$file"))
      matches=$(grep -c -i "$query" "$file")
      echo "  - $epic_name ($matches matches)"
      ((total_matches += matches))
    done
  else
    echo "  No matches"
  fi
  echo ""
fi

# Search in Tasks
if [ -d "devflow/epics" ]; then
  echo "Tasks:"
  results=$(find devflow/epics -name "[0-9]*.md" -exec grep -l -i "$query" {} \; 2>/dev/null | head -10)
  if [ -n "$results" ]; then
    for file in $results; do
      epic_name=$(basename $(dirname "$file"))
      task_num=$(basename "$file" .md)
      task_name=$(grep "^name:" "$file" | head -1 | sed 's/^name: *//')
      matches=$(grep -c -i "$query" "$file")
      echo "  - #$task_num ($epic_name) - $task_name ($matches matches)"
      ((total_matches += matches))
    done
  else
    echo "  No matches"
  fi
  echo ""
fi

# Search in Context
if [ -d "devflow/context" ]; then
  echo "Context:"
  results=$(grep -l -i "$query" devflow/context/*.md 2>/dev/null)
  if [ -n "$results" ]; then
    for file in $results; do
      name=$(basename "$file" .md)
      matches=$(grep -c -i "$query" "$file")
      echo "  - $name ($matches matches)"
      ((total_matches += matches))
    done
  else
    echo "  No matches"
  fi
  echo ""
fi

# Summary
total_files=$(find .claude -name "*.md" -exec grep -l -i "$query" {} \; 2>/dev/null | wc -l | tr -d ' ')
echo "Total: $total_files files with $total_matches matches"

exit 0
