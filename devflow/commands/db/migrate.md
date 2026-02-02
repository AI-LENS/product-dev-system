---
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
  - LS
---

# Database Migrate

## Usage
```
/db:migrate [action]
```

## Description
Manages Alembic database migrations. Supports creating new migrations, running pending migrations, rolling back, and viewing migration history.

## References
- `devflow/rules/db-patterns.md` — Database patterns and migration standards
- `devflow/agents/db-task-worker.md` — Database task agent

## Actions
- `create` (default if models changed) — Auto-generate migration from model changes
- `up` — Run all pending migrations
- `down` — Rollback the last migration
- `history` — Show migration history and current head
- `check` — Verify migration state without applying changes

## Execution

### Step 1: Detect Alembic Configuration
```bash
test -f alembic.ini || echo "alembic.ini not found"
```
If `alembic.ini` is missing:
```
No alembic.ini found. Initialize Alembic first:
  alembic init alembic
```

### Step 2: Determine Action
Parse the `[action]` argument. If no argument is provided, default to `check`.

### Step 3: Execute Action

#### Action: `create`
1. Check for uncommitted model changes:
   ```bash
   git diff --name-only -- "app/models/"
   ```
2. Auto-generate migration:
   ```bash
   alembic revision --autogenerate -m "{description}"
   ```
   If no description is provided, prompt the user for one.
3. Display the generated migration file for review:
   ```bash
   ls -t alembic/versions/*.py | head -1
   ```
   Read and display the file contents.
4. Ask user to confirm the migration looks correct before considering it done.

Output:
```
Migration created: alembic/versions/{revision}_{slug}.py
  - {summary of detected changes}
Next: Review the migration, then run /db:migrate up
```

#### Action: `up`
1. Show pending migrations:
   ```bash
   alembic history --indicate-current
   ```
2. Run pending migrations:
   ```bash
   alembic upgrade head
   ```
3. Verify current state:
   ```bash
   alembic current
   ```

Output:
```
Migrations applied successfully.
  - Current head: {revision}
  - Migrations run: {count}
```

#### Action: `down`
1. Show current migration:
   ```bash
   alembic current
   ```
2. Rollback one step:
   ```bash
   alembic downgrade -1
   ```
3. Show new current state:
   ```bash
   alembic current
   ```

Output:
```
Rolled back 1 migration.
  - Previous: {old_revision}
  - Current: {new_revision}
Next: Fix issues and run /db:migrate up
```

#### Action: `history`
1. Show full migration history:
   ```bash
   alembic history --verbose
   ```
2. Show current head:
   ```bash
   alembic current
   ```
3. Check for any branch points:
   ```bash
   alembic heads
   ```

Output:
```
Migration History:
  {revision} - {message} (current)
  {revision} - {message}
  {revision} - {message}
  ...
Heads: {count} ({revision list})
```

#### Action: `check`
1. Show current state:
   ```bash
   alembic current
   ```
2. Check for pending migrations:
   ```bash
   alembic check 2>&1 || true
   ```
3. Check for model changes not yet in a migration:
   ```bash
   alembic revision --autogenerate -m "check" --sql 2>&1 | head -20
   ```
   Do NOT write the migration file. Use the output to detect pending changes.

Output:
```
Migration Status:
  - Current: {revision}
  - Pending migrations: {count or "none"}
  - Untracked model changes: {yes/no with details}
```

### Step 4: Error Handling

If any migration command fails:
```
Migration failed: {error message}
  - Check: {specific suggestion based on error}
  - Common fixes:
    - Duplicate column: Remove from migration or check model
    - Connection refused: Verify DATABASE_URL in .env
    - Import error: Check model imports in alembic/env.py
```
