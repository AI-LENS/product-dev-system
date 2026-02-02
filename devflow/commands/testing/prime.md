---
allowed-tools: Bash, Read, Write, LS
---

# Testing Prime

Configure testing framework for the current project.

## Usage
```
/testing:prime
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/testing-strategy.md` — Testing pyramid and coverage targets
- `devflow/rules/test-patterns.md` — Test patterns per layer
- `devflow/rules/standard-patterns.md` — Standard output patterns

## Instructions

Detect the project type and set up the appropriate testing framework.

### 1. Project Detection

Scan the project root for indicators:

```
if pyproject.toml or requirements.txt exists → Python project detected
if angular.json exists → Angular project detected
if package.json with "react" in dependencies → React project detected
```

Report what was detected. If multiple stacks are found (e.g., Python backend + Angular frontend), configure both.

### 2. Python (FastAPI) Setup

**Install dependencies:**
```bash
pip install pytest pytest-cov pytest-asyncio factory-boy httpx
```

If `pyproject.toml` exists, add to `[project.optional-dependencies]` under a `test` group. If `requirements-dev.txt` or `requirements-test.txt` exists, append there.

**Create directory structure:**
```
tests/
  __init__.py
  conftest.py
  unit/
    __init__.py
  integration/
    __init__.py
  e2e/
    __init__.py
```

**Create `tests/conftest.py`:**
```python
"""Shared test fixtures for the project."""
import pytest
from httpx import AsyncClient, ASGITransport

# Adjust this import to match the project's FastAPI app location
from app.main import app


@pytest.fixture
async def client():
    """Async HTTP client for testing FastAPI endpoints."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.fixture
def anyio_backend():
    """Use asyncio as the async backend for tests."""
    return "asyncio"
```

**Create `tests/unit/test_sample.py`:**
```python
"""Sample unit test to verify test setup."""


def test_setup_works():
    """Verify the testing framework is properly configured."""
    assert True


def test_basic_math():
    """Sample test demonstrating arrange-act-assert pattern."""
    # Arrange
    a, b = 2, 3

    # Act
    result = a + b

    # Assert
    assert result == 5
```

**Create or update `pytest.ini` / `pyproject.toml` section:**
```ini
[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"
addopts = "-v --tb=short"
markers = [
    "slow: marks tests as slow (deselect with '-m \"not slow\"')",
    "integration: marks integration tests",
    "e2e: marks end-to-end tests",
]
```

**Verify:** Run `pytest tests/ -v --co` to collect tests without running them. Confirm the sample test is discovered.

### 3. Angular Setup

**Check current test runner:**
- If `karma.conf.js` exists, Karma+Jasmine is already configured (Angular default)
- If the user wants Jest instead, proceed with Jest migration

**For Jest setup (if requested or no Karma config exists):**
```bash
npm install --save-dev jest @types/jest jest-preset-angular ts-jest
```

**Create `jest.config.ts`:**
```typescript
import type { Config } from 'jest';

const config: Config = {
  preset: 'jest-preset-angular',
  setupFilesAfterSetup: ['<rootDir>/setup-jest.ts'],
  testPathIgnorePatterns: ['/node_modules/', '/dist/'],
  coverageDirectory: 'coverage',
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.module.ts',
    '!src/**/*.spec.ts',
    '!src/main.ts',
    '!src/polyfills.ts',
  ],
};

export default config;
```

**Create `setup-jest.ts`:**
```typescript
import 'jest-preset-angular/setup-jest';
```

**Create sample test if none exist** at `src/app/app.component.spec.ts`:
```typescript
import { TestBed } from '@angular/core/testing';
import { AppComponent } from './app.component';

describe('AppComponent', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [AppComponent],
    }).compileComponents();
  });

  it('should create the app', () => {
    const fixture = TestBed.createComponent(AppComponent);
    const app = fixture.componentInstance;
    expect(app).toBeTruthy();
  });
});
```

### 4. React Setup

**Install dependencies:**
```bash
npm install --save-dev jest @testing-library/react @testing-library/jest-dom @testing-library/user-event
```

**Create sample test** at `src/__tests__/App.test.tsx`:
```typescript
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import App from '../App';

describe('App', () => {
  it('renders without crashing', () => {
    render(<App />);
    expect(document.body).toBeTruthy();
  });
});
```

### 5. Post-Setup

After configuration is complete:

1. Run the test collection to verify setup
2. Report results:
```
Testing framework configured:
  - Framework: pytest / Jest / Karma+Jasmine
  - Config: pyproject.toml / jest.config.ts / karma.conf.js
  - Test directory: tests/ / src/**/*.spec.ts
  - Sample test: tests/unit/test_sample.py / src/app/app.component.spec.ts

Next steps:
  - Run tests: /testing:run
  - Check coverage: /testing:coverage
  - Set up E2E: /testing:e2e-setup
```

## Error Recovery

- If dependency installation fails, suggest manual installation with the exact command
- If the app import path is wrong in conftest.py, tell the user to update the import
- If tests fail to collect, check for syntax errors in config files
