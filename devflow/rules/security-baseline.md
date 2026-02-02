# Security Baseline

OWASP-aligned security standards for Python + FastAPI applications. All code must comply with these rules.

## 1. Injection Prevention

### Parameterized Queries (SQL Injection)

Never construct SQL queries with string concatenation or f-strings. Always use parameterized queries.

```python
# WRONG — SQL injection vulnerable
query = f"SELECT * FROM users WHERE email = '{email}'"
db.execute(query)

# CORRECT — parameterized query with SQLAlchemy
stmt = select(User).where(User.email == email)
result = db.execute(stmt)

# CORRECT — raw SQL with parameters (when ORM is insufficient)
result = db.execute(text("SELECT * FROM users WHERE email = :email"), {"email": email})
```

### Input Sanitization

Validate and sanitize all user inputs at the API boundary:

```python
from pydantic import BaseModel, Field, validator
import re

class UserInput(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    email: str = Field(pattern=r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
    bio: str = Field(max_length=500)

    @validator('name')
    def sanitize_name(cls, v):
        # Strip control characters
        return re.sub(r'[\x00-\x1f\x7f-\x9f]', '', v).strip()
```

### Command Injection

Never pass user input to shell commands. If shell execution is absolutely necessary:

```python
import subprocess

# WRONG
subprocess.run(f"convert {user_filename} output.png", shell=True)

# CORRECT — use list form, never shell=True with user input
subprocess.run(["convert", user_filename, "output.png"], shell=False)
```

## 2. XSS Prevention

### Output Encoding

When rendering user-generated content:

- **Angular:** Built-in XSS protection — Angular sanitizes by default. Never use `bypassSecurityTrustHtml()` unless absolutely necessary and the content is sanitized server-side.
- **Backend API:** Return data as JSON (automatically escaped). Never return raw HTML with user content embedded.

### Content Security Policy (CSP)

```python
# app/middleware/security_headers.py
from starlette.middleware.base import BaseHTTPMiddleware

class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        response = await call_next(request)
        response.headers["Content-Security-Policy"] = (
            "default-src 'self'; "
            "script-src 'self'; "
            "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; "
            "font-src 'self' https://fonts.gstatic.com; "
            "img-src 'self' data: https:; "
            "connect-src 'self' https://api.example.com; "
            "frame-ancestors 'none';"
        )
        return response
```

## 3. Authentication Best Practices

### Password Hashing

Always use bcrypt with a cost factor of at least 12:

```python
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto", bcrypt__rounds=12)

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)
```

### Password Requirements

Enforce minimum standards:
- Minimum 8 characters
- No maximum length below 128 characters (bcrypt truncates at 72 bytes)
- Check against common password lists (top 10,000)
- Do not require specific character classes (NIST 800-63B recommendation)

```python
from pydantic import BaseModel, Field, validator

COMMON_PASSWORDS = set()  # Load from file at startup

class PasswordInput(BaseModel):
    password: str = Field(min_length=8, max_length=128)

    @validator('password')
    def check_common(cls, v):
        if v.lower() in COMMON_PASSWORDS:
            raise ValueError('This password is too common. Please choose a different one.')
        return v
```

### JWT Token Rotation

See `devflow/rules/auth-patterns.md` for full JWT implementation details.

- Access token: short-lived (15 minutes)
- Refresh token: longer-lived (7 days), single-use with rotation
- Invalidate old refresh tokens on use (prevent replay)

## 4. Authorization Patterns

### Role-Based Access Control (RBAC)

```python
from enum import Enum
from functools import wraps

class Role(str, Enum):
    ADMIN = "admin"
    MANAGER = "manager"
    USER = "user"
    VIEWER = "viewer"

# Permission matrix
PERMISSIONS = {
    Role.ADMIN: {"*"},  # All permissions
    Role.MANAGER: {"read", "write", "delete_own", "manage_team"},
    Role.USER: {"read", "write", "delete_own"},
    Role.VIEWER: {"read"},
}

def require_permission(permission: str):
    """FastAPI dependency for permission checking."""
    async def check(current_user: User = Depends(get_current_user)):
        user_perms = PERMISSIONS.get(current_user.role, set())
        if "*" not in user_perms and permission not in user_perms:
            raise HTTPException(status_code=403, detail="Insufficient permissions")
        return current_user
    return check
```

### Resource-Level Permissions

```python
async def check_resource_access(
    resource_id: str,
    user: User,
    action: str,  # "read", "write", "delete"
) -> bool:
    """Check if user can perform action on a specific resource."""
    resource = await get_resource(resource_id)
    if not resource:
        raise HTTPException(status_code=404)

    # Owner can do anything
    if resource.owner_id == user.id:
        return True

    # Admin can do anything
    if user.role == Role.ADMIN:
        return True

    # Check explicit grants
    grant = await get_resource_grant(resource_id, user.id)
    if grant and action in grant.permissions:
        return True

    raise HTTPException(status_code=403, detail="Access denied to this resource")
```

## 5. Security Headers

Every response must include these headers:

```python
# All security headers in one middleware
class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        response = await call_next(request)

        # Prevent MIME type sniffing
        response.headers["X-Content-Type-Options"] = "nosniff"

        # Prevent clickjacking
        response.headers["X-Frame-Options"] = "DENY"

        # Enable XSS filter (legacy browsers)
        response.headers["X-XSS-Protection"] = "1; mode=block"

        # Enforce HTTPS
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains; preload"

        # Referrer policy
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"

        # Permissions policy
        response.headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()"

        # CSP (see XSS Prevention section)
        response.headers["Content-Security-Policy"] = "default-src 'self'; frame-ancestors 'none';"

        return response
```

## 6. CORS Configuration

Whitelist specific origins. Never use `allow_origins=["*"]` in production.

```python
from fastapi.middleware.cors import CORSMiddleware

# Development
CORS_ORIGINS_DEV = [
    "http://localhost:4200",   # Angular dev server
    "http://localhost:3000",   # React dev server (if used)
]

# Production
CORS_ORIGINS_PROD = [
    "https://app.example.com",
    "https://www.example.com",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,  # From config, never "*"
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH"],
    allow_headers=["Authorization", "Content-Type"],
    max_age=600,  # Preflight cache: 10 minutes
)
```

## 7. Secret Management

### Rules

1. **Never commit secrets to version control** — no API keys, passwords, tokens, or certificates in code
2. **Use environment variables** for all secrets
3. **`.env` file must be in `.gitignore`** — always verify
4. **Provide `.env.example`** with placeholder values for documentation
5. **Use a secrets manager in production** (AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager)

### Configuration Pattern

```python
# app/core/config.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Database
    DATABASE_URL: str  # Required, no default — forces explicit configuration
    DATABASE_POOL_SIZE: int = 10

    # Auth
    JWT_SECRET_KEY: str  # Required, no default
    JWT_ALGORITHM: str = "HS256"

    # AI Providers
    ANTHROPIC_API_KEY: str | None = None
    OPENAI_API_KEY: str | None = None

    # CORS
    CORS_ORIGINS: list[str] = ["http://localhost:4200"]

    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
```

### .env.example

```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/dbname

# Auth
JWT_SECRET_KEY=your-secret-key-here-change-in-production

# AI Providers (optional — set the ones you use)
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...

# CORS
CORS_ORIGINS=["http://localhost:4200"]
```

### Verification

```bash
# Ensure .env is gitignored
grep -q "^\.env$" .gitignore || echo "CRITICAL: .env is not in .gitignore"

# Check for committed secrets
git log --all --diff-filter=A -- "*.env" ".env" 2>/dev/null
```

## 8. Dependency Scanning

### Python Dependencies

```bash
# Install pip-audit
pip install pip-audit

# Run audit
pip-audit --format=json --output=audit-report.json

# Alternative: safety
pip install safety
safety check --json --output=safety-report.json
```

### Node.js Dependencies

```bash
# Built-in npm audit
npm audit --json > npm-audit.json

# Fix automatically where possible
npm audit fix

# For breaking changes
npm audit fix --force  # Use with caution
```

### Automation

Add dependency scanning to CI/CD pipeline. Block merges if critical vulnerabilities are found.

```yaml
# .github/workflows/security.yml
- name: Python dependency audit
  run: pip-audit --strict --desc on

- name: Node dependency audit
  run: npm audit --audit-level=high
```

## 9. Rate Limiting

### FastAPI Middleware

```python
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address)

# Global rate limit
@app.exception_handler(RateLimitExceeded)
async def rate_limit_handler(request, exc):
    return JSONResponse(
        status_code=429,
        content={"detail": "Rate limit exceeded. Please try again later."},
        headers={"Retry-After": str(exc.retry_after)},
    )

# Per-endpoint rate limits
@router.post("/api/v1/auth/login")
@limiter.limit("5/minute")  # Prevent brute force
async def login(request: Request, credentials: LoginRequest):
    ...

@router.post("/api/v1/ai/chat")
@limiter.limit("30/minute")  # Prevent AI abuse
async def chat(request: Request, message: ChatRequest):
    ...

# Per-user rate limits (when authenticated)
def get_user_key(request: Request) -> str:
    """Rate limit by user ID instead of IP."""
    user = request.state.user
    return f"user:{user.id}" if user else get_remote_address(request)
```

### Rate Limit Tiers

| Endpoint Category | Anonymous | Authenticated | Admin |
|-------------------|-----------|---------------|-------|
| Auth (login/register) | 5/min | N/A | N/A |
| Read endpoints | 60/min | 120/min | 600/min |
| Write endpoints | N/A | 30/min | 120/min |
| AI endpoints | N/A | 20/min | 60/min |
| File upload | N/A | 5/min | 20/min |

## 10. HTTPS Enforcement

### Production

- All traffic must be served over HTTPS
- Redirect HTTP to HTTPS at the load balancer or reverse proxy level
- HSTS header enforces HTTPS for subsequent visits (see Security Headers)

### Development

- Use HTTPS locally with self-signed certificates for testing:
  ```bash
  # Generate self-signed cert for local dev
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout localhost.key -out localhost.crt \
    -subj "/CN=localhost"

  # Run uvicorn with SSL
  uvicorn app.main:app --ssl-keyfile=localhost.key --ssl-certfile=localhost.crt
  ```

### Cookie Security

```python
# Secure cookie settings
COOKIE_SETTINGS = {
    "httponly": True,      # Prevent JavaScript access
    "secure": True,        # HTTPS only (set False in dev)
    "samesite": "lax",     # CSRF protection
    "max_age": 604800,     # 7 days for refresh token cookie
    "path": "/api/v1/auth", # Restrict cookie path
}
```

## 11. Security Event Logging

Log all security-relevant events for monitoring and incident response:

```python
import logging
import structlog

security_logger = structlog.get_logger("security")

# Events to log:

# Failed login attempts
security_logger.warning("login_failed",
    email=email,
    ip=request.client.host,
    reason="invalid_password",
    attempt_count=attempt_count,
)

# Successful logins
security_logger.info("login_success",
    user_id=user.id,
    ip=request.client.host,
)

# Permission denials
security_logger.warning("permission_denied",
    user_id=user.id,
    resource=resource_id,
    action=action,
    required_permission=permission,
)

# Rate limit hits
security_logger.warning("rate_limit_exceeded",
    ip=request.client.host,
    endpoint=request.url.path,
    user_id=getattr(request.state, 'user_id', None),
)

# Suspicious activity
security_logger.error("suspicious_activity",
    ip=request.client.host,
    reason="sql_injection_attempt",
    payload=sanitized_payload,  # Sanitize before logging
)

# Password changes
security_logger.info("password_changed",
    user_id=user.id,
    ip=request.client.host,
)

# Token refresh
security_logger.info("token_refreshed",
    user_id=user.id,
    ip=request.client.host,
)
```

### Alerting Thresholds

| Event | Threshold | Action |
|-------|-----------|--------|
| Failed logins (same IP) | 10/hour | Temporary IP block |
| Failed logins (same account) | 5/hour | Account lockout + email notification |
| Permission denials | 20/hour (same user) | Alert security team |
| Rate limit hits | 100/hour (same IP) | Extended rate limit |
| SQL injection patterns | Any | Alert + log full request |

## Compliance Checklist

Before deploying, verify:

- [ ] All SQL queries use parameterized statements or ORM
- [ ] All user inputs validated with Pydantic models
- [ ] Passwords hashed with bcrypt (cost factor >= 12)
- [ ] JWT tokens have appropriate expiration (access: 15min, refresh: 7d)
- [ ] Security headers set on all responses
- [ ] CORS configured with specific origins (no wildcard in production)
- [ ] `.env` in `.gitignore`, `.env.example` provided
- [ ] No secrets in code, git history, or logs
- [ ] Rate limiting on auth and write endpoints
- [ ] HTTPS enforced in production
- [ ] Dependency scanning in CI/CD
- [ ] Security events logged with structured logging
- [ ] Error responses do not leak stack traces or internal details in production
