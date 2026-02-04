---
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Task, AskUserQuestion
---

# Gate

Run a stage-specific quality gate on an artifact. Gates verify that each pipeline step produced output good enough for the next step to consume.

## Core Principles — NON-NEGOTIABLE

**1. NO BYPASS:** Gate failures MUST be fixed. Cannot skip or override without explicit documented rationale.

**2. TRACEABILITY:** Every downstream artifact MUST trace to upstream requirements.

**3. BLOCK ON CRITICAL:** Any critical issue is a hard stop. No exceptions.

**4. FULL VERIFICATION:** Gates run ALL checks, not samples.

## Usage

```
/devflow:gate <gate-name> <feature-name>
```

**Gate names:** `prd`, `spec`, `plan`, `epic`, `bootstrap`, `task`, `phase`, `build`, `test`, `quality`, `review`

## Required Rules

- `devflow/rules/elite-dev-protocol.md`
- `devflow/rules/datetime.md`
- `devflow/rules/frontmatter-operations.md`
- `devflow/rules/adr-patterns.md`

## Preflight Checklist

1. Verify `<gate-name>` is valid. If invalid, print valid options and STOP.
2. Verify `<feature-name>` is provided.
3. Read `gate_mode` from `devflow/devflow.config`. Default to `strict` if not set.
4. Verify the subject artifact exists.
5. Load ALL upstream artifacts for comparison.

## Gate Mode Configuration

```yaml
# In devflow/devflow.config
gate_mode: strict  # strict | standard | permissive

# strict (DEFAULT - RECOMMENDED):
#   - BLOCKs are FINAL - cannot proceed
#   - CONCERNs require acknowledgment
#   - All checks run, no shortcuts

# standard:
#   - BLOCKs require written rationale to override
#   - Overrides are logged with timestamp and rationale
#   - Audit trail maintained

# permissive (NOT RECOMMENDED):
#   - BLOCKs downgraded to CONCERNs
#   - Advisory only
#   - Use only for prototyping
```

## Verdict Levels

| Level | Meaning | Action Required |
|-------|---------|-----------------|
| **PASS** | All checks satisfied | Proceed to next step |
| **CONCERN** | Minor issues, non-blocking | Acknowledge and proceed, or fix |
| **BLOCK** | Critical issues | MUST fix before proceeding |

## Subject Artifacts Matrix

| Gate | Required Artifact | Upstream Artifacts |
|------|-------------------|-------------------|
| `prd` | `devflow/prds/<name>.md` | — |
| `spec` | `devflow/specs/<name>.md` | PRD |
| `plan` | `devflow/specs/<name>-plan.md` | Spec, PRD |
| `epic` | `devflow/epics/<name>/epic.md` + tasks | Plan, Spec |
| `bootstrap` | Project directory | Plan |
| `task` | Individual task file | Task's FR-xxx, Spec |
| `phase` | Phase tasks + test results | Spec (user stories), ADRs |
| `build` | All task files in epic | Spec, Plan |
| `test` | Test results + coverage | Spec (acceptance criteria) |
| `quality` | Lint/security output | — |
| `review` | PR checklist | All upstream |

## Gate: PRD

**Checks (ALL must pass for PASS verdict):**

| Check | PASS | CONCERN | BLOCK |
|-------|------|---------|-------|
| Problem statement | Specific, measurable impact | Somewhat vague | Missing or generic |
| Users/personas | Named roles with specific needs | Generic "users" | Missing |
| Out-of-scope | 3+ specific exclusions | 1-2 items | Empty |
| Constraints | Tech, time, team identified | Partial list | Missing |
| Value proposition | Falsifiable hypothesis | Vague benefit | Missing |
| Success criteria | Quantified metrics | Qualitative only | Missing |

**Execution:**
```
1. Read devflow/prds/<name>.md
2. For each check:
   - Extract relevant section
   - Evaluate against criteria
   - Record verdict with evidence (quote text)
3. Calculate overall verdict
```

**Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚦 GATE: PRD — <name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Check Results:
  ✓ Problem Statement: PASS
    "Reduce checkout abandonment by 40%"

  ⚠ Users/Personas: CONCERN
    Found: "users" (generic)
    Needed: Named roles (e.g., "Returning customers")

  ✓ Out-of-Scope: PASS
    5 items listed

  ✗ Constraints: BLOCK
    Missing: Technology constraints
    Missing: Timeline constraints

  ✓ Value Proposition: PASS
    Falsifiable: "Save 2 hours/week per user"

  ✓ Success Criteria: PASS
    Quantified: "80% completion rate"

Overall: ❌ BLOCK (1 blocking issue)

Blocking Issues:
  1. Constraints section incomplete
     Action: Add technology and timeline constraints

Concerns:
  1. User personas too generic
     Action: Replace "users" with named roles
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Gate: Spec

**Checks:**

| Check | PASS | CONCERN | BLOCK |
|-------|------|---------|-------|
| PRD → US coverage | Every PRD feature has US-xxx | 90%+ coverage | <90% coverage |
| Acceptance criteria | All Given/When/Then testable | Some vague | Missing or untestable |
| Priority distribution | P1≤30%, P2≤50%, P3≥20% | Slightly skewed | All P1 or no P3 |
| Entity coverage | All PRD entities in spec | Minor gaps | Major entities missing |
| FR traceability | All FR link to US | Some orphans | Many orphans |

**Traceability Verification:**

```
PRD Features → Spec User Stories
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Feature: User Authentication
  ✓ US-001: User can register
  ✓ US-002: User can login
  ✓ US-003: User can logout
  ✓ US-004: User can reset password
  Coverage: 4/4 (100%)

Feature: Dashboard
  ✓ US-005: User sees dashboard
  ✗ MISSING: Dashboard customization (from PRD)
  Coverage: 1/2 (50%) — BLOCK

Total Coverage: 5/6 (83%) — BLOCK (requires 100%)
```

## Gate: Plan

**Checks:**

| Check | PASS | CONCERN | BLOCK |
|-------|------|---------|-------|
| FR coverage | Every FR-xxx addressed in plan | 95%+ | <95% |
| Architecture rationale | All decisions have "why" | Some lack detail | No rationale |
| Entity coverage | All spec entities in data model | Minor gaps | Major missing |
| ADR generation | Key decisions documented as ADRs | Few ADRs | No ADRs |
| Risk assessment | 5+ risks with mitigations | 3-4 risks | <3 risks |
| Stack compliance | Follows project defaults | Minor deviations | Major deviation |

**FR → Plan Section Mapping:**
```
FR-001: User registration → Plan: Auth Module ✓
FR-002: Email verification → Plan: Email Service ✓
FR-003: Dashboard display → Plan: Dashboard Module ✓
FR-004: Data export → MISSING — BLOCK
```

## Gate: Epic

**Checks:**

| Check | PASS | CONCERN | BLOCK |
|-------|------|---------|-------|
| Plan coverage | Every plan section has task(s) | 95%+ | <95% |
| traces_to present | All tasks have traces_to | 90%+ | <90% |
| Dependency DAG | No cycles | — | Cycles detected |
| File conflicts | Parallel tasks don't share files | Minor overlap | Major conflicts |
| Phase structure | Full-stack phases | Some incomplete | Layer-only phases |
| Test tasks | Each feature has test tasks | Missing some | No test tasks |

**Dependency Graph Validation:**
```bash
# Detect cycles
# For each task, follow depends_on chain
# If we return to starting task → CYCLE → BLOCK
```

**Full-Stack Phase Validation:**
```
Phase 1: Authentication
  ✓ DB tasks: 001, 002 (users, sessions)
  ✓ API tasks: 003, 004 (endpoints)
  ✓ UI tasks: 005, 006 (pages)
  ✓ Test tasks: 007 (e2e)
  Status: FULL-STACK ✓

Phase 2: Dashboard
  ✓ DB tasks: 008 (widgets)
  ✓ API tasks: 009, 010
  ✗ UI tasks: MISSING — BLOCK
  ✗ Test tasks: MISSING — BLOCK
  Status: INCOMPLETE — BLOCK
```

## Gate: Phase (NEW — CRITICAL)

**Runs after each development phase. MANDATORY before proceeding to next phase.**

**Checks:**

| Check | PASS | CONCERN | BLOCK |
|-------|------|---------|-------|
| All tasks complete | 100% | 95%+ | <95% |
| Unit tests | 100% pass, 80%+ coverage | 70-80% coverage | <70% or failures |
| Integration tests | 100% pass | — | Any failure |
| E2E tests | 100% pass | — | Any failure |
| Regression | 100% previous pass | — | Any regression |
| ADR compliance | 100% | — | Any violation |
| User verification | Confirmed | — | Not verified |

**User Story Acceptance Verification:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 USER STORY VERIFICATION: Phase 1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

US-001: User can register
  AC-1: Given new user, When submit valid form → account created
        Test: test_register_success ✓ PASS

  AC-2: Given invalid email, When submit → error shown
        Test: test_register_invalid_email ✓ PASS

  AC-3: Given existing email, When submit → duplicate error
        Test: test_register_duplicate ✓ PASS

  Status: 3/3 acceptance criteria verified ✓

US-002: User can login
  AC-1: Given valid creds, When login → dashboard shown
        Test: test_login_success ✓ PASS

  AC-2: Given invalid creds, When login → error shown
        Test: test_login_invalid ✓ PASS

  AC-3: Given locked account, When login → locked message
        Test: MISSING — BLOCK

  Status: 2/3 acceptance criteria verified — BLOCK

Phase Status: ❌ BLOCK
  Missing test for US-002 AC-3 (locked account scenario)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Test Results Validation:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧪 TEST RESULTS: Phase 1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Unit Tests:
  Collected: 45
  Passed: 45
  Failed: 0
  Coverage: 87%
  Status: ✓ PASS

Integration Tests:
  Collected: 12
  Passed: 12
  Failed: 0
  Status: ✓ PASS

E2E Tests:
  Collected: 8
  Passed: 7
  Failed: 1
  Status: ❌ BLOCK

  Failed test: test_logout_clears_session
  Error: AssertionError: Session still active after logout

Regression Tests:
  Previous phases: N/A (first phase)
  Status: ✓ PASS

Overall: ❌ BLOCK (1 E2E test failure)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Gate: Test

**Checks:**

| Check | PASS | CONCERN | BLOCK |
|-------|------|---------|-------|
| Unit test pass rate | 100% | — | <100% |
| Integration pass rate | 100% | — | <100% |
| E2E pass rate | 100% | — | <100% |
| Coverage overall | ≥80% | 70-80% | <70% |
| US coverage | 100% AC tested | 90%+ | <90% |
| Skipped tests | 0 without reason | <5 with reason | >5 or no reason |
| Flaky tests | 0 | — | Any flaky |

## Gate: Quality

**Checks:**

| Check | PASS | CONCERN | BLOCK |
|-------|------|---------|-------|
| Lint errors | 0 | <10 | ≥10 |
| Type errors | 0 | — | Any |
| Security: High | 0 | — | Any |
| Security: Medium | 0 | <5 | ≥5 |
| Secrets detected | 0 | — | Any |

## Gate: Review

**Checks:**

| Check | PASS | CONCERN | BLOCK |
|-------|------|---------|-------|
| Checklist items | All addressed | <3 outstanding | ≥3 outstanding |
| ADR compliance | Verified | — | Violations |
| Breaking changes | Documented | Partial | Undocumented |
| Unresolved comments | 0 | — | Any |

## Execution Flow

### Step 1: Load Artifacts

```python
# Pseudocode
subject = read_artifact(gate_type, feature_name)
upstream = load_upstream_artifacts(gate_type, feature_name)
adrs = load_all_adrs("devflow/adrs/")
```

### Step 2: Run Checks

```python
results = []
for check in GATE_CHECKS[gate_type]:
    result = run_check(check, subject, upstream, adrs)
    results.append(result)
```

### Step 3: Traceability Verification

```python
# Forward: upstream → downstream
forward_coverage = verify_forward_coverage(upstream, subject)

# Backward: downstream → upstream
backward_coverage = verify_backward_coverage(subject, upstream)

# Forward orphans = BLOCK
# Backward orphans = CONCERN
```

### Step 4: Pre-Mortem Analysis

Generate 3-5 failure scenarios:
```
1. What if [scenario]?
   Impact: HIGH/MEDIUM/LOW
   Status: Mitigated/Unmitigated

2. What if [scenario]?
   ...
```

Unmitigated + HIGH = escalate to BLOCK.

### Step 5: Determine Verdict

```python
if any(result.level == BLOCK):
    verdict = BLOCK
elif any(result.level == CONCERN):
    verdict = CONCERN
else:
    verdict = PASS
```

### Step 6: Apply Gate Mode

```python
if gate_mode == "strict":
    if verdict == BLOCK:
        print("BLOCKED - Cannot proceed. Fix all issues.")
        return STOP

elif gate_mode == "standard":
    if verdict == BLOCK:
        rationale = ask_user("Provide rationale to override:")
        if rationale:
            log_override(rationale, timestamp)
            verdict = CONCERN  # Downgrade
        else:
            return STOP

elif gate_mode == "permissive":
    if verdict == BLOCK:
        verdict = CONCERN  # Advisory only
```

### Step 7: Log Result

Update artifact frontmatter:
```yaml
gates:
  - gate: <gate-name>
    verdict: <PASS|CONCERN|BLOCK>
    timestamp: <ISO 8601 UTC>
    mode: <strict|standard|permissive>
    checks:
      - name: <check-name>
        result: <PASS|CONCERN|BLOCK>
        evidence: "<quote or metric>"
    concerns:
      - "<concern text>"
    blocks:
      - "<block text>"
    override_rationale: "<if applicable>"
```

### Step 8: Output Report

Use the format from `devflow/templates/gate/gate-report-template.md`.

## Error Recovery

- **Artifact missing:** Print which file is missing and STOP.
- **Upstream missing:** Note gap (this is likely a BLOCK for traceability).
- **Runtime check fails:** Capture error output, include in BLOCK details.
- **Gate mode not set:** Default to `strict`.
- **Repeated failures:** After 3 attempts, suggest `/pm:validate` to check system integrity.
