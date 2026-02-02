# Test Execution Rule

Standard patterns for running tests across all testing commands.

## Core Principles

1. **Always use test-runner agent** from `devflow/agents/test-runner.md`
2. **No mocking** — use real services for accurate results
3. **Verbose output** — capture everything for debugging
4. **Check test structure first** — before assuming code bugs

## Execution Pattern

```markdown
Execute tests for: {target}

Requirements:
- Run with verbose output
- No mock services
- Capture full stack traces
- Analyze test structure if failures occur
```

## Framework Detection

### Python (FastAPI backend)
```bash
# Preferred: pytest
pytest {path} -v --tb=long

# With coverage
pytest {path} -v --cov --cov-report=term-missing
```

### JavaScript/TypeScript (frontend)
```bash
# Angular
ng test --watch=false --browsers=ChromeHeadless

# React
npx jest {path} --verbose
```

## Output Focus

### Success
```
✅ All tests passed ({count} tests in {time}s)
```

### Failure
```
❌ Test failures: {count}

{test_name} - {file}:{line}
  Error: {message}
  Fix: {suggestion}
```

## Cleanup

```bash
pkill -f "jest|mocha|pytest|uvicorn" 2>/dev/null || true
```

## Important Notes

- Don't parallelize tests (avoid conflicts)
- Let each test complete fully
- Report failures with actionable fixes
- Focus output on failures, not successes
