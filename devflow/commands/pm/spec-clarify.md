---
allowed-tools: Bash, Read, Write, LS
---

# Spec Clarify

Structured Q&A to resolve spec ambiguities and fill gaps.

## Usage
```
/pm:spec-clarify <feature_name>
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/datetime.md` - For getting real current date/time
- `devflow/rules/spec-standards.md` - For spec format standards

## Preflight Checklist

Before proceeding, complete these validation steps.
Do not bother the user with preflight checks progress. Just do them and move on.

### 1. Verify Spec Exists
- Check if `devflow/specs/$ARGUMENTS.md` exists
- If not found, tell user: "Spec not found: $ARGUMENTS. Create it first with: /pm:spec-create $ARGUMENTS"
- Stop execution if spec does not exist

### 2. Read Related Artifacts
- Read the spec: `devflow/specs/$ARGUMENTS.md`
- Read the PRD if available: `devflow/prds/$ARGUMENTS.md`
- Read active principles if available: `devflow/templates/principles/active-principles.md`

## Instructions

### 1. Analyze Spec for Ambiguities

Read the spec thoroughly and identify up to 5 ambiguities in these categories:

**Ambiguity Categories:**
1. **Undefined Behavior:** What happens in edge cases? Error scenarios? Empty states?
2. **Vague Requirements:** Requirements using words like "should", "appropriate", "reasonable", "fast"
3. **Missing Acceptance Criteria:** User stories without complete Given/When/Then
4. **Unclear Entities:** Entity relationships not fully defined, missing fields
5. **Conflicting Requirements:** Requirements that may contradict each other
6. **Missing Error Handling:** No specification for failure modes
7. **Undefined Boundaries:** Unclear scope boundaries, features that could be in or out
8. **Performance Gaps:** NFRs without specific measurable targets
9. **Security Gaps:** Missing auth/authz requirements, data protection needs
10. **Integration Gaps:** Undefined API contracts, missing sequence flows

### 2. Present Ambiguities

For each ambiguity found, present it in this format:

```
Ambiguity {N} of {total}: [{Category}]
---
Section: {spec section where the ambiguity exists}
Current Text: "{relevant quote from the spec}"
Issue: {clear explanation of why this is ambiguous}

Suggested Options:
  A) {Option A with implications}
  B) {Option B with implications}
  C) {Custom - let user define}

Which option? (A/B/C/skip)
```

### 3. Structured Q&A Rounds

Conduct up to 5 rounds of clarification:

**Round Structure:**
1. Present the ambiguity with context
2. Offer 2-3 concrete options plus custom
3. Wait for user response
4. Record the decision
5. Move to next ambiguity

**Rules:**
- Maximum 5 ambiguities per session (prioritize by impact)
- User can skip any question
- User can provide custom answers
- Track all decisions for the update

### 4. Update Spec

After all rounds are complete, update the spec:

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

For each resolved ambiguity:
- Update the relevant spec section with the clarified requirement
- Add specific acceptance criteria where they were missing
- Replace vague language with precise specifications
- Add error handling specifications where needed
- Update the `updated` field in frontmatter

Add a Clarification Log section at the bottom:

```markdown
## Clarification Log

### Session: [datetime]
| # | Category | Decision | Section Updated |
|---|----------|----------|-----------------|
| 1 | [category] | [decision summary] | [section] |
| 2 | [category] | [decision summary] | [section] |
```

### 5. Remove Open Questions

For each ambiguity resolved:
- Remove the corresponding item from the "Open Questions" section
- If all open questions are resolved, remove the section entirely

### 6. Post-Clarification

After successfully updating the spec:
1. Confirm: "Spec updated: devflow/specs/$ARGUMENTS.md"
2. Show summary:
   - Ambiguities found: {total}
   - Resolved: {resolved_count}
   - Skipped: {skipped_count}
   - Remaining open questions: {remaining_count}
3. Suggest next steps:
   - If open questions remain: "Run again to resolve more: /pm:spec-clarify $ARGUMENTS"
   - If all resolved: "Analyze consistency: /pm:spec-analyze $ARGUMENTS"
   - "Create technical plan: /pm:plan $ARGUMENTS"

## Important Notes

- Maximum 5 rounds per session to avoid fatigue
- Prioritize ambiguities by impact on implementation
- Always preserve existing resolved content
- Never change decisions from previous clarification sessions without asking
- Keep the clarification log as an audit trail
