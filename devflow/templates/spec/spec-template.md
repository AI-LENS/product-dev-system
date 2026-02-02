---
name: {feature-name}
status: draft
priority: P1
created: {datetime}
updated: {datetime}
prd: {prd-reference}
---

# Spec: {Feature Name}

## Overview

{2-3 sentence summary derived from PRD executive summary. Describe the feature, its purpose, and primary value proposition.}

## User Stories

### US-001: {Story Title}
**As a** {persona}
**I want to** {action}
**So that** {benefit}

**Priority:** P1/P2/P3

**Acceptance Criteria:**
- **Given** {precondition}
  **When** {action}
  **Then** {expected result}
- **Given** {another precondition}
  **When** {action}
  **Then** {expected result}

### US-002: {Story Title}
**As a** {persona}
**I want to** {action}
**So that** {benefit}

**Priority:** P1/P2/P3

**Acceptance Criteria:**
- **Given** {precondition}
  **When** {action}
  **Then** {expected result}

## Functional Requirements

### FR-001: {Requirement Title}
- **Description:** {what the system must do}
- **Priority:** P1
- **User Stories:** US-001
- **Acceptance:** {measurable criteria}
- **API Endpoint:** {if applicable - e.g., POST /api/v1/resource}
- **Data Model:** {key entities involved}

### FR-002: {Requirement Title}
- **Description:** {what the system must do}
- **Priority:** P2
- **User Stories:** US-001, US-002
- **Acceptance:** {measurable criteria}

## Non-Functional Requirements

### NFR-001: {Requirement Title}
- **Category:** Performance
- **Requirement:** {specific measurable requirement, e.g., API response < 200ms p95}
- **Acceptance:** {how to verify}

### NFR-002: {Requirement Title}
- **Category:** Security
- **Requirement:** {specific requirement, e.g., All endpoints require JWT authentication}
- **Acceptance:** {how to verify}

### NFR-003: {Requirement Title}
- **Category:** Scalability
- **Requirement:** {specific requirement, e.g., Support 1000 concurrent users}
- **Acceptance:** {how to verify}

## Key Entities

| Entity | Description | Relationships | Key Fields |
|--------|-------------|---------------|------------|
| {name} | {description} | {related entities} | {id, field1, field2} |
| {name} | {description} | {related entities} | {id, field1, field2} |

## Success Criteria

- [ ] {Measurable criterion 1 with specific target}
- [ ] {Measurable criterion 2 with specific target}
- [ ] {Measurable criterion 3 with specific target}

## Out of Scope

- {Explicitly excluded item 1}
- {Explicitly excluded item 2}
- {Explicitly excluded item 3}

## Open Questions

- {Unresolved question 1}
- {Unresolved question 2}

## References

- PRD: {prd-reference}
- Principles: devflow/templates/principles/active-principles.md
