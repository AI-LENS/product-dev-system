---
allowed-tools: Bash, Read, Write, LS
---

# Deploy Setup

Generate CI/CD pipeline configuration with GitHub Actions.

## Usage
```
/deploy:setup
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/deploy-patterns.md` — Deployment strategies and environment promotion
- `devflow/rules/testing-strategy.md` — CI test requirements
- `devflow/rules/standard-patterns.md` — Standard output patterns

## Instructions

### 1. Detect Project Stack

Scan the project to determine the CI pipeline components:

| Indicator | Stack Component | CI Steps |
|-----------|----------------|----------|
| `pyproject.toml` / `requirements.txt` | Python backend | lint, type-check, test |
| `angular.json` | Angular frontend | lint, test, build |
| `package.json` (React) | React frontend | lint, test, build |
| `Dockerfile` | Container build | docker build, push |
| `alembic.ini` | DB migrations | migration check |

### 2. Create GitHub Actions Workflow

**Create `.github/workflows/ci.yml`:**

Use the template from `devflow/templates/github-actions/ci-template.yml` as a base and customize based on detected stack.

**Pipeline stages (in order):**
1. **Lint** — ruff check + mypy (Python), ESLint (frontend)
2. **Test** — pytest with coverage (Python), Jest/Karma (frontend)
3. **Build** — Docker image build
4. **Deploy** — Configurable target (staging/production)

**For Python + FastAPI backend:**
```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  PYTHON_VERSION: "3.12"
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'

      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install ruff mypy

      - name: Run ruff
        run: ruff check .

      - name: Run mypy
        run: mypy app/ --ignore-missing-imports

  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: testdb
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'

      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install pytest pytest-cov pytest-asyncio httpx

      - name: Run tests with coverage
        run: pytest tests/ -v --cov=app --cov-report=term-missing --cov-report=xml
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/testdb

      - name: Upload coverage
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage.xml

  build:
    needs: [lint, test]
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### 3. Add Frontend CI (if Angular/React detected)

Append a frontend job to the workflow:
```yaml
  frontend-lint-test:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./frontend  # Adjust path as needed
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Test
        run: npm run test -- --watch=false --browsers=ChromeHeadless

      - name: Build
        run: npm run build -- --configuration=production
```

### 4. Create Branch Protection Rules Suggestion

After creating the workflow, suggest GitHub branch protection rules:
```
Suggested branch protection for 'main':
  - Require pull request before merging
  - Require status checks: lint, test, build
  - Require branches to be up to date before merging
  - Require 1 approval minimum
  - Dismiss stale reviews on new pushes

To configure: Settings > Branches > Branch protection rules > Add rule
Or run: gh api repos/{owner}/{repo}/branches/main/protection -X PUT ...
```

### 5. Post-Setup

```
CI/CD pipeline created:
  - Workflow: .github/workflows/ci.yml
  - Stages: lint -> test -> build (-> deploy on main)
  - Test database: PostgreSQL 16 (service container)
  - Registry: GitHub Container Registry (ghcr.io)

Next steps:
  - Push to trigger first CI run
  - Configure branch protection rules
  - Add deployment target: /deploy:docker
  - Set up secrets in GitHub repo settings if needed
```

## Error Recovery

- If `.github/workflows/` directory does not exist, create it
- If a workflow file already exists, ask the user before overwriting
- If the project uses a different CI system, adapt the pipeline format
