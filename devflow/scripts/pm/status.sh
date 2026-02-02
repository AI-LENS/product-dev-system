#!/bin/bash

echo "Getting status..."
echo ""
echo ""

echo "Project Dashboard"
echo "================="
echo ""

# PRDs
echo "PRDs:"
if [ -d ".claude/prds" ]; then
  total=$(ls .claude/prds/*.md 2>/dev/null | wc -l | tr -d ' ')
  backlog=$(find .claude/prds -name "*.md" -exec grep -l "^status: *backlog" {} \; 2>/dev/null | wc -l | tr -d ' ')
  in_progress=$(find .claude/prds -name "*.md" -exec grep -l "^status: *in-progress" {} \; 2>/dev/null | wc -l | tr -d ' ')
  implemented=$(find .claude/prds -name "*.md" -exec grep -l "^status: *implemented" {} \; 2>/dev/null | wc -l | tr -d ' ')
  echo "  Total: $total (Backlog: $backlog, Active: $in_progress, Done: $implemented)"
else
  echo "  No PRDs found"
fi

echo ""

# Specs
echo "Specs:"
if [ -d ".claude/specs" ]; then
  specs=$(ls .claude/specs/*.md 2>/dev/null | grep -v "\-plan.md" | wc -l | tr -d ' ')
  plans=$(ls .claude/specs/*-plan.md 2>/dev/null | wc -l | tr -d ' ')
  echo "  Specs: $specs, Plans: $plans"
else
  echo "  No specs found"
fi

echo ""

# Epics
echo "Epics:"
if [ -d ".claude/epics" ]; then
  total_epics=$(ls -d .claude/epics/*/ 2>/dev/null | wc -l | tr -d ' ')
  echo "  Total: $total_epics"

  for epic_dir in .claude/epics/*/; do
    [ -d "$epic_dir" ] || continue
    [ -f "$epic_dir/epic.md" ] || continue

    epic_name=$(basename "$epic_dir")
    status=$(grep "^status:" "$epic_dir/epic.md" | head -1 | sed 's/^status: *//')
    progress=$(grep "^progress:" "$epic_dir/epic.md" | head -1 | sed 's/^progress: *//')
    [ -z "$progress" ] && progress="0%"

    echo "  - $epic_name [$status] $progress"
  done
else
  echo "  No epics found"
fi

echo ""

# Tasks
echo "Tasks:"
if [ -d ".claude/epics" ]; then
  total=$(find .claude/epics -name "[0-9]*.md" 2>/dev/null | wc -l | tr -d ' ')
  open=$(find .claude/epics -name "[0-9]*.md" -exec grep -l "^status: *open" {} \; 2>/dev/null | wc -l | tr -d ' ')
  in_prog=$(find .claude/epics -name "[0-9]*.md" -exec grep -l "^status: *in-progress" {} \; 2>/dev/null | wc -l | tr -d ' ')
  closed=$(find .claude/epics -name "[0-9]*.md" -exec grep -l "^status: *closed" {} \; 2>/dev/null | wc -l | tr -d ' ')
  echo "  Open: $open | In Progress: $in_prog | Closed: $closed | Total: $total"
else
  echo "  No tasks found"
fi

echo ""

# Git info
echo "Git:"
branch=$(git branch --show-current 2>/dev/null || echo "N/A")
uncommitted=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
echo "  Branch: $branch"
echo "  Uncommitted changes: $uncommitted"

echo ""

# Quick actions
echo "Quick Actions:"
echo "  /pm:next - Find next available task"
echo "  /pm:standup - Daily standup report"
echo "  /pm:help - Show all commands"

exit 0
