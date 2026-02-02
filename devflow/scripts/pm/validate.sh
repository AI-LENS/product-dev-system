#!/bin/bash

echo "Validating DevFlow PM System..."
echo ""
echo ""

echo "Validating PM System"
echo "====================="
echo ""

errors=0
warnings=0

# Check directory structure
echo "Directory Structure:"
[ -d ".claude" ] && echo "  .claude directory exists" || { echo "  .claude directory missing"; ((errors++)); }
[ -d ".claude/prds" ] && echo "  PRDs directory exists" || echo "  PRDs directory missing (run /pm:init)"
[ -d ".claude/epics" ] && echo "  Epics directory exists" || echo "  Epics directory missing (run /pm:init)"
[ -d ".claude/specs" ] && echo "  Specs directory exists" || echo "  Specs directory missing (run /pm:init)"
[ -d ".claude/context" ] && echo "  Context directory exists" || echo "  Context directory missing (run /context:create)"
echo ""

# Check DevFlow structure
echo "DevFlow Structure:"
[ -d "devflow/commands/pm" ] && echo "  PM commands directory exists" || { echo "  PM commands missing"; ((errors++)); }
[ -d "devflow/scripts/pm" ] && echo "  PM scripts directory exists" || { echo "  PM scripts missing"; ((errors++)); }
[ -d "devflow/templates" ] && echo "  Templates directory exists" || { echo "  Templates missing"; ((warnings++)); }
[ -d "devflow/rules" ] && echo "  Rules directory exists" || { echo "  Rules missing"; ((warnings++)); }
echo ""

# Check for orphaned files
echo "Data Integrity:"

# Check epics have epic.md files
for epic_dir in .claude/epics/*/; do
  [ -d "$epic_dir" ] || continue
  if [ ! -f "$epic_dir/epic.md" ]; then
    echo "  Missing epic.md in $(basename "$epic_dir")"
    ((warnings++))
  fi
done

# Check specs have matching PRDs
for spec_file in .claude/specs/*.md; do
  [ -f "$spec_file" ] || continue
  [[ "$spec_file" == *"-plan.md" ]] && continue
  spec_name=$(basename "$spec_file" .md)
  if [ ! -f ".claude/prds/$spec_name.md" ]; then
    echo "  Spec '$spec_name' has no matching PRD"
    ((warnings++))
  fi
done

# Check for orphaned tasks
orphaned=$(find .claude -name "[0-9]*.md" -not -path ".claude/epics/*/*" 2>/dev/null | wc -l | tr -d ' ')
[ "$orphaned" -gt 0 ] && echo "  Found $orphaned orphaned task files" && ((warnings++))

echo ""

# Check for broken references
echo "Reference Check:"
ref_issues=0

for task_file in .claude/epics/*/[0-9]*.md; do
  [ -f "$task_file" ] || continue

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
    epic_dir=$(dirname "$task_file")
    for dep in $deps; do
      dep=$(echo "$dep" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
      [ -z "$dep" ] && continue
      if [ ! -f "$epic_dir/$dep.md" ]; then
        echo "  Task $(basename "$task_file" .md) references missing task: $dep"
        ((warnings++))
        ((ref_issues++))
      fi
    done
  fi
done

[ $ref_issues -eq 0 ] && echo "  All references valid"

echo ""

# Check frontmatter
echo "Frontmatter Validation:"
invalid=0

for file in $(find .claude -name "*.md" \( -path "*/epics/*" -o -path "*/prds/*" -o -path "*/specs/*" \) 2>/dev/null); do
  if ! head -1 "$file" | grep -q "^---"; then
    echo "  Missing frontmatter: $file"
    ((invalid++))
  fi
done

[ $invalid -eq 0 ] && echo "  All files have frontmatter"

echo ""

# Check principles
echo "Principles:"
if [ -f "devflow/templates/principles/active-principles.md" ]; then
  echo "  Active principles file exists"
  principle_count=$(grep -c "^#### Principle" "devflow/templates/principles/active-principles.md" 2>/dev/null || echo 0)
  echo "  Principles defined: $principle_count"
else
  echo "  No active principles (run /devflow:principles)"
fi

echo ""

# Summary
echo "Validation Summary:"
echo "  Errors: $errors"
echo "  Warnings: $warnings"
echo "  Invalid files: $invalid"

if [ $errors -eq 0 ] && [ $warnings -eq 0 ] && [ $invalid -eq 0 ]; then
  echo ""
  echo "System is healthy!"
else
  echo ""
  echo "Run /pm:init to fix structural issues"
fi

exit 0
