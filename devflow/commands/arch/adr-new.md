---
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - LS
---

# Architecture Decision Record — New

## Usage
```
/arch:adr-new <decision>
```

## Description
Records a new Architecture Decision Record (ADR) in `.claude/adrs/`. ADRs capture significant architectural decisions, technology choices, and pattern selections for the project.

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
mkdir -p .claude/adrs
```
List existing ADRs and determine the next number:
```bash
ls .claude/adrs/ADR-*.md 2>/dev/null | sort -V | tail -1
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
Filename: `.claude/adrs/ADR-{number}-{slug}.md`

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

### Step 6: Engage the User
After creating the file with the template structure, ask the user to provide:
1. The **context** behind the decision
2. The **options** they considered (at least 2)
3. The **chosen option** and reasoning
4. Any **related ADRs** or specs

Fill in the sections based on their responses. If the user provides enough information upfront, populate the ADR directly without further prompting.

### Step 7: Output
```
✅ ADR created: .claude/adrs/ADR-{number}-{slug}.md
  - Status: proposed
  - Title: {Decision Title}
  - Number: ADR-{number}
Next: Review and update status with /arch:adr-list to verify
```
