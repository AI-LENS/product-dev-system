---
gate: {gate-name}
feature: {feature-name}
verdict: {PASS|CONCERN|BLOCK}
timestamp: {datetime}
gate_mode: {strict|standard|permissive}
---

# Gate Report: {gate-name} — {feature-name}

## Verdict: {PASS | CONCERN | BLOCK}

{One-sentence summary of the verdict.}

## Checks

| # | Check | Result | Details |
|---|-------|--------|---------|
| 1 | {check description} | PASS / CONCERN / BLOCK | {specifics} |
| 2 | {check description} | PASS / CONCERN / BLOCK | {specifics} |
| 3 | {check description} | PASS / CONCERN / BLOCK | {specifics} |

## Traceability

### Forward Coverage (Requirements → Implementation)

| Source | ID | Downstream Artifact | Status |
|--------|----|---------------------|--------|
| PRD Feature | {feature} | US-{xxx} | Covered / Orphan |
| Spec Story | US-{xxx} | FR-{xxx} | Covered / Orphan |
| Spec Requirement | FR-{xxx} | Plan Section / Task | Covered / Orphan |

**Forward coverage: {X}% ({N}/{M} requirements traced)**

### Backward Coverage (Implementation → Requirements)

| Artifact | Traces To | Status |
|----------|-----------|--------|
| Task {NNN} | FR-{xxx} | Traced / Orphan |

**Backward coverage: {X}% ({N}/{M} artifacts traced)**

## Pre-Mortem

| # | Failure Scenario | Impact | Status | Notes |
|---|-----------------|--------|--------|-------|
| 1 | {what could go wrong} | HIGH / MEDIUM / LOW | Mitigated / Unmitigated | {how it's addressed or why it's risky} |
| 2 | {what could go wrong} | HIGH / MEDIUM / LOW | Mitigated / Unmitigated | {notes} |
| 3 | {what could go wrong} | HIGH / MEDIUM / LOW | Mitigated / Unmitigated | {notes} |

## Blocking Issues

{List each BLOCK-level issue. If none, write "None."}

- **BLOCK-1**: {description}
  - **Why it blocks**: {downstream impact if ignored}
  - **Fix**: {what needs to change}

## Concerns

{List each CONCERN-level issue. If none, write "None."}

- **CONCERN-1**: {description}
  - **Risk**: {what could go wrong}
  - **Recommendation**: {suggested action}

## Gate Log Entry

```yaml
- gate: {gate-name}
  verdict: {PASS|CONCERN|BLOCK}
  timestamp: {datetime}
  concerns:
    - "{concern 1}"
  blocks:
    - "{block 1}"
  override_rationale: "{if standard mode and BLOCK was overridden}"
```
