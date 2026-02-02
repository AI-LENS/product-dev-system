---
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Task, AskUserQuestion
---

# Gate

Run a stage-specific quality gate on an artifact. Gates verify that each pipeline step produced output good enough for the next step to consume.

## Usage

```
/devflow:gate <gate-name> <feature-name>
```

**Gate names:** `prd`, `spec`, `plan`, `epic`, `bootstrap`, `task`, `build`, `test`, `quality`, `review`

## Required Rules

- `devflow/rules/elite-dev-protocol.md`
- `devflow/rules/datetime.md`
- `devflow/rules/frontmatter-operations.md`

## Preflight Checklist

1. Verify `<gate-name>` is one of: `prd`, `spec`, `plan`, `epic`, `bootstrap`, `task`, `build`, `test`, `quality`, `review`. If invalid, print valid options and stop.
2. Verify `<feature-name>` is provided.
3. Read `gate_mode` from `devflow/devflow.config`. Default to `standard` if not set.
4. Verify the subject artifact exists (see Subject Artifacts table below).

### Subject Artifacts

| Gate | Required Artifact | Upstream Artifacts (also read) |
|------|-------------------|-------------------------------|
| `prd` | `devflow/prds/<name>.md` | — |
| `spec` | `devflow/specs/<name>.md` | `devflow/prds/<name>.md` |
| `plan` | `devflow/specs/<name>-plan.md` | `devflow/specs/<name>.md`, `devflow/prds/<name>.md` |
| `epic` | `devflow/epics/<name>/epic.md` + task files | `devflow/specs/<name>-plan.md`, `devflow/specs/<name>.md` |
| `bootstrap` | Project directory (from plan) | `devflow/specs/<name>-plan.md` |
| `task` | Individual task file | Task's `traces_to` FR-xxx in spec |
| `build` | All task files in epic | `devflow/specs/<name>.md`, `devflow/specs/<name>-plan.md` |
| `test` | Test results output | `devflow/specs/<name>.md` (coverage requirements) |
| `quality` | Lint/security output | — |
| `review` | PR checklist | All upstream artifacts |

## Instructions

### Step 1: Read Subject + Upstream Artifacts

Read the subject artifact and all upstream artifacts listed in the table above. Build a mental model of what the artifact should contain based on its upstream inputs.

### Step 2: Run Gate-Specific Checks

Execute the checks defined in `devflow/rules/elite-dev-protocol.md` for the given gate name. For each check:
- Evaluate against the actual artifact content
- Classify as PASS, CONCERN, or BLOCK
- Record specific evidence (quote the problematic text, cite the missing item)

#### gate:prd
1. Read `devflow/prds/<name>.md`
2. Check: Problem statement specificity — is it concrete or vague?
3. Check: Users/personas — are they named roles with real needs, or generic "users"?
4. Check: Out-of-scope — does it have real items (not empty)?
5. Check: Constraints — are they honest (tech, time, team)?
6. Check: Value proposition — is it falsifiable?

#### gate:spec
1. Read `devflow/specs/<name>.md` and `devflow/prds/<name>.md`
2. Check: Every PRD feature has at least one US-xxx
3. Check: Acceptance criteria are testable (no vague adjectives without thresholds)
4. Check: Priority distribution — not everything is P1
5. Check: Key entities match PRD entities
6. Check: FR-xxx requirements link to US-xxx stories

#### gate:plan
1. Read `devflow/specs/<name>-plan.md`, `devflow/specs/<name>.md`, `devflow/prds/<name>.md`
2. Check: Every FR-xxx from spec is addressed in a plan section
3. Check: Architecture decisions have rationale
4. Check: Data model covers all spec entities
5. Check: Risk assessment is non-empty and honest
6. Check: Project structure matches stack decisions

#### gate:epic
1. Read `devflow/epics/<name>/epic.md`, all task files, and the plan
2. Check: Every plan section maps to at least one task
3. Check: Tasks have `traces_to:` fields
4. Check: Dependency graph is a DAG (detect cycles)
5. Check: Parallel tasks don't share files (check `Files Affected` sections)
6. Check: No orphaned plan sections

#### gate:bootstrap
1. Run: `cd <project-dir> && python -m pytest --co -q 2>&1 | tail -5` (test discovery)
2. Run: Server start check (e.g., `python -c "from app.main import app; print('OK')"`)
3. Run: Database connection check (if applicable)
4. Check: Directory structure matches plan
5. Check: `.env.example` exists with documented variables

#### gate:task
1. Read the task file and its `traces_to:` FR-xxx requirements from spec
2. Check: Each acceptance criterion has evidence of completion
3. Check: Tests exist in the expected location and pass
4. Check: Code follows existing patterns (compare with neighboring files)
5. Check: No orphan TODOs without linked issues

#### gate:build
1. Read all task files in the epic — verify all are complete
2. Run: Full test suite (`pytest` or equivalent)
3. Check: No import errors or missing modules across task boundaries
4. Check: API contracts between tasks are consistent

#### gate:test
1. Read test results and coverage report
2. Check: Coverage >= 80% on new code
3. Check: Zero failures
4. Check: No tests marked as `skip` without explanation

#### gate:quality
1. Read lint and security check output
2. Check: Zero lint errors
3. Check: Zero high/critical security findings
4. Check: No secrets detected in codebase

#### gate:review
1. Read PR checklist
2. Check: All items addressed or marked N/A with reason
3. Check: No unresolved comments
4. Check: Breaking changes documented (if any)

### Step 3: Pre-Mortem

Generate 3-5 failure scenarios specific to this gate and artifact. For each:
- Describe what could go wrong
- Assess impact (HIGH / MEDIUM / LOW)
- Classify as Mitigated (artifact addresses it) or Unmitigated

Unmitigated + HIGH impact = escalate to BLOCK.

### Step 4: Traceability Check

**Forward coverage**: For each upstream requirement, verify it has a downstream artifact.
**Backward coverage**: For each artifact element, verify it traces to an upstream requirement.

Calculate coverage percentages. Forward orphans = BLOCK. Backward orphans = CONCERN.

### Step 5: Render Verdict

Aggregate all check results:
- Any BLOCK-level issue → overall verdict is **BLOCK**
- No BLOCKs but CONCERNs exist → overall verdict is **CONCERN**
- All checks pass → overall verdict is **PASS**

Apply `gate_mode`:
- `strict`: BLOCKs are final. Cannot proceed.
- `standard`: BLOCKs require written rationale to override. Ask user for rationale. Log it.
- `permissive`: BLOCKs downgraded to CONCERNs. All advisory.

Print the gate report using the format from `devflow/templates/gate/gate-report-template.md`.

### Step 6: Log Result

Append the gate result to the subject artifact's frontmatter under the `gates:` key:

```yaml
gates:
  - gate: <gate-name>
    verdict: <PASS|CONCERN|BLOCK>
    timestamp: <ISO 8601 UTC>
    concerns:
      - "<concern text>"
    blocks:
      - "<block text>"
    override_rationale: "<rationale if BLOCK overridden in standard mode>"
```

Get the real timestamp via `date -u +"%Y-%m-%dT%H:%M:%SZ"`.

If the artifact doesn't have a `gates:` key yet, add it to the frontmatter.

## Error Recovery

- If the subject artifact doesn't exist, print which file is missing and stop.
- If upstream artifacts are missing, note the gap (this itself may be a BLOCK for traceability).
- If a runtime check fails (e.g., server won't start for gate:bootstrap), capture the error output and include it in the BLOCK details.
