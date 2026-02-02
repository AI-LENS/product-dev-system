---
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - LS
---

# Auth Setup

## Usage
```
/init:auth
```

## Description
Sets up JWT-based authentication for a Python + FastAPI backend. Creates access and refresh tokens, password hashing, user model, login/register/refresh endpoints, FastAPI dependency injection for protected routes, and an RBAC middleware skeleton.

## Prerequisites
- Backend project exists with `backend/app/` structure
- Database layer initialized (`/init:database` has been run)
- `backend/app/core/database.py` and `backend/app/models/base.py` exist

If prerequisites are not met:
```
❌ Database layer not found. Run /init:database first.
```

## Execution

### Step 1: Verify Structure
```bash
test -f backend/app/core/database.py || echo "MISSING_DATABASE"
test -f backend/app/models/base.py || echo "MISSING_BASE_MODEL"
```

### Step 2: Create User Model

#### backend/app/models/user.py
```python
from sqlalchemy import Column, String, Boolean, Enum
from sqlalchemy.orm import Mapped, mapped_column
import enum

from app.core.database import Base
from app.models.base import TimestampMixin


class UserRole(str, enum.Enum):
    admin = "admin"
    user = "user"
    moderator = "moderator"


class User(TimestampMixin, Base):
    __tablename__ = "users"

    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    role: Mapped[UserRole] = mapped_column(
        Enum(UserRole),
        default=UserRole.user,
        nullable=False,
    )
```

Update `backend/app/models/__init__.py` to include the User model:
```python
from app.models.base import TimestampMixin
from app.core.database import Base
from app.models.user import User, UserRole

__all__ = ["Base", "TimestampMixin", "User", "UserRole"]
```

Update `backend/alembic/env.py` to import the User model:
Add this import near the top of the file with the other model imports:
```python
from app.models.user import User  # noqa: F401
```

### Step 3: Create Auth Schemas

#### backend/app/schemas/auth.py
```python
from pydantic import BaseModel, EmailStr, Field


class UserRegister(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    full_name: str | None = None


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: int
    email: str
    full_name: str | None
    is_active: bool
    role: str

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class TokenRefresh(BaseModel):
    refresh_token: str


class TokenPayload(BaseModel):
    sub: int
    role: str
    exp: int
    type: str  # "access" or "refresh"
```

### Step 4: Create Security Core Module

#### backend/app/core/security.py
```python
from datetime import datetime, timedelta, timezone
from typing import Any

from jose import jwt, JWTError
from passlib.context import CryptContext
from app.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = settings.ACCESS_TOKEN_EXPIRE_MINUTES
REFRESH_TOKEN_EXPIRE_DAYS = 7


def hash_password(password: str) -> str:
    """Hash a plaintext password using bcrypt."""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a plaintext password against its hash."""
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(subject: int, role: str, expires_delta: timedelta | None = None) -> str:
    """Create a JWT access token."""
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)

    to_encode: dict[str, Any] = {
        "sub": subject,
        "role": role,
        "exp": expire,
        "type": "access",
    }
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=ALGORITHM)


def create_refresh_token(subject: int, role: str) -> str:
    """Create a JWT refresh token with longer expiry."""
    expire = datetime.now(timezone.utc) + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode: dict[str, Any] = {
        "sub": subject,
        "role": role,
        "exp": expire,
        "type": "refresh",
    }
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=ALGORITHM)


def decode_token(token: str) -> dict[str, Any] | None:
    """Decode and validate a JWT token. Returns payload or None if invalid."""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        return None
```

### Step 5: Create Auth Dependencies

#### backend/app/api/deps.py
```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.security import decode_token
from app.models.user import User, UserRole

security_scheme = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    """Extract and validate the current user from the JWT access token."""
    payload = decode_token(credentials.credentials)

    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )

    if payload.get("type") != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token type — expected access token",
        )

    user_id: int = payload.get("sub")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token missing subject claim",
        )

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is deactivated",
        )

    return user


def require_role(*roles: UserRole):
    """Dependency factory that restricts access to specific roles."""

    async def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Insufficient permissions. Required role: {', '.join(r.value for r in roles)}",
            )
        return current_user

    return role_checker
```

### Step 6: Create Auth Endpoints

#### backend/app/api/v1/auth.py
```python
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
)
from app.models.user import User
from app.schemas.auth import (
    UserRegister,
    UserLogin,
    UserResponse,
    TokenResponse,
    TokenRefresh,
)
from app.api.deps import get_current_user

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(payload: UserRegister, db: AsyncSession = Depends(get_db)):
    """Register a new user account."""
    result = await db.execute(select(User).where(User.email == payload.email))
    existing = result.scalar_one_or_none()

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )

    user = User(
        email=payload.email,
        hashed_password=hash_password(payload.password),
        full_name=payload.full_name,
    )
    db.add(user)
    await db.flush()
    await db.refresh(user)

    access_token = create_access_token(subject=user.id, role=user.role.value)
    refresh_token = create_refresh_token(subject=user.id, role=user.role.value)

    return TokenResponse(access_token=access_token, refresh_token=refresh_token)


@router.post("/login", response_model=TokenResponse)
async def login(payload: UserLogin, db: AsyncSession = Depends(get_db)):
    """Authenticate and receive access + refresh tokens."""
    result = await db.execute(select(User).where(User.email == payload.email))
    user = result.scalar_one_or_none()

    if not user or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is deactivated",
        )

    access_token = create_access_token(subject=user.id, role=user.role.value)
    refresh_token = create_refresh_token(subject=user.id, role=user.role.value)

    return TokenResponse(access_token=access_token, refresh_token=refresh_token)


@router.post("/refresh", response_model=TokenResponse)
async def refresh(payload: TokenRefresh, db: AsyncSession = Depends(get_db)):
    """Exchange a refresh token for a new access + refresh token pair."""
    token_data = decode_token(payload.refresh_token)

    if token_data is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
        )

    if token_data.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token type — expected refresh token",
        )

    user_id = token_data.get("sub")
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()

    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or deactivated",
        )

    access_token = create_access_token(subject=user.id, role=user.role.value)
    refresh_token = create_refresh_token(subject=user.id, role=user.role.value)

    return TokenResponse(access_token=access_token, refresh_token=refresh_token)


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    """Get the current authenticated user's profile."""
    return current_user
```

### Step 7: Register Auth Router

Update `backend/app/api/v1/router.py` to include the auth router:
```python
from fastapi import APIRouter
from app.api.v1.auth import router as auth_router

api_router = APIRouter()
api_router.include_router(auth_router)


@api_router.get("/ping")
async def ping():
    return {"message": "pong"}
```

### Step 8: Create RBAC Middleware Skeleton

#### backend/app/core/rbac.py
```python
"""
Role-Based Access Control (RBAC) middleware and utilities.

Usage in routes:
    from app.api.deps import require_role
    from app.models.user import UserRole

    @router.get("/admin/dashboard")
    async def admin_dashboard(user: User = Depends(require_role(UserRole.admin))):
        return {"message": "Welcome, admin"}

    @router.get("/mod/queue")
    async def mod_queue(user: User = Depends(require_role(UserRole.admin, UserRole.moderator))):
        return {"message": "Moderation queue"}
"""

from app.models.user import UserRole

# Permission definitions — extend as your app grows
ROLE_PERMISSIONS: dict[UserRole, set[str]] = {
    UserRole.admin: {
        "users:read",
        "users:write",
        "users:delete",
        "content:read",
        "content:write",
        "content:delete",
        "settings:read",
        "settings:write",
    },
    UserRole.moderator: {
        "users:read",
        "content:read",
        "content:write",
        "content:delete",
    },
    UserRole.user: {
        "content:read",
        "content:write",
    },
}


def has_permission(role: UserRole, permission: str) -> bool:
    """Check if a role has a specific permission."""
    role_perms = ROLE_PERMISSIONS.get(role, set())
    return permission in role_perms


def get_permissions(role: UserRole) -> set[str]:
    """Get all permissions for a given role."""
    return ROLE_PERMISSIONS.get(role, set())
```

### Step 9: Update .env.example
Ensure auth-related environment variables are present:
```env
# Auth
SECRET_KEY=generate-a-secure-random-key-minimum-32-characters
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7
```

### Step 10: Output
```
✅ Auth layer initialized
  - Auth: JWT (access + refresh tokens)
  - Hashing: bcrypt via passlib
  - RBAC: role-based middleware skeleton

Files created/updated:
  - backend/app/models/user.py (User model with roles)
  - backend/app/schemas/auth.py (request/response schemas)
  - backend/app/core/security.py (JWT + password hashing)
  - backend/app/api/deps.py (auth dependencies)
  - backend/app/api/v1/auth.py (login/register/refresh/me endpoints)
  - backend/app/api/v1/router.py (updated with auth router)
  - backend/app/core/rbac.py (RBAC permission skeleton)

Endpoints added:
  - POST /api/v1/auth/register — create account
  - POST /api/v1/auth/login — get tokens
  - POST /api/v1/auth/refresh — refresh tokens
  - GET  /api/v1/auth/me — current user profile

Next steps:
  1. Generate migration: cd backend && alembic revision --autogenerate -m "add users table"
  2. Apply migration: cd backend && alembic upgrade head
  3. Update SECRET_KEY in .env with a secure random value
  4. Test: POST /api/v1/auth/register with email + password
```
