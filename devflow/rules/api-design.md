# API Design Patterns

REST API design standards for FastAPI backends.

## Resource Naming

### URL Structure
```
/api/v1/{resource}              # Collection
/api/v1/{resource}/{id}         # Single item
/api/v1/{resource}/{id}/{sub}   # Sub-resource collection
```

### Conventions
- Plural nouns for resources: `/api/v1/projects`, `/api/v1/tasks`
- Kebab-case for multi-word resources: `/api/v1/task-comments`, `/api/v1/user-profiles`
- No verbs in URLs: `/api/v1/projects` not `/api/v1/get-projects`
- Nest sub-resources max one level: `/api/v1/projects/{id}/tasks` is fine, deeper nesting is not
- Use query parameters for cross-resource queries: `/api/v1/tasks?project_id={id}&assignee_id={id}`

## HTTP Methods

| Method | URL | Action | Response |
|--------|-----|--------|----------|
| GET | /api/v1/projects | List all projects | 200 + array |
| GET | /api/v1/projects/{id} | Get single project | 200 + object |
| POST | /api/v1/projects | Create project | 201 + object |
| PUT | /api/v1/projects/{id} | Full replace | 200 + object |
| PATCH | /api/v1/projects/{id} | Partial update | 200 + object |
| DELETE | /api/v1/projects/{id} | Delete project | 204 no content |

### When to Use PUT vs PATCH
- **PUT**: Client sends the complete resource. All fields required. Replaces entirely.
- **PATCH**: Client sends only changed fields. Omitted fields remain unchanged. Preferred for most update operations.

## Status Codes

### Success
| Code | Meaning | When to Use |
|------|---------|-------------|
| 200 | OK | GET, PUT, PATCH success |
| 201 | Created | POST success (include Location header) |
| 204 | No Content | DELETE success, actions with no response body |

### Client Errors
| Code | Meaning | When to Use |
|------|---------|-------------|
| 400 | Bad Request | Malformed request syntax, invalid JSON |
| 401 | Unauthorized | Missing or invalid authentication |
| 403 | Forbidden | Authenticated but lacks permission |
| 404 | Not Found | Resource does not exist |
| 409 | Conflict | Duplicate resource, state conflict |
| 422 | Unprocessable Entity | Validation errors (FastAPI default for Pydantic) |

### Server Errors
| Code | Meaning | When to Use |
|------|---------|-------------|
| 500 | Internal Server Error | Unhandled exception (never intentionally return) |

## Pagination

### Cursor-Based (Preferred)
Best for real-time data and large datasets. Use for all user-facing list endpoints.

Request:
```
GET /api/v1/tasks?limit=20&after={cursor}
```

Response:
```json
{
  "data": [...],
  "pagination": {
    "has_next": true,
    "next_cursor": "eyJpZCI6ICIxMjMifQ==",
    "limit": 20
  }
}
```

Cursor is a base64-encoded JSON object containing sort fields (typically `id` and `created_at`).

### Offset-Based (Simple Cases)
Use for admin panels, dashboards, and small datasets.

Request:
```
GET /api/v1/users?page=2&page_size=20
```

Response:
```json
{
  "data": [...],
  "pagination": {
    "page": 2,
    "page_size": 20,
    "total": 142,
    "total_pages": 8
  }
}
```

## Filtering and Sorting

### Filtering
Use query parameters with field names:
```
GET /api/v1/tasks?status=active&priority=high&assignee_id=abc123
```

For date ranges:
```
GET /api/v1/tasks?created_after=2024-01-01&created_before=2024-12-31
```

For search:
```
GET /api/v1/tasks?q=fix+login+bug
```

### Sorting
Use `sort` parameter with optional `-` prefix for descending:
```
GET /api/v1/tasks?sort=-created_at          # Newest first
GET /api/v1/tasks?sort=priority,-created_at  # Priority asc, then newest
```

## Error Response Format

All errors use a consistent JSON structure:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format",
        "value": "not-an-email"
      }
    ]
  }
}
```

### Error Codes
Use uppercase snake_case error codes:
- `VALIDATION_ERROR` — Request data failed validation
- `NOT_FOUND` — Resource does not exist
- `UNAUTHORIZED` — Authentication required
- `FORBIDDEN` — Insufficient permissions
- `CONFLICT` — Resource already exists or state conflict
- `INTERNAL_ERROR` — Server error (never expose internals)

### FastAPI Implementation

```python
from fastapi import HTTPException
from pydantic import BaseModel


class ErrorDetail(BaseModel):
    field: str | None = None
    message: str
    value: str | None = None


class ErrorResponse(BaseModel):
    code: str
    message: str
    details: list[ErrorDetail] = []


class APIError(HTTPException):
    def __init__(self, status_code: int, code: str, message: str, details: list[dict] | None = None):
        super().__init__(
            status_code=status_code,
            detail={
                "error": {
                    "code": code,
                    "message": message,
                    "details": details or [],
                }
            },
        )


# Usage
raise APIError(
    status_code=404,
    code="NOT_FOUND",
    message="Project not found",
)
```

## API Versioning

### URL Prefix Strategy
All endpoints are prefixed with `/api/v1/`:

```python
from fastapi import APIRouter

router = APIRouter(prefix="/api/v1")
```

### Versioning Rules
- Increment version for breaking changes only
- Additive changes (new fields, new endpoints) do NOT require a new version
- Support previous version for minimum 6 months after deprecation
- Use `Deprecation` header to signal upcoming removal:
  ```
  Deprecation: true
  Sunset: Sat, 01 Jan 2025 00:00:00 GMT
  Link: </api/v2/resource>; rel="successor-version"
  ```

## OpenAPI / Swagger Documentation

FastAPI auto-generates OpenAPI docs. Enhance them with:

```python
from fastapi import FastAPI

app = FastAPI(
    title="Project API",
    description="API for managing projects and tasks",
    version="1.0.0",
    docs_url="/api/docs",          # Swagger UI
    redoc_url="/api/redoc",        # ReDoc
    openapi_url="/api/openapi.json",
)
```

### Endpoint Documentation

```python
@router.get(
    "/projects/{project_id}",
    response_model=ProjectResponse,
    summary="Get project by ID",
    description="Retrieves a single project with its metadata.",
    responses={
        404: {"description": "Project not found"},
    },
)
async def get_project(project_id: uuid.UUID):
    ...
```

### Tag Grouping

```python
router = APIRouter(prefix="/api/v1/projects", tags=["Projects"])
```

## Rate Limiting

### Strategy
- Use `slowapi` or custom middleware for FastAPI
- Default: 100 requests per minute per user
- Auth endpoints: 10 requests per minute per IP
- File upload: 20 requests per minute per user

### Headers
Include rate limit info in responses:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1704067200
```

### Implementation

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@router.get("/projects")
@limiter.limit("100/minute")
async def list_projects(request: Request):
    ...
```

## CORS Configuration

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:4200",     # Angular dev server
        "http://localhost:3000",     # React dev server
        "https://app.example.com",  # Production
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["*"],
    expose_headers=["X-RateLimit-Limit", "X-RateLimit-Remaining", "X-RateLimit-Reset"],
)
```

### CORS Rules
- Never use `allow_origins=["*"]` in production
- Explicitly list allowed origins
- In development, allow localhost origins
- Load allowed origins from environment variables

## Rules Summary

1. Plural nouns, kebab-case URLs, max one nesting level
2. Use correct HTTP methods and status codes
3. Cursor-based pagination for user-facing endpoints
4. Consistent error response format with error codes
5. Version via URL prefix `/api/v1/`
6. Document every endpoint with response models and examples
7. Rate limit all endpoints, stricter for auth
8. Explicit CORS origins, never wildcard in production
