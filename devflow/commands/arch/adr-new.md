---
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - LS
  - AskUserQuestion
---

# Architecture Decision Record — New

## Usage
```
/arch:adr-new <decision>
```

## Description
Records a new Architecture Decision Record (ADR) in `devflow/adrs/`. ADRs capture significant architectural decisions, technology choices, and pattern selections for the project.

## When to Create ADRs

ADRs are REQUIRED for:
- Database choices (PostgreSQL, MySQL, MongoDB, etc.)
- Framework choices (FastAPI, Django, React, Angular, etc.)
- Architecture patterns (microservices, monolith, event-driven, etc.)
- Authentication approaches (JWT, sessions, OAuth, etc.)
- Significant library choices that affect architecture
- Data model decisions (relationships, schema choices)
- API design decisions (REST, GraphQL, versioning strategy)

## References
- `devflow/rules/adr-patterns.md` — ADR format standards and lifecycle
- `devflow/rules/datetime.md` — DateTime handling for timestamps

## Execution

### Step 1: Parse Input
Extract the decision title from the argument:
```
Decision Title = <decision> argument provided by user
```
If no argument is provided:
```
❌ Missing decision title: Usage: /arch:adr-new "Use PostgreSQL for primary datastore"
```

### Step 2: Get Current DateTime
```bash
date -u +"%Y-%m-%dT%H:%M:%SZ"
```
Store the output as `{datetime}`.

### Step 3: Determine ADR Number
```bash
mkdir -p devflow/adrs
```
List existing ADRs and determine the next number:
```bash
ls devflow/adrs/ADR-*.md 2>/dev/null | sort -V | tail -1
```
- If no ADRs exist, next number is `001`.
- If ADRs exist, extract the highest number and increment by 1.
- Format: three-digit zero-padded (001, 002, 003, ...).

### Step 4: Generate Slug
Convert the decision title to a URL-friendly slug:
- Lowercase all characters
- Replace spaces and special characters with hyphens
- Remove consecutive hyphens
- Trim leading/trailing hyphens
- Max length: 60 characters

Example: "Use PostgreSQL for primary datastore" becomes `use-postgresql-for-primary-datastore`

### Step 5: Create ADR File
Filename: `devflow/adrs/ADR-{number}-{slug}.md`

Use the template from `devflow/templates/adr/adr-template.md` and populate it:

```markdown
---
adr: ADR-{number}
title: {Decision Title}
status: proposed
created: {datetime}
updated: {datetime}
deciders: []
---

# ADR-{number}: {Decision Title}

## Status
Proposed

## Context
{Ask the user to describe the context, or infer from the decision title.}
{What is the issue we're deciding on? What forces are at play?}
{What constraints exist? What requirements drive this decision?}

## Decision
{Describe the decision being made.}
{Be specific about what will be adopted, used, or changed.}

## Options Considered

### Option 1: {name}
- **Pros:**
  - {advantage 1}
  - {advantage 2}
- **Cons:**
  - {disadvantage 1}
  - {disadvantage 2}

### Option 2: {name}
- **Pros:**
  - {advantage 1}
  - {advantage 2}
- **Cons:**
  - {disadvantage 1}
  - {disadvantage 2}

### Option 3: {name}
- **Pros:**
  - {advantage 1}
  - {advantage 2}
- **Cons:**
  - {disadvantage 1}
  - {disadvantage 2}

## Consequences

### Positive
- {positive outcome 1}
- {positive outcome 2}

### Negative
- {trade-off accepted 1}
- {trade-off accepted 2}

## References
- {related ADRs, e.g., "Supersedes ADR-001"}
- {relevant specs or PRDs}
- {external resources, documentation links}
```

### Step 6: Gather ADR Information — STRUCTURED QUESTIONING

Use AskUserQuestion to systematically gather all ADR information:

**Question 1: Context**
> What problem or requirement led to this decision?
> Options:
> - New project needs [technology]
> - Existing system requires change
> - Performance/scalability requirements
> - Team expertise consideration
> - Other (describe)

**Question 2: Options Considered**
> What alternatives did you consider?
> List at least 2 options. For each option, we'll capture pros and cons.
>
> Option A: [name]
> Option B: [name]
> Option C: [name] (optional)

For EACH option, ask:
> For [Option Name], what are the:
> - Pros (advantages)
> - Cons (disadvantages)

**Question 3: Decision Rationale**
> Why was [chosen option] selected over the alternatives?
> Options:
> - Best fit for requirements
> - Team familiarity
> - Performance characteristics
> - Cost considerations
> - Community support
> - Other (describe)

**Question 4: Consequences**
> What are the positive and negative consequences of this decision?
> Positive: [list]
> Negative/trade-offs: [list]

**Question 5: Related Artifacts**
> Does this ADR relate to:
> - Other ADRs (supersedes, references)
> - Specific PRD or Spec
> - External documentation
> - None of the above

Fill in the ADR sections based on their responses. If the user provides enough information upfront, populate the ADR directly without further prompting.

### Step 7: Output
```
✅ ADR created: devflow/adrs/ADR-{number}-{slug}.md
  - Status: proposed
  - Title: {Decision Title}
  - Number: ADR-{number}
Next: Review and update status with /arch:adr-list to verify
```
