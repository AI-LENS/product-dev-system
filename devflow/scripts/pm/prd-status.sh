#!/bin/bash

echo "PRD Status Report"
echo "=================="
echo ""

if [ ! -d ".claude/prds" ]; then
  echo "No PRD directory found."
  exit 0
fi

total=$(ls .claude/prds/*.md 2>/dev/null | wc -l | tr -d ' ')
[ "$total" -eq 0 ] && echo "No PRDs found." && exit 0

# Count by status
backlog=0
in_progress=0
implemented=0

for file in .claude/prds/*.md; do
  [ -f "$file" ] || continue
  status=$(grep "^status:" "$file" | head -1 | sed 's/^status: *//')

  case "$status" in
    backlog|draft|"") ((backlog++)) ;;
    in-progress|active) ((in_progress++)) ;;
    implemented|completed|done) ((implemented++)) ;;
    *) ((backlog++)) ;;
  esac
done

echo "Getting status..."
echo ""

# Display distribution
echo "Distribution:"
echo "=============="
echo ""

if [ "$total" -gt 0 ]; then
  backlog_bar=""
  in_progress_bar=""
  implemented_bar=""

  [ "$backlog" -gt 0 ] && backlog_bar=$(printf '%0.s#' $(seq 1 $((backlog * 20 / total))))
  [ "$in_progress" -gt 0 ] && in_progress_bar=$(printf '%0.s#' $(seq 1 $((in_progress * 20 / total))))
  [ "$implemented" -gt 0 ] && implemented_bar=$(printf '%0.s#' $(seq 1 $((implemented * 20 / total))))

  printf "  Backlog:     %-3d [%s]\n" "$backlog" "$backlog_bar"
  printf "  In Progress: %-3d [%s]\n" "$in_progress" "$in_progress_bar"
  printf "  Implemented: %-3d [%s]\n" "$implemented" "$implemented_bar"
fi

echo ""
echo "  Total PRDs: $total"

# PRDs with specs
echo ""
echo "Spec Coverage:"
specs_count=0
for file in .claude/prds/*.md; do
  [ -f "$file" ] || continue
  name=$(basename "$file" .md)
  if [ -f ".claude/specs/$name.md" ]; then
    ((specs_count++))
    has_plan=""
    [ -f ".claude/specs/$name-plan.md" ] && has_plan=" + plan"
    echo "  - $name: has spec$has_plan"
  fi
done
echo "  Coverage: $specs_count/$total PRDs have specs"

# Recent activity
echo ""
echo "Recent PRDs (last 5 modified):"
ls -t .claude/prds/*.md 2>/dev/null | head -5 | while read file; do
  name=$(grep "^name:" "$file" | head -1 | sed 's/^name: *//')
  [ -z "$name" ] && name=$(basename "$file" .md)
  status=$(grep "^status:" "$file" | head -1 | sed 's/^status: *//')
  echo "  - $name [$status]"
done

# Suggestions
echo ""
echo "Next Actions:"
[ $backlog -gt 0 ] && echo "  - Create specs for backlog PRDs: /pm:spec-create <name>"
[ $in_progress -gt 0 ] && echo "  - Check progress on active PRDs: /pm:epic-status <name>"
[ $total -eq 0 ] && echo "  - Create your first PRD: /pm:prd-new <name>"

exit 0
