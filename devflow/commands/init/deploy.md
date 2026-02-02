---
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - LS
---

# CI/CD and Deployment Scaffold

## Usage
```
/init:deploy
```

## Description
Creates the CI/CD pipeline and deployment configuration for a Python + FastAPI project. Generates GitHub Actions workflows, Dockerfile, docker-compose configuration, environment file templates, and deployment documentation.

## Prerequisites
- Project has been scaffolded (backend directory exists)
- Git repository initialized

If prerequisites are not met:
```
❌ backend/ not found. Run /init:project first.
```

## Execution

### Step 1: Verify Structure
```bash
test -d backend || echo "MISSING_BACKEND"
test -d .git || echo "NOT_GIT_REPO"
```

### Step 2: Create GitHub Actions Workflow

#### .github/workflows/ci.yml
```yaml
name: CI Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

env:
  PYTHON_VERSION: "3.11"
  NODE_VERSION: "20"

jobs:
  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Install dependencies
        working-directory: backend
        run: |
          pip install --upgrade pip
          pip install ruff mypy
          pip install -r requirements.txt

      - name: Run Ruff linter
        working-directory: backend
        run: ruff check .

      - name: Run Ruff formatter check
        working-directory: backend
        run: ruff format --check .

      - name: Run MyPy type checker
        working-directory: backend
        run: mypy app/ --ignore-missing-imports

  test:
    name: Test
    runs-on: ubuntu-latest
    needs: lint
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Install dependencies
        working-directory: backend
        run: |
          pip install --upgrade pip
          pip install -r requirements.txt
          pip install pytest pytest-asyncio pytest-cov httpx

      - name: Run tests
        working-directory: backend
        env:
          DATABASE_URL: postgresql+asyncpg://postgres:postgres@localhost:5432/test_db
          SECRET_KEY: test-secret-key-not-for-production
          ENVIRONMENT: test
        run: |
          pytest --cov=app --cov-report=xml --cov-report=term-missing -v

      - name: Upload coverage
        if: github.event_name == 'pull_request'
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: backend/coverage.xml

  build:
    name: Build Docker Image
    runs-on: ubuntu-latest
    needs: test
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: false
          tags: app:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy:
    name: Deploy
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main'
    environment: production
    steps:
      - uses: actions/checkout@v4

      - name: Deploy to production
        run: |
          echo "Add your deployment commands here"
          echo "Options: Docker push to registry, SSH deploy, cloud provider CLI"
          # Example for a generic Docker deployment:
          # docker push $REGISTRY/$IMAGE:${{ github.sha }}
          # ssh $DEPLOY_HOST "docker pull $REGISTRY/$IMAGE:${{ github.sha }} && docker-compose up -d"
```

### Step 3: Create Dockerfile

#### Dockerfile
```dockerfile
# Stage 1: Builder
FROM python:3.11-slim AS builder

WORKDIR /build

COPY backend/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim AS runtime

WORKDIR /app

# Create non-root user
RUN groupadd --gid 1000 appuser && \
    useradd --uid 1000 --gid 1000 --shell /bin/bash appuser

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Copy application code
COPY backend/ .

# Switch to non-root user
USER appuser

EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

### Step 4: Create Docker Compose

#### docker-compose.yml
```yaml
services:
  app:
    build:
      context: .
      target: runtime
    ports:
      - "8000:8000"
    env_file:
      - .env
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped
    networks:
      - app-network

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-postgres}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
      POSTGRES_DB: ${POSTGRES_DB:-appdb}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-postgres}"]
      interval: 5s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    networks:
      - app-network

volumes:
  postgres_data:

networks:
  app-network:
    driver: bridge
```

#### docker-compose.dev.yml
```yaml
# Development overrides — use with: docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
services:
  app:
    build:
      target: runtime
    command: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
    volumes:
      - ./backend:/app
    environment:
      - DEBUG=true
      - ENVIRONMENT=development
```

### Step 5: Create Environment File Templates

#### .env.example
If file already exists, verify these variables are present and add any missing ones:
```env
# Application
ENVIRONMENT=development
DEBUG=true

# Database
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=appdb
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/appdb

# Auth
SECRET_KEY=change-this-to-a-random-64-char-string
ACCESS_TOKEN_EXPIRE_MINUTES=30

# API
API_V1_STR=/api/v1
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:4200

# Deployment (production only)
# REGISTRY=ghcr.io/your-org
# DEPLOY_HOST=your-server.com
```

#### .env.production.example
```env
# Production environment template
# Copy to .env on the production server and fill in real values

ENVIRONMENT=production
DEBUG=false

POSTGRES_USER=<db-user>
POSTGRES_PASSWORD=<strong-random-password>
POSTGRES_DB=<db-name>
DATABASE_URL=postgresql+asyncpg://<db-user>:<password>@<db-host>:5432/<db-name>

SECRET_KEY=<generate-with: python -c "import secrets; print(secrets.token_urlsafe(64))">
ACCESS_TOKEN_EXPIRE_MINUTES=15

API_V1_STR=/api/v1
ALLOWED_ORIGINS=https://yourdomain.com
```

### Step 6: Create Deployment Notes

If the user requests it or CLAUDE.md exists, append a deployment section to CLAUDE.md:
```markdown
## Deployment

### Local Development
```bash
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

### Production Build
```bash
docker-compose build
docker-compose up -d
```

### CI/CD Pipeline
The GitHub Actions workflow at `.github/workflows/ci.yml` runs:
1. **Lint** — Ruff linter + formatter + MyPy type checker
2. **Test** — pytest with PostgreSQL service container
3. **Build** — Docker image build (main branch only)
4. **Deploy** — Production deployment (main branch only, requires `production` environment approval)

### Database Migrations in Production
```bash
docker-compose exec app alembic upgrade head
```

### Rollback
```bash
docker-compose exec app alembic downgrade -1
```
```

### Step 7: Output
```
✅ CI/CD and deployment configured
  - CI: GitHub Actions (lint → test → build → deploy)
  - Container: Multi-stage Dockerfile
  - Orchestration: docker-compose (app + postgres)
  - Environments: .env.example + .env.production.example

Files created/updated:
  - .github/workflows/ci.yml
  - Dockerfile (multi-stage build)
  - docker-compose.yml
  - docker-compose.dev.yml
  - .env.example (updated)
  - .env.production.example

Next steps:
  1. Review .github/workflows/ci.yml — customize deploy step for your infrastructure
  2. Set GitHub repository secrets for production deployment
  3. Create GitHub environment "production" with required reviewers
  4. Test locally: docker-compose up --build
```
