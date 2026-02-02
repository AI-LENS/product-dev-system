---
allowed-tools: Read, Write, LS
---

# PRD Edit

Edit an existing Product Requirements Document.

## Usage
```
/pm:prd-edit <feature_name>
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/datetime.md` - For getting real current date/time
- `devflow/rules/frontmatter-operations.md` - For frontmatter handling

## Preflight Checklist

Before proceeding, complete these validation steps.
Do not bother the user with preflight checks progress. Just do them and move on.

### 1. Verify PRD Exists
- Check if `.claude/prds/$ARGUMENTS.md` exists
- If not found, tell user: "PRD not found: $ARGUMENTS. Available PRDs:" then list contents of `.claude/prds/`
- Stop execution if PRD does not exist

### 2. Validate Frontmatter
- Read the PRD file
- Verify it has valid frontmatter with: name, status, created
- If missing frontmatter, warn but continue

## Instructions

### 1. Read Current PRD

Read `.claude/prds/$ARGUMENTS.md`:
- Parse frontmatter (name, description, status, created, updated)
- Read all sections
- Display current PRD summary to user

### 2. Interactive Edit

Ask user what sections to edit. Present the available sections:
- Executive Summary
- Problem Statement
- User Stories
- Requirements (Functional / Non-Functional)
- Success Criteria
- Constraints & Assumptions
- Out of Scope
- Dependencies
- Status (backlog / in-progress / implemented)

Allow the user to:
- Select one or more sections to modify
- Provide new content or modifications
- Add entirely new sections if needed

### 3. Update PRD

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update PRD file:
- Preserve all frontmatter fields except `updated`
- Preserve the original `created` field
- Apply user's edits to selected sections
- Update `updated` field with current datetime
- Keep all unedited sections exactly as they were

### 4. Check Spec Impact

If PRD has an associated spec (check `.claude/specs/$ARGUMENTS.md`):
- Notify user: "This PRD has a spec: $ARGUMENTS"
- Ask: "Spec may need updating based on PRD changes. Review spec? (yes/no)"
- If yes, suggest: "Review with: /pm:spec-clarify $ARGUMENTS"

### 5. Check Epic Impact

If PRD has an associated epic (check `.claude/epics/$ARGUMENTS/epic.md`):
- Notify user: "This PRD has an epic: $ARGUMENTS"
- Ask: "Epic may need updating based on PRD changes. Review epic? (yes/no)"
- If yes, suggest: "Re-create spec and plan: /pm:spec-create $ARGUMENTS"

### 6. Output

```
Updated PRD: $ARGUMENTS
  Sections edited: {list_of_sections}
  Updated: {timestamp}

{If has spec}: Spec may need review: /pm:spec-clarify $ARGUMENTS
{If has epic}: Epic may need review: /pm:epic-decompose $ARGUMENTS

Next: /pm:spec-create $ARGUMENTS to formalize into spec
```

## Important Notes

- Preserve original creation date
- Keep all unedited sections intact
- Follow `devflow/rules/frontmatter-operations.md` for frontmatter handling
- Never delete content without user confirmation
