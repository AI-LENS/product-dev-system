---
allowed-tools:
  - Read
  - Bash
  - Glob
  - LS
---

# Tech Stack Audit

## Usage
```
/arch:stack-audit
```

## Description
Verifies tech stack consistency across the project. Checks dependency health, version compatibility, outdated packages, and known security advisories for both Python and Node.js ecosystems.

## Execution

### Step 1: Detect Project Type
```bash
test -f requirements.txt && echo "PYTHON_REQUIREMENTS"
test -f pyproject.toml && echo "PYTHON_PYPROJECT"
test -f Pipfile && echo "PYTHON_PIPFILE"
test -f package.json && echo "NODE_PROJECT"
```

Determine which ecosystems are present. A project may have both Python and Node.

If no dependency files are found:
```
❌ No dependency files found (requirements.txt, pyproject.toml, package.json)
```

### Step 2: Python Dependency Audit

#### 2a: Check for Outdated Packages
```bash
pip list --outdated --format=json 2>/dev/null
```
Parse the JSON output. For each outdated package, report:
- Package name
- Current version
- Latest version
- Type (major/minor/patch based on semver difference)

#### 2b: Check for Security Vulnerabilities
```bash
pip audit --format=json 2>/dev/null
```
If `pip-audit` is not installed, note it:
```
⚠️ pip-audit not installed. Run: pip install pip-audit
```

If available, parse results and report:
- Package name
- Installed version
- Vulnerability ID (CVE or PYSEC)
- Severity (low/medium/high/critical)
- Fix version (if available)

#### 2c: Verify Core Stack Consistency
Check that the required Python stack is present:
- `fastapi` — web framework
- `sqlalchemy` — ORM
- `alembic` — migrations
- `uvicorn` — ASGI server
- `pydantic` — data validation

For each, check if installed and report version:
```bash
pip show fastapi sqlalchemy alembic uvicorn pydantic 2>/dev/null
```

Report missing core packages as warnings.

### Step 3: Node.js Dependency Audit

#### 3a: Check for Outdated Packages
```bash
npm outdated --json 2>/dev/null
```
Parse the JSON output. For each outdated package, report:
- Package name
- Current version
- Wanted version
- Latest version

#### 3b: Check for Security Vulnerabilities
```bash
npm audit --json 2>/dev/null
```
Parse results and report:
- Severity counts (low/moderate/high/critical)
- Affected packages
- Available fixes

#### 3c: Check for Unused Dependencies
Read `package.json` and cross-reference imports across source files to identify potentially unused dependencies. Flag them as suggestions, not errors.

### Step 4: Cross-Ecosystem Consistency

If both Python and Node exist in the project:
- Check that `.nvmrc` or `engines` field exists in `package.json`
- Check that Python version is pinned (`.python-version` or `pyproject.toml` `requires-python`)
- Verify both have lockfiles (`package-lock.json`/`yarn.lock` and `requirements.txt`/`poetry.lock`)
- Flag if one ecosystem has a lockfile and the other does not

### Step 5: Environment File Check
```bash
test -f .env.example && echo "ENV_EXAMPLE_EXISTS"
test -f .env && echo "ENV_EXISTS"
```
- If `.env` exists but `.env.example` does not: warn that `.env.example` should be created
- If `.env` is tracked by git: critical warning
```bash
git ls-files --error-unmatch .env 2>/dev/null && echo "ENV_TRACKED"
```

### Step 6: Report Output

```
Tech Stack Audit Report
========================

Python Stack:
  fastapi        0.104.1  ✅ current
  sqlalchemy     2.0.23   ✅ current
  alembic        1.13.0   ⚠️ outdated (latest: 1.13.1)
  uvicorn        0.24.0   ✅ current
  pydantic       2.5.2    ✅ current

Node Stack:
  angular        17.0.0   ✅ current
  tailwindcss    3.4.0    ✅ current
  daisyui        4.4.0    ⚠️ outdated (latest: 4.5.0)

Security:
  Python: 0 vulnerabilities
  Node: 2 moderate, 0 high, 0 critical

Outdated Packages:
  Python: 1 outdated (0 major, 1 minor, 0 patch)
  Node: 1 outdated (0 major, 1 minor, 0 patch)

Environment:
  .env.example: ✅ exists
  .env in git: ✅ not tracked

Overall: ⚠️ 2 warnings, 0 critical issues
```

### Step 7: Recommendations
Based on findings, provide actionable recommendations:
- For outdated packages: exact update commands (`pip install --upgrade {pkg}` or `npm update {pkg}`)
- For security issues: exact fix commands (`npm audit fix` or specific version pins)
- For missing lockfiles: exact commands to generate them
- For missing `.env.example`: suggest creating one from current `.env` structure
