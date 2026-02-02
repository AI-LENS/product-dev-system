---
allowed-tools: Bash, Read, Write, LS
---

# Deploy Environment Check

Validate environment variables and configuration consistency.

## Usage
```
/deploy:env-check
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/deploy-patterns.md` — Environment promotion rules
- `devflow/rules/standard-patterns.md` — Standard output patterns

## Instructions

### 1. Locate Environment Files

Search for environment configuration files:

```
.env                  — Current local environment
.env.example          — Template with all required variables
.env.development      — Development-specific overrides
.env.staging          — Staging-specific config
.env.production       — Production-specific config
.env.test             — Test-specific config
```

If `.env.example` does not exist, scan the codebase for environment variable references to build a list.

### 2. Build Required Variables List

**From `.env.example` (if exists):**
Read each line and extract variable names (ignore comments and blank lines).

**From codebase scan (if no .env.example):**
```bash
# Find os.getenv / os.environ references in Python
grep -rn "os\.getenv\|os\.environ\|settings\.\|config\." app/ --include="*.py" | grep -oP '[A-Z_]{3,}' | sort -u

# Find environment references in docker-compose
grep -oP '\$\{?\K[A-Z_]+' docker-compose.yml 2>/dev/null | sort -u
```

### 3. Validate Current Environment

**Check `.env` against `.env.example`:**

For each required variable:
1. **Present check:** Is the variable defined in `.env`?
2. **Non-empty check:** Does the variable have a value (not just `=`)?
3. **Format validation:**

| Variable Pattern | Expected Format | Validation |
|-----------------|-----------------|------------|
| `*_URL` | Valid URL | Starts with `http://`, `https://`, `postgresql://`, `redis://` |
| `*_PORT` | Integer 1-65535 | Numeric, within valid port range |
| `*_HOST` | Hostname or IP | Non-empty string |
| `*_KEY`, `*_SECRET`, `*_TOKEN` | Non-placeholder | Not `changeme`, `xxx`, `your-*-here`, `sk-...` placeholder |
| `*_EMAIL` | Email format | Contains `@` |
| `DEBUG` | Boolean | `true`, `false`, `0`, `1` |
| `LOG_LEVEL` | Log level | `debug`, `info`, `warning`, `error`, `critical` |
| `*_TIMEOUT` | Positive integer | Numeric, greater than 0 |

### 4. Secrets Safety Check

Scan the codebase for accidentally committed secrets:

```bash
# Check for hardcoded secrets in source files
grep -rn "password\s*=\s*['\"]" app/ --include="*.py" | grep -v "test" | grep -v "example"
grep -rn "api_key\s*=\s*['\"]" app/ --include="*.py" | grep -v "test" | grep -v "example"
grep -rn "secret\s*=\s*['\"]" app/ --include="*.py" | grep -v "test" | grep -v "example"
```

Check that `.env` is in `.gitignore`:
```bash
grep -q "^\.env$" .gitignore && echo "OK: .env is gitignored" || echo "WARNING: .env is NOT in .gitignore"
```

Check git history for accidentally committed secrets:
```bash
git log --all --diff-filter=A -- ".env" "*.env" 2>/dev/null | head -5
```

### 5. Cross-Environment Consistency

If multiple environment files exist (`.env.development`, `.env.staging`, `.env.production`):

Compare variable names across environments:
```
Variable              dev    staging  prod
---------------------  -----  -------  -----
DATABASE_URL           set    set      set
REDIS_URL              set    set      set
SECRET_KEY             set    set      set
DEBUG                  true   false    false
STRIPE_API_KEY         set    MISSING  set
SENTRY_DSN             -      set      set
```

Flag inconsistencies:
- Variable in one environment but missing in another
- DEBUG=true in staging or production
- Placeholder values in staging or production

### 6. Generate Report

```
Environment Check Report
========================

Source: .env.example (15 variables)
Target: .env

Variables:
  Present: 13/15
  Missing: 2
    - SENTRY_DSN (required for error tracking)
    - REDIS_URL (required for caching)

Format Validation:
  Valid: 11/13
  Invalid: 2
    - DATABASE_URL: missing protocol prefix (should start with postgresql://)
    - API_PORT: value "abc" is not a valid port number

Secrets Safety:
  .env in .gitignore: YES
  Hardcoded secrets in code: NONE
  Secrets in git history: NONE

Cross-Environment:
  Consistency: 2 issues
    - STRIPE_API_KEY missing in staging
    - DEBUG=true in staging (should be false)

Overall: {PASS/FAIL}
  {If FAIL: list of items to fix}
```

### 7. Auto-Generate .env.example (if missing)

If `.env.example` does not exist, offer to create one from the codebase scan:

```bash
# Generated .env.example
# Copy this file to .env and fill in the values

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/dbname

# Redis
REDIS_URL=redis://localhost:6379/0

# Application
SECRET_KEY=change-me-to-a-random-string
DEBUG=false
LOG_LEVEL=info
API_PORT=8000

# External Services
# OPENAI_API_KEY=sk-...
# SENTRY_DSN=https://...
```

## Error Recovery

- If no `.env` file exists, suggest creating one from `.env.example`
- If no `.env.example` exists, generate one from codebase scan
- If secrets are found in code, provide exact file and line to fix
