---
name: {feature-name}-plan
status: draft
created: {datetime}
updated: {datetime}
spec: {spec-reference}
prd: {prd-reference}
---

# Technical Plan: {Feature Name}

## Architecture Overview

{High-level architecture description. Describe the major components, how they interact, and the overall system design philosophy.}

### System Diagram
```
[Client] --> [API Gateway / FastAPI] --> [Service Layer] --> [Repository Layer] --> [PostgreSQL]
                                    --> [Cache Layer] --> [Redis]
                                    --> [Background Tasks] --> [Celery/ARQ]
```

## Architecture Decisions

### AD-001: {Decision Title}
- **Context:** {Why this decision is needed}
- **Decision:** {What was decided}
- **Rationale:** {Why this option was chosen}
- **Alternatives Considered:**
  - {Alt 1}: {Why rejected}
  - {Alt 2}: {Why rejected}
- **Consequences:** {Impact of this decision}
- **Status:** Proposed

## Tech Stack

### Backend
- **Language:** Python 3.11+
- **Framework:** FastAPI
- **ORM:** SQLAlchemy 2.0 (async)
- **Migrations:** Alembic
- **Validation:** Pydantic v2
- **Auth:** JWT with python-jose / passlib
- **Testing:** pytest + pytest-asyncio + httpx
- **Task Queue:** {Celery/ARQ if needed}
- **Caching:** {Redis if needed}

### Frontend
- **Framework:** {Angular 17+ / React 18+}
- **State Management:** {NgRx / Redux Toolkit / Zustand}
- **UI Library:** {Material / Tailwind / Shadcn}
- **HTTP Client:** {HttpClient / Axios / fetch}
- **Testing:** {Jest + Testing Library / Karma + Jasmine}

### Database
- **Primary:** PostgreSQL 15+
- **Driver:** asyncpg (async) / psycopg2 (sync)
- **Cache:** {Redis if needed}
- **Search:** {PostgreSQL full-text / Elasticsearch if needed}

### Infrastructure
- **Containerization:** Docker + Docker Compose
- **CI/CD:** GitHub Actions
- **Hosting:** {Cloud provider}
- **Monitoring:** {Prometheus + Grafana / Datadog}
- **Logging:** {Structured JSON logging}

## Data Model

### Entity: {EntityName}
```python
class EntityName(Base):
    __tablename__ = "entity_names"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    # Add fields based on spec entities
    created_at: Mapped[datetime] = mapped_column(default=func.now())
    updated_at: Mapped[datetime] = mapped_column(default=func.now(), onupdate=func.now())

    # Relationships
    # related_items: Mapped[list["RelatedItem"]] = relationship(back_populates="entity")
```

### Entity Relationships
```
{Entity1} 1---* {Entity2}
{Entity2} *---* {Entity3}
```

### Database Indexes
| Table | Index | Columns | Type |
|-------|-------|---------|------|
| {table} | {index_name} | {columns} | {UNIQUE/BTREE/GIN} |

### Migrations Strategy
- Use Alembic for all schema changes
- Auto-generate migrations from model changes
- Review generated migrations before applying
- Include data migrations when needed

## Project Structure

```
project-root/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI app factory
│   ├── config.py               # Settings (pydantic-settings)
│   ├── database.py             # DB engine, session
│   ├── dependencies.py         # Shared dependencies
│   ├── api/
│   │   ├── __init__.py
│   │   └── v1/
│   │       ├── __init__.py
│   │       ├── router.py       # v1 router aggregator
│   │       ├── endpoints/
│   │       │   └── {resource}.py
│   │       └── schemas/
│   │           └── {resource}.py
│   ├── models/
│   │   ├── __init__.py
│   │   └── {entity}.py         # SQLAlchemy models
│   ├── services/
│   │   ├── __init__.py
│   │   └── {entity}_service.py # Business logic
│   ├── repositories/
│   │   ├── __init__.py
│   │   ├── base.py             # Generic CRUD repo
│   │   └── {entity}_repo.py
│   └── core/
│       ├── __init__.py
│       ├── security.py         # Auth helpers
│       ├── exceptions.py       # Custom exceptions
│       └── middleware.py       # CORS, logging
├── migrations/
│   ├── env.py
│   └── versions/
├── tests/
│   ├── conftest.py
│   ├── test_api/
│   ├── test_services/
│   └── test_repositories/
├── docker-compose.yml
├── Dockerfile
├── pyproject.toml
├── alembic.ini
└── .env.example
```

## API Design

### Endpoints

| Method | Path | Description | Auth | FR |
|--------|------|-------------|------|-----|
| {METHOD} | /api/v1/{resource} | {description} | {Yes/No} | {FR-xxx} |

### Authentication Flow
```
1. Client sends credentials to POST /api/v1/auth/login
2. Server validates and returns JWT access + refresh tokens
3. Client includes access token in Authorization: Bearer {token}
4. Server validates token in middleware/dependency
5. Refresh token used to get new access token when expired
```

### Error Response Format
```json
{
  "detail": {
    "code": "ERROR_CODE",
    "message": "Human readable message",
    "field": "optional_field_name"
  }
}
```

## Principles Compliance

| Principle | Compliance | Notes |
|-----------|------------|-------|
| {principle_name} | {YES/NO/PARTIAL} | {explanation} |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| {risk description} | {Low/Medium/High} | {Low/Medium/High} | {mitigation strategy} |

## Implementation Order

1. **Phase 1:** Project setup, database models, migrations
2. **Phase 2:** Core API endpoints, authentication
3. **Phase 3:** Business logic, service layer
4. **Phase 4:** Frontend components, integration
5. **Phase 5:** Testing, documentation, deployment
