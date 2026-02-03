---
allowed-tools:
  - Read
  - Bash
  - Glob
  - LS
---

# Architecture Decision Records — List

## Usage
```
/arch:adr-list
```

## Description
Lists all Architecture Decision Records from the `devflow/adrs/` directory, showing ADR number, title, status, and creation date in a formatted table.

## Execution

### Step 1: Check ADR Directory
```bash
test -d .claude/adrs || echo "NO_ADRS_DIR"
```
If directory does not exist:
```
No ADRs found. Create one with: /arch:adr-new "Your decision title"
```

### Step 2: List ADR Files
```bash
ls devflow/adrs/ADR-*.md 2>/dev/null | sort -V
```
If no files found:
```
No ADRs found. Create one with: /arch:adr-new "Your decision title"
```

### Step 3: Parse Each ADR
For each ADR file, read the YAML frontmatter and extract:
- `adr` — the ADR identifier (e.g., ADR-001)
- `title` — the decision title
- `status` — current status (proposed, accepted, deprecated, superseded)
- `created` — creation date

### Step 4: Display Results
Format output as a table:

```
{count} ADRs found:

| ADR     | Title                              | Status    | Created    |
|---------|------------------------------------|-----------|------------|
| ADR-001 | Use PostgreSQL for primary store   | accepted  | 2024-03-15 |
| ADR-002 | Adopt FastAPI for backend          | proposed  | 2024-03-18 |
| ADR-003 | Use Redis for session caching      | deprecated| 2024-03-20 |
```

### Status Legend
Display after the table:
```
Statuses: proposed | accepted | deprecated | superseded
```

### Step 5: Summary
```
{total} ADRs: {accepted_count} accepted, {proposed_count} proposed, {deprecated_count} deprecated, {superseded_count} superseded
```

Only include non-zero status counts in the summary.
