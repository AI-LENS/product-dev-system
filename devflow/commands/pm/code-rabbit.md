---
allowed-tools: Bash, Read, Write, LS
---

# CodeRabbit Integration

Configure CodeRabbit for automated PR review.

## Usage
```
/pm:code-rabbit
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/review-workflow.md` — PR review standards
- `devflow/rules/standard-patterns.md` — Standard output patterns

## Instructions

### 1. Check for Existing Configuration

```bash
test -f .coderabbit.yaml && echo "exists" || echo "not found"
```

If `.coderabbit.yaml` already exists, read it and ask the user if they want to update or replace it.

### 2. Detect Project Stack

Scan the project to configure language-specific review rules:

| Indicator | Language Config |
|-----------|----------------|
| `pyproject.toml` / `*.py` | Python review rules |
| `angular.json` / `*.ts` | TypeScript/Angular review rules |
| `package.json` (React) | TypeScript/React review rules |
| `Dockerfile` | Docker review rules |
| `alembic/` | Database migration review rules |

### 3. Create .coderabbit.yaml

**Create `.coderabbit.yaml`:**

```yaml
# CodeRabbit Configuration
# Documentation: https://docs.coderabbit.ai

language: en-US

reviews:
  # Enable automatic reviews on PRs
  auto_review:
    enabled: true
    # Review when PR is opened or updated
    drafts: false
    # Base branch for reviews
    base_branches:
      - main
      - develop

  # Review profile: assertive catches more issues, chill is less noisy
  profile: assertive

  # Request changes vs comment
  request_changes_workflow: true

  # High-level summary of changes
  high_level_summary: true

  # Poem in review (disable for professional settings)
  poem: false

  # Review status in PR comment
  review_status: true

  # Collapse walkthrough after a certain number of files
  collapse_walkthrough: 6

  # Path-specific instructions for the reviewer
  path_instructions:
    - path: "app/api/**"
      instructions: |
        Review API endpoints for:
        - Authentication and authorization on every endpoint
        - Input validation using Pydantic models
        - Proper error handling with consistent error response format
        - No N+1 query patterns
        - Pagination on list endpoints
        - Rate limiting on public endpoints
        - OpenAPI documentation annotations

    - path: "app/models/**"
      instructions: |
        Review database models for:
        - Proper column types and constraints
        - Index definitions for query patterns
        - Relationship definitions (lazy vs eager loading)
        - Migration compatibility with running code

    - path: "app/services/**"
      instructions: |
        Review service layer for:
        - Single responsibility principle
        - Proper error handling and logging
        - No direct database access (use repository pattern)
        - Async operations where appropriate

    - path: "alembic/versions/**"
      instructions: |
        Review database migrations for:
        - Both upgrade() and downgrade() implemented
        - Backwards compatibility with current running code
        - No destructive operations (DROP) without explicit approval
        - Batched data migrations for large tables
        - Concurrent index creation where possible

    - path: "tests/**"
      instructions: |
        Review tests for:
        - Meaningful test names following test_{what}_{scenario}_{expected}
        - Arrange-Act-Assert pattern
        - Edge cases and error paths covered
        - No flaky patterns (random data, time-dependent, order-dependent)
        - Factory usage instead of hardcoded test data

    - path: "src/**/*.ts"
      instructions: |
        Review TypeScript/Angular code for:
        - Proper typing (no 'any' types)
        - Component lifecycle management (unsubscribe, destroy)
        - Accessibility (ARIA labels, keyboard navigation)
        - Reactive patterns (Observables, async pipe)
        - DaisyUI/Tailwind class usage consistency

    - path: "*.dockerfile"
      instructions: |
        Review Dockerfiles for:
        - Multi-stage builds for smaller images
        - Non-root user
        - No secrets in build args or layers
        - Health check defined
        - .dockerignore present

    - path: ".github/workflows/**"
      instructions: |
        Review CI/CD workflows for:
        - Pinned action versions (not @latest)
        - Secrets not exposed in logs
        - Proper caching configured
        - Required checks defined

  # Tools configuration
  tools:
    # Enable/disable specific linting tools
    ruff:
      enabled: true
    eslint:
      enabled: true
    mypy:
      enabled: true
    biome:
      enabled: false
    hadolint:
      enabled: true
    shellcheck:
      enabled: true

chat:
  # Allow developers to ask CodeRabbit questions in PR comments
  auto_reply: true

# Paths to ignore in reviews
path_filters:
  - "!**/*.lock"
  - "!**/package-lock.json"
  - "!**/poetry.lock"
  - "!**/*.min.js"
  - "!**/*.min.css"
  - "!**/dist/**"
  - "!**/build/**"
  - "!**/node_modules/**"
  - "!**/__pycache__/**"
  - "!**/migrations/versions/**"
  - "!**/*.generated.*"
  - "!**/coverage/**"
  - "!**/htmlcov/**"
```

### 4. Post-Setup

```
CodeRabbit configured:
  - Config: .coderabbit.yaml
  - Auto-review: enabled on PRs to main and develop
  - Profile: assertive
  - Path-specific rules: API, models, services, tests, frontend, Docker, CI

Next steps:
  1. Install CodeRabbit GitHub App: https://github.com/apps/coderabbitai
  2. Grant access to this repository
  3. Open a PR to see automated review in action
  4. Adjust path_instructions based on team feedback
```

## Error Recovery

- If .coderabbit.yaml already exists and user does not want to overwrite, exit gracefully
- If project stack differs from detected, adjust path_instructions accordingly
