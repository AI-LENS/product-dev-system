# Elite Developer Protocol

Core verification rule for DevFlow. Every artifact-producing step passes through a quality gate before the pipeline advances.

## Gate Verdicts

Every gate produces exactly one verdict:

| Verdict | Meaning | Pipeline Effect |
|---------|---------|-----------------|
| **PASS** | All checks satisfied. | Continue. Near-silent output (one-line summary). |
| **CONCERN** | Non-critical issues found. | Show issues. User decides: proceed, iterate, or deep-dive. |
| **BLOCK** | Critical issue that will cause downstream failure. | Pipeline halts. Must fix and re-run gate. |

Verdict behavior depends on `gate_mode` in `devflow/devflow.config`:

| gate_mode | BLOCK behavior | CONCERN behavior |
|-----------|---------------|-----------------|
| `strict` | Mandatory halt. No override. | Shown, user decides. |
| `standard` | Must provide written rationale to override. Rationale logged in `gates:` frontmatter. | Shown, user decides. |
| `permissive` | Downgraded to CONCERN. All advisory. | Shown, user decides. |

## Traceability Chain

Every requirement must be traceable end-to-end:

```
PRD Feature → US-xxx (Spec) → FR-xxx (Spec) → Plan Section → Task (traces_to: FR-xxx) → Code
```

### Orphan Detection

- **Forward orphan**: A requirement (PRD feature, US-xxx, or FR-xxx) with no downstream implementation. Verdict: **BLOCK**.
- **Backward orphan**: An implementation artifact (task, code) with no upstream requirement. Verdict: **CONCERN** (may be valid infrastructure work, but must be acknowledged).

## Pre-Mortem Protocol

At each gate, ask: **"What would make this fail in production?"**

Generate 3-5 specific failure scenarios for the artifact under review. Classify each as:

- **Mitigated**: The artifact already addresses this risk.
- **Unmitigated**: The artifact does NOT address this risk.

Unmitigated risks with HIGH impact = **BLOCK**. Unmitigated risks with LOW/MEDIUM impact = **CONCERN**.

## Self-Review Protocol (for Agents)

Before any agent reports work as complete, it MUST:

1. **Re-read** the original task requirements and acceptance criteria.
2. **Check each acceptance criterion** — mark as MET or UNMET with evidence.
3. **Verify tests** — run tests, report pass count and failure count.
4. **Check patterns** — compare implementation against existing project patterns. Note deviations.
5. **Assess confidence** — report honestly as HIGH / MEDIUM / LOW.
6. **Report known limitations** — list anything incomplete, hacky, or risky.

### Self-Review Output Format

Every agent appends this to their completion report:

```
### Self-Review
- Acceptance criteria: X/Y met, Z gaps: [list gaps or "none"]
- Tests: X passing, Y failing
- Pattern compliance: [compliant / N deviations noted]
- Known limitations: [list or "none"]
- Confidence: HIGH / MEDIUM / LOW
```

If confidence is LOW or acceptance criteria have gaps, the agent must flag this — it does not silently pass.

## Gate-Specific Checks

### gate:prd
- Problem statement is specific (not "improve user experience" — what experience, for whom, what's broken)
- Users/personas are concrete (not "users" — named roles with real needs)
- Out-of-scope has real items (not empty or trivially obvious)
- Constraints are honest (tech, time, team, budget — not "none")
- Value proposition is falsifiable (could be wrong, therefore meaningful)

### gate:spec
- Every PRD feature maps to at least one US-xxx
- Acceptance criteria are testable (no "appropriate", "fast", "good", "proper" without numbers)
- Priority distribution is sane (not everything is P1)
- Key entities match PRD entities (no phantom entities, no missing entities)
- FR-xxx requirements link back to US-xxx stories

### gate:plan
- Every FR-xxx from spec is addressed in a plan section
- Architecture decisions have rationale (not just "we chose X")
- Data model covers all spec entities with correct relationships
- Risk assessment is honest (not empty, not "no risks identified")
- Project structure matches the stack decisions

### gate:epic
- Every plan section maps to at least one task
- Tasks have `traces_to:` fields linking to FR-xxx IDs
- Dependency graph is a DAG (no cycles)
- Parallel tasks do not share the same files (conflict detection)
- No plan section is orphaned (has no corresponding task)

### gate:bootstrap
- Server starts without errors
- Database connects and migrations run
- `pytest` discovers and runs (even if no app tests yet)
- Directory structure matches the plan's project structure
- Environment variables documented in `.env.example`

### gate:task
- Every acceptance criterion is met (with evidence)
- Tests exist and pass for the task's scope
- Code follows existing project patterns (imports, naming, structure)
- No orphan TODOs left without linked issues
- `traces_to:` FR-xxx requirements are satisfied

### gate:build
- All individual tasks are complete
- Full test suite passes (not just individual task tests)
- Integration between tasks works (cross-task API calls, shared models)
- No merge conflicts in the aggregate codebase

### gate:test
- Coverage >= 80% on new code (not overall — new code only)
- Zero test failures
- No flaky tests (tests that pass/fail inconsistently)
- Edge cases covered (empty input, boundary values, error paths)

### gate:quality
- Zero lint errors (warnings acceptable if justified)
- Zero high/critical security findings
- No secrets in codebase (API keys, passwords, tokens)

### gate:review
- All PR checklist items addressed or explicitly marked N/A with reason
- No unresolved review comments
- Changelog or release notes updated
- Breaking changes documented

## Gate Logging

Every gate result is logged in the artifact's frontmatter under a `gates:` key:

```yaml
gates:
  - gate: prd
    verdict: PASS
    timestamp: 2025-01-15T10:30:00Z
    concerns: []
    blocks: []
  - gate: spec
    verdict: CONCERN
    timestamp: 2025-01-15T11:00:00Z
    concerns:
      - "US-003 acceptance criteria uses 'appropriate' without threshold"
    blocks: []
```

This creates an audit trail. Re-running a gate appends a new entry (does not overwrite).
