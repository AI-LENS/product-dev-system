---
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
  - LS
---

# Database Seed

## Usage
```
/db:seed [environment]
```

## Description
Creates and runs seed data scripts for the database. Environment-aware: uses dev seeds for local development and test seeds for testing. All seeds are idempotent — safe to run multiple times.

## References
- `devflow/rules/db-patterns.md` — Database patterns and repository usage
- `devflow/agents/db-task-worker.md` — Database task agent

## Arguments
- `dev` (default) — Run development seed data
- `test` — Run test fixture seed data
- `create <name>` — Create a new seed script
- `reset` — Drop all data and re-seed (dev environment only)

## Execution

### Step 1: Verify Seed Directory Structure
```bash
mkdir -p app/seeds/dev app/seeds/test
```

Check for the seed runner script:
```bash
test -f app/seeds/runner.py
```

If `runner.py` does not exist, create it:

```python
"""Seed runner — executes seed scripts in order."""
import asyncio
import importlib
import pkgutil
from pathlib import Path
from app.core.database import AsyncSessionLocal


async def run_seeds(environment: str = "dev") -> None:
    seed_dir = Path(__file__).parent / environment
    if not seed_dir.exists():
        print(f"No seed directory found: {seed_dir}")
        return

    modules = sorted(
        [name for _, name, _ in pkgutil.iter_modules([str(seed_dir)])],
    )

    async with AsyncSessionLocal() as session:
        for module_name in modules:
            module = importlib.import_module(f"app.seeds.{environment}.{module_name}")
            if hasattr(module, "seed"):
                print(f"  Seeding: {module_name}...")
                await module.seed(session)
                await session.commit()
                print(f"  Done: {module_name}")

    print(f"All {environment} seeds complete.")


if __name__ == "__main__":
    import sys
    env = sys.argv[1] if len(sys.argv) > 1 else "dev"
    asyncio.run(run_seeds(env))
```

### Step 2: Execute Action

#### Action: `dev` or `test` (run seeds)
1. Verify database is reachable:
   ```bash
   python -c "from app.core.database import engine; print('DB OK')" 2>&1
   ```
2. Run the seed runner:
   ```bash
   python -m app.seeds.runner {environment}
   ```

Output:
```
Seeding {environment} data...
  Seeding: 001_users...
  Done: 001_users
  Seeding: 002_projects...
  Done: 002_projects
All {environment} seeds complete.
```

#### Action: `create <name>`
1. Determine the next sequence number by listing existing seeds:
   ```bash
   ls app/seeds/dev/ 2>/dev/null | sort | tail -1
   ```
2. Create the seed file at `app/seeds/dev/{NNN}_{name}.py`:

```python
"""Seed: {name}"""
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.{name} import {ModelName}


async def seed(session: AsyncSession) -> None:
    """Seed {name} data. Idempotent — checks before inserting."""

    items = [
        # Add seed data here
        # {"field": "value", ...},
    ]

    for item_data in items:
        # Check if already exists (idempotent)
        existing = await session.scalar(
            select({ModelName}).where(
                {ModelName}.{unique_field} == item_data["{unique_field}"]
            )
        )
        if existing is None:
            obj = {ModelName}(**item_data)
            session.add(obj)
```

Output:
```
Seed created: app/seeds/dev/{NNN}_{name}.py
Next: Edit the seed file to add your data, then run /db:seed
```

#### Action: `reset`
1. Confirm this is not a production environment:
   ```bash
   echo $APP_ENV
   ```
   If `APP_ENV` is `production` or `prod`:
   ```
   Seed reset is disabled in production. This would delete all data.
   ```
   Stop execution.

2. Drop all data (truncate tables in reverse dependency order):
   ```bash
   python -c "
   import asyncio
   from app.core.database import engine
   from sqlalchemy import text

   async def reset():
       async with engine.begin() as conn:
           await conn.execute(text('TRUNCATE TABLE {} CASCADE'.format(
               ', '.join(reversed(table_names))
           )))
   asyncio.run(reset())
   "
   ```
3. Re-run dev seeds:
   ```bash
   python -m app.seeds.runner dev
   ```

Output:
```
Database reset complete.
  - Tables truncated: {count}
  - Dev seeds applied: {count}
```

### Step 3: Seed Script Conventions

All seed scripts must follow these patterns:

1. **Idempotent**: Check if data exists before inserting
   ```python
   existing = await session.scalar(
       select(User).where(User.email == "admin@example.com")
   )
   if existing is None:
       session.add(User(email="admin@example.com", ...))
   ```

2. **Ordered**: Prefix files with three-digit numbers: `001_users.py`, `002_projects.py`

3. **Respect foreign keys**: Seed parent tables before child tables

4. **Use realistic data**: Dev seeds should contain data useful for manual testing

5. **Use minimal data**: Test seeds should contain the minimum data needed for tests

### Step 4: Error Handling

If seeding fails:
```
Seed failed: {error message}
  - Failed at: {seed_file}
  - Error: {details}
  - Fix: Check the seed file for data conflicts or missing dependencies
  - Hint: Run /db:migrate up first if you see missing table errors
```
