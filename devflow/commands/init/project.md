---
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - LS
---

# Project Bootstrap

## Usage
```
/init:project
```

## Description
Scaffolds a new full-stack project with the standard DevFlow structure. Prompts for project configuration, creates directory structure, initializes git, and generates base configuration files.

## Execution

### Step 1: Gather Project Configuration
Ask the user for the following:

1. **Project name** (required)
   - Must be lowercase, alphanumeric with hyphens
   - Example: `my-saas-app`

2. **Frontend framework** (required, pick one)
   - Option A: Angular (latest v19+) + DaisyUI + Tailwind CSS
   - Option B: React + Tailwind CSS

3. **Backend needed?** (default: yes)
   - Backend is always Python + FastAPI
   - If user says no, skip backend scaffolding

4. **Database** (default: PostgreSQL)
   - PostgreSQL (recommended default)
   - SQLite (for simple projects or prototyping)

5. **Description** (optional)
   - One-line project description for package files

### Step 2: Create Root Directory Structure
```bash
mkdir -p {project-name}
cd {project-name}
```

Create the following structure:
```
{project-name}/
├── .github/
│   └── workflows/
├── devflow/
│   └── adrs/
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py
│   │   ├── config.py
│   │   ├── api/
│   │   │   ├── __init__.py
│   │   │   └── v1/
│   │   │       ├── __init__.py
│   │   │       └── router.py
│   │   ├── models/
│   │   │   ├── __init__.py
│   │   │   └── base.py
│   │   ├── schemas/
│   │   │   └── __init__.py
│   │   ├── services/
│   │   │   └── __init__.py
│   │   ├── core/
│   │   │   ├── __init__.py
│   │   │   ├── security.py
│   │   │   └── database.py
│   │   └── utils/
│   │       └── __init__.py
│   ├── tests/
│   │   ├── __init__.py
│   │   ├── conftest.py
│   │   └── test_health.py
│   ├── alembic/
│   │   ├── env.py
│   │   ├── script.py.mako
│   │   └── versions/
│   ├── alembic.ini
│   ├── pyproject.toml
│   └── requirements.txt
├── frontend/
│   └── (framework-specific structure — see Step 4)
├── .env.example
├── .gitignore
├── docker-compose.yml
├── Dockerfile
└── CLAUDE.md
```

### Step 3: Create Backend Files

#### backend/app/main.py
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.api.v1.router import api_router

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=settings.API_V1_STR)


@app.get("/health")
async def health_check():
    return {"status": "healthy", "version": settings.VERSION}
```

#### backend/app/config.py
```python
from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    PROJECT_NAME: str = "{project-name}"
    VERSION: str = "0.1.0"
    API_V1_STR: str = "/api/v1"
    ALLOWED_ORIGINS: List[str] = ["http://localhost:3000", "http://localhost:4200"]

    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/{project_name_underscore}"
    SECRET_KEY: str = "change-me-in-production"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
```

#### backend/app/api/v1/router.py
```python
from fastapi import APIRouter

api_router = APIRouter()


@api_router.get("/ping")
async def ping():
    return {"message": "pong"}
```

#### backend/app/core/database.py
```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from app.config import settings

engine = create_async_engine(settings.DATABASE_URL, echo=False)
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


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
```

#### backend/app/models/base.py
```python
from datetime import datetime, timezone
from sqlalchemy import Column, DateTime, Integer
from app.core.database import Base


class TimestampMixin:
    id = Column(Integer, primary_key=True, autoincrement=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
```

#### backend/pyproject.toml
```toml
[project]
name = "{project-name}"
version = "0.1.0"
description = "{description}"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.104.0",
    "uvicorn[standard]>=0.24.0",
    "sqlalchemy[asyncio]>=2.0.0",
    "alembic>=1.13.0",
    "pydantic>=2.5.0",
    "pydantic-settings>=2.1.0",
    "asyncpg>=0.29.0",
    "python-dotenv>=1.0.0",
    "python-jose[cryptography]>=3.3.0",
    "passlib[bcrypt]>=1.7.4",
    "httpx>=0.25.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.4.0",
    "pytest-asyncio>=0.23.0",
    "pytest-cov>=4.1.0",
    "ruff>=0.1.0",
    "mypy>=1.7.0",
    "pip-audit>=2.6.0",
]

[tool.ruff]
target-version = "py311"
line-length = 120

[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"
```

#### backend/requirements.txt
```
fastapi>=0.104.0
uvicorn[standard]>=0.24.0
sqlalchemy[asyncio]>=2.0.0
alembic>=1.13.0
pydantic>=2.5.0
pydantic-settings>=2.1.0
asyncpg>=0.29.0
python-dotenv>=1.0.0
python-jose[cryptography]>=3.3.0
passlib[bcrypt]>=1.7.4
httpx>=0.25.0
```

#### backend/tests/conftest.py
```python
import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
```

#### backend/tests/test_health.py
```python
import pytest


@pytest.mark.asyncio
async def test_health_check(client):
    response = await client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"


@pytest.mark.asyncio
async def test_ping(client):
    response = await client.get("/api/v1/ping")
    assert response.status_code == 200
    assert response.json() == {"message": "pong"}
```

### Step 4: Create Frontend Structure

#### If Angular (latest) + DaisyUI + Tailwind:

**Always use the latest Angular version (19+):**

```bash
# Install latest Angular CLI globally
npm install -g @angular/cli@latest

# Create new Angular app with latest features
ng new frontend --style=scss --routing=true --ssr=false --skip-git

cd frontend

# Add Tailwind CSS
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init

# Add DaisyUI
npm install -D daisyui@latest

# Add HTTP client and forms
ng add @angular/common
```

**Configure Tailwind** (`frontend/tailwind.config.js`):
```javascript
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{html,ts}"],
  theme: {
    extend: {},
  },
  plugins: [require("daisyui")],
  daisyui: {
    themes: ["light", "dark", "corporate"],
  },
};
```

**Update styles** (`frontend/src/styles.scss`):
```scss
@tailwind base;
@tailwind components;
@tailwind utilities;
```

**Angular 19+ features to use:**
- Standalone components (default)
- Signals for reactive state
- New control flow (@if, @for, @switch)
- Deferrable views (@defer)
- Built-in image optimization

**Configure proxy** (`frontend/proxy.conf.json`):
```json
{
  "/api": {
    "target": "http://localhost:8000",
    "secure": false,
    "changeOrigin": true
  }
}
```

Update `frontend/angular.json` to use proxy:
```json
"serve": {
  "options": {
    "proxyConfig": "proxy.conf.json"
  }
}
```

#### If React + Tailwind:
```bash
mkdir -p frontend/src/{components,pages,hooks,services,utils}
mkdir -p frontend/public
```

Create `frontend/package.json` with React, Tailwind CSS, and Vite.
Create `frontend/tailwind.config.js` with standard Tailwind config.
Create `frontend/vite.config.ts` with proxy to backend API.

### Step 5: Create Root Configuration Files

#### .env.example
```env
# Database
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/{project_name_underscore}

# Auth
SECRET_KEY=generate-a-secure-random-key
ACCESS_TOKEN_EXPIRE_MINUTES=30

# API
API_V1_STR=/api/v1
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:4200

# Environment
ENVIRONMENT=development
DEBUG=true
```

#### .gitignore
```
# Python
__pycache__/
*.py[cod]
*.egg-info/
dist/
.venv/
venv/

# Node
node_modules/
.next/
.angular/

# Environment
.env
.env.local
.env.*.local

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Build
build/
*.egg

# Testing
.coverage
htmlcov/
.pytest_cache/
```

#### docker-compose.yml
```yaml
services:
  app:
    build: .
    ports:
      - "8000:8000"
    env_file:
      - .env
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - ./backend:/app

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: {project_name_underscore}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

#### Dockerfile
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/ .

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

#### CLAUDE.md
```markdown
# {Project Name}

## Tech Stack
- Backend: Python 3.11+ / FastAPI
- Database: PostgreSQL + SQLAlchemy + Alembic
- Frontend: {Angular + DaisyUI + Tailwind | React + Tailwind}

## Getting Started
1. Copy .env.example to .env and update values
2. Start services: docker-compose up -d
3. Run migrations: cd backend && alembic upgrade head
4. Start backend: cd backend && uvicorn app.main:app --reload
5. Start frontend: cd frontend && npm start

## Project Structure
- backend/ — Python FastAPI application
- frontend/ — {Framework} application
- devflow/adrs/ — Architecture Decision Records
```

### Step 6: Initialize Git
```bash
cd {project-name}
git init
git add .
git commit -m "Initial project scaffold via DevFlow"
```

### Step 7: Output
```
✅ Project "{project-name}" created
  - Backend: Python + FastAPI
  - Frontend: {framework}
  - Database: {database}
  - Structure: {file_count} files created

Next steps:
  1. cd {project-name}
  2. cp .env.example .env — update values
  3. docker-compose up -d — start database
  4. /init:database — set up migrations
  5. /init:auth — add authentication
```
