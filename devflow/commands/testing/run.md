---
allowed-tools: Bash, Read, Write, LS, Task
---

# Testing Run

Execute tests and analyze results.

## Usage
```
/testing:run [path]
```

- `path` (optional): specific test file or directory to run. Defaults to full test suite.

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/test-execution.md` — Test execution patterns
- `devflow/rules/testing-strategy.md` — Testing pyramid and standards
- `devflow/rules/standard-patterns.md` — Standard output patterns

## Agent

Use the test-runner agent: `devflow/agents/test-runner.md`

## Instructions

### 1. Detect Test Framework

Scan project root to determine framework:

| Indicator | Framework | Command |
|-----------|-----------|---------|
| `pyproject.toml` or `pytest.ini` | pytest | `pytest` |
| `angular.json` | Karma/Jasmine or Jest | `ng test` or `npx jest` |
| `package.json` with jest config | Jest | `npx jest` |
| `package.json` with vitest | Vitest | `npx vitest run` |

### 2. Build Test Command

**Python (pytest):**
```bash
# Full suite
pytest tests/ -v --tb=long

# Specific path
pytest $ARGUMENTS -v --tb=long

# With markers
pytest tests/ -v --tb=long -m "not slow"
```

**Angular:**
```bash
# Full suite (headless)
ng test --watch=false --browsers=ChromeHeadless

# With Jest
npx jest --verbose
```

**React/Node:**
```bash
npx jest $ARGUMENTS --verbose --no-coverage
```

### 3. Execute Tests

Run the test command and capture full output including:
- Test discovery count
- Pass/fail status per test
- Error messages and stack traces
- Timing information

### 4. Analyze Results

**If all tests pass:**
```
All {count} tests passed ({time}s)
  - Unit: {unit_count} passed
  - Integration: {integration_count} passed
  - E2E: {e2e_count} passed
```

**If tests fail:**

For each failing test, analyze the failure:

1. **Read the failing test file** to understand test intent
2. **Read the source file under test** to understand the code
3. **Classify the failure:**
   - **Assertion failure:** Expected vs actual mismatch. Check if test expectation is wrong or code has a bug.
   - **Import error:** Missing module or wrong path. Suggest the correct import.
   - **Fixture error:** Missing fixture or wrong setup. Check conftest.py.
   - **Timeout:** Async operation not completing. Check for missing await or hanging connections.
   - **Type error:** Wrong argument types. Check function signatures.

4. **Suggest a fix** with specific code changes:
```
{count} tests failed:

1. test_create_user_valid_email_returns_201 (tests/unit/test_users.py:15)
   Error: AssertionError: assert 422 == 201
   Cause: Missing required field 'name' in request body
   Fix: Add 'name' to the test request payload:
     response = await client.post("/api/users", json={"email": "test@example.com", "name": "Test"})

2. test_get_orders_empty_db (tests/integration/test_orders.py:30)
   Error: sqlalchemy.exc.OperationalError: database "testdb" does not exist
   Fix: Create test database or set TEST_DATABASE_URL environment variable
```

### 5. Cleanup

After test execution:
```bash
pkill -f "jest|mocha|pytest|uvicorn" 2>/dev/null || true
```

## Error Recovery

- If no tests are found, suggest running `/testing:prime` to set up the framework
- If the test database is unavailable, suggest checking Docker or connection settings
- If imports fail, suggest checking the project structure and PYTHONPATH
