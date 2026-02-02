# Database Patterns

Standard database patterns for Python+FastAPI projects using SQLAlchemy + Alembic + PostgreSQL.

## SQLAlchemy Model Conventions

### Declarative Base

```python
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy import String, DateTime, func
from datetime import datetime
import uuid


class Base(DeclarativeBase):
    pass
```

### Timestamp Mixin

Every table gets created_at and updated_at automatically:

```python
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import DateTime, func
from datetime import datetime


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
```

### Soft Delete Mixin

For entities that should never be permanently removed:

```python
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import DateTime
from datetime import datetime
from typing import Optional


class SoftDeleteMixin:
    deleted_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
        default=None,
    )

    @property
    def is_deleted(self) -> bool:
        return self.deleted_at is not None
```

### UUID Primary Key Mixin

```python
import uuid
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID


class UUIDPrimaryKeyMixin:
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
```

### Complete Model Example

```python
from app.core.database import Base
from app.models.mixins import TimestampMixin, SoftDeleteMixin, UUIDPrimaryKeyMixin
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import String, ForeignKey
import uuid


class Project(UUIDPrimaryKeyMixin, TimestampMixin, SoftDeleteMixin, Base):
    __tablename__ = "project"

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    slug: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("user.id"), nullable=False)

    # Relationships
    owner: Mapped["User"] = relationship(back_populates="projects", lazy="selectin")
    tasks: Mapped[list["Task"]] = relationship(back_populates="project", lazy="selectin")
```

## Naming Conventions

### Tables
- **snake_case**, singular: `user`, `project`, `task_comment`
- Never pluralize: `user` not `users`
- Join tables: `{table_a}_{table_b}` alphabetically: `project_user`

### Columns
- **snake_case**: `first_name`, `created_at`
- Foreign keys: `{referenced_table}_id`: `user_id`, `project_id`
- Boolean columns: `is_` or `has_` prefix: `is_active`, `has_verified_email`

### Constraints and Indexes
Set naming convention on metadata so Alembic generates consistent names:

```python
from sqlalchemy import MetaData

convention = {
    "ix": "ix_%(column_0_label)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}

metadata = MetaData(naming_convention=convention)


class Base(DeclarativeBase):
    metadata = metadata
```

## Alembic Migration Patterns

### Auto-Generate from Model Changes

```bash
# After modifying models
alembic revision --autogenerate -m "add project table"
```

Always review the generated migration before applying. Auto-generate detects:
- Table creation/deletion
- Column addition/removal/type changes
- Index and constraint changes

Auto-generate does NOT detect:
- Table or column renames (shows as drop+create)
- Data migrations
- Changes to column data

### Manual Migrations

Use for data migrations, renames, or complex operations:

```bash
alembic revision -m "backfill user display names"
```

```python
def upgrade():
    # Use op.execute for raw SQL data migrations
    op.execute("""
        UPDATE "user"
        SET display_name = first_name || ' ' || last_name
        WHERE display_name IS NULL
    """)


def downgrade():
    op.execute("""
        UPDATE "user"
        SET display_name = NULL
    """)
```

### Data Migrations

For large tables, batch the updates:

```python
from alembic import op
import sqlalchemy as sa


def upgrade():
    conn = op.get_bind()
    # Process in batches of 1000
    while True:
        result = conn.execute(sa.text("""
            UPDATE "user"
            SET status = 'active'
            WHERE status IS NULL
            LIMIT 1000
        """))
        if result.rowcount == 0:
            break
```

### Migration Best Practices
- One logical change per migration
- Always write downgrade functions
- Test migrations on a copy of production data
- Never edit a migration that has been applied to shared environments
- Use `alembic stamp head` to mark DB as current without running migrations

## Index Strategies

### When to Add Indexes
- Every foreign key column (always)
- Columns used in WHERE clauses frequently
- Columns used in ORDER BY
- Columns used in JOIN conditions
- Unique constraints (automatically indexed)

### Composite Indexes

Order columns by selectivity (most selective first):

```python
from sqlalchemy import Index

class Task(Base):
    __tablename__ = "task"
    __table_args__ = (
        Index("ix_task_project_id_status", "project_id", "status"),
        Index("ix_task_assignee_id_due_date", "assignee_id", "due_date"),
    )
```

### Partial Indexes

Index only rows that matter:

```python
from sqlalchemy import Index

class Task(Base):
    __table_args__ = (
        # Only index non-deleted tasks
        Index(
            "ix_task_active_status",
            "status",
            postgresql_where=sa.text("deleted_at IS NULL"),
        ),
    )
```

### GIN Indexes for JSONB and Full-Text

```python
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy import Index

class Document(Base):
    __tablename__ = "document"

    metadata_json: Mapped[dict] = mapped_column(JSONB, default={})

    __table_args__ = (
        Index("ix_document_metadata", "metadata_json", postgresql_using="gin"),
    )
```

## Query Optimization

### Eager Loading vs Lazy Loading

Default to `lazy="selectin"` for relationships you always need. Use explicit loading for optional relationships:

```python
from sqlalchemy.orm import selectinload, joinedload

# selectinload: Separate SELECT IN query (good for collections)
stmt = select(Project).options(selectinload(Project.tasks))

# joinedload: JOIN in same query (good for single related objects)
stmt = select(Task).options(joinedload(Task.assignee))
```

### N+1 Prevention

Never access relationships in a loop without eager loading:

```python
# BAD: N+1 queries
projects = session.scalars(select(Project)).all()
for project in projects:
    print(project.owner.name)  # Triggers a query per project

# GOOD: Eager load
projects = session.scalars(
    select(Project).options(selectinload(Project.owner))
).all()
for project in projects:
    print(project.owner.name)  # No additional queries
```

### Pagination

Cursor-based for large datasets, offset for admin/simple cases:

```python
from sqlalchemy import select


# Cursor-based pagination (preferred)
async def get_tasks_cursor(
    session: AsyncSession,
    after_id: uuid.UUID | None = None,
    limit: int = 20,
) -> list[Task]:
    stmt = select(Task).order_by(Task.created_at.desc(), Task.id.desc())
    if after_id:
        cursor_task = await session.get(Task, after_id)
        if cursor_task:
            stmt = stmt.where(
                sa.or_(
                    Task.created_at < cursor_task.created_at,
                    sa.and_(
                        Task.created_at == cursor_task.created_at,
                        Task.id < cursor_task.id,
                    ),
                )
            )
    stmt = stmt.limit(limit + 1)  # Fetch one extra to detect has_next
    results = (await session.scalars(stmt)).all()
    has_next = len(results) > limit
    return results[:limit], has_next


# Offset-based pagination (simple cases)
async def get_tasks_offset(
    session: AsyncSession,
    page: int = 1,
    page_size: int = 20,
) -> tuple[list[Task], int]:
    offset = (page - 1) * page_size
    stmt = select(Task).offset(offset).limit(page_size)
    total = await session.scalar(select(func.count(Task.id)))
    results = (await session.scalars(stmt)).all()
    return results, total
```

## Connection Pooling

### SQLAlchemy Async Engine with asyncpg

```python
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession

engine = create_async_engine(
    "postgresql+asyncpg://user:pass@localhost:5432/dbname",
    pool_size=20,          # Persistent connections
    max_overflow=10,       # Extra connections under load
    pool_timeout=30,       # Seconds to wait for connection
    pool_recycle=1800,     # Recycle connections after 30 min
    pool_pre_ping=True,    # Verify connections before use
    echo=False,            # Set True for SQL logging in dev
)

AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)
```

### Session Dependency for FastAPI

```python
from typing import AsyncGenerator


async def get_session() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
```

## Repository Pattern

Encapsulate data access behind repository classes:

```python
from typing import Generic, TypeVar, Type
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import Base
import uuid

ModelType = TypeVar("ModelType", bound=Base)


class BaseRepository(Generic[ModelType]):
    def __init__(self, model: Type[ModelType], session: AsyncSession):
        self.model = model
        self.session = session

    async def get_by_id(self, id: uuid.UUID) -> ModelType | None:
        return await self.session.get(self.model, id)

    async def get_all(self, skip: int = 0, limit: int = 100) -> list[ModelType]:
        stmt = select(self.model).offset(skip).limit(limit)
        result = await self.session.scalars(stmt)
        return list(result.all())

    async def create(self, obj: ModelType) -> ModelType:
        self.session.add(obj)
        await self.session.flush()
        await self.session.refresh(obj)
        return obj

    async def update(self, obj: ModelType, data: dict) -> ModelType:
        for key, value in data.items():
            setattr(obj, key, value)
        await self.session.flush()
        await self.session.refresh(obj)
        return obj

    async def delete(self, obj: ModelType) -> None:
        await self.session.delete(obj)
        await self.session.flush()


class ProjectRepository(BaseRepository["Project"]):
    def __init__(self, session: AsyncSession):
        super().__init__(Project, session)

    async def get_by_slug(self, slug: str) -> "Project | None":
        stmt = select(Project).where(Project.slug == slug)
        return await self.session.scalar(stmt)

    async def get_by_owner(self, owner_id: uuid.UUID) -> list["Project"]:
        stmt = select(Project).where(Project.owner_id == owner_id)
        result = await self.session.scalars(stmt)
        return list(result.all())
```

## Transaction Management

### Implicit Transactions via Session Dependency

The `get_session` dependency above auto-commits on success and rolls back on exception. This is the default pattern.

### Explicit Nested Transactions (Savepoints)

For operations that need partial rollback:

```python
async def transfer_ownership(
    session: AsyncSession,
    project_id: uuid.UUID,
    new_owner_id: uuid.UUID,
) -> None:
    async with session.begin_nested():
        project = await session.get(Project, project_id)
        project.owner_id = new_owner_id

    async with session.begin_nested():
        # If this fails, only this savepoint rolls back
        await notify_new_owner(session, new_owner_id, project_id)
```

### Unit of Work Pattern

Group related operations in a service method that runs within a single session:

```python
class ProjectService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.project_repo = ProjectRepository(session)

    async def create_project_with_defaults(self, name: str, owner_id: uuid.UUID) -> Project:
        # All operations share the same session/transaction
        project = Project(name=name, slug=slugify(name), owner_id=owner_id)
        project = await self.project_repo.create(project)

        # Create default task board
        board = TaskBoard(project_id=project.id, name="Default")
        self.session.add(board)

        # Create default columns
        for idx, col_name in enumerate(["To Do", "In Progress", "Done"]):
            column = BoardColumn(board_id=board.id, name=col_name, position=idx)
            self.session.add(column)

        await self.session.flush()
        return project
```

## Rules Summary

1. Always use mixins for timestamps and soft-delete
2. Always use UUID primary keys
3. Set naming conventions on metadata
4. One logical change per migration
5. Always review auto-generated migrations
6. Index every foreign key column
7. Use `selectinload` for collections, `joinedload` for single objects
8. Use cursor-based pagination for user-facing endpoints
9. Configure connection pooling with `pool_pre_ping=True`
10. Use the repository pattern to encapsulate data access
11. Let the session dependency manage transaction boundaries
