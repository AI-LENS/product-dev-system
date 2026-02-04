---
allowed-tools: Bash, Read, Write, LS, AskUserQuestion
---

# Spec Create

Formalize a PRD into a structured specification document with user stories, acceptance criteria, and prioritized requirements.

## Usage
```
/pm:spec-create <feature_name>
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/datetime.md` - For getting real current date/time
- `devflow/rules/spec-standards.md` - For spec format standards

## Preflight Checklist

Before proceeding, complete these validation steps.
Do not bother the user with preflight checks progress. Just do them and move on.

### 1. Verify PRD Exists
- Check if `devflow/prds/$ARGUMENTS.md` exists
- If not found, tell user: "PRD not found: $ARGUMENTS. Create it first with: /pm:prd-new $ARGUMENTS"
- Stop execution if PRD does not exist

### 2. Check for Existing Spec
- Check if `devflow/specs/$ARGUMENTS.md` already exists
- If it exists, ask user: "Spec '$ARGUMENTS' already exists. Do you want to overwrite it? (yes/no)"
- Only proceed with explicit 'yes' confirmation

### 3. Verify Directory Structure
- Check if `devflow/specs/` directory exists
- If not, create it: `mkdir -p devflow/specs/`

### 4. Load Active Principles
- Check if `devflow/templates/principles/active-principles.md` exists
- If it exists, read and note the active principles for compliance checking
- If not, proceed without principles check

### 5. Load Spec Template
- Read `devflow/templates/spec/spec-template.md` for the expected format

### 6. Get Current DateTime
- Run: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

## Instructions

### 1. Read and Analyze PRD

Read `devflow/prds/$ARGUMENTS.md`:
- Parse all sections: Executive Summary, Problem Statement, User Stories, Requirements, Success Criteria, Constraints, Out of Scope, Dependencies
- Identify key entities, actors, and actions
- Note all functional and non-functional requirements

### 1b. User Story Validation — PROBE QUESTIONING (MANDATORY)

**CRITICAL:** Before formalizing, validate understanding with the user. Use AskUserQuestion.

#### Phase 1: Core Flow Validation

For each major feature identified in the PRD, confirm the primary user flow:

**Question 1: Primary User Flow**
> For [Feature X], what is the MAIN user flow?
> Present 2-3 options based on PRD analysis:
> - Option A: [Flow A description]
> - Option B: [Flow B description]
> - Other (user specifies)

**Question 2: Critical Acceptance Criteria**
> What MUST be true for [Feature X] to be considered complete?
> - [Proposed criterion 1 from PRD]
> - [Proposed criterion 2 from PRD]
> - Add more criteria
> - These are sufficient

#### Phase 2: Priority Validation

**Question 3: Priority Confirmation**
> I've identified these priorities from the PRD. Correct?
>
> **P1 (Must Have):**
> - [Feature list]
>
> **P2 (Should Have):**
> - [Feature list]
>
> **P3 (Nice to Have):**
> - [Feature list]
>
> Options:
> - Correct as shown
> - Move some items (specify which)
> - All are P1 (warning: this usually means not enough prioritization)

#### Phase 3: Edge Cases & Error Handling

**Question 4: Error Scenarios**
> What should happen when things go wrong?
> For each core feature, ask:
> - Invalid input handling
> - Permission denied scenarios
> - System unavailable scenarios
> - Concurrent modification conflicts

**Question 5: Empty/Boundary States**
> What about edge cases?
> - Empty state (no data yet)
> - Maximum limits (how many items? how much data?)
> - First-time user experience

### 2. Create User Stories with Acceptance Criteria

Transform PRD user stories into formal Given/When/Then format:

```markdown
### US-001: [Story Title]
**As a** [persona]
**I want to** [action]
**So that** [benefit]

**Priority:** P1/P2/P3

**Acceptance Criteria:**
- **Given** [precondition]
  **When** [action]
  **Then** [expected result]
- **Given** [another precondition]
  **When** [action]
  **Then** [expected result]
```

**Priority Classification Rules:**
- **P1 (Must Have):** Core functionality without which the feature is unusable. Launch blockers.
- **P2 (Should Have):** Important functionality that significantly improves the experience. Target for initial release.
- **P3 (Nice to Have):** Enhancements that can be deferred to a later iteration.

### 3. Define Functional Requirements

Create numbered requirements in FR-xxx format:

```markdown
### FR-001: [Requirement Title]
- **Description:** [What the system must do]
- **Priority:** P1
- **User Stories:** US-001, US-003
- **Acceptance:** [Measurable criteria]
- **API Endpoint:** [If applicable - e.g., POST /api/v1/resource]
- **Data Model:** [Key entities involved]
```

### 4. Document Key Entities

Create an entity relationship overview:

```markdown
## Key Entities

| Entity | Description | Relationships | Key Fields |
|--------|-------------|---------------|------------|
| User   | System user | Has many Posts | id, email, name, role |
| Post   | Content item | Belongs to User | id, title, body, status |
```

Include:
- All domain entities identified from the PRD
- Their relationships (has-many, belongs-to, many-to-many)
- Key fields/attributes
- Database table mapping (for SQLAlchemy models)

### 5. Define Success Criteria

Transform PRD success criteria into measurable specifications:

```markdown
## Success Criteria
- [ ] [Metric]: [Target value] (measured by [method])
- [ ] API response time < 200ms for 95th percentile
- [ ] Unit test coverage >= 80%
- [ ] Zero critical security vulnerabilities
```

### 6. Compile Spec Document

Save to `devflow/specs/$ARGUMENTS.md` with this structure:

```markdown
---
name: $ARGUMENTS
status: draft
priority: P1
created: [Current ISO date/time]
updated: [Current ISO date/time]
prd: devflow/prds/$ARGUMENTS.md
---

# Spec: [Feature Name - Title Case]

## Overview
[2-3 sentence summary derived from PRD executive summary]

## User Stories

### US-001: [Story Title]
[Full story with acceptance criteria...]

[Continue for all stories...]

## Functional Requirements

### FR-001: [Requirement Title]
[Full requirement details...]

[Continue for all requirements...]

## Non-Functional Requirements

### NFR-001: [Requirement Title]
- **Category:** Performance/Security/Scalability/Reliability
- **Requirement:** [Specific measurable requirement]
- **Acceptance:** [How to verify]

## Key Entities

| Entity | Description | Relationships | Key Fields |
|--------|-------------|---------------|------------|
[Entity table...]

## Success Criteria
- [ ] [Measurable criteria...]

## Out of Scope
- [Items explicitly excluded from this spec]

## Open Questions
- [Any unresolved questions from the PRD]

## References
- PRD: devflow/prds/$ARGUMENTS.md
- Principles: devflow/templates/principles/active-principles.md
```

### 7. Spec Review & Validation (MANDATORY)

Before saving, present a summary to the user using AskUserQuestion:

> **Spec Summary for: $ARGUMENTS**
>
> **User Stories:** [count] (P1: [n], P2: [n], P3: [n])
> **Functional Requirements:** [count]
> **Key Entities:** [list]
> **Success Criteria:** [count]
>
> Key acceptance criteria:
> - [Top 3-5 most important criteria]
>
> Does this accurately capture the requirements?
> - Yes, save the spec
> - Needs changes (specify what)
> - Add more user stories
> - Adjust priorities

Iterate until user confirms.

### 8. Quality Checks

Before saving the spec, verify:
- [ ] All user stories have Given/When/Then acceptance criteria
- [ ] All functional requirements have FR-xxx numbering
- [ ] All requirements are linked to user stories
- [ ] Priority classification (P1/P2/P3) is assigned to all items
- [ ] Key entities are documented with relationships
- [ ] Success criteria are measurable with specific numbers
- [ ] Spec does not contradict active principles
- [ ] Out of scope items from PRD are carried forward

### 9. Post-Creation

After successfully creating the spec:
1. Confirm: "Spec created: devflow/specs/$ARGUMENTS.md"
2. Show summary:
   - Total user stories: {count} (P1: {count}, P2: {count}, P3: {count})
   - Total functional requirements: {count}
   - Total entities: {count}
   - Open questions: {count}
3. **IMPORTANT:** Suggest the NEXT step in sequence:
   - "Next step: /pm:spec-clarify $ARGUMENTS (optional but recommended for complex features)"
   - "Or skip to: /pm:plan $ARGUMENTS to create the technical implementation plan"

## Error Recovery

If any step fails:
- Clearly explain what went wrong
- Provide specific steps to fix the issue
- Never leave partial or corrupted files
