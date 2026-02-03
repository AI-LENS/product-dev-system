---
allowed-tools: Bash, Read, Write, LS
---

# Update Context

This command updates the project context documentation in `devflow/context/` to reflect the current state of the project. Run this at the end of each development session to keep context accurate.

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/datetime.md` - For getting real current date/time

## Preflight Checklist

Before proceeding, complete these validation steps.
Do not bother the user with preflight checks progress. Just do them and move on.

### 1. Context Validation
- Run: `ls -la devflow/context/ 2>/dev/null`
- If directory doesn't exist or is empty:
  - Tell user: "No context to update. Please run /context:create first."
  - Exit gracefully
- Count existing files: `ls -1 devflow/context/*.md 2>/dev/null | wc -l`
- Report: "Found {count} context files to check for updates"

### 2. Change Detection

Gather information about what has changed:

**Git Changes:**
- Run: `git status --short` to see uncommitted changes
- Run: `git log --oneline -10` to see recent commits
- Run: `git diff --stat HEAD~5..HEAD 2>/dev/null` to see files changed recently

**Dependency Changes:**
- Python: `git diff HEAD~5..HEAD requirements.txt pyproject.toml 2>/dev/null`
- Node.js: `git diff HEAD~5..HEAD package.json 2>/dev/null`
- Other: Check relevant build/dependency files for the detected project type

### 3. Get Current DateTime
- Run: `date -u +"%Y-%m-%dT%H:%M:%SZ"`
- Store for updating `last_updated` field in modified files

## Instructions

### 1. Systematic Change Analysis

For each context file, determine if updates are needed:

#### `progress.md` - **Always Update**
  - Check: Recent commits, current branch, uncommitted changes
  - Update: Latest completed work, current blockers, next steps
  - Run: `git log --oneline -5` to get recent commit messages

#### `project-structure.md` - **Update if Changed**
  - Check: `git diff --name-status HEAD~10..HEAD | grep -E '^A'` for new files
  - Update: New directories, moved files, structural reorganization

#### `tech-context.md` - **Update if Dependencies Changed**
  - Check: Package files for new dependencies or version changes
  - Update: New libraries, upgraded versions, new dev tools

#### `system-patterns.md` - **Update if Architecture Changed**
  - Check: New design patterns, architectural decisions
  - Update: New patterns adopted, refactoring done

#### `product-context.md` - **Update if Requirements Changed**
  - Check: New features implemented, user feedback incorporated
  - Update: New user stories, changed requirements

#### `project-brief.md` - **Rarely Update**
  - Check: Only if fundamental project goals changed

#### `project-overview.md` - **Update for Major Milestones**
  - Check: Major features completed, significant progress

#### `project-vision.md` - **Rarely Update**
  - Check: Strategic direction changes

#### `project-style-guide.md` - **Update if Conventions Changed**
  - Check: New linting rules, style decisions

### 2. Smart Update Strategy

For each file that needs updating:
1. Read existing file to understand current content
2. Identify specific sections that need updates
3. Preserve frontmatter but update `last_updated` field:
   ```yaml
   ---
   created: [preserve original]
   last_updated: [REAL datetime from date command]
   version: [increment if major update, e.g., 1.0 -> 1.1]
   author: DevFlow PM System
   ---
   ```
4. Make targeted, surgical updates -- do not rewrite entire file
5. Add update notes at the bottom if significant:
   ```markdown
   ## Update History
   - {date}: {summary of what changed}
   ```

### 3. Update Validation

After updating each file:
- Verify file still has valid frontmatter
- Check file size is reasonable (not corrupted)
- Ensure markdown formatting is preserved

### 4. Skip Optimization

Skip files that don't need updates:
- If no relevant changes detected, skip the file
- Report skipped files in summary
- Don't update timestamp if content unchanged

### 5. Update Summary

```
Context Update Complete

Update Statistics:
  - Files Scanned: {total_count}
  - Files Updated: {updated_count}
  - Files Skipped: {skipped_count} (no changes needed)

Updated Files:
  progress.md - Updated recent commits, current status
  tech-context.md - Added new dependencies
  project-structure.md - Noted new directories

Skipped Files (no changes):
  - project-brief.md (last updated: {date})
  - project-vision.md (last updated: {date})

Last Update: {timestamp}
Next: Run this command regularly to keep context current
```

## Important Notes

- **Only update files with actual changes** -- preserve accurate timestamps
- **Always use real datetime** from system clock for `last_updated`
- **Make surgical updates** -- don't regenerate entire files
- **Validate each update** -- ensure files remain valid
- **Handle errors gracefully** -- don't corrupt existing context

$ARGUMENTS
