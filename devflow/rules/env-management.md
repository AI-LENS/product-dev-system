# Environment Variable Management

## Purpose
Defines standards for managing environment variables across development, staging, and production environments. Follows the 12-factor app methodology for configuration management.

## Core Principles

1. **Never commit secrets** — `.env` files with real values must never be checked into version control
2. **Always provide examples** — `.env.example` is committed and kept up-to-date
3. **Validate on startup** — The application must fail fast if required variables are missing
4. **Use typed configuration** — Parse environment variables into typed settings objects, not raw strings
5. **Environment-specific defaults** — Sensible defaults for development, strict requirements for production

## .env File Structure

### Standard Layout
Group variables by concern with comment headers:

```env
# =============================================================================
# Application
# =============================================================================
ENVIRONMENT=development          # development | staging | production
DEBUG=true                       # Enable debug mode (NEVER true in production)

# =============================================================================
# Database
# =============================================================================
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/myapp
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=myapp

# =============================================================================
# Authentication
# =============================================================================
SECRET_KEY=dev-only-change-in-production
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# =============================================================================
# API
# =============================================================================
API_V1_STR=/api/v1
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:4200

# =============================================================================
# AI/LLM (optional)
# =============================================================================
AI_DEFAULT_PROVIDER=anthropic
AI_ANTHROPIC_API_KEY=
AI_OPENAI_API_KEY=

# =============================================================================
# External Services (optional)
# =============================================================================
# REDIS_URL=redis://localhost:6379/0
# SMTP_HOST=smtp.example.com
# SMTP_PORT=587
# AWS_ACCESS_KEY_ID=
# AWS_SECRET_ACCESS_KEY=
```

### Naming Conventions
- ALL_CAPS with underscores
- Prefix with service name for clarity: `AI_ANTHROPIC_API_KEY`, `SMTP_HOST`
- Boolean values: `true` / `false` (lowercase)
- List values: comma-separated, no spaces: `http://localhost:3000,http://localhost:4200`

## Required vs Optional Variables

### Required Variables (application will not start without these)
```python
# In config.py or settings.py
DATABASE_URL: str          # No default — must be provided
SECRET_KEY: str            # No default — must be provided in production
```

### Optional Variables (have sensible defaults)
```python
ENVIRONMENT: str = "development"
DEBUG: bool = False
API_V1_STR: str = "/api/v1"
ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
```

### Conditionally Required
Some variables are only required in specific environments:
```python
# Required only in production
if settings.ENVIRONMENT == "production":
    assert settings.SECRET_KEY != "dev-only-change-in-production", "Set a real SECRET_KEY in production"
    assert not settings.DEBUG, "DEBUG must be false in production"
```

## Per-Environment Configuration

### Development (.env)
```env
ENVIRONMENT=development
DEBUG=true
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/myapp_dev
SECRET_KEY=dev-only-not-secret
```

### Staging (.env.staging)
```env
ENVIRONMENT=staging
DEBUG=false
DATABASE_URL=postgresql+asyncpg://user:pass@staging-db:5432/myapp_staging
SECRET_KEY=<real-secret>
```

### Production (.env.production)
```env
ENVIRONMENT=production
DEBUG=false
DATABASE_URL=postgresql+asyncpg://user:pass@prod-db:5432/myapp
SECRET_KEY=<real-secret-64-chars>
ALLOWED_ORIGINS=https://yourdomain.com
```

### Loading Order
The application loads environment variables in this priority (highest wins):
1. Actual environment variables (set by the OS, Docker, or CI)
2. `.env` file in the project root
3. Hardcoded defaults in the Settings class

## Python Integration with Pydantic Settings

### Settings Class Pattern
```python
from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    # Application
    ENVIRONMENT: str = "development"
    DEBUG: bool = False
    PROJECT_NAME: str = "MyApp"
    VERSION: str = "0.1.0"

    # Database
    DATABASE_URL: str  # Required — no default

    # Auth
    SECRET_KEY: str  # Required — no default
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    # API
    API_V1_STR: str = "/api/v1"
    ALLOWED_ORIGINS: List[str] = ["http://localhost:3000"]

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
```

### Startup Validation
Add validation logic that runs when the application starts:

```python
# In main.py or a startup event
from app.config import settings


def validate_settings():
    """Validate critical settings on startup. Fail fast if misconfigured."""
    errors = []

    if not settings.DATABASE_URL:
        errors.append("DATABASE_URL is required")

    if not settings.SECRET_KEY:
        errors.append("SECRET_KEY is required")

    if settings.ENVIRONMENT == "production":
        if settings.DEBUG:
            errors.append("DEBUG must be false in production")
        if len(settings.SECRET_KEY) < 32:
            errors.append("SECRET_KEY must be at least 32 characters in production")
        if "localhost" in settings.DATABASE_URL:
            errors.append("DATABASE_URL should not point to localhost in production")

    if errors:
        for e in errors:
            print(f"CONFIG ERROR: {e}")
        raise SystemExit(1)


# Call during startup
validate_settings()
```

## Secret Handling

### What Counts as a Secret
- Database passwords
- API keys (AI providers, payment processors, email services)
- JWT secret keys
- OAuth client secrets
- Encryption keys

### Rules for Secrets
1. **Never commit to git** — `.env` is always in `.gitignore`
2. **Never log secrets** — sanitize logs to redact sensitive values
3. **Rotate regularly** — especially after team member departures
4. **Use secret managers in production** — AWS Secrets Manager, HashiCorp Vault, or GitHub Actions secrets
5. **Minimum privilege** — each service gets only the secrets it needs

### .gitignore Entries
```gitignore
# Environment files with secrets
.env
.env.local
.env.*.local
.env.staging
.env.production

# Keep the example file committed
!.env.example
```

### Generating Secrets
```bash
# Generate a secure random secret key
python -c "import secrets; print(secrets.token_urlsafe(64))"
```

## .env.example Maintenance

### Rules
- `.env.example` is always committed to version control
- It contains every variable the application uses
- Secret values are replaced with descriptive placeholders
- Default values for non-secrets can be real values
- Comments explain what each variable does

### Template
```env
# Copy this file to .env and fill in the values
# cp .env.example .env

ENVIRONMENT=development
DEBUG=true

DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/myapp
SECRET_KEY=<generate-with: python -c "import secrets; print(secrets.token_urlsafe(64))">

AI_ANTHROPIC_API_KEY=<your-anthropic-api-key>
AI_OPENAI_API_KEY=<your-openai-api-key>
```

### Keeping .env.example Updated
Whenever a new environment variable is added to the application:
1. Add it to `.env.example` with a placeholder or default value
2. Add it to the `Settings` class in `config.py`
3. Document whether it is required or optional
4. If it is a secret, use a `<descriptive-placeholder>` in `.env.example`

## 12-Factor App Compliance

This standard follows the [12-Factor App](https://12factor.net/) methodology for configuration:

| Factor | Implementation |
|--------|---------------|
| **III. Config** | All config via environment variables, not code |
| **IV. Backing Services** | Database, Redis, AI APIs configured via URLs in env vars |
| **V. Build, Release, Run** | Same build artifact, different env vars per environment |
| **X. Dev/Prod Parity** | Same config structure across all environments |

## Validation Checklist

Before deploying to any environment, verify:
- [ ] `.env` is in `.gitignore`
- [ ] `.env.example` is committed and up-to-date
- [ ] All required variables are documented
- [ ] Production secrets are not in any committed file
- [ ] Startup validation catches missing required variables
- [ ] No `localhost` URLs in production config
- [ ] `DEBUG=false` in production
- [ ] `SECRET_KEY` is unique, random, and at least 32 characters in production
