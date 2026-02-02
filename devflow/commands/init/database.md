---
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - LS
---

# Database Initialization

## Usage
```
/init:database
```

## Description
Sets up the database layer for a Python + FastAPI project using SQLAlchemy as the ORM and Alembic for migrations. Creates the models directory structure, base model class with common fields, Alembic configuration, initial migration, and seed data scaffold.

## Prerequisites
- Project has been scaffolded (via `/init:project` or manually)
- `backend/` directory exists with `app/` package
- Python environment has `sqlalchemy`, `alembic`, `asyncpg`, and `pydantic-settings` installed
- PostgreSQL connection details available (or `.env` file configured)

If prerequisites are not met:
```
❌ backend/app/ not found. Run /init:project first.
```

## Execution

### Step 1: Verify Project Structure
```bash
test -d backend/app || echo "MISSING_BACKEND"
test -f backend/app/config.py || echo "MISSING_CONFIG"
```

### Step 2: Create Database Core Module

#### backend/app/core/database.py
If this file does not already exist, create it:
```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from app.config import settings

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG if hasattr(settings, "DEBUG") else False,
    pool_size=5,
    max_overflow=10,
    pool_pre_ping=True,
)

async_session = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    pass


async def get_db() -> AsyncSession:
    async with async_session() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def init_db():
    """Create all tables. Use only for testing — prefer Alembic migrations in production."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
```

### Step 3: Create Base Model with Common Fields

#### backend/app/models/base.py
```python
from datetime import datetime, timezone
from sqlalchemy import Column, DateTime, Integer
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base


class TimestampMixin:
    """Mixin that adds id, created_at, and updated_at to any model."""

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
```

#### backend/app/models/__init__.py
```python
from app.models.base import TimestampMixin
from app.core.database import Base

__all__ = ["Base", "TimestampMixin"]
```

### Step 4: Set Up Alembic

#### Initialize Alembic directory
```bash
mkdir -p backend/alembic/versions
```

#### backend/alembic.ini
```ini
[alembic]
script_location = alembic
prepend_sys_path = .
sqlalchemy.url = driver://user:pass@localhost/dbname

[post_write_hooks]

[loggers]
keys = root,sqlalchemy,alembic

[handlers]
keys = console

[formatters]
keys = generic

[logger_root]
level = WARN
handlers = console

[logger_sqlalchemy]
level = WARN
handlers =
qualname = sqlalchemy.engine

[logger_alembic]
level = INFO
handlers =
qualname = alembic

[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = NOTSET
formatter = generic

[formatter_generic]
format = %(levelname)-5.5s [%(name)s] %(message)s
datefmt = %H:%M:%S
```

#### backend/alembic/env.py
```python
import asyncio
from logging.config import fileConfig

from sqlalchemy import pool
from sqlalchemy.ext.asyncio import async_engine_from_config
from alembic import context

# Import your models so Alembic can detect them
from app.core.database import Base
from app.config import settings

# Import all model modules here so they register with Base.metadata
# from app.models.user import User  # uncomment as models are added

config = context.config
config.set_main_option("sqlalchemy.url", settings.DATABASE_URL)

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection) -> None:
    context.configure(connection=connection, target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    """Run migrations in 'online' mode with async engine."""
    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)
    await connectable.dispose()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode."""
    asyncio.run(run_async_migrations())


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
```

#### backend/alembic/script.py.mako
```mako
"""${message}

Revision ID: ${up_revision}
Revises: ${down_revision | comma,n}
Create Date: ${create_date}

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
${imports if imports else ""}

# revision identifiers, used by Alembic.
revision: str = ${repr(up_revision)}
down_revision: Union[str, None] = ${repr(down_revision)}
branch_labels: Union[str, Sequence[str], None] = ${repr(branch_labels)}
depends_on: Union[str, Sequence[str], None] = ${repr(depends_on)}


def upgrade() -> None:
    ${upgrades if upgrades else "pass"}


def downgrade() -> None:
    ${downgrades if downgrades else "pass"}
```

### Step 5: Create Seed Data Scaffold

#### backend/app/core/seed.py
```python
"""
Seed data for development and testing environments.

Usage:
    python -m app.core.seed

This module populates the database with initial data for development.
It is idempotent — running it multiple times will not create duplicates.
"""

import asyncio
from sqlalchemy import select
from app.core.database import async_session, init_db


async def seed_data():
    """Populate database with seed data."""
    await init_db()

    async with async_session() as session:
        # Example: seed default roles, categories, or config values
        # from app.models.user import User
        #
        # existing = await session.execute(select(User).where(User.email == "admin@example.com"))
        # if not existing.scalar_one_or_none():
        #     admin = User(
        #         email="admin@example.com",
        #         hashed_password="...",
        #         is_active=True,
        #         role="admin",
        #     )
        #     session.add(admin)
        #     await session.commit()
        #     print("Seeded admin user")

        print("Seed data applied successfully")


if __name__ == "__main__":
    asyncio.run(seed_data())
```

### Step 6: Update .env.example
Ensure the `.env.example` at the project root includes database configuration:
```env
# Database
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/{project_name}
DATABASE_ECHO=false

# For running Alembic CLI directly (sync driver)
ALEMBIC_DATABASE_URL=postgresql://postgres:postgres@localhost:5432/{project_name}
```

If `.env.example` already exists, append these lines only if they are missing.

### Step 7: Create Initial Migration
Instruct the user to generate the initial migration:
```bash
cd backend
alembic revision --autogenerate -m "initial schema"
```

Note: This requires the database to be running. If using docker-compose:
```bash
docker-compose up -d db
```

### Step 8: Output
```
✅ Database layer initialized
  - ORM: SQLAlchemy (async)
  - Migrations: Alembic
  - Base model: TimestampMixin (id, created_at, updated_at)
  - Seed scaffold: backend/app/core/seed.py

Files created/updated:
  - backend/app/core/database.py
  - backend/app/models/base.py
  - backend/app/models/__init__.py
  - backend/app/core/seed.py
  - backend/alembic.ini
  - backend/alembic/env.py
  - backend/alembic/script.py.mako
  - backend/alembic/versions/ (empty, ready for migrations)

Next steps:
  1. Start database: docker-compose up -d db
  2. Generate initial migration: cd backend && alembic revision --autogenerate -m "initial schema"
  3. Apply migration: cd backend && alembic upgrade head
  4. Add models in backend/app/models/ — import them in alembic/env.py
  5. Run /init:auth to add user model and auth endpoints
```
