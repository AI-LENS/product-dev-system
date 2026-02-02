---
allowed-tools: Read, Write, LS, Glob, Grep, Bash
---

# Security Check

Run an OWASP-aligned security audit across the codebase.

## Usage
```
/quality:security-check
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/security-baseline.md` — OWASP security standards
- `devflow/rules/auth-patterns.md` — Authentication implementation patterns

## Preflight Checklist

1. **Detect project type:**
   - Check for `requirements.txt`, `pyproject.toml`, `Pipfile` (Python)
   - Check for `package.json` (Node.js)
   - If neither found: "No dependency files found. Security check requires a project with dependencies."

2. **Check tool availability:**
   - `pip-audit` or `safety` for Python
   - `npm` for Node.js
   - If tools missing, note which checks will be skipped

## Instructions

You are a security engineer performing a comprehensive audit of the codebase.

### Check 1: Python Dependency Vulnerabilities

```bash
# Option A: pip-audit (preferred)
pip-audit --format=json 2>/dev/null

# Option B: safety (alternative)
safety check --json 2>/dev/null
```

If neither tool is installed:
```
⚠️ No Python vulnerability scanner found.
Fix: pip install pip-audit
```

Parse results and categorize:
- **Critical:** CVE with CVSS >= 9.0 or known exploits
- **High:** CVE with CVSS >= 7.0
- **Medium:** CVE with CVSS >= 4.0
- **Low:** CVE with CVSS < 4.0

For each vulnerability, provide:
```
[CRITICAL] CVE-2024-XXXXX in package-name==1.2.3
  Description: [brief description]
  Fix: pip install package-name>=1.2.4
```

### Check 2: Node.js Dependency Vulnerabilities

```bash
npm audit --json 2>/dev/null
```

If `package.json` does not exist, skip this check.

Parse results and categorize by severity (critical, high, moderate, low). For each:
```
[HIGH] GHSA-XXXX in package-name@1.2.3
  Description: [brief description]
  Fix: npm audit fix  OR  npm install package-name@1.2.4
```

### Check 3: Hardcoded Secrets

Scan the codebase for potential secrets. Search for these patterns:

```python
# Patterns to search for:
SECRET_PATTERNS = [
    # API keys
    r'(?i)(api[_-]?key|apikey)\s*[=:]\s*["\'][a-zA-Z0-9_\-]{20,}["\']',
    # AWS keys
    r'AKIA[0-9A-Z]{16}',
    # Generic secrets
    r'(?i)(secret|password|passwd|pwd|token)\s*[=:]\s*["\'][^"\']{8,}["\']',
    # Private keys
    r'-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----',
    # JWT tokens
    r'eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]+',
    # Connection strings with credentials
    r'(?i)(postgres|mysql|mongodb|redis)://\w+:[^@\s]+@',
    # Anthropic keys
    r'sk-ant-[a-zA-Z0-9_-]{20,}',
    # OpenAI keys
    r'sk-[a-zA-Z0-9]{20,}',
    # Generic bearer tokens in code
    r'(?i)bearer\s+[a-zA-Z0-9_\-\.]{20,}',
]
```

**Exclusions:**
- Skip `.env.example` (should have placeholder values)
- Skip test files that use obviously fake values (e.g., `"test-key-123"`, `"fake-token"`)
- Skip `node_modules/`, `__pycache__/`, `.git/`, `venv/`, `.venv/`
- Skip binary files

For each finding:
```
[CRITICAL] Hardcoded secret detected
  File: src/services/payment.py:42
  Pattern: API key assignment
  Content: api_key = "sk-live-..."  (truncated)
  Fix: Move to environment variable. Add to .env, reference via settings.
```

### Check 4: SQL Injection

Scan Python files for raw SQL patterns that may be vulnerable:

```python
# Dangerous patterns to detect:
SQL_INJECTION_PATTERNS = [
    # f-string SQL
    r'f["\'].*(?:SELECT|INSERT|UPDATE|DELETE|DROP|ALTER).*\{',
    # String format SQL
    r'\.format\(.*(?:SELECT|INSERT|UPDATE|DELETE|DROP|ALTER)',
    # % formatting SQL
    r'%.*(?:SELECT|INSERT|UPDATE|DELETE|DROP|ALTER).*%\s*\(',
    # String concatenation SQL
    r'(?:SELECT|INSERT|UPDATE|DELETE).*\+\s*(?:str\(|request\.|user)',
    # execute with string interpolation
    r'\.execute\(\s*f["\']',
    r'\.execute\(\s*["\'].*%',
    r'\.execute\(\s*["\'].*\.format\(',
]
```

**Safe patterns to ignore:**
- `text("SELECT ... WHERE id = :id")` with parameter binding
- SQLAlchemy ORM queries (`select(Model).where(...)`)
- Alembic migration files
- Comments and docstrings

For each finding:
```
[HIGH] Potential SQL injection
  File: app/services/user_service.py:87
  Code: db.execute(f"SELECT * FROM users WHERE email = '{email}'")
  Fix: Use parameterized query:
       db.execute(text("SELECT * FROM users WHERE email = :email"), {"email": email})
       Or better: select(User).where(User.email == email)
```

### Check 5: XSS Vulnerabilities

Scan frontend code for unsafe patterns:

```python
XSS_PATTERNS = [
    # Angular dangerous bypasses
    r'bypassSecurityTrustHtml',
    r'bypassSecurityTrustScript',
    r'bypassSecurityTrustUrl',
    r'bypassSecurityTrustResourceUrl',
    # innerHTML assignment
    r'\[innerHTML\]\s*=',
    r'\.innerHTML\s*=',
    # document.write
    r'document\.write\(',
    # eval
    r'(?<!\.)\beval\(',
    # React dangerouslySetInnerHTML
    r'dangerouslySetInnerHTML',
]
```

For each finding:
```
[HIGH] Potential XSS vulnerability
  File: src/app/components/comment.component.html:15
  Code: [innerHTML]="comment.body"
  Fix: Use Angular's built-in sanitization or DomSanitizer.
       If HTML rendering is needed, sanitize server-side first.
```

### Check 6: Authentication Implementation

Verify the auth implementation follows best practices:

**6a: Password hashing**
- Search for password hashing in the codebase
- Verify bcrypt is used (not MD5, SHA1, SHA256 without salt)
- Check cost factor >= 12
- Flag any plaintext password storage or comparison

```python
# Safe patterns:
r'CryptContext.*bcrypt'
r'bcrypt\.hash'
r'passlib.*bcrypt'

# Dangerous patterns:
r'hashlib\.(md5|sha1|sha256).*password'
r'password\s*==\s*'  # Direct comparison
```

**6b: JWT configuration**
- Check for JWT secret key in environment (not hardcoded)
- Verify token expiration is set (access: <= 30min, refresh: <= 30d)
- Check for algorithm specification (not "none")

```python
# Check for:
r'JWT_SECRET.*=.*["\'][^"\']{5,}["\']'  # Hardcoded JWT secret
r'algorithm.*none'                        # Insecure algorithm
r'verify=False'                           # Disabled verification
```

**6c: Token refresh**
- Verify refresh token rotation (old token invalidated on use)
- Check for refresh token revocation mechanism

### Check 7: Security Headers

Search for security headers middleware:

```python
REQUIRED_HEADERS = [
    "Strict-Transport-Security",
    "X-Content-Type-Options",
    "X-Frame-Options",
    "Content-Security-Policy",
    "Referrer-Policy",
]
```

For each missing header:
```
[MEDIUM] Missing security header: X-Content-Type-Options
  Fix: Add to security headers middleware:
       response.headers["X-Content-Type-Options"] = "nosniff"
  Reference: devflow/rules/security-baseline.md section 5
```

### Check 8: CORS Configuration

Search for CORS middleware setup:

```python
# Dangerous patterns:
r'allow_origins.*\*'         # Wildcard origins
r'allow_origins.*\["?\*"?\]' # Wildcard in list
r'allow_methods.*\*'         # All methods allowed
r'allow_headers.*\*'         # All headers allowed
```

```
[HIGH] Insecure CORS: allow_origins=["*"]
  File: app/main.py:23
  Fix: Replace with specific origins: ["https://app.example.com"]
  Note: Wildcard acceptable in development only.
```

If no CORS middleware found:
```
[MEDIUM] No CORS middleware configured
  Fix: Add CORSMiddleware to FastAPI app.
  Reference: devflow/rules/security-baseline.md section 6
```

### Check 9: .env File Safety

```bash
# Check if .env exists
test -f .env && echo "ENV_EXISTS"

# Check if .env is in .gitignore
grep -q "^\.env$" .gitignore 2>/dev/null && echo "ENV_GITIGNORED" || echo "ENV_NOT_GITIGNORED"

# Check if .env is tracked by git
git ls-files --error-unmatch .env 2>/dev/null && echo "ENV_TRACKED" || echo "ENV_NOT_TRACKED"

# Check if .env.example exists
test -f .env.example && echo "ENV_EXAMPLE_EXISTS"
```

Findings:
```
[CRITICAL] .env file is tracked by git
  Fix: git rm --cached .env && echo ".env" >> .gitignore
  Then: Review git history for leaked secrets (git filter-branch or BFG)

[HIGH] .env not in .gitignore
  Fix: echo ".env" >> .gitignore

[MEDIUM] No .env.example file
  Fix: Create .env.example with placeholder values for documentation
```

### Output: Security Report

Compile all findings into a categorized report:

```markdown
# Security Audit Report

**Date:** [current datetime]
**Project:** [project name from package.json or pyproject.toml]

## Summary

| Severity | Count |
|----------|-------|
| Critical | [N] |
| High | [N] |
| Medium | [N] |
| Low | [N] |
| **Total** | **[N]** |

## Critical Findings

### [Finding title]
- **Category:** [injection/XSS/secrets/auth/headers/cors/deps]
- **File:** [file:line]
- **Description:** [what the issue is]
- **Impact:** [what could happen if exploited]
- **Fix:**
  ```
  [exact code or command to fix]
  ```

## High Findings
[same format]

## Medium Findings
[same format]

## Low Findings
[same format]

## Checks Passed
- [x] [Check that passed with no findings]
- [x] [Check that passed with no findings]

## Checks Skipped
- [ ] [Check] — Reason: [tool not installed / not applicable]

## Recommendations
1. [Priority 1 fix]
2. [Priority 2 fix]
3. [Priority 3 fix]

## References
- devflow/rules/security-baseline.md
- devflow/rules/auth-patterns.md
- OWASP Top 10: https://owasp.org/www-project-top-ten/
```

Save report to `devflow/reports/security-audit-[date].md`.

### Final Output

```
Security Audit Complete
========================
Critical: [N]  High: [N]  Medium: [N]  Low: [N]

Top issues:
1. [Most critical finding — one line]
2. [Second most critical — one line]
3. [Third most critical — one line]

Report: devflow/reports/security-audit-[date].md
```

If critical findings exist:
```
❌ CRITICAL issues found — do not deploy until resolved
```

If only medium/low:
```
⚠️ Issues found — review and address before production
```

If clean:
```
✅ No critical or high issues found
```

## Error Recovery

- If a scanning tool is not installed, skip that check and note it in the report
- If the project has no Python backend, skip Python-specific checks
- If the project has no frontend, skip XSS checks
- Never expose actual secret values in the report — always truncate
