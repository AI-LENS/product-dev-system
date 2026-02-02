# Spec Format Standards

Standards and rules for writing specification documents in the DevFlow system.

## User Story Format

All user stories MUST follow this exact format:

```markdown
### US-{NNN}: {Title}
**As a** {persona}
**I want to** {action}
**So that** {benefit}

**Priority:** P1/P2/P3

**Acceptance Criteria:**
- **Given** {precondition}
  **When** {action}
  **Then** {expected result}
```

### Rules:
- Every user story MUST have at least one Given/When/Then acceptance criterion
- User story IDs are sequential: US-001, US-002, US-003
- Each story MUST have a priority classification
- Stories should be independent and testable

## Priority Classification

### P1 - Must Have (Launch Blocker)
- Core functionality without which the feature is unusable
- Security requirements
- Legal/compliance requirements
- Data integrity requirements

### P2 - Should Have (Target for Initial Release)
- Important functionality that significantly improves experience
- Performance optimization beyond minimum thresholds
- Error handling for non-critical paths
- User experience enhancements

### P3 - Nice to Have (Can Be Deferred)
- Convenience features
- Advanced configuration options
- Analytics and reporting
- UI polish and animations

### Rules:
- Every requirement MUST have a priority
- P1 requirements cannot depend on P3 requirements
- A spec should have a healthy distribution (not all P1)
- P1 items should cover the minimum viable feature

## Functional Requirements Format

All functional requirements MUST use this numbering and format:

```markdown
### FR-{NNN}: {Title}
- **Description:** {What the system must do - clear and unambiguous}
- **Priority:** P1/P2/P3
- **User Stories:** {Comma-separated US-xxx references}
- **Acceptance:** {Measurable, testable criteria}
- **API Endpoint:** {If applicable - method + path}
- **Data Model:** {Key entities involved}
```

### Rules:
- FR IDs are sequential: FR-001, FR-002, FR-003
- Every FR MUST link to at least one user story
- Description must be specific and unambiguous (avoid "should", "appropriate", "fast")
- Acceptance criteria must be measurable

## Non-Functional Requirements Format

```markdown
### NFR-{NNN}: {Title}
- **Category:** Performance/Security/Scalability/Reliability/Accessibility
- **Requirement:** {Specific measurable requirement}
- **Acceptance:** {How to verify - specific test or metric}
```

### Rules:
- NFR IDs are sequential: NFR-001, NFR-002, NFR-003
- Performance NFRs must include specific numbers (e.g., "< 200ms p95")
- Security NFRs must reference specific standards (e.g., "OWASP Top 10")
- Scalability NFRs must include specific capacity numbers

## Entity Documentation

All key entities must be documented in a table:

```markdown
| Entity | Description | Relationships | Key Fields |
|--------|-------------|---------------|------------|
| User   | System user | Has many Posts | id, email, name, role |
```

### Rules:
- Every entity referenced in requirements must appear in the entity table
- Relationships must specify cardinality (1-1, 1-many, many-many)
- Key fields must include the primary key and important attributes
- Entities should map to future database tables / SQLAlchemy models

## Cross-Referencing with PRD

### Rules:
- Every spec MUST reference its source PRD in frontmatter (`prd:` field)
- All PRD user stories should be traceable to spec user stories
- PRD functional requirements should map to spec FRs
- PRD out-of-scope items should be carried forward to spec
- Any additions in the spec (not in PRD) should be noted and justified

## Frontmatter Requirements

Every spec file MUST have this frontmatter:

```yaml
---
name: {feature-name}
status: draft/review/approved/implemented
priority: P1/P2/P3
created: {ISO 8601 datetime}
updated: {ISO 8601 datetime}
prd: {path to source PRD}
---
```

### Status Values:
- **draft**: Initial creation, may have open questions
- **review**: Ready for stakeholder review
- **approved**: Reviewed and approved for implementation
- **implemented**: Feature has been built

## Quality Checklist

Before a spec is considered complete:
- [ ] All user stories have Given/When/Then acceptance criteria
- [ ] All FRs have unique IDs in FR-xxx format
- [ ] All FRs link to user stories
- [ ] Priority assigned to all requirements
- [ ] Key entities documented with relationships
- [ ] Success criteria are measurable with specific numbers
- [ ] Out of scope section is present
- [ ] No undefined terms or ambiguous language
- [ ] PRD cross-reference verified
- [ ] No circular dependencies between requirements
