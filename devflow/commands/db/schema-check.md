---
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - LS
---

# Database Schema Check

## Usage
```
/db:schema-check
```

## Description
Validates the database schema against best practices and detects common issues. Checks for missing indexes, N+1 query patterns, orphaned columns, missing constraints, and schema drift between models and the actual database.

## References
- `devflow/rules/db-patterns.md` — Database patterns and index strategies

## Execution

### Step 1: Discover Models
Find all SQLAlchemy model files:
```bash
find app/models/ -name "*.py" -not -name "__init__.py" -not -name "mixins.py"
```
Read each model file to build a picture of the schema.

### Step 2: Run Checks

#### Check 1: Missing Indexes on Foreign Keys
For every column ending in `_id` or declared as `ForeignKey`:
- Verify an index exists on that column
- Foreign key columns without indexes cause slow JOIN performance

Report format:
```
Foreign Key Index Check:
  app/models/task.py:
    project_id — index: ix_task_project_id (OK)
    assignee_id — NO INDEX (add Index or mapped_column(index=True))
```

#### Check 2: N+1 Query Patterns in Code
Search application code for patterns that suggest N+1 queries:
```bash
# Look for relationship access inside loops
grep -rn "for .* in .*:" app/routers/ app/services/ | head -50
```
Then check if any of those loops access relationship attributes without prior eager loading.

Common N+1 patterns to flag:
- `for item in items: item.relationship.field` without `selectinload` or `joinedload`
- Accessing `.all()` result relationships in Jinja/template loops
- Service methods that call repository methods in loops

Report format:
```
N+1 Query Check:
  app/services/project_service.py:42
    Loop accesses project.owner — add selectinload(Project.owner) to query
  app/routers/tasks.py:67
    Loop accesses task.comments — add selectinload(Task.comments) to query
```

#### Check 3: Orphaned Columns
Check for columns referenced in models but potentially unused in application code:
- For each model column, search for its usage in routers, services, and schemas
- Flag columns that appear only in the model definition and nowhere else

Report format:
```
Potentially Unused Columns:
  Task.legacy_status — no references found outside model
  User.temp_token — no references found outside model
```

#### Check 4: Missing Constraints
Check models for common missing constraints:
- String columns without `max_length` — risks unbounded data
- Nullable columns that should probably be NOT NULL
- Missing unique constraints on natural keys (email, slug, etc.)
- Missing check constraints on status/enum columns

Report format:
```
Constraint Check:
  User.email — should have unique=True (natural key)
  Task.title — String without length limit (add String(255))
  Task.priority — no check constraint (consider CheckConstraint for valid values)
```

#### Check 5: Schema Drift
Compare SQLAlchemy models against the actual database state:
```bash
alembic check 2>&1
```

If Alembic detects differences:
```bash
alembic revision --autogenerate -m "drift_check" --sql 2>&1
```
Do NOT create the migration. Parse the output to show what has drifted.

Report format:
```
Schema Drift:
  Table "task":
    - Column "priority" exists in model but not in database
    - Column "legacy_field" exists in database but not in model
  No drift detected for: user, project, comment
```

If the database is not reachable, skip this check and note it:
```
Schema Drift: SKIPPED (database not reachable)
```

#### Check 6: Migration Health
Verify migration chain integrity:
```bash
alembic heads
alembic branches
```
- Flag if there are multiple heads (needs merge migration)
- Flag if there are unresolved branch points

Report format:
```
Migration Health:
  Heads: 1 (healthy)
  Branches: none
  Current: {revision}
```

### Step 3: Generate Summary

Compile all checks into a summary report:

```
Schema Check Results
====================

Foreign Key Indexes:   {X issues / All OK}
N+1 Query Patterns:    {X patterns found / None detected}
Unused Columns:        {X candidates / None detected}
Missing Constraints:   {X suggestions / All OK}
Schema Drift:          {X differences / In sync / Skipped}
Migration Health:      {Healthy / X issues}

{If issues found:}
Priority Fixes:
1. {Most critical issue and how to fix it}
2. {Second issue}
3. {Third issue}
```

### Step 4: Error Handling

If model files cannot be parsed:
```
Could not parse: app/models/{file}.py
  - Reason: {error}
  - Skipping this model for analysis
```

If the check completes with issues:
```
{count} issues found. Run /db:migrate create after fixing model changes.
```

If everything passes:
```
All schema checks passed. No issues detected.
```
