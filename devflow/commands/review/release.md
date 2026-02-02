---
allowed-tools: Bash, Read, Write, LS
---

# Pre-Release Validation

Run pre-release checks to validate readiness for production deployment.

## Usage
```
/review:release
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/deploy-patterns.md` — Deployment strategies, rollback procedures
- `devflow/rules/review-workflow.md` — Release branch management, versioning
- `devflow/rules/testing-strategy.md` — Test requirements
- `devflow/rules/standard-patterns.md` — Standard output patterns

## Instructions

### 1. Version Check

Determine current version and proposed release version:

```bash
# Check version in common locations
cat VERSION 2>/dev/null
grep -oP 'version\s*=\s*"\K[^"]+' pyproject.toml 2>/dev/null
grep -oP '"version":\s*"\K[^"]+' package.json 2>/dev/null
git describe --tags --abbrev=0 2>/dev/null
```

Verify version follows semantic versioning (X.Y.Z). Flag if version has not been bumped from previous release.

### 2. Database Migrations

```bash
# Check for pending migrations (Alembic)
alembic history --verbose 2>/dev/null | head -20
alembic check 2>/dev/null

# Verify migrations run cleanly
alembic upgrade head --sql 2>/dev/null | head -50
```

**Checks:**
- [ ] All migrations have both upgrade() and downgrade() paths
- [ ] Migration chain is linear (no branching heads)
- [ ] Migrations are backwards-compatible with current running code
- [ ] No destructive operations without explicit review sign-off

If Alembic is not used, check for other migration tools or skip this section.

### 3. Feature Flags

Scan the codebase for feature flag usage:
```bash
grep -rn "feature_flag\|is_enabled\|feature_flags\|FEATURE_" app/ --include="*.py" 2>/dev/null
```

**Checks:**
- [ ] New feature flags are documented
- [ ] Feature flags have default values (fail closed)
- [ ] No feature flags that have been at 100% for more than 30 days (clean up)
- [ ] Feature flag configuration exists for all environments

### 4. Monitoring and Alerting

Verify observability is in place:

```bash
# Check for health endpoints
grep -rn "/health\|/ready" app/ --include="*.py" 2>/dev/null

# Check for structured logging
grep -rn "structlog\|logger\." app/ --include="*.py" 2>/dev/null | head -10

# Check for metrics
grep -rn "prometheus\|Counter\|Histogram\|Gauge" app/ --include="*.py" 2>/dev/null | head -10

# Check for error tracking (Sentry, etc.)
grep -rn "sentry\|SENTRY_DSN" app/ --include="*.py" 2>/dev/null
grep -rn "SENTRY_DSN" .env.example 2>/dev/null
```

**Checks:**
- [ ] `/health` and `/ready` endpoints exist and respond correctly
- [ ] Structured logging configured (structlog or equivalent)
- [ ] Error tracking configured (Sentry DSN in env)
- [ ] Key metrics exposed (request rate, error rate, latency)
- [ ] Alerting rules defined for error rate and latency thresholds

### 5. Rollback Plan

**Checks:**
- [ ] Previous version tag exists for rollback target
- [ ] Database migrations can be rolled back (downgrade functions tested)
- [ ] Rollback procedure documented or well-understood
- [ ] Blue-green or canary deployment configured

### 6. Changelog

Check for changelog updates:
```bash
# Check if CHANGELOG exists and has recent entries
head -30 CHANGELOG.md 2>/dev/null || head -30 CHANGELOG 2>/dev/null
```

**Checks:**
- [ ] CHANGELOG.md updated with release notes
- [ ] All user-facing changes documented
- [ ] Breaking changes called out prominently
- [ ] Migration steps documented for breaking changes

### 7. Code Quality

```bash
# Check for TODO/FIXME in critical paths
grep -rn "TODO\|FIXME\|HACK\|XXX" app/api/ app/services/ app/models/ --include="*.py" 2>/dev/null

# Run linter
ruff check app/ 2>/dev/null

# Run type checker
mypy app/ --ignore-missing-imports 2>/dev/null | tail -5

# Check test suite passes
pytest tests/ -v --tb=short 2>/dev/null | tail -20
```

**Checks:**
- [ ] No TODO/FIXME in critical paths (API routes, services, models)
- [ ] Linting passes with no errors
- [ ] Type checking passes (or known issues are documented)
- [ ] Full test suite passes

### 8. Dependency Audit

```bash
# Python dependency audit
pip audit 2>/dev/null || echo "pip-audit not installed"

# Check for known vulnerabilities
safety check 2>/dev/null || echo "safety not installed"

# NPM audit (if frontend)
cd frontend && npm audit --production 2>/dev/null || true
```

**Checks:**
- [ ] No critical or high severity vulnerabilities in dependencies
- [ ] All dependencies are pinned to specific versions
- [ ] License compatibility verified for new dependencies

### 9. Generate Release Report

```markdown
# Pre-Release Validation Report

Version: {version}
Date: {datetime}
Branch: {branch_name}

## Checklist Summary

| Category | Status | Issues |
|----------|--------|--------|
| Version | {PASS/FAIL} | {details} |
| Migrations | {PASS/FAIL/N/A} | {details} |
| Feature Flags | {PASS/FAIL/N/A} | {details} |
| Monitoring | {PASS/FAIL} | {details} |
| Rollback Plan | {PASS/FAIL} | {details} |
| Changelog | {PASS/FAIL} | {details} |
| Code Quality | {PASS/FAIL} | {details} |
| Dependencies | {PASS/FAIL} | {details} |

## Blocking Issues
{list of items that must be fixed before release}

## Warnings
{list of non-blocking concerns}

## Release Readiness: {READY / NOT READY}

## Next Steps
{if READY}
1. Create release branch: git checkout -b release/v{version}
2. Tag: git tag v{version}
3. Deploy to staging for final verification
4. Deploy to production with canary release (5% -> 25% -> 50% -> 100%)

{if NOT READY}
1. Fix blocking issues listed above
2. Re-run: /review:release
```

## Error Recovery

- If no version is found, suggest adding a VERSION file or pyproject.toml version
- If Alembic is not installed, skip migration checks and note in report
- If linting tools are missing, suggest installation commands
