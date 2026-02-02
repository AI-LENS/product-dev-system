# Authentication Patterns

Python + FastAPI authentication implementation patterns. Reference this file for all auth-related development.

## 1. JWT Implementation

### Token Configuration

```python
# app/core/config.py
class AuthSettings(BaseModel):
    JWT_SECRET_KEY: str                # From environment, never hardcoded
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    TOKEN_ISSUER: str = "your-app-name"
    TOKEN_AUDIENCE: str = "your-app-api"
```

### Token Creation

```python
# app/auth/tokens.py
from datetime import datetime, timedelta, timezone
from jose import jwt
from uuid import uuid4

def create_access_token(
    user_id: str,
    role: str,
    permissions: list[str] | None = None,
) -> str:
    """Create a short-lived access token (15 minutes)."""
    now = datetime.now(timezone.utc)
    payload = {
        "sub": user_id,                                # Subject (user ID)
        "role": role,                                   # User role
        "permissions": permissions or [],               # Fine-grained permissions
        "type": "access",                               # Token type
        "iat": now,                                     # Issued at
        "exp": now + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
        "iss": settings.TOKEN_ISSUER,                   # Issuer
        "aud": settings.TOKEN_AUDIENCE,                 # Audience
        "jti": str(uuid4()),                            # Unique token ID
    }
    return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)

def create_refresh_token(user_id: str) -> tuple[str, str]:
    """
    Create a long-lived refresh token (7 days).
    Returns: (token_string, token_jti) — store the JTI for revocation.
    """
    now = datetime.now(timezone.utc)
    jti = str(uuid4())
    payload = {
        "sub": user_id,
        "type": "refresh",
        "iat": now,
        "exp": now + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
        "iss": settings.TOKEN_ISSUER,
        "jti": jti,
    }
    token = jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return token, jti

def decode_token(token: str) -> dict:
    """Decode and validate a JWT token."""
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
            audience=settings.TOKEN_AUDIENCE,
            issuer=settings.TOKEN_ISSUER,
        )
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token has expired")
    except jwt.JWTClaimsError:
        raise HTTPException(status_code=401, detail="Invalid token claims")
    except jwt.JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
```

### Token Response

```python
class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int  # Seconds until access token expires

def create_token_pair(user: User) -> TokenResponse:
    """Create both access and refresh tokens."""
    access_token = create_access_token(
        user_id=str(user.id),
        role=user.role,
        permissions=user.permissions,
    )
    refresh_token, refresh_jti = create_refresh_token(str(user.id))

    # Store refresh token JTI in database for revocation tracking
    store_refresh_token(user_id=user.id, jti=refresh_jti)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )
```

## 2. Password Hashing

```python
# app/auth/password.py
from passlib.context import CryptContext

pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto",
    bcrypt__rounds=12,  # Cost factor — increase for higher security, decrease for speed
)

def hash_password(password: str) -> str:
    """Hash a plaintext password using bcrypt."""
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a plaintext password against a bcrypt hash."""
    return pwd_context.verify(plain_password, hashed_password)
```

## 3. FastAPI OAuth2PasswordBearer

```python
# app/auth/dependencies.py
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

async def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    """
    Decode the access token and return the current user.
    Used as a FastAPI dependency on protected endpoints.
    """
    payload = decode_token(token)

    if payload.get("type") != "access":
        raise HTTPException(status_code=401, detail="Invalid token type")

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token payload")

    user = await get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=401, detail="User not found")

    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is disabled")

    return user

async def get_current_active_user(
    current_user: User = Depends(get_current_user),
) -> User:
    """Alias that ensures the user is active. Use on endpoints requiring active status."""
    return current_user
```

## 4. Dependency Injection for Current User

### Basic Usage

```python
from fastapi import APIRouter, Depends

router = APIRouter()

@router.get("/api/v1/profile")
async def get_profile(current_user: User = Depends(get_current_user)):
    """Any authenticated user can access their profile."""
    return current_user

@router.put("/api/v1/profile")
async def update_profile(
    data: ProfileUpdate,
    current_user: User = Depends(get_current_user),
):
    """Update the authenticated user's profile."""
    return await update_user(current_user.id, data)
```

### Role-Based Dependencies

```python
def require_role(*roles: str):
    """Dependency that checks if user has one of the specified roles."""
    async def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in roles:
            raise HTTPException(
                status_code=403,
                detail=f"Role '{current_user.role}' does not have access. Required: {', '.join(roles)}",
            )
        return current_user
    return role_checker

# Usage
@router.get("/api/v1/admin/users")
async def list_all_users(admin: User = Depends(require_role("admin"))):
    return await get_all_users()

@router.delete("/api/v1/admin/users/{user_id}")
async def delete_user(
    user_id: str,
    admin: User = Depends(require_role("admin")),
):
    return await remove_user(user_id)
```

### Permission-Based Dependencies

```python
def require_permission(permission: str):
    """Dependency that checks if user has a specific permission."""
    async def permission_checker(current_user: User = Depends(get_current_user)) -> User:
        user_perms = get_permissions_for_role(current_user.role)
        if "*" not in user_perms and permission not in user_perms:
            raise HTTPException(status_code=403, detail="Insufficient permissions")
        return current_user
    return permission_checker

# Usage
@router.post("/api/v1/reports/export")
async def export_report(
    request: ExportRequest,
    user: User = Depends(require_permission("reports:export")),
):
    ...
```

### Optional Authentication

```python
async def get_optional_user(
    token: str | None = Depends(OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login", auto_error=False)),
) -> User | None:
    """Returns user if authenticated, None if not. For endpoints accessible to both."""
    if not token:
        return None
    try:
        return await get_current_user(token)
    except HTTPException:
        return None

@router.get("/api/v1/content/{id}")
async def get_content(
    id: str,
    current_user: User | None = Depends(get_optional_user),
):
    """Public content, but authenticated users see additional data."""
    content = await get_content_by_id(id)
    if current_user:
        content.show_private_fields = True
    return content
```

## 5. Token Refresh Rotation

Refresh tokens are single-use. When a refresh token is used, a new pair is issued and the old refresh token is invalidated.

```python
# app/auth/refresh.py

@router.post("/api/v1/auth/refresh")
async def refresh_tokens(request: RefreshRequest):
    """
    Exchange a refresh token for a new access + refresh token pair.
    The old refresh token is invalidated immediately.
    """
    # 1. Decode the refresh token
    payload = decode_token(request.refresh_token)

    if payload.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Invalid token type")

    jti = payload.get("jti")
    user_id = payload.get("sub")

    # 2. Check if refresh token has been used (revoked)
    if await is_refresh_token_revoked(jti):
        # Token reuse detected — possible theft!
        # Invalidate ALL refresh tokens for this user
        await revoke_all_refresh_tokens(user_id)
        security_logger.error("refresh_token_reuse_detected",
            user_id=user_id, jti=jti)
        raise HTTPException(status_code=401, detail="Token has been revoked. Please log in again.")

    # 3. Revoke the current refresh token
    await revoke_refresh_token(jti)

    # 4. Get the user
    user = await get_user_by_id(user_id)
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="User not found or inactive")

    # 5. Issue new token pair
    return create_token_pair(user)
```

### Refresh Token Storage

```python
# Database model for tracking refresh tokens
class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id = Column(String, primary_key=True, default=lambda: str(uuid4()))
    user_id = Column(String, ForeignKey("users.id"), index=True)
    jti = Column(String, unique=True, index=True)  # JWT ID for lookup
    revoked = Column(Boolean, default=False)
    revoked_at = Column(DateTime, nullable=True)
    expires_at = Column(DateTime)
    created_at = Column(DateTime, default=datetime.utcnow)
    ip_address = Column(String, nullable=True)
    user_agent = Column(String, nullable=True)

async def store_refresh_token(user_id: str, jti: str, request: Request | None = None):
    token = RefreshToken(
        user_id=user_id,
        jti=jti,
        expires_at=datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
        ip_address=request.client.host if request else None,
        user_agent=request.headers.get("user-agent") if request else None,
    )
    db.add(token)
    await db.commit()

async def is_refresh_token_revoked(jti: str) -> bool:
    token = await db.get(RefreshToken, jti=jti)
    return token is None or token.revoked

async def revoke_refresh_token(jti: str):
    token = await db.get(RefreshToken, jti=jti)
    if token:
        token.revoked = True
        token.revoked_at = datetime.utcnow()
        await db.commit()

async def revoke_all_refresh_tokens(user_id: str):
    """Revoke all active refresh tokens for a user (nuclear option)."""
    await db.execute(
        update(RefreshToken)
        .where(RefreshToken.user_id == user_id, RefreshToken.revoked == False)
        .values(revoked=True, revoked_at=datetime.utcnow())
    )
    await db.commit()
```

## 6. Role-Based Access Control Middleware

```python
# app/middleware/rbac.py
from starlette.middleware.base import BaseHTTPMiddleware

class RBACMiddleware(BaseHTTPMiddleware):
    """
    Optional middleware for route-level RBAC.
    Useful when you want to define permissions in route configuration
    rather than per-endpoint dependencies.
    """

    # Route permission map
    ROUTE_PERMISSIONS = {
        "/api/v1/admin/*": {"admin"},
        "/api/v1/users/*/manage": {"admin", "manager"},
        "/api/v1/reports/export": {"admin", "manager", "analyst"},
    }

    async def dispatch(self, request, call_next):
        # Skip auth for public routes
        if self._is_public_route(request.url.path):
            return await call_next(request)

        # Check route permissions
        required_roles = self._get_required_roles(request.url.path)
        if required_roles:
            user = getattr(request.state, "user", None)
            if not user or user.role not in required_roles:
                return JSONResponse(status_code=403, content={"detail": "Forbidden"})

        return await call_next(request)

    def _is_public_route(self, path: str) -> bool:
        public = ["/api/v1/auth/login", "/api/v1/auth/register", "/api/v1/health", "/docs", "/openapi.json"]
        return any(path.startswith(p) for p in public)

    def _get_required_roles(self, path: str) -> set[str] | None:
        import fnmatch
        for pattern, roles in self.ROUTE_PERMISSIONS.items():
            if fnmatch.fnmatch(path, pattern):
                return roles
        return None
```

## 7. Registration Flow

```python
# app/api/v1/auth.py
from pydantic import BaseModel, Field, EmailStr

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    name: str = Field(min_length=1, max_length=100)

class RegisterResponse(BaseModel):
    user_id: str
    email: str
    message: str

@router.post("/api/v1/auth/register", response_model=RegisterResponse)
async def register(request: RegisterRequest):
    """
    Register a new user account.
    """
    # 1. Check if email already exists
    existing = await get_user_by_email(request.email)
    if existing:
        raise HTTPException(status_code=409, detail="Email already registered")

    # 2. Validate password strength
    validate_password_strength(request.password)

    # 3. Hash password
    hashed = hash_password(request.password)

    # 4. Create user
    user = await create_user(
        email=request.email,
        password_hash=hashed,
        name=request.name,
        role="user",  # Default role
        is_active=True,  # Set False if email verification required
    )

    # 5. (Optional) Send verification email
    if settings.REQUIRE_EMAIL_VERIFICATION:
        token = create_email_verification_token(user.id)
        await send_verification_email(user.email, token)
        return RegisterResponse(
            user_id=str(user.id),
            email=user.email,
            message="Account created. Please check your email to verify.",
        )

    # 6. Log security event
    security_logger.info("user_registered", user_id=str(user.id), email=user.email)

    return RegisterResponse(
        user_id=str(user.id),
        email=user.email,
        message="Account created successfully.",
    )
```

### Email Verification (Optional)

```python
@router.post("/api/v1/auth/verify-email")
async def verify_email(token: str):
    """Verify user's email address using the token sent via email."""
    payload = decode_token(token)
    if payload.get("type") != "email_verification":
        raise HTTPException(status_code=400, detail="Invalid verification token")

    user = await get_user_by_id(payload["sub"])
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.is_email_verified = True
    user.is_active = True
    await db.commit()

    return {"message": "Email verified successfully. You can now log in."}
```

## 8. Password Reset Flow

```python
@router.post("/api/v1/auth/forgot-password")
async def forgot_password(request: ForgotPasswordRequest):
    """
    Send a password reset email.
    Always returns success to prevent email enumeration.
    """
    user = await get_user_by_email(request.email)
    if user:
        token = create_password_reset_token(user.id)  # 1-hour expiry
        await send_password_reset_email(user.email, token)
        security_logger.info("password_reset_requested", user_id=str(user.id))

    # Always return the same response (prevent email enumeration)
    return {"message": "If an account exists with this email, a reset link has been sent."}

@router.post("/api/v1/auth/reset-password")
async def reset_password(request: ResetPasswordRequest):
    """Reset password using the token from the email."""
    # 1. Decode and validate reset token
    payload = decode_token(request.token)
    if payload.get("type") != "password_reset":
        raise HTTPException(status_code=400, detail="Invalid reset token")

    # 2. Check if token has been used
    if await is_reset_token_used(payload["jti"]):
        raise HTTPException(status_code=400, detail="Reset token has already been used")

    # 3. Get user
    user = await get_user_by_id(payload["sub"])
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # 4. Validate new password
    validate_password_strength(request.new_password)

    # 5. Hash and update password
    user.password_hash = hash_password(request.new_password)
    await db.commit()

    # 6. Mark reset token as used
    await mark_reset_token_used(payload["jti"])

    # 7. Revoke all existing refresh tokens (force re-login everywhere)
    await revoke_all_refresh_tokens(str(user.id))

    # 8. Log security event
    security_logger.info("password_reset_completed", user_id=str(user.id))

    return {"message": "Password reset successfully. Please log in with your new password."}
```

## 9. Session Management Considerations

While JWTs are stateless, some scenarios require session-like tracking:

```python
# Track active sessions per user
class UserSession(Base):
    __tablename__ = "user_sessions"

    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.id"), index=True)
    refresh_token_jti = Column(String, unique=True)
    ip_address = Column(String)
    user_agent = Column(String)
    device_name = Column(String, nullable=True)
    last_active = Column(DateTime, default=datetime.utcnow)
    created_at = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)

# Endpoints for session management
@router.get("/api/v1/auth/sessions")
async def list_sessions(current_user: User = Depends(get_current_user)):
    """List all active sessions for the current user."""
    sessions = await get_active_sessions(current_user.id)
    return [
        {
            "id": s.id,
            "device": s.device_name or "Unknown device",
            "ip": s.ip_address,
            "last_active": s.last_active,
            "is_current": s.refresh_token_jti == current_session_jti,
        }
        for s in sessions
    ]

@router.delete("/api/v1/auth/sessions/{session_id}")
async def revoke_session(
    session_id: str,
    current_user: User = Depends(get_current_user),
):
    """Revoke a specific session (logout from a device)."""
    session = await get_session(session_id)
    if not session or session.user_id != str(current_user.id):
        raise HTTPException(status_code=404)
    await revoke_refresh_token(session.refresh_token_jti)
    session.is_active = False
    await db.commit()
    return {"message": "Session revoked"}

@router.post("/api/v1/auth/logout-all")
async def logout_all(current_user: User = Depends(get_current_user)):
    """Revoke all sessions (logout everywhere)."""
    await revoke_all_refresh_tokens(str(current_user.id))
    return {"message": "All sessions revoked"}
```

## 10. Multi-Tenancy Patterns

If the application serves multiple organizations/tenants:

```python
# Option A: Tenant ID in JWT claims
def create_access_token(user_id: str, role: str, tenant_id: str) -> str:
    payload = {
        "sub": user_id,
        "role": role,
        "tenant_id": tenant_id,  # Tenant isolation
        "type": "access",
        ...
    }
    return jwt.encode(payload, ...)

# Option B: Tenant resolution middleware
class TenantMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        # Resolve tenant from subdomain, header, or JWT
        tenant = resolve_tenant(request)
        request.state.tenant_id = tenant.id
        return await call_next(request)

# Ensure all queries are scoped to tenant
async def get_items(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Always filter by tenant
    stmt = select(Item).where(Item.tenant_id == current_user.tenant_id)
    return (await db.execute(stmt)).scalars().all()
```

## Login Endpoint

```python
from fastapi.security import OAuth2PasswordRequestForm

@router.post("/api/v1/auth/login", response_model=TokenResponse)
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    """
    OAuth2 compatible login endpoint.
    Returns access + refresh token pair.
    """
    # 1. Find user by email
    user = await get_user_by_email(form_data.username)  # OAuth2 uses 'username' field

    # 2. Verify password (constant-time comparison via passlib)
    if not user or not verify_password(form_data.password, user.password_hash):
        security_logger.warning("login_failed",
            email=form_data.username,
            reason="invalid_credentials")
        # Use generic message to prevent user enumeration
        raise HTTPException(status_code=401, detail="Invalid email or password")

    # 3. Check account status
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is disabled")

    # 4. Create token pair
    tokens = create_token_pair(user)

    # 5. Log success
    security_logger.info("login_success", user_id=str(user.id))

    return tokens
```
