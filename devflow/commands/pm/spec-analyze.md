---
allowed-tools: Bash, Read, Write, LS
---

# Spec Analyze

Cross-artifact consistency check across spec, PRD, and principles.

## Usage
```
/pm:spec-analyze <feature_name>
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/spec-standards.md` - For spec format standards

## Preflight Checklist

Before proceeding, complete these validation steps.
Do not bother the user with preflight checks progress. Just do them and move on.

### 1. Verify Spec Exists
- Check if `.claude/specs/$ARGUMENTS.md` exists
- If not found, tell user: "Spec not found: $ARGUMENTS. Create it first with: /pm:spec-create $ARGUMENTS"
- Stop execution if spec does not exist

### 2. Gather All Related Artifacts
- Read spec: `.claude/specs/$ARGUMENTS.md`
- Read PRD (if exists): `.claude/prds/$ARGUMENTS.md`
- Read principles (if exists): `devflow/templates/principles/active-principles.md`
- Read plan (if exists): `.claude/specs/$ARGUMENTS-plan.md`
- Note which artifacts are available for analysis

## Instructions

### 1. Spec vs Principles Check

If active principles exist, check each spec requirement against each principle:

```markdown
## Principles Compliance

| Principle | Status | Details |
|-----------|--------|---------|
| Test-first | PASS | All user stories have testable acceptance criteria |
| Simplicity | WARN | FR-005 introduces unnecessary complexity |
| API-first | PASS | All endpoints defined before implementation |
```

**Check for:**
- Direct contradictions (FAIL): Spec requirement violates a hard-rule principle
- Potential tensions (WARN): Spec requirement may conflict with a guideline principle
- Full compliance (PASS): Spec requirement aligns with principle

### 2. Spec vs PRD Consistency

Compare spec against the PRD for completeness:

```markdown
## PRD Coverage

| PRD Section | Spec Coverage | Status |
|-------------|---------------|--------|
| User Story: As a user, I want... | US-001 | COVERED |
| Functional Req: Search feature | Missing | GAP |
| NFR: Response time < 200ms | NFR-001 | COVERED |
```

**Check for:**
- **Gaps:** PRD requirements not reflected in spec
- **Drift:** Spec requirements that contradict PRD
- **Additions:** Spec requirements not in PRD (may be valid elaboration)
- **Scope creep:** Spec includes items PRD explicitly excluded

### 3. Internal Consistency Check

Analyze the spec for self-consistency:

```markdown
## Internal Consistency

| Issue | Type | Severity | Details |
|-------|------|----------|---------|
| FR-003 vs FR-007 | Contradiction | HIGH | Both define different auth flows |
| US-002 | Missing Ref | LOW | References entity not in Key Entities |
| NFR-002 | Vague | MEDIUM | "Fast response" not quantified |
```

**Check for:**
- **Contradictions:** Two requirements that cannot both be satisfied
- **Circular dependencies:** Requirements that depend on each other
- **Missing references:** User stories referencing undefined entities
- **Incomplete acceptance criteria:** Given/When/Then with missing steps
- **Priority conflicts:** P1 requirement depending on P3 requirement
- **Undefined terms:** Domain terms used but not defined in entities

### 4. Missing Requirements Analysis

Identify common requirements that may be missing:

**Standard Checklist:**
- [ ] Authentication/Authorization requirements
- [ ] Error handling specifications
- [ ] Input validation rules
- [ ] Pagination for list endpoints
- [ ] Rate limiting specifications
- [ ] Audit logging requirements
- [ ] Data retention/deletion policies
- [ ] Internationalization needs
- [ ] Accessibility requirements
- [ ] API versioning strategy
- [ ] Caching strategy
- [ ] Database migration strategy
- [ ] Monitoring and alerting requirements

### 5. Generate Analysis Report

Create a comprehensive analysis report. Display it to the user (do not save as separate file -- update the spec if user agrees):

```markdown
# Spec Analysis Report: $ARGUMENTS
Generated: [datetime]

## Summary
- Principles Compliance: {X}/{Y} passed ({Z} warnings)
- PRD Coverage: {X}/{Y} requirements covered ({Z} gaps)
- Internal Issues: {count} found ({high} high, {medium} medium, {low} low)
- Missing Requirements: {count} potential gaps identified

## Critical Issues (Must Fix)
1. [Issue description with specific sections]
2. [Issue description with specific sections]

## Warnings (Should Review)
1. [Warning with recommendation]
2. [Warning with recommendation]

## Recommendations
1. [Specific actionable recommendation]
2. [Specific actionable recommendation]

## Principles Compliance Detail
[Full table from step 1]

## PRD Coverage Detail
[Full table from step 2]

## Internal Consistency Detail
[Full table from step 3]

## Missing Requirements Detail
[Checklist from step 4]
```

### 6. Offer Fixes

After presenting the report:
1. Ask: "Would you like to fix any of the identified issues now? (yes/no/specific issue number)"
2. If yes, update the spec with fixes:
   - Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`
   - Update relevant sections
   - Update `updated` field in frontmatter
   - Add analysis reference to clarification log
3. If no, suggest: "Run /pm:spec-clarify $ARGUMENTS to resolve ambiguities interactively"

### 7. Post-Analysis

1. Confirm analysis complete
2. Show score summary:
   - Overall health: {Good/Needs Work/Critical Issues}
3. Suggest next steps:
   - If critical issues: "Fix critical issues first, then re-analyze"
   - If warnings only: "Review warnings, then create plan: /pm:plan $ARGUMENTS"
   - If all clear: "Spec is ready! Create technical plan: /pm:plan $ARGUMENTS"

## Important Notes

- This is a read-heavy analysis command -- minimize writes
- Only update the spec if user explicitly agrees to fixes
- Report findings objectively without being alarmist
- Focus on actionable issues, not theoretical concerns
