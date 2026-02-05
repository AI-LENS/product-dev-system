---
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Task, TaskCreate, TaskUpdate, TaskList, TaskGet, Agent, AskUserQuestion
---

# Execute

Run the Execution Phase — agents consume brainstorming artifacts and build, test, review, and ship. This command is optional; you can run any individual command from Phase B independently.

## Usage

```
/devflow:execute <name>
```

Where `<name>` matches the name used in `/devflow:kickstart <name>`.

## Resume Behavior

**This command is resumable.** If interrupted (context compaction, error, etc.), just run it again with the same `<name>`. It will:

1. Check task status in GitHub issues or local epic files
2. Skip completed tasks, resume in-progress tasks
3. Continue from the first incomplete step

**To check current status:** Run `/pm:status` to see what's complete vs pending.

## Execution Policy — NO SKIPPING

**ALL steps are MANDATORY. Gates are BLOCKING. No exceptions.**

- Every step in the pipeline MUST be executed in sequence
- Gates MUST pass before proceeding — there is no "skip" option
- If a gate fails, execution STOPS until the issue is fixed
- User cannot skip steps, jump ahead, or bypass gates
- The only valid responses at gates are: "Fix and retry" or "Abort execution"

## Step Completion Protocol — MANDATORY USER CONFIRMATION

**⛔ CRITICAL:** After EVERY step, you MUST get explicit user approval before proceeding.

### Step Confirmation Pattern — REQUIRED AFTER EVERY STEP

**After completing ANY step (including sub-steps like 3.2, 3.3, etc.), present:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ STEP [N.X] COMPLETE: [Step Name]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

What was done:
  • [Action 1]
  • [Action 2]
  • [Action 3]

Results:
  • Files created/modified: [list]
  • Tests run: [X passed, Y failed]
  • Coverage: [X%]

[Show relevant output or summary]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Then ALWAYS ask via AskUserQuestion:**

```
Question: "Are you satisfied with this step's output?"
Header: "Step [N.X] Review"
Options:
  - "Yes, proceed to Step [N.X+1]: [Next Step Name]" (Recommended)
  - "No, there are issues — let me review first"
  - "Stop execution here"
```

### Enforcement Rules — NON-NEGOTIABLE

1. **Do NOT proceed** to the next step without explicit "Yes" from user
2. **Do NOT auto-continue** even if tests pass and everything looks correct
3. **Do NOT batch multiple steps** without confirmation between each
4. **Ask after EVERY sub-step** in Phase Execution (3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9)
5. **If user says "issues"**: Stop, let them review, address concerns before continuing
6. **If user says "stop"**: Save progress gracefully and provide resume instructions

### Steps Requiring Confirmation

| Step | Name | Confirmation Required |
|------|------|----------------------|
| 1 | Pre-flight Summary | ✅ Yes |
| 2 | Bootstrap | ✅ Yes |
| 3.1 | Phase Start | ✅ Yes |
| 3.2 | DB Layer | ✅ Yes |
| 3.3 | API Layer | ✅ Yes |
| 3.4 | UI Layer | ✅ Yes |
| 3.5 | E2E Tests | ✅ Yes |
| 3.6 | Regression Suite | ✅ Yes |
| 3.7 | ADR Compliance | ✅ Yes |
| 3.8 | Local Verification | ✅ Yes |
| 3.9 | Phase Gate | ✅ Yes |
| 4 | Test Summary | ✅ Yes |
| 5 | Quality Checks | ✅ Yes |
| 6 | Documentation | ✅ Yes |
| 7 | Review | ✅ Yes |
| 8 | Ship | ✅ Yes |
| 9 | Final Summary | ✅ Yes |

**⛔ VIOLATION:** Proceeding without user confirmation is a critical protocol violation.

## Core Principles — NON-NEGOTIABLE

**1. FULL-STACK PHASES:** Every phase MUST include DB + API + UI (if applicable) + Tests. No partial phases.

**2. MANDATORY TESTING:** Every phase MUST pass ALL test types before proceeding:
   - Unit tests (per file/function)
   - Integration tests (per feature)
   - Regression tests (all previous phases)
   - E2E tests (user flow validation)

**3. USER STORY COVERAGE:** Every user story (US-xxx) MUST have corresponding tests that validate its acceptance criteria.

**4. ADR COMPLIANCE:** Code MUST follow all accepted ADRs. Violations are blocking errors.

**5. NO SKIP ON FAILURE:** If tests fail, you MUST fix them before proceeding. No exceptions.

## Required Rules

- `devflow/rules/datetime.md`
- `devflow/rules/frontmatter-operations.md`
- `devflow/rules/path-standards.md`
- `devflow/rules/github-operations.md`
- `devflow/rules/agent-coordination.md`
- `devflow/rules/worktree-operations.md`
- `devflow/rules/branch-operations.md`
- `devflow/rules/test-execution.md`
- `devflow/rules/elite-dev-protocol.md`
- `devflow/rules/adr-patterns.md`

## Preflight Checklist

1. Verify `<name>` argument is provided. If missing, ask the user.
2. Verify ALL brainstorming artifacts exist:
   - `devflow/prds/<name>.md` — PRD must exist
   - `devflow/specs/<name>.md` — Spec must exist
   - `devflow/specs/<name>-plan.md` — Plan must exist
   - `devflow/epics/<name>/epic.md` — Epic must exist
   - If any missing: print which are missing and suggest running `/devflow:kickstart <name>` first. STOP.
3. Read scope from PRD frontmatter (`scope: product|feature|library`).
4. Verify `devflow/devflow.config` exists.
5. Check GitHub CLI (`gh`) is authenticated: `gh auth status`.
6. **Load ADRs:** Read all ADR files from `devflow/adrs/` and extract accepted decisions.
7. **Load User Stories:** Read spec and extract all US-xxx with acceptance criteria for test mapping.
8. **Load Design Artifacts (if scope is product/feature with UI):**
   - `devflow/design/tokens.md` — Design tokens (colors, typography, spacing)
   - `devflow/design/shell.md` — App shell layout
   - `devflow/design/sections/*.md` — Section-specific UI specs
   - If design was created in kickstart but files missing: WARN user.
9. **Load Context:** Read `devflow/context/*.md` for codebase context.

## Scope Behavior Matrix

| Step | Product | Feature | Library |
|------|---------|---------|---------|
| Bootstrap | Full scaffold (backend + frontend + DB + auth + AI + deploy) | Skip (project exists) | Skip (project exists) |
| **Local Deploy** | Start local servers, verify setup | Start local, verify feature | Run tests locally |
| Build | All workers (db, api, ui, ai) | Affected workers only | api-task-worker + test-runner |
| **Verify** | Check each feature locally before next | Check feature works | Run examples |
| Test | Full suite (unit + integration + E2E + AI eval) | Affected tests | Unit + integration + property-based |
| Quality | Lint + security + perf budgets | Lint + security | Lint + security + type checking |
| **Docs** | Mintlify docs (beginner-friendly) | Update affected docs | API reference + examples |
| Review | PR checklist per epic | PR checklist | PR checklist + API review |
| Ship | Full deploy (CI/CD + Docker + env + monitoring) | Feature deploy (branch merge) | Publish (package build + publish + docs) |

## Task Agent Strategy

**CRITICAL:** Use the Task tool to spawn sub-agents for maximum parallelization. This provides:
- Parallel task execution (multiple agents working simultaneously)
- Better context management (each agent has its own context)
- Resilience to context compaction
- Progress tracking via TaskCreate/TaskUpdate

### Execution Pattern

1. **Create tasks first** using TaskCreate for all pending work items
2. **Analyze dependencies** from epic files to determine parallel vs sequential
3. **Launch parallel agents** for independent tasks (single message, multiple Task calls)
4. **Wait and launch next batch** when dependencies complete
5. **Update task status** as each completes

### Parallelization Map (Build Phase)

```
Parallel by layer (no file conflicts):
- db-task-worker: schema, migrations, seeds
- api-task-worker: endpoints, services (after DB)
- ui-task-worker: components, pages (after API contracts)
- ai-task-worker: prompts, evals (independent)
- test-runner: tests (after implementations)

Within each layer, parallelize tasks that don't touch same files.
```

### Task Agent Types

Use appropriate subagent_type for each task:
- `general-purpose` — complex multi-step tasks
- `Bash` — simple command execution
- `Explore` — codebase exploration

### Example: Parallel Task Launch

```
# Launch 3 independent tasks in ONE message:
Task(subagent_type="general-purpose", prompt="Implement DB schema for users...")
Task(subagent_type="general-purpose", prompt="Implement DB schema for sessions...")
Task(subagent_type="general-purpose", prompt="Set up CI pipeline...")
```

## Test Requirements Matrix

| Test Type | When Run | Coverage Required | Failure Action |
|-----------|----------|-------------------|----------------|
| Unit | After each task | 80% of new code | BLOCK - fix before proceeding |
| Integration | After each feature | All API endpoints | BLOCK - fix before proceeding |
| Regression | After each phase | 100% previous tests pass | BLOCK - cannot proceed |
| E2E | After each phase | All US-xxx acceptance criteria | BLOCK - cannot proceed |
| Performance | Before ship | NFR thresholds met | CONCERN - user decides |
| Security | Before ship | No high/critical findings | BLOCK - must fix |

## Full-Stack Phase Structure — MANDATORY

**EVERY phase MUST follow this structure. No exceptions.**

```
┌─────────────────────────────────────────────────────────────────────┐
│  PHASE {N}: {Feature Name}                                          │
│  Example: Phase 1: Authentication Feature                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  STEP 1: DATABASE LAYER                                             │
│  ├─ Create SQLAlchemy models                                        │
│  ├─ Create Alembic migration                                        │
│  ├─ Apply migration                                                 │
│  ├─ Create seed data (if needed)                                    │
│  └─ ✓ GATE: DB layer tests pass                                     │
│                                                                     │
│  STEP 2: API LAYER                                                  │
│  ├─ Create Pydantic schemas                                         │
│  ├─ Create service layer                                            │
│  ├─ Create API endpoints                                            │
│  ├─ Add authentication (if required)                                │
│  └─ ✓ GATE: API tests pass (unit + integration)                     │
│                                                                     │
│  STEP 3: UI LAYER (if applicable)                                   │
│  ├─ Create components                                               │
│  ├─ Create pages                                                    │
│  ├─ Wire up state management                                        │
│  ├─ Connect to API                                                  │
│  └─ ✓ GATE: UI tests pass                                           │
│                                                                     │
│  STEP 4: FEATURE TESTS (MANDATORY)                                  │
│  ├─ Unit tests: All new functions/methods                           │
│  ├─ Integration tests: API endpoint flows                           │
│  ├─ E2E tests: User story acceptance criteria                       │
│  └─ ✓ GATE: ALL tests pass (no skip allowed)                        │
│                                                                     │
│  STEP 5: REGRESSION SUITE (MANDATORY)                               │
│  ├─ Run ALL previous phase tests                                    │
│  ├─ Run full test suite                                             │
│  └─ ✓ GATE: Zero regressions (100% previous tests pass)             │
│                                                                     │
│  STEP 6: LOCAL VERIFICATION                                         │
│  ├─ Deploy locally                                                  │
│  ├─ User manually verifies feature                                  │
│  └─ ✓ GATE: User sign-off                                           │
│                                                                     │
│  STEP 7: ADR COMPLIANCE CHECK                                       │
│  ├─ Verify code follows all accepted ADRs                           │
│  └─ ✓ GATE: No ADR violations                                       │
│                                                                     │
│  PHASE COMPLETE: All 7 steps passed                                 │
│  → Proceed to Phase {N+1}                                           │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## User Story Test Mapping — MANDATORY

**Before execution begins**, create a test mapping table from the spec:

```markdown
## User Story → Test Mapping

| User Story | Acceptance Criteria | Test File | Test Status |
|------------|---------------------|-----------|-------------|
| US-001 | Given logged out, When login, Then see dashboard | tests/e2e/test_auth_flow.py::test_login_success | PENDING |
| US-001 | Given invalid creds, When login, Then see error | tests/e2e/test_auth_flow.py::test_login_invalid | PENDING |
| US-002 | Given logged in, When logout, Then redirect to login | tests/e2e/test_auth_flow.py::test_logout | PENDING |
| US-003 | Given admin, When access users, Then see user list | tests/e2e/test_user_mgmt.py::test_admin_users | PENDING |
```

**EVERY user story acceptance criterion MUST have a corresponding test.**

Track this mapping throughout execution and update status:
- PENDING → WRITTEN → PASSING → VERIFIED

## Instructions

### Step 1: Pre-flight Summary & Test Mapping

Read all artifacts and present the COMPLETE execution plan with ALL steps:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 EXECUTION PHASE: <name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Scope: <product|feature|library>

Artifacts Loaded:
  ✓ PRD:     devflow/prds/<name>.md
  ✓ Spec:    devflow/specs/<name>.md ([N] user stories)
  ✓ Plan:    devflow/specs/<name>-plan.md
  ✓ Epic:    devflow/epics/<name>/epic.md
  ✓ Tasks:   [N] task files
  ✓ ADRs:    [N] accepted decisions
  ✓ Design:  [present|skipped] (tokens, shell, [N] sections)
  ✓ Context: devflow/context/*.md

User Stories to Test:
  - US-001: [title] ([N] acceptance criteria)
  - US-002: [title] ([N] acceptance criteria)
  - US-003: [title] ([N] acceptance criteria)
  Total: [N] acceptance criteria requiring tests

Phases Detected:
  Phase 1: [Feature] ([N] tasks) - Full stack: DB + API + UI
  Phase 2: [Feature] ([N] tasks) - Full stack: DB + API + UI
  Phase 3: [Feature] ([N] tasks) - Full stack: DB + API + UI

ADRs to Enforce:
  - ADR-001: [title]
  - ADR-002: [title]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 MANDATORY EXECUTION STEPS (ALL will be executed)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 2: BOOTSTRAP (product scope only)
  ├─ /init:project — Scaffold project
  ├─ /init:database — SQLAlchemy + Alembic
  ├─ /init:auth — JWT authentication
  ├─ /init:ai — AI/LLM layer (if applicable)
  ├─ /init:deploy — CI/CD scaffold
  └─ 🚦 GATE: Bootstrap verification (BLOCKING)

FOR EACH PHASE (Steps 3.1-3.9):
  ├─ Step 3.1: Phase Start — Load artifacts
  ├─ Step 3.2: DB Layer — Models, migrations, seeds
  │   └─ 🚦 GATE: DB tests pass (BLOCKING)
  ├─ Step 3.3: API Layer — Schemas, services, endpoints
  │   └─ 🚦 GATE: API tests pass (BLOCKING)
  ├─ Step 3.4: UI Layer — Components, pages, state
  │   └─ 🚦 GATE: UI tests pass (BLOCKING)
  ├─ Step 3.5: E2E Tests — User story validation
  │   └─ 🚦 GATE: All E2E tests pass (BLOCKING)
  ├─ Step 3.6: Regression Suite — All previous tests
  │   └─ 🚦 GATE: Zero regressions (BLOCKING)
  ├─ Step 3.7: ADR Compliance — Verify decisions followed
  │   └─ 🚦 GATE: No violations (BLOCKING)
  ├─ Step 3.8: Local Verification — User confirms feature
  │   └─ 🚦 GATE: User sign-off (BLOCKING)
  └─ Step 3.9: Phase Gate — All criteria checked
      └─ 🚦 GATE: Phase complete (BLOCKING)

STEP 4: TEST SUMMARY
  └─ Final test report with coverage

STEP 5: QUALITY CHECKS
  ├─ Linting (ruff)
  ├─ Type checking (mypy)
  └─ Security (bandit, pip-audit)

STEP 6: DOCUMENTATION (Mintlify)
  └─ Generate beginner-friendly docs

STEP 7: REVIEW
  └─ /review:pr-checklist with ADR compliance

STEP 8: SHIP
  ├─ /deploy:setup — CI/CD pipeline
  ├─ /deploy:docker — Containerization
  ├─ /deploy:env-check — Environment validation
  └─ /review:release — Pre-release validation

STEP 9: FINAL SUMMARY
  └─ Execution complete report

⚠️  ALL gates are BLOCKING. Execution cannot proceed if any gate fails.
⚠️  Steps CANNOT be skipped. The only options are: proceed or abort.
⚠️  USER CONFIRMATION required after EVERY step before proceeding.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**🚦 CONFIRMATION REQUIRED:** Ask via AskUserQuestion:
- "Yes, start execution" (Recommended)
- "Abort"

**There is NO "skip to step X" option. There is NO "skip phase" option.**

### Step 2: Bootstrap (product scope only)

**Scope: product** — Run the full bootstrap sequence.

**FIRST: Load Required Artifacts**

Before bootstrapping, read:
1. `devflow/specs/<name>-plan.md` — Project Structure section, Tech Stack section
2. `devflow/adrs/ADR-*.md` — All technology decisions (framework, DB, auth approach)
3. `devflow/prds/<name>.md` — Constraints section (for any infrastructure requirements)

**Then scaffold matching the plan exactly:**

1. `/init:project` — Scaffold project (structure MUST match plan's Project Structure)
2. `/init:database` — SQLAlchemy + Alembic setup (per plan's Tech Stack)
3. `/init:auth` — JWT auth (per auth ADR)
4. `/init:ai` (if plan includes AI layer)
5. `/init:deploy` — CI/CD scaffold (per plan's Infrastructure section)

**Bootstrap Checklist:**
- [ ] Directory structure matches plan's Project Structure
- [ ] Tech stack matches plan (FastAPI, PostgreSQL, etc.)
- [ ] Auth approach matches ADR
- [ ] Environment variables match plan's config requirements

**MANDATORY GATE: Bootstrap (BLOCKING)**

```bash
# Verify project starts
cd <project> && python -m pytest --co -q  # Test discovery
python -c "from app.main import app; print('OK')"  # Server check
alembic upgrade head  # DB migration
```

**Gate Evaluation:**
- If ALL checks pass: Display "Bootstrap Gate: ✅ PASSED" → Proceed to Step 3
- If ANY check fails: Display "Bootstrap Gate: ❌ BLOCKED" → STOP
  - Present ONLY: "Fix and retry" or "Abort execution"
  - **NO skip option exists**

### Step 3: Phase Execution Loop — THE CORE

**For EACH phase, execute ALL steps in sequence. No skipping.**

#### Step 3.1: Phase Start

**Load all artifacts needed for this phase:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🏗️  PHASE {N}: {Feature Name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Artifacts for this phase:
  PRD:     devflow/prds/<name>.md (problem context)
  Spec:    devflow/specs/<name>.md (US-xxx for this phase)
  Plan:    devflow/specs/<name>-plan.md (architecture)
  Tasks:   devflow/epics/<name>/0XX.md - 0YY.md
  ADRs:    devflow/adrs/ADR-*.md (decisions to follow)
  Design:  devflow/design/*.md (UI specs, if applicable)

User Stories in this phase:
  - US-00X: [title] ([N] acceptance criteria)
  - US-00Y: [title] ([N] acceptance criteria)

Full Stack Components (from Plan):
  DB:  [tables/models from plan's data model]
  API: [endpoints from plan's API design]
  UI:  [pages/components from design specs]

Functional Requirements:
  - FR-001: [title] (traces to US-00X)
  - FR-002: [title] (traces to US-00Y)

Starting Phase {N}...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### Step 3.2: Build Database Layer

**FIRST: Load Required Artifacts**

Before writing any DB code, read:
1. `devflow/specs/<name>-plan.md` — Data Model section (entities, relationships, indexes)
2. `devflow/specs/<name>.md` — Key Entities table
3. `devflow/adrs/ADR-*-database*.md` — Database-related ADRs
4. `devflow/epics/<name>/*.md` — Task files for this phase (DB tasks)

**Then create DB components matching the plan:**
- SQLAlchemy models (matching plan's data model exactly)
- Alembic migrations (tables, indexes as specified)
- Apply migrations
- Seed data (if needed)

**DB Layer Checklist:**
- [ ] All entities from plan's data model created
- [ ] Relationships match plan (1:N, N:M, etc.)
- [ ] Indexes created as specified in plan
- [ ] Field types match spec's entity definitions
- [ ] Follows ADR database decisions

**MANDATORY: DB Layer Tests**
```bash
pytest tests/unit/test_models*.py -v --tb=short
pytest tests/integration/test_db*.py -v --tb=short
```

If tests fail: STOP. Fix. Re-run. DO NOT PROCEED.

**🚦 CONFIRMATION REQUIRED:** Present DB layer summary (models created, migrations applied, test results), then ask via AskUserQuestion:
- "Yes, DB layer looks good — proceed to Step 3.3: API Layer" (Recommended)
- "No, there are issues — let me review first"
- "Stop execution here"

**Do NOT proceed to API Layer without explicit user approval.**

#### Step 3.3: Build API Layer

**FIRST: Load Required Artifacts**

Before writing any API code, read:
1. `devflow/specs/<name>-plan.md` — API Design section (endpoints, auth, versioning)
2. `devflow/specs/<name>.md` — Functional Requirements (FR-xxx) for this phase
3. `devflow/adrs/ADR-*-api*.md` or `ADR-*-auth*.md` — API/Auth ADRs
4. `devflow/epics/<name>/*.md` — Task files for this phase (API tasks)

**Then create API components matching the plan:**
- Pydantic schemas (request/response matching plan's API design)
- Service layer (business logic implementing FR-xxx requirements)
- API endpoints (paths, methods, auth as specified in plan)
- Authentication/authorization (following auth ADR)

**API Layer Checklist:**
- [ ] All endpoints from plan created
- [ ] Request/response schemas match plan
- [ ] Each endpoint traces to FR-xxx requirement
- [ ] Auth requirements implemented per ADR
- [ ] API versioning follows plan (e.g., /api/v1/)
- [ ] Error responses match plan's error taxonomy

**MANDATORY: API Layer Tests**
```bash
pytest tests/unit/test_services*.py -v --tb=short
pytest tests/unit/test_schemas*.py -v --tb=short
pytest tests/integration/test_api*.py -v --tb=short
```

If tests fail: STOP. Fix. Re-run. DO NOT PROCEED.

**🚦 CONFIRMATION REQUIRED:** Present API layer summary (endpoints created, schemas, test results), then ask via AskUserQuestion:
- "Yes, API layer looks good — proceed to Step 3.4: UI Layer" (Recommended)
- "No, there are issues — let me review first"
- "Stop execution here"

**Do NOT proceed to UI Layer without explicit user approval.**

#### Step 3.4: Build UI Layer (if applicable)

**FIRST: Load Design Artifacts**

Before writing any UI code, read and apply:
1. `devflow/design/tokens.md` — Use defined colors, typography, spacing
2. `devflow/design/shell.md` — Follow app shell layout structure
3. `devflow/design/sections/<feature>.md` — Follow section-specific UI specs

**Then create UI components following the design specs:**
- Angular/React components (matching design tokens)
- Pages (following shell layout)
- State management
- API integration

**Component Checklist:**
- [ ] Uses design tokens (not hardcoded colors/fonts)
- [ ] Follows shell layout structure
- [ ] Matches section spec wireframes
- [ ] Responsive breakpoints per design
- [ ] Accessibility (ARIA labels, keyboard nav)

**MANDATORY: UI Tests**
```bash
npm test -- --coverage
# or
ng test --code-coverage
```

If tests fail: STOP. Fix. Re-run. DO NOT PROCEED.

**🚦 CONFIRMATION REQUIRED:** Present UI layer summary (components created, pages, test results), then ask via AskUserQuestion:
- "Yes, UI layer looks good — proceed to Step 3.5: E2E Tests" (Recommended)
- "No, there are issues — let me review first"
- "Stop execution here"

**Do NOT proceed to E2E Tests without explicit user approval.**

#### Step 3.5: E2E Tests — USER STORY VALIDATION (MANDATORY)

**Unit and integration tests already passed in Steps 3.2-3.4 (fail-fast).**
**Now run E2E tests to validate complete user flows.**

**FIRST: Load Required Artifacts**
1. `devflow/specs/<name>.md` — User Stories (US-xxx with Given/When/Then)
2. `devflow/epics/<name>/epic.md` — Which US-xxx belong to this phase
3. `devflow/prds/<name>.md` — Original user needs (for context)

**For EACH user story in this phase, create E2E tests for ALL acceptance criteria.**

```bash
pytest tests/e2e/ -v --tb=short -k "phase_{N}"
```

**E2E Test Requirements:**
- Each US-xxx must have at least one test per acceptance criterion
- Tests must validate the Given/When/Then exactly as written in spec
- Happy path AND error paths must be tested
- Test complete user flows from UI to database

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧪 E2E TESTS: Phase {N}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

US-001: User can login
  ✓ test_login_success (Given valid creds → dashboard)
  ✓ test_login_invalid (Given invalid creds → error)
  ✓ test_login_locked (Given locked account → locked message)

US-002: User can logout
  ✓ test_logout_clears_session
  ✓ test_logout_redirects_to_login

Coverage: 5/5 acceptance criteria have tests
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Run E2E tests:**
```bash
pytest tests/e2e/test_phase_{N}*.py -v --tb=short
```

If any test fails: STOP. Fix. Re-run. DO NOT PROCEED.

---

**PHASE TEST SUMMARY (Fail-Fast Results)**

Display cumulative results from all layer steps:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧪 PHASE {N} TEST SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

UNIT + INTEGRATION (passed in Steps 3.2-3.4):
  DB Layer (Step 3.2):
    - Model tests: {N}/{N} passed ✓
    - Migration tests: {N}/{N} passed ✓
  API Layer (Step 3.3):
    - Service tests: {N}/{N} passed ✓
    - Endpoint tests: {N}/{N} passed ✓
  UI Layer (Step 3.4):
    - Component tests: {N}/{N} passed ✓
  Coverage: {X}%

E2E TESTS (passed in Step 3.5):
  US-001: {N}/{N} acceptance criteria ✓
  US-002: {N}/{N} acceptance criteria ✓
  Total:  {N}/{N} user stories verified ✓

Phase {N} Tests: ALL PASSED ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**🚦 CONFIRMATION REQUIRED:** Present E2E test summary (user stories covered, acceptance criteria verified), then ask via AskUserQuestion:
- "Yes, E2E tests look good — proceed to Step 3.6: Regression Suite" (Recommended)
- "No, there are issues — let me review first"
- "Stop execution here"

**Do NOT proceed to Regression Suite without explicit user approval.**

#### Step 3.6: Regression Suite — MANDATORY

**Run ALL previous phase tests to ensure no regressions.**

```bash
pytest tests/ -v --tb=short --ignore=tests/e2e/test_phase_{N+1}*
```

Expected output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 REGRESSION SUITE: Phase {N}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase 1 tests: 23/23 passed ✓
Phase 2 tests: 31/31 passed ✓
Current phase: 45/45 passed ✓

Total: 99/99 passed (0 regressions)
Coverage: 87%
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If ANY previous test fails:**
- This is a REGRESSION
- STOP immediately
- Identify which change broke the test
- Fix the regression
- Re-run full suite
- DO NOT PROCEED until 100% previous tests pass

**🚦 CONFIRMATION REQUIRED:** Present regression suite results (all phases, total tests), then ask via AskUserQuestion:
- "Yes, no regressions — proceed to Step 3.7: ADR Compliance" (Recommended)
- "No, there are issues — let me review first"
- "Stop execution here"

**Do NOT proceed to ADR Compliance without explicit user approval.**

#### Step 3.7: ADR Compliance Check — MANDATORY

**Load and verify against ALL ADRs:**

Read all files in `devflow/adrs/ADR-*.md` and verify code follows each decision.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 ADR COMPLIANCE CHECK: Phase {N}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ADR-001: Use PostgreSQL
  ✓ All models use SQLAlchemy with PostgreSQL dialect
  ✓ No SQLite or MySQL references found

ADR-002: Use FastAPI
  ✓ All endpoints use FastAPI router
  ✓ Dependency injection used correctly

ADR-003: JWT Authentication
  ✓ JWT tokens used for auth
  ✓ Refresh token pattern implemented

ADR-004: Feature-based folder structure
  ✓ New code organized by feature
  ⚠ VIOLATION: utils/helpers.py should be in feature folder

Status: 1 VIOLATION found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If ADR violation found:** STOP. Fix. Re-check. DO NOT PROCEED.

**🚦 CONFIRMATION REQUIRED:** Present ADR compliance results (each ADR status), then ask via AskUserQuestion:
- "Yes, ADR compliance verified — proceed to Step 3.8: Local Verification" (Recommended)
- "No, there are issues — let me review first"
- "Stop execution here"

**Do NOT proceed to Local Verification without explicit user approval.**

#### Step 3.8: Local Verification — MANDATORY

Deploy locally and have user verify:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 LOCAL VERIFICATION: Phase {N}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Local servers running:
  Backend:  http://localhost:8000
  Frontend: http://localhost:3000
  API Docs: http://localhost:8000/docs

Please verify manually:
  1. [ ] Navigate to {feature page}
  2. [ ] Perform {user action from US-001}
  3. [ ] Verify {expected outcome}
  4. [ ] Perform {user action from US-002}
  5. [ ] Verify {expected outcome}

Does {Feature Name} work correctly?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Use AskUserQuestion:
- Yes, feature works correctly → Proceed to next phase
- No, issues found → STOP. Fix. Re-verify.

#### Step 3.9: Phase Gate — MANDATORY BLOCKING CHECKPOINT

**THIS GATE IS NON-NEGOTIABLE. NO SKIP OPTION EXISTS.**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚦 PHASE GATE: Phase {N} - {Feature Name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Checklist (ALL must be ✓ to proceed):
  [ ] DB Layer: {N} models, migrations applied
  [ ] API Layer: {N} endpoints, all tests pass
  [ ] UI Layer: {N} components, all tests pass
  [ ] Unit Tests: {N}/{N} passed
  [ ] Integration Tests: {N}/{N} passed
  [ ] E2E Tests: {N}/{N} passed
  [ ] Regression Suite: {N}/{N} passed (0 regressions)
  [ ] ADR Compliance: No violations
  [ ] User Verification: Confirmed
  [ ] Coverage: {X}% (>= 80% required)

User Stories Completed:
  [ ] US-001: {title} - All acceptance criteria met
  [ ] US-002: {title} - All acceptance criteria met

Phase Status: [EVALUATING...]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Gate Evaluation Rules:**

1. **If ALL checklist items are ✓:**
   - Display "Phase Status: ✅ PASSED"
   - Automatically proceed to Phase {N+1}

2. **If ANY checklist item is ✗:**
   - Display "Phase Status: ❌ BLOCKED"
   - List ALL failing items with details
   - Present ONLY these options via AskUserQuestion:
     - "Fix issues and re-run gate" (Recommended)
     - "Abort execution entirely"
   - **There is NO skip option. There is NO proceed option.**
   - Execution CANNOT continue until all items pass

3. **Re-running the gate:**
   - After fixes, re-execute the failed steps (3.2-3.8 as needed)
   - Then re-evaluate this gate
   - Repeat until all items pass or user aborts

### Step 4: Test Summary (After All Phases)

After all phases complete, run final test suite:

```bash
pytest tests/ -v --cov=app --cov-report=term-missing --cov-report=html
```

Present comprehensive test report:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 FINAL TEST REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Test Summary:
  Unit Tests:        {N} passed, {N} failed
  Integration Tests: {N} passed, {N} failed
  E2E Tests:         {N} passed, {N} failed
  Total:             {N} passed, {N} failed

Coverage:
  Overall:           {X}%
  app/models:        {X}%
  app/services:      {X}%
  app/api:           {X}%

User Story Coverage:
  US-001: 5/5 acceptance criteria tested ✓
  US-002: 3/3 acceptance criteria tested ✓
  US-003: 4/4 acceptance criteria tested ✓
  Total: {N}/{N} (100%)

Coverage Report: htmlcov/index.html
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**🚦 CONFIRMATION REQUIRED:** Present final test report, then ask via AskUserQuestion:
- "Yes, test summary looks good — proceed to Step 5: Quality Checks" (Recommended)
- "No, there are issues — let me review first"
- "Stop execution here"

**Do NOT proceed to Quality Checks without explicit user approval.**

### Step 5: Quality Checks

Run comprehensive quality checks:

```bash
# Linting
ruff check app/ tests/
ruff format app/ tests/ --check

# Type checking
mypy app/ --strict

# Security
bandit -r app/
pip-audit
```

**🚦 CONFIRMATION REQUIRED:** Present quality check results (linting, type checking, security), then ask via AskUserQuestion:
- "Yes, quality checks pass — proceed to Step 6: Documentation" (Recommended)
- "No, there are issues — let me review first"
- "Stop execution here"

**Do NOT proceed to Documentation without explicit user approval.**

### Step 6: Documentation (Mintlify)

**Generate beginner-friendly documentation** using Mintlify.

Ask: "Generate documentation?"

- **If yes:**

  1. **Initialize Mintlify** (if not exists):
     ```bash
     npx mintlify init
     ```

  2. **Generate docs structure** based on scope:

     **Scope: product**
     ```
     docs/
     ├── mint.json              # Mintlify config
     ├── introduction.mdx       # What is this product?
     ├── quickstart.mdx         # Get running in 5 minutes
     ├── installation.mdx       # Step-by-step setup
     ├── concepts/
     │   ├── overview.mdx       # How it works (with diagrams)
     │   └── architecture.mdx   # System architecture
     ├── guides/
     │   ├── getting-started.mdx
     │   └── <feature>.mdx      # One guide per feature
     ├── api-reference/
     │   └── endpoints.mdx      # Auto-generated from OpenAPI
     ├── architecture/
     │   ├── decisions.mdx      # ADR summary page
     │   └── adr-XXX.mdx        # Individual ADR pages
     └── examples/
         └── <use-case>.mdx     # Real-world examples
     ```

     **Scope: feature**
     - Update existing docs with new feature guide
     - Add API endpoints if new
     - Update quickstart if workflow changed

     **Scope: library**
     ```
     docs/
     ├── mint.json
     ├── introduction.mdx       # What problem does this solve?
     ├── installation.mdx       # pip install, requirements
     ├── quickstart.mdx         # Hello world example
     ├── api-reference/
     │   └── <module>.mdx       # Every public function
     ├── guides/
     │   └── <pattern>.mdx      # Common usage patterns
     └── examples/
         └── <example>.mdx      # Copy-paste examples
     ```

  3. **Writing style for beginners**:
     - Assume reader knows basic programming but not this codebase
     - Start every page with "What you'll learn"
     - Include copy-paste code examples
     - Add "Common mistakes" sections
     - Use diagrams for complex flows
     - Link related concepts

  4. **Include ADRs in documentation**:
     Generate `docs/architecture/decisions.mdx`:
     ```mdx
     ---
     title: Architecture Decisions
     description: Key architectural decisions and their rationale
     ---

     # Architecture Decisions

     This project follows these architectural decisions (ADRs):

     | Decision | Status | Summary |
     |----------|--------|---------|
     | [ADR-001](/architecture/adr-001) | Accepted | PostgreSQL for data |
     | [ADR-002](/architecture/adr-002) | Accepted | FastAPI backend |
     | ...

     ## Why ADRs Matter

     ADRs help you understand:
     - **Why** we chose certain technologies
     - **What alternatives** were considered
     - **Trade-offs** we accepted

     New to the project? Read the ADRs to understand our architecture.
     ```

     Create individual ADR pages in `docs/architecture/adr-XXX.mdx` from `devflow/adrs/`.

  5. **Local preview**:
     ```bash
     npx mintlify dev
     ```
     Print: `📚 Docs preview: http://localhost:3333`

  6. Ask: "Docs look good?"

- **If skip:** Continue. Docs can be added later.

**🚦 CONFIRMATION REQUIRED:** Present documentation summary (pages created, structure), then ask via AskUserQuestion:
- "Yes, documentation looks good — proceed to Step 7: Review" (Recommended)
- "No, there are issues — let me review first"
- "Stop execution here"

**Do NOT proceed to Review without explicit user approval.**

### Step 7: Review

Run `/review:pr-checklist` with mandatory ADR compliance check.

**🚦 CONFIRMATION REQUIRED:** Present PR checklist results, then ask via AskUserQuestion:
- "Yes, review complete — proceed to Step 8: Ship" (Recommended)
- "No, there are issues — let me review first"
- "Stop execution here"

**Do NOT proceed to Ship without explicit user approval.**

### Step 8: Ship

Prepare for deployment with final validation:

1. `/deploy:setup` — CI/CD pipeline
2. `/deploy:docker` — Dockerfile + compose
3. `/deploy:env-check` — Validate env vars
4. `/review:release` — Pre-release validation

**🚦 CONFIRMATION REQUIRED:** Present deployment setup results (CI/CD, Docker, env vars), then ask via AskUserQuestion:
- "Yes, deployment ready — proceed to Step 9: Final Summary" (Recommended)
- "No, there are issues — let me review first"
- "Stop execution here"

**Do NOT proceed to Final Summary without explicit user approval.**

### Step 9: Final Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ EXECUTION COMPLETE: <name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Scope: <product|feature|library>

Results:
  Phases Completed:     {N}/{N}
  Tasks Completed:      {N}/{N}

Test Results:
  Unit Tests:           {N} passed
  Integration Tests:    {N} passed
  E2E Tests:            {N} passed
  Regression Tests:     {N} passed
  Coverage:             {X}%

User Story Verification:
  US-001: ✓ All acceptance criteria met
  US-002: ✓ All acceptance criteria met
  ...
  Total: {N}/{N} user stories verified

ADR Compliance: ✓ All {N} ADRs followed

Artifacts:
  Code:          <project-dir>/
  Tests:         <project-dir>/tests/
  Coverage:      <project-dir>/htmlcov/
  Docs:          <project-dir>/docs/
  ADRs:          devflow/adrs/

Ready for production deployment.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Error Recovery

- **Test failures:** STOP. Fix. Re-run ALL phase tests. Never skip.
- **Regression:** Identify which change broke the test. Fix. Re-run full suite.
- **ADR violation:** Fix code to comply. Re-check. Never override.
- **Phase gate failure:** Cannot proceed. Fix all items. Re-run gate.
- **Interrupted execution:** Re-run `/devflow:execute <name>`. It will resume from last checkpoint.
