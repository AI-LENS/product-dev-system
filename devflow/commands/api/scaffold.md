---
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - LS
---

# API Scaffold

## Usage
```
/api:scaffold <resource>
```

## Description
Scaffolds a complete FastAPI CRUD endpoint stack for a given resource. Creates the router, service, Pydantic schemas, repository, and test file following project conventions.

## References
- `devflow/rules/api-design.md` — REST API conventions
- `devflow/rules/backend-patterns.md` — Backend project structure
- `devflow/rules/db-patterns.md` — Repository and database patterns
- `devflow/agents/api-task-worker.md` — API task agent

## Execution

### Step 1: Parse Input
Extract the resource name from the argument:
```
Resource = <resource> argument provided by user
```
If no argument is provided:
```
Missing resource name. Usage: /api:scaffold project
```

Derive naming variants:
- `snake_case`: the resource as-is (e.g., `task_comment`)
- `PascalCase`: for class names (e.g., `TaskComment`)
- `kebab-case`: for URLs (e.g., `task-comments`)
- `plural`: for collection URLs (e.g., `task_comments`)

### Step 2: Check for Existing Model
```bash
test -f app/models/{resource}.py && echo "exists" || echo "missing"
```

If the model file exists, read it to understand the fields. Use the model's columns to auto-populate schema fields.

If the model does not exist, create the scaffold with placeholder fields and note that the model needs to be created.

### Step 3: Check for Existing Files
Before creating any file, check if it already exists:
```bash
test -f app/routers/{resource}.py && echo "Router exists"
test -f app/services/{resource}_service.py && echo "Service exists"
test -f app/schemas/{resource}.py && echo "Schema exists"
test -f app/repositories/{resource}_repository.py && echo "Repository exists"
test -f tests/test_{resource}.py && echo "Test exists"
```
If any file exists, skip it and note it in the output. Never overwrite existing files.

### Step 4: Create Schema File
Create `app/schemas/{resource}.py`:

```python
from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime
import uuid


class {PascalCase}Base(BaseModel):
    """Shared fields."""
    name: str = Field(..., min_length=1, max_length=255)
    # TODO: Add fields from model


class {PascalCase}Create({PascalCase}Base):
    """Fields required for creation."""
    pass


class {PascalCase}Update(BaseModel):
    """Partial update — all fields optional."""
    name: str | None = Field(None, min_length=1, max_length=255)
    # TODO: Add optional fields from model


class {PascalCase}Response({PascalCase}Base):
    """API response representation."""
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    created_at: datetime
    updated_at: datetime


class {PascalCase}ListResponse(BaseModel):
    """Paginated list response."""
    data: list[{PascalCase}Response]
    pagination: dict  # Replace with PaginationMeta from app.schemas.common
```

If the model file was found in Step 2, populate fields from the model instead of using placeholders.

### Step 5: Create Repository File
Create `app/repositories/{resource}_repository.py`:

```python
from app.repositories.base import BaseRepository
from app.models.{resource} import {PascalCase}
from sqlalchemy.ext.asyncio import AsyncSession


class {PascalCase}Repository(BaseRepository[{PascalCase}]):
    def __init__(self, session: AsyncSession):
        super().__init__({PascalCase}, session)

    # Add custom query methods as needed
```

If `app/repositories/base.py` does not exist, create it with the `BaseRepository` class from `devflow/rules/db-patterns.md`.

### Step 6: Create Service File
Create `app/services/{resource}_service.py`:

```python
from app.repositories.{resource}_repository import {PascalCase}Repository
from app.schemas.{resource} import {PascalCase}Create, {PascalCase}Update
from app.models.{resource} import {PascalCase}
from app.core.exceptions import NotFoundError
from sqlalchemy.ext.asyncio import AsyncSession
import uuid


class {PascalCase}Service:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.repo = {PascalCase}Repository(session)

    async def get_by_id(self, id: uuid.UUID) -> {PascalCase}:
        result = await self.repo.get_by_id(id)
        if not result:
            raise NotFoundError("{PascalCase}", str(id))
        return result

    async def list(self, skip: int = 0, limit: int = 20) -> list[{PascalCase}]:
        return await self.repo.get_all(skip=skip, limit=limit)

    async def create(self, data: {PascalCase}Create) -> {PascalCase}:
        obj = {PascalCase}(**data.model_dump())
        return await self.repo.create(obj)

    async def update(self, id: uuid.UUID, data: {PascalCase}Update) -> {PascalCase}:
        existing = await self.get_by_id(id)
        update_data = data.model_dump(exclude_unset=True)
        return await self.repo.update(existing, update_data)

    async def delete(self, id: uuid.UUID) -> None:
        existing = await self.get_by_id(id)
        await self.repo.delete(existing)
```

### Step 7: Create Router File
Create `app/routers/{resource}.py`:

```python
from fastapi import APIRouter, Depends, Query, status
from app.schemas.{resource} import (
    {PascalCase}Create,
    {PascalCase}Update,
    {PascalCase}Response,
    {PascalCase}ListResponse,
)
from app.services.{resource}_service import {PascalCase}Service
from app.core.database import get_session
from sqlalchemy.ext.asyncio import AsyncSession
import uuid

router = APIRouter(prefix="/api/v1/{kebab-case-plural}", tags=["{PascalCase}s"])


def get_service(session: AsyncSession = Depends(get_session)) -> {PascalCase}Service:
    return {PascalCase}Service(session)


@router.get(
    "",
    response_model={PascalCase}ListResponse,
    summary="List {resource}s",
)
async def list_{resource}s(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    service: {PascalCase}Service = Depends(get_service),
):
    items = await service.list(skip=skip, limit=limit)
    return {PascalCase}ListResponse(
        data=[{PascalCase}Response.model_validate(i) for i in items],
        pagination={"limit": limit, "has_next": len(items) == limit},
    )


@router.get(
    "/{{{resource}_id}}",
    response_model={PascalCase}Response,
    summary="Get {resource} by ID",
    responses={404: {"description": "{PascalCase} not found"}},
)
async def get_{resource}(
    {resource}_id: uuid.UUID,
    service: {PascalCase}Service = Depends(get_service),
):
    result = await service.get_by_id({resource}_id)
    return {PascalCase}Response.model_validate(result)


@router.post(
    "",
    response_model={PascalCase}Response,
    status_code=status.HTTP_201_CREATED,
    summary="Create {resource}",
)
async def create_{resource}(
    data: {PascalCase}Create,
    service: {PascalCase}Service = Depends(get_service),
):
    result = await service.create(data)
    return {PascalCase}Response.model_validate(result)


@router.patch(
    "/{{{resource}_id}}",
    response_model={PascalCase}Response,
    summary="Update {resource}",
    responses={404: {"description": "{PascalCase} not found"}},
)
async def update_{resource}(
    {resource}_id: uuid.UUID,
    data: {PascalCase}Update,
    service: {PascalCase}Service = Depends(get_service),
):
    result = await service.update({resource}_id, data)
    return {PascalCase}Response.model_validate(result)


@router.delete(
    "/{{{resource}_id}}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete {resource}",
    responses={404: {"description": "{PascalCase} not found"}},
)
async def delete_{resource}(
    {resource}_id: uuid.UUID,
    service: {PascalCase}Service = Depends(get_service),
):
    await service.delete({resource}_id)
```

### Step 8: Create Test File
Create `tests/test_{resource}.py`:

```python
import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.mark.asyncio
async def test_create_{resource}(client: AsyncClient):
    response = await client.post(
        "/api/v1/{kebab-case-plural}",
        json={"name": "Test {PascalCase}"},
    )
    assert response.status_code == 201
    data = response.json()
    assert "id" in data
    assert data["name"] == "Test {PascalCase}"


@pytest.mark.asyncio
async def test_list_{resource}s(client: AsyncClient):
    response = await client.get("/api/v1/{kebab-case-plural}")
    assert response.status_code == 200
    data = response.json()
    assert "data" in data
    assert "pagination" in data


@pytest.mark.asyncio
async def test_get_{resource}_not_found(client: AsyncClient):
    response = await client.get(
        "/api/v1/{kebab-case-plural}/00000000-0000-0000-0000-000000000000"
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_update_{resource}(client: AsyncClient):
    # Create first
    create_resp = await client.post(
        "/api/v1/{kebab-case-plural}",
        json={"name": "Original"},
    )
    item_id = create_resp.json()["id"]

    # Update
    response = await client.patch(
        f"/api/v1/{kebab-case-plural}/{item_id}",
        json={"name": "Updated"},
    )
    assert response.status_code == 200
    assert response.json()["name"] == "Updated"


@pytest.mark.asyncio
async def test_delete_{resource}(client: AsyncClient):
    # Create first
    create_resp = await client.post(
        "/api/v1/{kebab-case-plural}",
        json={"name": "To Delete"},
    )
    item_id = create_resp.json()["id"]

    # Delete
    response = await client.delete(f"/api/v1/{kebab-case-plural}/{item_id}")
    assert response.status_code == 204

    # Verify deleted
    response = await client.get(f"/api/v1/{kebab-case-plural}/{item_id}")
    assert response.status_code == 404
```

### Step 9: Register Router
Check `app/main.py` and add the router import if not already present:

```python
from app.routers.{resource} import router as {resource}_router
app.include_router({resource}_router)
```

### Step 10: Output

```
API scaffold complete for: {resource}

Files created:
  - app/schemas/{resource}.py — Pydantic schemas
  - app/repositories/{resource}_repository.py — Data access
  - app/services/{resource}_service.py — Business logic
  - app/routers/{resource}.py — Route handlers
  - tests/test_{resource}.py — Endpoint tests

Endpoints:
  GET    /api/v1/{kebab-case-plural}              — List {resource}s
  GET    /api/v1/{kebab-case-plural}/{id}          — Get {resource}
  POST   /api/v1/{kebab-case-plural}               — Create {resource}
  PATCH  /api/v1/{kebab-case-plural}/{id}          — Update {resource}
  DELETE /api/v1/{kebab-case-plural}/{id}          — Delete {resource}

{If model was missing:}
Note: Model file app/models/{resource}.py not found.
  - Update schemas with actual fields after creating the model
  - Run /db:migrate create to generate migration

Next: Run tests with pytest tests/test_{resource}.py -v
```
