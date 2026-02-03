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

**The command asks before each major step**, so you can also:
- Skip steps you've already done manually
- Jump to a specific phase

**To check current status:** Run `/pm:status` to see what's complete vs pending.

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

## Preflight Checklist

1. Verify `<name>` argument is provided. If missing, ask the user.
2. Verify brainstorming artifacts exist:
   - `devflow/prds/<name>.md` — PRD must exist
   - `devflow/specs/<name>.md` — Spec must exist
   - `devflow/specs/<name>-plan.md` — Plan must exist
   - `devflow/epics/<name>/epic.md` — Epic must exist
   - If any missing: print which are missing and suggest running `/devflow:kickstart <name>` first. Stop.
3. Read scope from PRD frontmatter (`scope: product|feature|library`).
4. Verify `devflow/devflow.config` exists.
5. Check GitHub CLI (`gh`) is authenticated: `gh auth status`.

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

## Phased Development (Large Applications)

**For large applications**, break into logical phases. Complete and test each phase before starting the next.

### Phase Detection

At the start of execution, analyze the epic to determine if phased development is needed:

```
Task count > 15 OR estimated complexity = high → Use phased development
```

Ask user: "This is a large application. Break into phases?"
- **Yes:** Continue with phased approach
- **No:** Build all at once (not recommended for large apps)

### Phase Breakdown (Feature-Based)

**Group by FEATURES, not layers.** Each phase = complete feature with full stack (DB + API + UI). This enables true end-to-end testing.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Development Phases for: <name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase 1: Setup & Auth Feature (5 tasks)
  Full stack:
  - DB: users table, sessions table
  - API: /auth/login, /auth/register, /auth/logout
  - UI: Login page, Register page, Auth state
  - Tests: Auth E2E flow works completely

Phase 2: Dashboard Feature (6 tasks)
  Full stack:
  - DB: dashboard_widgets table
  - API: /dashboard, /widgets CRUD
  - UI: Dashboard page, Widget components
  - Tests: User can view/customize dashboard

Phase 3: User Management Feature (5 tasks)
  Full stack:
  - DB: roles, permissions tables
  - API: /users CRUD, /roles
  - UI: User list, User detail, Role assignment
  - Tests: Admin can manage users completely

Phase 4: Reports Feature (6 tasks)
  Full stack:
  - DB: reports table, report_templates
  - API: /reports CRUD, /reports/generate
  - UI: Report builder, Report viewer
  - Tests: User can create and view reports

Phase 5: Settings & Polish (4 tasks)
  Full stack:
  - DB: settings table
  - API: /settings
  - UI: Settings page, Profile page
  - Tests: Full app regression + E2E

Total: 26 tasks across 5 feature phases
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Why feature-based:**
- Each phase is independently testable end-to-end
- User can see and verify complete features
- Aligns with user stories and acceptance criteria
- No "API works but no UI to test it" situations

### Phase Execution Loop

For each phase:

```
┌─────────────────────────────────────────────┐
│  PHASE X: <phase_name>                      │
├─────────────────────────────────────────────┤
│  1. Build all tasks in phase                │
│  2. Run unit tests for phase                │
│  3. Run integration tests for phase         │
│  4. Deploy locally & verify                 │
│  5. Run full regression suite               │
│  6. User sign-off: "Phase X complete?"      │
│  7. ✓ CHECKPOINT: Phase locked              │
│  8. Proceed to next phase                   │
└─────────────────────────────────────────────┘
```

### Phase Gate (Mandatory)

**Before moving to next phase**, ALL must pass:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚦 Phase Gate: Phase 2 - Core Features
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Checklist:
  ✓ All 8 tasks completed
  ✓ Unit tests: 45/45 passed
  ✓ Integration tests: 12/12 passed
  ✓ Full regression: 67/67 passed (includes Phase 1)
  ✓ Local deployment verified
  ✓ No critical bugs open
  ✓ Code review passed

Phase Status: ✅ PASSED

Ready to proceed to Phase 3: Secondary Features?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If any check fails:** Stop. Fix issues. Re-run gate. Do NOT proceed with failures.

### Phase Rollback

If a phase introduces critical bugs:

1. Identify which phase introduced the issue
2. Roll back to last stable phase checkpoint
3. Fix the issue
4. Re-run phase from beginning
5. Pass gate before continuing

## Elite Developer Workflow

**Build → Test → Deploy Locally → Verify → Repeat**

Like an elite developer, we test and verify each feature before moving on:

1. Build a feature/task
2. **Run tests immediately** (unit + integration for that feature)
3. Deploy locally (hot reload)
4. Manually verify it works
5. Ask user: "Feature X looks good? Continue to next?"
6. Repeat for next feature

### Continuous Testing Strategy

**Tests run at multiple points:**

| When | What Tests | Why |
|------|-----------|-----|
| After each task | Unit tests for changed files | Catch bugs immediately |
| After each feature | Integration tests for feature | Verify feature works end-to-end |
| After build phase | Full test suite | Catch cross-feature regressions |
| Before review | Full suite + coverage | Ensure nothing missed |
| Before ship | Full suite + E2E + perf | Production readiness |

**Test commands used:**
```bash
# After task (fast, ~10s)
pytest tests/ -k "test_<module>" --tb=short

# After feature (~30s)
pytest tests/ -k "<feature>" --tb=short

# Full suite (~2-5min)
pytest tests/ --cov=app --cov-report=term-missing
```

This catches issues early and gives the user visibility into progress.

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

## Instructions

Execute the following steps. Use TaskCreate to track work, spawn Task agents for parallel execution where possible. Ask before each major phase.

### Step 1: Pre-flight Summary

Print what will happen based on scope:

```
Execution Phase for: <name>
Scope: <product|feature|library>

Artifacts found:
  ✓ PRD:   devflow/prds/<name>.md
  ✓ Spec:  devflow/specs/<name>.md
  ✓ Plan:  devflow/specs/<name>-plan.md
  ✓ Epic:  devflow/epics/<name>/epic.md
  ✓ Tasks: <N> task files

Steps:
  1. Bootstrap     <run|skip based on scope>
  2. Local Deploy  <start servers for verification>
  3. Build         <worker list based on scope>
     → Verify each feature locally
  4. Test          <test types based on scope>
  5. Quality       <checks based on scope>
  6. Docs          <Mintlify documentation>
  7. Review        <review type based on scope>
  8. Ship          <local ready, prod plan>
```

Ask: "Proceed with full execution, or select specific steps?"
- **Full:** Run all steps sequentially
- **Select:** Let user pick which steps to run (checkboxes)

### Step 2: Bootstrap (product scope only)

**Scope: product** — Run the full bootstrap sequence:

Ask: "Bootstrap the project? This scaffolds the codebase from scratch."
- **If yes:**
  1. `/init:project` — Scaffold project (FastAPI + Angular/React + PostgreSQL)
  2. `/init:database` — SQLAlchemy + Alembic setup
  3. `/init:auth` — JWT auth for FastAPI
  4. Read plan to check if AI layer is needed:
     - If yes: `/init:ai` — AI/LLM layer setup
  5. `/init:deploy` — CI/CD scaffold
  6. Verify: project builds, database migrates, server starts
- **If skip:** Continue.

**Scope: feature** — Skip. Print: `Feature scope — project already exists. Skipping bootstrap.`

**Scope: library** — Skip. Print: `Library scope — project already exists. Skipping bootstrap.`
If the library doesn't have a package structure yet, suggest: "Run `/init:project` manually if you need scaffolding."

#### Step 2a: Gate — Bootstrap (product scope only)

Run `/devflow:gate bootstrap <name>`.

- **BLOCK:** Fix the issues (server won't start, DB won't connect, structure mismatch), and re-run the gate.
- **CONCERN:** Present concerns to the user. They choose: proceed or fix.
- **PASS:** Continue.

### Step 2b: Local Deploy (after bootstrap)

**Start local development environment** so user can verify as we build:

```bash
# Backend (FastAPI)
cd backend && uvicorn main:app --reload --port 8000

# Frontend (Angular/React)
cd frontend && npm run dev

# Database
docker-compose up -d postgres
```

Print:
```
🚀 Local Environment Running

Backend:  http://localhost:8000
Frontend: http://localhost:3000 (or 4200 for Angular)
API Docs: http://localhost:8000/docs

Tip: Keep these running. We'll verify features as we build.
```

Ask: "Local servers running? Ready to build?"

### Step 3: Build

Ask: "Launch parallel agents to build?"

- **If yes:**
  1. Run `/pm:epic-start <name>` — launches parallel-worker which coordinates:

     **Scope: product**
     - `db-task-worker` — models, migrations, seeds
     - `api-task-worker` — endpoints, services, schemas
     - `ui-task-worker` — components, pages, layouts
     - `ai-task-worker` — prompts, providers, evaluation (if AI layer in plan)

     **Scope: feature**
     - Read plan to determine affected layers
     - Launch only the relevant workers (e.g., api + ui, or db + api)

     **Scope: library**
     - `api-task-worker` — core module implementations
     - `test-runner` — test suite alongside implementation

  2. **Per-task tests**: After each task completes, immediately run tests:
     ```bash
     pytest tests/ -k "test_<module>" --tb=short -q
     ```
     - If tests fail: fix immediately before moving on
     - If tests pass: continue
  3. **Per-task gate**: Run `/devflow:gate task <name>` for that task.
     - If BLOCK: pause the work stream for that task, report to user.
     - If CONCERN: log and continue.
     - If PASS: continue to next task.
  4. **Per-feature tests**: After each feature (group of tasks), run integration tests:
     ```bash
     pytest tests/ -k "<feature>" --tb=short
     ```
  5. **Periodic full suite**: Every 3-5 features, run full test suite to catch regressions
  6. Monitor progress: `/pm:status` after agents complete
  7. If any tasks remain open: `/pm:blocked` to identify issues

- **If skip:** Continue. User can run `/pm:epic-start <name>` later.

#### Step 3b: Test After Each Task

**Immediately after each task completes**, run its tests:

```bash
# Run tests for the specific module/feature
pytest tests/ -k "test_<module>" --tb=short -q
```

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧪 Task Tests: <task_name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Running: pytest tests/ -k "test_users" --tb=short

✓ test_create_user PASSED
✓ test_get_user PASSED
✓ test_update_user PASSED
✓ test_delete_user PASSED

Result: 4/4 passed (0.8s)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

- **All pass:** Continue to next task
- **Failures:** Stop, fix, re-run tests, then continue

#### Step 3c: Feature Verification Loop

**After each logical feature/component is complete**, run feature tests and pause for user verification:

```bash
# Run integration tests for the feature
pytest tests/ -k "<feature>" --tb=short
```

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Feature Checkpoint: <feature_name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Tasks completed:
  ✓ <task 1>
  ✓ <task 2>
  ✓ <task 3>

Tests run:
  ✓ Unit tests: 12/12 passed
  ✓ Integration tests: 5/5 passed
  ✓ Total: 17/17 passed (2.3s)

How to verify manually:
  1. Open http://localhost:3000/<route>
  2. Try: <specific action>
  3. Expected: <expected result>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Ask: "Tests pass and feature works as expected?"
- **Yes:** Continue to next feature
- **No:** Ask what's wrong, fix it, re-run tests, re-verify
- **Skip verification:** Continue without manual check (tests still required)

This ensures:
- Tests run continuously, not just at the end
- Bugs caught immediately after they're introduced
- User sees progress incrementally
- Confidence in what's being built

#### Step 3d: Periodic Full Suite

**Every 3-5 features**, run the full test suite to catch regressions:

```bash
pytest tests/ --tb=short -q
```

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 Regression Check (after 5 features)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Running full test suite...

✓ 47/47 tests passed (12.3s)
✓ No regressions detected
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### Step 3a: Gate — Build (aggregate)

After all tasks complete, run `/devflow:gate build <name>`.

- **BLOCK:** Integration issues between tasks, missing tasks, or test failures. Fix and re-run.
- **CONCERN:** Present to user. They choose: proceed or fix.
- **PASS:** Continue.

### Step 4: Test

Ask: "Run tests?"

- **If yes:**
  1. `/testing:prime` — Configure test framework (if not already configured)
  2. `/testing:run` — Execute test suite

     **Scope: product**
     - Unit tests (all layers)
     - Integration tests (API + DB)
     - `/testing:e2e-setup` + E2E tests (if UI exists)
     - `/testing:ai-eval` (if AI layer exists)
     - `/testing:perf` — Performance benchmarks

     **Scope: feature**
     - Unit tests (affected modules)
     - Integration tests (affected APIs)
     - E2E tests (affected user flows, if UI)

     **Scope: library**
     - Unit tests (all public API functions)
     - Integration tests (with real dependencies if applicable)
     - Property-based tests (for core logic)

  3. `/testing:coverage` — Coverage report + gap analysis
  4. If failures: present failures, ask user whether to fix and re-run or continue

- **If skip:** Continue.

#### Step 4a: Gate — Test

Run `/devflow:gate test <name>`.

- **BLOCK:** Coverage below threshold, test failures, or flaky tests. Fix and re-run.
- **CONCERN:** Present to user.
- **PASS:** Continue.

### Step 5: Quality

Ask: "Run quality checks?"

- **If yes:**
  1. `/quality:lint-setup` — Configure linting (if not already configured)
     - **Scope: product/feature** — ESLint + Prettier (frontend) + Ruff (backend)
     - **Scope: library** — Ruff + mypy (strict type checking)
  2. `/quality:security-check` — OWASP security audit
  3. If issues found: present issues, ask user whether to fix or continue

- **If skip:** Continue.

#### Step 5a: Gate — Quality

Run `/devflow:gate quality <name>`.

- **BLOCK:** Lint errors, high/critical security findings, or secrets in code. Fix and re-run.
- **CONCERN:** Present to user.
- **PASS:** Continue.

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

  4. **Local preview**:
     ```bash
     npx mintlify dev
     ```
     Print: `📚 Docs preview: http://localhost:3333`

  5. Ask: "Docs look good?"

- **If skip:** Continue. Docs can be added later.

### Step 7: Review

Ask: "Run review checklist?"

- **If yes:**
  1. `/review:pr-checklist` — Generate domain-aware PR review checklist

     **Scope: product**
     - Architecture compliance check
     - Data model review
     - API contract review
     - UI/UX review
     - Security review
     - Performance review

     **Scope: feature**
     - Feature-scoped review (affected layers only)
     - Backward compatibility check
     - Migration safety check

     **Scope: library**
     - API surface review (breaking changes, naming consistency)
     - Documentation completeness
     - Type coverage
     - Changelog entry

  2. Present checklist to user for sign-off
  3. If issues: fix and re-review

- **If skip:** Continue.

#### Step 7a: Gate — Review

Run `/devflow:gate review <name>`.

- **BLOCK:** Unaddressed checklist items, unresolved review comments. Fix and re-run.
- **CONCERN:** Present to user.
- **PASS:** Continue.

### Step 8: Ship

Ask: "Ready to ship?"

- **If yes:**

  **Scope: product**
  1. `/deploy:setup` — Generate CI/CD pipeline (GitHub Actions)
  2. `/deploy:docker` — Dockerfile + docker-compose
  3. `/deploy:env-check` — Validate environment variables
  4. `/review:release` — Pre-release validation
  5. Print deployment instructions

  **Scope: feature**
  1. `/deploy:env-check` — Validate any new env vars
  2. `/review:release` — Pre-release validation (feature-scoped)
  3. Suggest: merge PR, deploy via existing pipeline

  **Scope: library**
  1. Verify package builds: `python -m build` or equivalent
  2. `/deploy:env-check` — Validate publish credentials
  3. `/review:release` — Pre-release validation
  4. Print publish instructions:
     ```
     # PyPI publish
     python -m twine upload dist/*

     # Or private index
     python -m twine upload --repository private dist/*
     ```

- **If skip:** Continue.

### Step 9: Summary

Print final summary including gate results and traceability:

```
Execution Phase Complete
  Scope: <product|feature|library>
  Name:  <name>

Results:
  Bootstrap:    <completed|skipped>
  Local Deploy: <running at localhost:8000/3000|skipped>
  Build:        <X/Y tasks completed, Y features verified>
  Test:         <passed|X failures|skipped>
  Quality:      <clean|X issues|skipped>
  Docs:         <generated|updated|skipped>
  Review:       <approved|X items open|skipped>
  Ship:         <local ready, prod plan generated|skipped>

Gate Results:
  - gate:bootstrap — [PASS|CONCERN|BLOCK|skipped]
  - gate:task      — [X/Y tasks passed]
  - gate:build     — [PASS|CONCERN|BLOCK]
  - gate:test      — [PASS|CONCERN|BLOCK|skipped]
  - gate:quality   — [PASS|CONCERN|BLOCK|skipped]
  - gate:review    — [PASS|CONCERN|BLOCK|skipped]

Traceability Summary:
  - FR → Task coverage: [X]%
  - Tasks with traces_to: [X]/[Y]
  - Acceptance criteria met: [X]/[Y]

Open items:
  - [list any remaining tasks, failures, or issues]

Useful commands:
  /pm:status               # Check project status
  /pm:blocked              # See blocked tasks
  /testing:run             # Re-run tests
  /review:incident         # File an incident report
```

## Error Recovery

- If any step fails, print the error and ask the user whether to retry, skip, or abort.
- Build failures: check `/pm:blocked`, show agent logs, offer to reassign tasks.
- Test failures: show failure details, offer to fix and re-run.
- The user can re-run `/devflow:execute <name>` and select only the steps they need.
- Individual commands always work standalone — execute is an orchestrator, not a replacement.
