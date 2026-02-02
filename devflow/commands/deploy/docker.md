---
allowed-tools: Bash, Read, Write, LS
---

# Deploy Docker

Generate Docker files for containerized deployment.

## Usage
```
/deploy:docker
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/deploy-patterns.md` — Deployment strategies, health checks, zero-downtime
- `devflow/rules/standard-patterns.md` — Standard output patterns

## Templates

Reference for base content:
- `devflow/templates/docker/Dockerfile-template` — Multi-stage Dockerfile
- `devflow/templates/docker/docker-compose-template.yml` — Docker Compose configuration

## Instructions

### 1. Detect Project Structure

Scan the project to determine what services are needed:

| Indicator | Service |
|-----------|---------|
| `app/main.py` with FastAPI | Python API container |
| `requirements.txt` or `pyproject.toml` | Python dependencies |
| `angular.json` | Angular frontend container |
| `package.json` (React) | React frontend container |
| Redis usage in code | Redis service |
| Celery/task queue usage | Worker container |
| `alembic/` directory | Migration step in entrypoint |

### 2. Create Dockerfile

**Create `Dockerfile`** using multi-stage build for Python+FastAPI:

```dockerfile
# ============================================================
# Stage 1: Builder — install dependencies
# ============================================================
FROM python:3.12-slim AS builder

WORKDIR /app

# Install system dependencies needed for building Python packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy dependency files first for better layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ============================================================
# Stage 2: Runtime — minimal production image
# ============================================================
FROM python:3.12-slim AS runtime

WORKDIR /app

# Install runtime system dependencies only
RUN apt-get update && \
    apt-get install -y --no-install-recommends libpq5 curl && \
    rm -rf /var/lib/apt/lists/*

# Copy installed Python packages from builder
COPY --from=builder /install /usr/local

# Create non-root user for security
RUN groupadd --gid 1001 appuser && \
    useradd --uid 1001 --gid 1001 --shell /bin/bash --create-home appuser

# Copy application code
COPY . .

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose FastAPI port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run with uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

If `alembic/` exists, create an **entrypoint script** at `docker-entrypoint.sh`:
```bash
#!/bin/bash
set -e

echo "Running database migrations..."
alembic upgrade head

echo "Starting application..."
exec "$@"
```
And update the Dockerfile CMD to use the entrypoint:
```dockerfile
COPY docker-entrypoint.sh .
RUN chmod +x docker-entrypoint.sh
ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

### 3. Create docker-compose.yml

**Create `docker-compose.yml`:**

```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    env_file:
      - .env
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@db:5432/appdb
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped
    networks:
      - app-network

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s
    restart: unless-stopped
    networks:
      - app-network

volumes:
  postgres_data:

networks:
  app-network:
    driver: bridge
```

**If Angular frontend detected, add:**
```yaml
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "4200:80"
    depends_on:
      - app
    restart: unless-stopped
    networks:
      - app-network
```

**If Redis usage detected, add:**
```yaml
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    networks:
      - app-network
```
And add `redis_data:` to volumes and `REDIS_URL=redis://redis:6379/0` to app environment.

### 4. Create .dockerignore

**Create `.dockerignore`:**
```
# Version control
.git
.gitignore

# Python
__pycache__
*.pyc
*.pyo
.pytest_cache
.mypy_cache
.ruff_cache
htmlcov
.coverage
*.egg-info
dist
build
.venv
venv
env

# Node (if frontend in same repo)
node_modules
.angular
dist

# IDE
.vscode
.idea
*.swp
*.swo

# Environment
.env
.env.local
.env.*.local

# Docker
docker-compose*.yml
Dockerfile*

# Documentation
*.md
LICENSE

# Tests
tests/
e2e/

# CI
.github/
```

### 5. Create docker-compose.override.yml (Development)

**Create `docker-compose.override.yml`** for development overrides:
```yaml
# Development overrides — automatically loaded by docker compose
services:
  app:
    build:
      target: runtime
    volumes:
      - .:/app
    command: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
    environment:
      - DEBUG=true
      - LOG_LEVEL=debug
```

### 6. Post-Setup

```
Docker files created:
  - Dockerfile (multi-stage: builder + runtime)
  - docker-compose.yml (app + PostgreSQL{+ Redis}{+ frontend})
  - docker-compose.override.yml (development overrides)
  - .dockerignore

Quick start:
  docker compose up --build

Production build:
  docker compose -f docker-compose.yml up --build -d

Next steps:
  - Set up environment variables in .env
  - Configure CI to build and push images: /deploy:setup
  - Validate environment: /deploy:env-check
```

## Error Recovery

- If Dockerfile already exists, ask user before overwriting
- If docker-compose.yml already exists, ask user before overwriting
- If requirements.txt is missing, check for pyproject.toml and suggest: `pip freeze > requirements.txt`
