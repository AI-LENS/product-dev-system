# Backend Patterns

Python+FastAPI backend patterns and project structure standards.

## Project Structure

```
app/
  __init__.py
  main.py                     # FastAPI app factory, middleware, startup/shutdown
  core/
    __init__.py
    config.py                 # Settings via pydantic-settings
    database.py               # Engine, session factory, Base
    security.py               # Auth utilities, JWT, password hashing
    exceptions.py             # Custom exception classes
    logging.py                # structlog configuration
  models/
    __init__.py               # Re-export all models for Alembic
    mixins.py                 # TimestampMixin, SoftDeleteMixin, UUIDPrimaryKeyMixin
    user.py                   # One file per domain entity
    project.py
    task.py
  schemas/
    __init__.py
    common.py                 # Shared schemas: PaginationParams, ErrorResponse
    user.py                   # UserCreate, UserUpdate, UserResponse
    project.py
    task.py
  repositories/
    __init__.py
    base.py                   # BaseRepository generic class
    user_repository.py
    project_repository.py
    task_repository.py
  services/
    __init__.py
    user_service.py           # Business logic, orchestrates repositories
    project_service.py
    task_service.py
  routers/
    __init__.py
    health.py                 # Health check endpoint
    user.py                   # Route handlers, thin layer
    project.py
    task.py
  middleware/
    __init__.py
    logging.py                # Request/response logging
    timing.py                 # Request duration tracking
    error_handler.py          # Global exception handler
alembic/
  env.py
  versions/
tests/
  __init__.py
  conftest.py                 # Shared fixtures, test DB setup
  test_user.py
  test_project.py
  test_task.py
```

## Dependency Injection

Use FastAPI's `Depends()` to inject services and sessions:

```python
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_session
from app.services.project_service import ProjectService
from app.repositories.project_repository import ProjectRepository


def get_project_repository(
    session: AsyncSession = Depends(get_session),
) -> ProjectRepository:
    return ProjectRepository(session)


def get_project_service(
    repo: ProjectRepository = Depends(get_project_repository),
) -> ProjectService:
    return ProjectService(repo)


# In router
@router.get("/projects/{project_id}")
async def get_project(
    project_id: uuid.UUID,
    service: ProjectService = Depends(get_project_service),
) -> ProjectResponse:
    return await service.get_project(project_id)
```

### Dependency Chain
```
Router -> Service -> Repository -> Session
```
- **Router**: HTTP concerns only (parse request, return response)
- **Service**: Business logic, validation, orchestration
- **Repository**: Data access, queries
- **Session**: Database connection (auto-managed)

## Pydantic Schemas

### Naming Convention
- `{Entity}Create` — POST request body
- `{Entity}Update` — PATCH request body (all fields optional)
- `{Entity}Response` — Response body
- `{Entity}ListResponse` — Paginated list response

### Schema Patterns

```python
from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime
import uuid


class ProjectBase(BaseModel):
    """Shared fields between create and response."""
    name: str = Field(..., min_length=1, max_length=255)
    description: str | None = Field(None, max_length=2000)


class ProjectCreate(ProjectBase):
    """Fields required to create a project."""
    slug: str = Field(..., pattern=r"^[a-z0-9]+(?:-[a-z0-9]+)*$", max_length=255)


class ProjectUpdate(BaseModel):
    """All fields optional for partial update."""
    name: str | None = Field(None, min_length=1, max_length=255)
    description: str | None = Field(None, max_length=2000)


class ProjectResponse(ProjectBase):
    """Full project representation for API responses."""
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    slug: str
    owner_id: uuid.UUID
    created_at: datetime
    updated_at: datetime


class ProjectListResponse(BaseModel):
    """Paginated list of projects."""
    data: list[ProjectResponse]
    pagination: PaginationMeta
```

### Common Schemas

```python
class PaginationParams(BaseModel):
    """Query parameters for pagination."""
    limit: int = Field(20, ge=1, le=100)
    after: str | None = None  # Cursor for cursor-based pagination
    page: int | None = Field(None, ge=1)  # For offset-based pagination


class PaginationMeta(BaseModel):
    """Pagination metadata in responses."""
    has_next: bool
    next_cursor: str | None = None
    limit: int
    total: int | None = None  # Only for offset-based


class ErrorDetail(BaseModel):
    field: str | None = None
    message: str
    value: str | None = None


class ErrorResponse(BaseModel):
    code: str
    message: str
    details: list[ErrorDetail] = []
```

## Async Patterns

### Async Endpoints

All endpoints should be `async def`:

```python
@router.get("/projects")
async def list_projects(
    pagination: PaginationParams = Depends(),
    service: ProjectService = Depends(get_project_service),
) -> ProjectListResponse:
    projects, meta = await service.list_projects(pagination)
    return ProjectListResponse(
        data=[ProjectResponse.model_validate(p) for p in projects],
        pagination=meta,
    )
```

### Async Database Queries

Use `AsyncSession` for all database operations:

```python
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select


async def get_active_projects(session: AsyncSession) -> list[Project]:
    stmt = select(Project).where(Project.deleted_at.is_(None))
    result = await session.scalars(stmt)
    return list(result.all())
```

### When to Use sync vs async
- **Always async**: Database queries, HTTP calls, file I/O
- **Sync is OK**: CPU-bound computation (but offload to thread pool if heavy)

```python
import asyncio
from functools import partial


# Heavy CPU work — offload to thread pool
@router.post("/reports/generate")
async def generate_report(params: ReportParams):
    result = await asyncio.get_event_loop().run_in_executor(
        None, partial(compute_heavy_report, params)
    )
    return result
```

## Middleware Patterns

### Request Logging

```python
import structlog
import time
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

logger = structlog.get_logger()


class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start_time = time.perf_counter()

        response = await call_next(request)

        duration_ms = (time.perf_counter() - start_time) * 1000
        logger.info(
            "request_completed",
            method=request.method,
            path=request.url.path,
            status_code=response.status_code,
            duration_ms=round(duration_ms, 2),
        )
        response.headers["X-Request-Duration-Ms"] = str(round(duration_ms, 2))
        return response
```

### Request Timing

```python
class TimingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start = time.perf_counter()
        response = await call_next(request)
        duration = time.perf_counter() - start
        response.headers["X-Process-Time"] = f"{duration:.4f}"
        return response
```

### Middleware Registration Order

```python
# main.py — order matters, outermost first
app.add_middleware(CORSMiddleware, ...)     # CORS first
app.add_middleware(LoggingMiddleware)        # Logging wraps everything
app.add_middleware(TimingMiddleware)         # Timing inside logging
```

## Exception Handling

### Custom Exceptions

```python
# app/core/exceptions.py

class AppException(Exception):
    """Base application exception."""
    def __init__(self, message: str, code: str = "INTERNAL_ERROR"):
        self.message = message
        self.code = code
        super().__init__(message)


class NotFoundError(AppException):
    def __init__(self, resource: str, identifier: str):
        super().__init__(
            message=f"{resource} not found: {identifier}",
            code="NOT_FOUND",
        )


class ConflictError(AppException):
    def __init__(self, message: str):
        super().__init__(message=message, code="CONFLICT")


class ForbiddenError(AppException):
    def __init__(self, message: str = "Insufficient permissions"):
        super().__init__(message=message, code="FORBIDDEN")


class ValidationError(AppException):
    def __init__(self, message: str, details: list[dict] | None = None):
        self.details = details or []
        super().__init__(message=message, code="VALIDATION_ERROR")
```

### Global Exception Handler

```python
# app/middleware/error_handler.py
from fastapi import Request
from fastapi.responses import JSONResponse
from app.core.exceptions import AppException, NotFoundError, ForbiddenError
import structlog

logger = structlog.get_logger()

STATUS_MAP = {
    "NOT_FOUND": 404,
    "CONFLICT": 409,
    "FORBIDDEN": 403,
    "VALIDATION_ERROR": 422,
    "UNAUTHORIZED": 401,
    "INTERNAL_ERROR": 500,
}


async def app_exception_handler(request: Request, exc: AppException) -> JSONResponse:
    status_code = STATUS_MAP.get(exc.code, 500)

    if status_code >= 500:
        logger.error("unhandled_error", error=str(exc), path=request.url.path)

    return JSONResponse(
        status_code=status_code,
        content={
            "error": {
                "code": exc.code,
                "message": exc.message,
                "details": getattr(exc, "details", []),
            }
        },
    )


# Register in main.py
app.add_exception_handler(AppException, app_exception_handler)
```

## Logging with structlog

### Configuration

```python
# app/core/logging.py
import structlog
import logging


def setup_logging(log_level: str = "INFO") -> None:
    structlog.configure(
        processors=[
            structlog.contextvars.merge_contextvars,
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.stdlib.PositionalArgumentsFormatter(),
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.UnicodeDecoder(),
            structlog.processors.JSONRenderer(),  # JSON in production
        ],
        wrapper_class=structlog.stdlib.BoundLogger,
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        cache_logger_on_first_use=True,
    )
    logging.basicConfig(level=getattr(logging, log_level))
```

### Usage

```python
import structlog

logger = structlog.get_logger()

# Structured logging with context
logger.info("project_created", project_id=str(project.id), name=project.name)
logger.warning("rate_limit_approaching", user_id=str(user.id), remaining=5)
logger.error("payment_failed", order_id=str(order.id), error=str(exc))
```

## Settings Management

### pydantic-settings Configuration

```python
# app/core/config.py
from pydantic_settings import BaseSettings
from pydantic import Field


class Settings(BaseSettings):
    # Application
    app_name: str = "MyApp"
    app_env: str = Field("development", alias="APP_ENV")
    debug: bool = False
    log_level: str = "INFO"

    # Database
    database_url: str = Field(..., alias="DATABASE_URL")
    db_pool_size: int = 20
    db_max_overflow: int = 10

    # Auth
    secret_key: str = Field(..., alias="SECRET_KEY")
    access_token_expire_minutes: int = 30

    # CORS
    cors_origins: list[str] = ["http://localhost:4200"]

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


settings = Settings()
```

### Usage

```python
from app.core.config import settings

engine = create_async_engine(
    settings.database_url,
    pool_size=settings.db_pool_size,
)
```

## Background Tasks

### FastAPI BackgroundTasks

For lightweight tasks that do not need a task queue:

```python
from fastapi import BackgroundTasks


async def send_welcome_email(email: str, name: str) -> None:
    # Send email logic
    ...


@router.post("/users", status_code=201)
async def create_user(
    user_data: UserCreate,
    background_tasks: BackgroundTasks,
    service: UserService = Depends(get_user_service),
) -> UserResponse:
    user = await service.create_user(user_data)
    background_tasks.add_task(send_welcome_email, user.email, user.name)
    return UserResponse.model_validate(user)
```

### When to Use BackgroundTasks vs Task Queue
- **BackgroundTasks**: Email notifications, audit logging, cache invalidation
- **Task Queue (Celery/ARQ)**: Heavy computation, external API calls with retries, scheduled jobs

## Health Check Endpoint

```python
# app/routers/health.py
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.core.database import get_session

router = APIRouter(tags=["Health"])


@router.get("/api/health")
async def health_check(session: AsyncSession = Depends(get_session)):
    try:
        await session.execute(text("SELECT 1"))
        db_status = "healthy"
    except Exception:
        db_status = "unhealthy"

    return {
        "status": "healthy" if db_status == "healthy" else "degraded",
        "database": db_status,
    }
```

## Rules Summary

1. Follow the standard project structure (routers/services/repositories/schemas/models)
2. Use dependency injection via `Depends()` for all dependencies
3. Keep routers thin — business logic goes in services
4. Use Pydantic schemas for all request/response validation
5. All endpoints are `async def`
6. Custom exceptions with global handler — never raise raw HTTPException in services
7. Structured logging with structlog — never use `print()`
8. Settings via pydantic-settings — never hardcode configuration
9. BackgroundTasks for lightweight async work, task queue for heavy jobs
10. Every app needs a `/api/health` endpoint
