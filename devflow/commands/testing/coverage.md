---
allowed-tools: Bash, Read, Write, LS
---

# Testing Coverage

Generate and analyze test coverage reports.

## Usage
```
/testing:coverage
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/testing-strategy.md` — Coverage targets
- `devflow/rules/test-execution.md` — Test execution patterns
- `devflow/rules/standard-patterns.md` — Standard output patterns

## Instructions

### 1. Detect Framework and Run Coverage

**Python (pytest-cov):**
```bash
pytest tests/ -v --cov=app --cov-report=term-missing --cov-report=html:htmlcov --cov-report=json:coverage.json
```

If `--cov=app` path is wrong, detect the source directory from `pyproject.toml` (`[tool.pytest.ini_options] testpaths`) or scan for the main Python package directory.

**Angular:**
```bash
ng test --watch=false --code-coverage --browsers=ChromeHeadless
```
Coverage output lands in `coverage/` directory.

**React/Jest:**
```bash
npx jest --coverage --coverageReporters=text --coverageReporters=json-summary --coverageReporters=html
```

### 2. Parse Coverage Results

Read the coverage output and extract:
- **Overall project coverage percentage**
- **Per-file breakdown** (file path, statements, branches, functions, lines, uncovered lines)
- **Files below threshold** (highlight any file under 60%)

### 3. Generate Coverage Report

Present the report in this format:

```
Coverage Report
===============

Overall: {percentage}% ({status: PASS if >= 60%, FAIL if < 60%})

Per-file breakdown:
  File                          Stmts   Miss  Cover   Uncovered Lines
  ----------------------------- ------- ------ ------- ----------------
  app/main.py                      45      3    93%    22, 45-46
  app/services/user.py             80     12    85%    33-40, 55, 78-80
  app/services/order.py            60     25    58%    15-30, 42-50, 65
  app/models/user.py               20      0   100%
  ----------------------------- ------- ------ ------- ----------------
  TOTAL                           205     40    80%

Below threshold (< 60%):
  - app/services/order.py: 58% (target: 60%)

New code coverage: {percentage}% ({status: PASS if >= 80%, FAIL if < 80%})
```

### 4. Gap Analysis

Identify critical paths that lack test coverage:

1. **Read the source files** with lowest coverage
2. **Identify untested functions** by checking uncovered line ranges
3. **Classify by risk:**
   - **High risk:** Auth, payment, data mutation endpoints with no tests
   - **Medium risk:** Business logic functions with partial coverage
   - **Low risk:** Utility functions, config, boilerplate

4. **Report gaps with recommendations:**
```
Coverage Gaps (prioritized):

1. HIGH RISK: app/services/payment.py — charge_card() (lines 33-40)
   No tests for payment processing. Add integration test with mocked Stripe API.

2. HIGH RISK: app/api/auth.py — verify_token() (lines 15-30)
   Token verification untested. Add unit tests for valid, expired, and malformed tokens.

3. MEDIUM: app/services/order.py — calculate_total() (lines 42-50)
   Missing tests for discount calculation. Add parametrized tests per tier.

Suggested next actions:
  - Write tests for HIGH RISK gaps first
  - Run /testing:run after adding tests to verify
  - Target: reach 80% on all critical service files
```

### 5. Coverage Trends (if available)

If previous coverage data exists (e.g., `coverage.json` from prior run):
- Compare current vs previous overall coverage
- Report delta: `Coverage: 78% (+3% from last run)`
- Flag any files that decreased in coverage

## Output Files

- `htmlcov/index.html` — Interactive HTML coverage report (Python)
- `coverage/index.html` — Interactive HTML coverage report (Angular/React)
- `coverage.json` — Machine-readable coverage data

## Error Recovery

- If pytest-cov is not installed: `pip install pytest-cov`
- If no tests exist: suggest running `/testing:prime` first
- If coverage is 0%: check that the `--cov` source path matches the project structure
