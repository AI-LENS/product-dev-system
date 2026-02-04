---
allowed-tools: Bash, Read, Write, LS, AskUserQuestion
---

# Plan

Convert a spec into a technical implementation plan with architecture decisions, data model, and project structure.

## Usage
```
/pm:plan <feature_name>
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/datetime.md` - For getting real current date/time

## Preflight Checklist

Before proceeding, complete these validation steps.
Do not bother the user with preflight checks progress. Just do them and move on.

### 1. Verify Spec Exists
- Check if `devflow/specs/$ARGUMENTS.md` exists
- If not found, tell user: "Spec not found: $ARGUMENTS. Create it first with: /pm:spec-create $ARGUMENTS"
- Stop execution if spec does not exist

### 2. Check for Existing Plan
- Check if `devflow/specs/$ARGUMENTS-plan.md` already exists
- If it exists, ask user: "Plan '$ARGUMENTS' already exists. Do you want to overwrite it? (yes/no)"
- Only proceed with explicit 'yes' confirmation

### 3. Load Related Artifacts
- Read spec: `devflow/specs/$ARGUMENTS.md`
- Read PRD (if exists): `devflow/prds/$ARGUMENTS.md`
- Read principles (if exists): `devflow/templates/principles/active-principles.md`
- Read plan template: `devflow/templates/plan/plan-template.md`

### 4. Get Current DateTime
- Run: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

## Instructions

### 1. Analyze Spec Requirements

From the spec, extract:
- All functional requirements (FR-xxx)
- All non-functional requirements (NFR-xxx)
- Key entities and relationships
- User stories and acceptance criteria
- Technology constraints

### 1b. Architecture Decision Validation — PROBE QUESTIONING (MANDATORY)

**CRITICAL:** Architecture decisions have long-lasting impact. Validate key choices with the user using AskUserQuestion.

#### Phase 1: Stack Confirmation

**Question 1: Backend Architecture**
> Based on the spec requirements, I recommend:
> - **Framework:** FastAPI (default)
> - **Why:** [Reason based on spec - async needs, API-first, etc.]
>
> Confirm backend approach?
> - FastAPI (Recommended - matches spec requirements)
> - Django (Better for admin-heavy apps)
> - Flask (Simpler, less structure)
> - Other (specify)

**Question 2: Database Strategy**
> Data model analysis suggests:
> - **Primary DB:** PostgreSQL
> - **Relationships:** [Complexity level - simple/moderate/complex]
> - **Expected volume:** [Estimate from spec]
>
> Confirm database approach?
> - PostgreSQL (Recommended)
> - PostgreSQL + Redis (if caching needed)
> - MySQL (if required by existing infra)
> - Other (specify)

**Question 3: Frontend Approach** (if applicable)
> UI requirements suggest:
> - **Complexity:** [Simple forms / Complex interactions / Data-heavy dashboards]
> - **Real-time needs:** [Yes/No]
>
> Confirm frontend approach?
> - Angular + DaisyUI (Recommended for complex apps)
> - React + Tailwind (Recommended for simpler apps)
> - No frontend (API only)
> - Other (specify)

#### Phase 2: Architecture Pattern Validation

**Question 4: Code Organization**
> For a project of this complexity, I recommend:
> - **Pattern:** [Repository pattern / Service layer / Simple CRUD]
> - **Structure:** [Feature-based / Layer-based]
>
> Which structure do you prefer?
> - Feature-based folders (group by feature: auth/, users/, posts/)
> - Layer-based folders (group by layer: models/, services/, routes/)
> - Hybrid (layers within features)

**Question 5: Authentication Approach** (if auth required)
> The spec requires authentication. Options:
> - JWT with refresh tokens (Recommended for SPAs)
> - Session-based auth (Traditional web apps)
> - OAuth2 only (Third-party auth)
> - API keys (For service-to-service)

**Question 6: API Versioning Strategy**
> How should we handle API versioning?
> - URL path versioning (/api/v1/) (Recommended)
> - Header versioning
> - No versioning (single version)

#### Phase 3: Risk & Scalability

**Question 7: Performance Requirements**
> Based on NFRs, key performance targets:
> - Response time: [X]ms (from spec or default 200ms)
> - Concurrent users: [X] (from spec)
> - Data volume: [X] records
>
> Are these targets correct?
> - Yes, proceed with these targets
> - Adjust targets (specify new values)
> - No specific requirements (use sensible defaults)

**Question 8: Deployment Target**
> Where will this be deployed?
> - Docker + self-hosted (Recommended for control)
> - Cloud managed (AWS/GCP/Azure)
> - Serverless (Lambda, Cloud Functions)
> - Local development only (for now)

### 2. Architecture Decisions

For each significant decision, document with rationale:

```markdown
## Architecture Decisions

### AD-001: [Decision Title]
- **Context:** [Why this decision is needed]
- **Decision:** [What was decided]
- **Rationale:** [Why this option was chosen]
- **Alternatives Considered:**
  - [Alt 1]: [Why rejected]
  - [Alt 2]: [Why rejected]
- **Consequences:** [Impact of this decision]
- **Status:** Proposed
```

### 3. Tech Stack Definition

Default stack (confirm with user if different):

```markdown
## Tech Stack

### Backend
- **Language:** Python 3.11+
- **Framework:** FastAPI
- **ORM:** SQLAlchemy 2.0 (async)
- **Migrations:** Alembic
- **Validation:** Pydantic v2
- **Auth:** JWT with python-jose / passlib
- **Testing:** pytest + pytest-asyncio + httpx

### Frontend
- **Framework:** Angular 17+ / React 18+ (confirm with user)
- **State Management:** NgRx / Redux Toolkit
- **UI Library:** [Based on project needs]
- **Testing:** Jest + Testing Library

### Database
- **Primary:** PostgreSQL 15+
- **Cache:** Redis (if needed)
- **Search:** PostgreSQL full-text / Elasticsearch (if needed)

### Infrastructure
- **Containerization:** Docker + Docker Compose
- **CI/CD:** GitHub Actions
- **Hosting:** [Based on project needs]
- **Monitoring:** [Based on project needs]
```

### 4. Data Model

Design SQLAlchemy models based on spec entities:

```markdown
## Data Model

### Entity: User
```python
class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255))
    name: Mapped[str] = mapped_column(String(100))
    role: Mapped[str] = mapped_column(String(20), default="user")
    is_active: Mapped[bool] = mapped_column(default=True)
    created_at: Mapped[datetime] = mapped_column(default=func.now())
    updated_at: Mapped[datetime] = mapped_column(default=func.now(), onupdate=func.now())

    # Relationships
    posts: Mapped[list["Post"]] = relationship(back_populates="author")
```

### Entity Relationships
```
User 1---* Post
User 1---* Comment
Post 1---* Comment
```

### Database Indexes
| Table | Index | Columns | Type |
|-------|-------|---------|------|
| users | ix_users_email | email | UNIQUE |
| posts | ix_posts_status | status | BTREE |
| posts | ix_posts_created | created_at | BTREE |
```

### 5. Project Structure

Define the directory layout:

```markdown
## Project Structure

```
project-root/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI app factory
│   ├── config.py               # Settings (pydantic-settings)
│   ├── database.py             # DB engine, session
│   ├── dependencies.py         # Shared dependencies
│   ├── api/
│   │   ├── __init__.py
│   │   ├── v1/
│   │   │   ├── __init__.py
│   │   │   ├── router.py       # v1 router aggregator
│   │   │   ├── endpoints/
│   │   │   │   ├── users.py
│   │   │   │   └── posts.py
│   │   │   └── schemas/
│   │   │       ├── users.py    # Pydantic request/response
│   │   │       └── posts.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── user.py             # SQLAlchemy models
│   │   └── post.py
│   ├── services/
│   │   ├── __init__.py
│   │   ├── user_service.py     # Business logic
│   │   └── post_service.py
│   ├── repositories/
│   │   ├── __init__.py
│   │   ├── base.py             # Generic CRUD repo
│   │   ├── user_repo.py
│   │   └── post_repo.py
│   └── core/
│       ├── __init__.py
│       ├── security.py         # Auth helpers
│       ├── exceptions.py       # Custom exceptions
│       └── middleware.py       # CORS, logging, etc.
├── migrations/
│   ├── env.py
│   └── versions/
├── tests/
│   ├── conftest.py
│   ├── test_api/
│   ├── test_services/
│   └── test_repositories/
├── docker-compose.yml
├── Dockerfile
├── pyproject.toml
├── alembic.ini
└── .env.example
```
```

### 6. API Design

Define key API endpoints:

```markdown
## API Design

### Endpoints

| Method | Path | Description | Auth | FR |
|--------|------|-------------|------|-----|
| POST | /api/v1/auth/register | Register new user | No | FR-001 |
| POST | /api/v1/auth/login | User login | No | FR-002 |
| GET | /api/v1/users/me | Get current user | Yes | FR-003 |
| GET | /api/v1/posts | List posts | No | FR-004 |
| POST | /api/v1/posts | Create post | Yes | FR-005 |

### Request/Response Examples
[Include key examples for critical endpoints]
```

### 7. Principles Compliance Check

Verify plan aligns with active principles:

```markdown
## Principles Compliance

| Principle | Compliance | Notes |
|-----------|------------|-------|
| Test-first | YES | pytest structure defined, test directories in project layout |
| API-first | YES | All endpoints defined before implementation |
| Simplicity | YES | Standard FastAPI patterns, no over-engineering |
```

### 8. Risk Assessment

Identify implementation risks:

```markdown
## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| DB schema changes during dev | Medium | High | Use Alembic migrations from day 1 |
| Auth complexity | Low | High | Use established JWT patterns |
| Performance bottleneck | Medium | Medium | Define indexes early, add caching layer |
```

### 9. Save Plan

Save to `devflow/specs/$ARGUMENTS-plan.md`:

```markdown
---
name: $ARGUMENTS-plan
status: draft
created: [Current ISO date/time]
updated: [Current ISO date/time]
spec: devflow/specs/$ARGUMENTS.md
prd: devflow/prds/$ARGUMENTS.md
---

# Technical Plan: [Feature Name]

[All sections from above]
```

### 10. Quality Checks

Before saving, verify:
- [ ] All spec FRs are addressed in the plan
- [ ] Data model covers all spec entities
- [ ] API endpoints map to functional requirements
- [ ] Tech stack aligns with project defaults (Python+FastAPI)
- [ ] Principles compliance is verified
- [ ] Project structure follows standard patterns
- [ ] Risk assessment includes at least 3 risks

### 11. Post-Creation

After successfully creating the plan:
1. Confirm: "Plan created: devflow/specs/$ARGUMENTS-plan.md"
2. Show summary:
   - Architecture decisions: {count}
   - Data models: {count}
   - API endpoints: {count}
   - Risks identified: {count}
3. Suggest next step: "Decompose into tasks: /pm:epic-decompose $ARGUMENTS"

## Error Recovery

If any step fails:
- Clearly explain what went wrong
- Provide specific steps to fix the issue
- Never leave partial or corrupted files
