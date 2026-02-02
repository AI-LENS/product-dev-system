---
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Task, Agent, AskUserQuestion
---

# Execute

Run the Execution Phase — agents consume brainstorming artifacts and build, test, review, and ship. This command is optional; you can run any individual command from Phase B independently.

## Usage

```
/devflow:execute <name>
```

Where `<name>` matches the name used in `/devflow:kickstart <name>`.

## Required Rules

- `devflow/rules/datetime.md`
- `devflow/rules/frontmatter-operations.md`
- `devflow/rules/path-standards.md`
- `devflow/rules/github-operations.md`
- `devflow/rules/agent-coordination.md`
- `devflow/rules/worktree-operations.md`
- `devflow/rules/branch-operations.md`
- `devflow/rules/test-execution.md`

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
| Build | All workers (db, api, ui, ai) | Affected workers only | api-task-worker + test-runner |
| Test | Full suite (unit + integration + E2E + AI eval) | Affected tests | Unit + integration + property-based |
| Quality | Lint + security + perf budgets | Lint + security | Lint + security + type checking |
| Review | PR checklist per epic | PR checklist | PR checklist + API review |
| Ship | Full deploy (CI/CD + Docker + env + monitoring) | Feature deploy (branch merge) | Publish (package build + publish + docs) |

## Instructions

Execute the following steps sequentially. Each step asks the user before proceeding. The user can skip any step.

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
  1. Bootstrap    <run|skip based on scope>
  2. Build        <worker list based on scope>
  3. Test         <test types based on scope>
  4. Quality      <checks based on scope>
  5. Review       <review type based on scope>
  6. Ship         <deploy type based on scope>
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

  2. Monitor progress: `/pm:status` after agents complete
  3. If any tasks remain open: `/pm:blocked` to identify issues

- **If skip:** Continue. User can run `/pm:epic-start <name>` later.

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

### Step 5: Quality

Ask: "Run quality checks?"

- **If yes:**
  1. `/quality:lint-setup` — Configure linting (if not already configured)
     - **Scope: product/feature** — ESLint + Prettier (frontend) + Ruff (backend)
     - **Scope: library** — Ruff + mypy (strict type checking)
  2. `/quality:security-check` — OWASP security audit
  3. If issues found: present issues, ask user whether to fix or continue

- **If skip:** Continue.

### Step 6: Review

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

### Step 7: Ship

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

### Step 8: Summary

Print final summary:

```
Execution Phase Complete
  Scope: <product|feature|library>
  Name:  <name>

Results:
  Bootstrap:  <completed|skipped>
  Build:      <X/Y tasks completed>
  Test:       <passed|X failures|skipped>
  Quality:    <clean|X issues|skipped>
  Review:     <approved|X items open|skipped>
  Ship:       <deployed|ready to deploy|skipped>

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
