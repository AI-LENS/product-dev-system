# Testing Strategy

Testing pyramid and coverage standards for all DevFlow projects.

## Testing Pyramid

### Unit Tests (70% of test effort)

**Python (pytest):**
- Test individual functions, methods, and classes in isolation
- Mock only external services (APIs, databases, file systems)
- Use `pytest.mark.parametrize` for input variants
- Target: every public method has at least one test

**Frontend (Jest / Jasmine):**
- Test components, services, pipes, and utilities in isolation
- Mock HTTP calls and external dependencies
- Test both happy paths and error states
- Target: every component and service has tests

### Integration Tests (20% of test effort)

- Test interactions between components (API endpoint + database, service + repository)
- Use real database with test schema (PostgreSQL in Docker or SQLite for speed)
- Test full request/response cycle through FastAPI TestClient
- Verify serialization, validation, and error handling end-to-end
- Test Angular/React service integration with API contracts

### E2E Tests (10% of test effort)

- Use Playwright (preferred) or Cypress for browser-based user flow testing
- Cover critical user journeys: login, core feature flows, checkout/submit
- Run in headless mode in CI, headed mode for debugging
- Keep E2E suite fast: max 10 minutes total runtime

## Coverage Targets

| Scope | Minimum |
|-------|---------|
| New code in PR | 80% |
| Overall project | 60% |
| Critical paths (auth, payments, data) | 90% |
| Utility/helper modules | 70% |

## Test Naming Conventions

### Python (pytest)
```python
# Pattern: test_{what}_{scenario}_{expected}
def test_create_user_valid_email_returns_201():
    ...

def test_create_user_duplicate_email_raises_conflict():
    ...

def test_get_orders_empty_db_returns_empty_list():
    ...
```

### JavaScript/TypeScript (Jest / Jasmine)
```typescript
describe('UserService', () => {
  describe('createUser', () => {
    it('should return 201 when email is valid', () => { ... });
    it('should throw ConflictError when email is duplicate', () => { ... });
  });
});
```

## Fixture Patterns

### Python
- Use `conftest.py` at each test directory level for shared fixtures
- Use `factory_boy` for model factories (consistent, composable test data)
- Use `pytest.fixture` with appropriate scope (`function`, `session`, `module`)
- Prefer factory functions over raw fixture data for readability

### Frontend
- Use `beforeEach` for component setup
- Create test utility files for shared mock data
- Use `TestBed` (Angular) or `render` helpers (React Testing Library)

## Test Data Management

- **Isolated test databases:** Each test run gets a clean database state
- **Transaction rollback:** Wrap each test in a transaction, rollback after completion
- **No shared mutable state:** Tests must not depend on execution order
- **Seed data:** Use factories, not SQL dumps (factories are version-controlled and composable)

## CI Integration

- Run full test suite on every pull request
- Block merge if any test fails
- Run linting before tests (fail fast on syntax/style errors)
- Cache dependencies between runs for speed
- Parallelize test execution where possible (pytest-xdist, Jest workers)
- Report coverage as PR comment

## Performance Guidelines

- Unit test suite: complete in under 2 minutes
- Integration test suite: complete in under 5 minutes
- E2E test suite: complete in under 10 minutes
- Total CI pipeline: under 15 minutes
