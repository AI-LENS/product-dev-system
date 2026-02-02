---
allowed-tools: Bash, Read, Write, LS
---

# PR Review Checklist

Generate a domain-aware PR review checklist based on changed files.

## Usage
```
/review:pr-checklist
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/review-workflow.md` — PR review standards, approval requirements
- `devflow/rules/testing-strategy.md` — Coverage requirements
- `devflow/rules/standard-patterns.md` — Standard output patterns

## Instructions

### 1. Identify Changed Files

Determine what files have changed in the current branch vs main:

```bash
# Get list of changed files
git diff --name-only main...HEAD

# Get diff stats
git diff --stat main...HEAD

# Get total lines changed
git diff --shortstat main...HEAD
```

If not on a feature branch, check staged/unstaged changes:
```bash
git diff --name-only HEAD
git diff --name-only --cached
```

### 2. Classify Changes

Categorize each changed file:

| Path Pattern | Category | Review Focus |
|-------------|----------|-------------|
| `app/api/` or `app/routes/` | API endpoints | Security, validation, backwards compatibility |
| `app/models/` | Data models | Schema changes, migration impact |
| `app/services/` | Business logic | Correctness, edge cases, error handling |
| `alembic/versions/` | DB migrations | Safety, rollback, data integrity |
| `tests/` | Tests | Coverage, quality, edge cases |
| `*.html`, `*.component.ts` | Frontend UI | Accessibility, responsiveness |
| `*.css`, `*.scss` | Styles | Consistency, responsive design |
| `Dockerfile`, `docker-compose*` | Infrastructure | Security, efficiency |
| `.github/workflows/` | CI/CD | Pipeline correctness, secrets handling |
| `requirements*.txt`, `package.json` | Dependencies | Security vulnerabilities, license |
| `.env*` | Configuration | No secrets committed |

### 3. Check PR Size

```bash
LINES=$(git diff --shortstat main...HEAD | grep -oP '\d+ insertion' | grep -oP '\d+')
DELETIONS=$(git diff --shortstat main...HEAD | grep -oP '\d+ deletion' | grep -oP '\d+')
TOTAL=$((LINES + DELETIONS))
```

If total > 400 lines, flag:
```
PR size: {total} lines changed (limit: 400)
Consider splitting this PR into smaller, focused changes.
```

### 4. Generate Checklist

Build a checklist dynamically based on the categories detected:

```markdown
## PR Review Checklist

**Branch:** {branch_name}
**Files changed:** {count}
**Lines changed:** +{additions} / -{deletions}
{**Size warning** if > 400 lines}

### General
- [ ] Code is readable and follows project conventions
- [ ] No debug statements or commented-out code left behind
- [ ] No TODO/FIXME without a linked issue number
- [ ] Commit messages follow conventional commit format
```

**If API endpoints changed:**
```markdown
### Security
- [ ] Authentication required on all new endpoints
- [ ] Authorization checks (user can only access their own data)
- [ ] Input validation using Pydantic models for all request bodies
- [ ] No raw SQL queries (use ORM or parameterized queries)
- [ ] No XSS vectors in responses (no raw HTML in JSON)
- [ ] Rate limiting configured on public endpoints
- [ ] CORS settings are restrictive (not wildcard)
- [ ] Sensitive data not logged (passwords, tokens, PII)
```

**If database/model changes detected:**
```markdown
### Database
- [ ] Migration has both upgrade() and downgrade() functions
- [ ] Migration is backwards-compatible with running code
- [ ] No DROP TABLE or DROP COLUMN without explicit approval
- [ ] New indexes added for new query patterns
- [ ] Large data migrations are batched (not single transaction)
- [ ] Foreign key constraints are appropriate
- [ ] Nullable fields are intentional (not accidental)
```

**If frontend UI changes detected:**
```markdown
### Accessibility
- [ ] All interactive elements have ARIA labels
- [ ] Keyboard navigation works for new components
- [ ] Color contrast meets WCAG AA (4.5:1 ratio)
- [ ] Form inputs have visible labels (not just placeholders)
- [ ] Focus management is correct for modals/dialogs
- [ ] Images have alt text
- [ ] Screen reader tested (or VoiceOver spot-check)
```

**If API contract changes detected:**
```markdown
### API Contract
- [ ] No breaking changes to existing endpoints
- [ ] New endpoints documented with OpenAPI annotations
- [ ] Response schemas defined with Pydantic models
- [ ] Error responses follow project error format
- [ ] Pagination added for list endpoints
- [ ] API version prefix used (/api/v1/)
```

**If business logic changed:**
```markdown
### Performance
- [ ] No N+1 query patterns (use joinedload/selectinload)
- [ ] Large result sets are paginated
- [ ] Expensive operations are async or background-queued
- [ ] No unbounded loops or recursion
- [ ] Caching considered for repeated expensive operations
- [ ] Database queries use indexed columns in WHERE clauses
```

**Always include:**
```markdown
### Testing
- [ ] New code has unit tests (80% coverage minimum)
- [ ] Edge cases covered (empty input, null, boundary values)
- [ ] Error paths tested (network failure, invalid data, timeouts)
- [ ] No flaky tests introduced
- [ ] Integration test added for new API endpoints
- [ ] Test data uses factories, not hardcoded values
```

### 5. Read and Summarize Key Changes

For each changed file in critical categories (API, models, services):
1. Read the diff
2. Summarize what changed in 1-2 sentences
3. Flag any concerns

```markdown
### Change Summary

| File | Change | Notes |
|------|--------|-------|
| app/api/users.py | Added PATCH /users/{id} endpoint | Needs auth check verification |
| app/models/user.py | Added `preferences` JSON column | Migration needed, nullable OK |
| app/services/user.py | Added update_preferences() | Validate JSON schema |
| tests/test_users.py | Added 5 tests for preferences | Good coverage |
```

### 6. Output

Present the full checklist. If possible, pre-check items that are clearly satisfied based on code review. Leave unchecked items that need human verification.

## Error Recovery

- If not on a feature branch, use staged changes instead
- If no changes detected, report: "No changes found. Are you on the right branch?"
- If git commands fail, check if the repository is valid
