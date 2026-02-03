---
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Task, TaskCreate, TaskUpdate, TaskList, AskUserQuestion
---

# Kickstart

Run the entire Brainstorming Phase sequentially. Adapts its pipeline based on scope — whether you're building a new product, adding a feature, or creating a backend library.

## Usage

```
/devflow:kickstart <name>
```

## Resume Behavior

**This command is resumable.** If interrupted (context compaction, error, etc.), just run it again with the same `<name>`. It will:

1. Detect existing artifacts and skip completed steps
2. Read scope from existing PRD frontmatter (won't ask again)
3. Continue from the first incomplete step

**What gets checked:**
- `devflow/prds/<name>.md` → PRD step
- `devflow/specs/<name>.md` → Spec step
- `devflow/specs/<name>-plan.md` → Plan step
- `devflow/epics/<name>/epic.md` → Decompose step

**To force redo a step:** Delete the artifact file and re-run kickstart.

## Required Rules

- `devflow/rules/datetime.md`
- `devflow/rules/frontmatter-operations.md`
- `devflow/rules/path-standards.md`
- `devflow/rules/github-operations.md`
- `devflow/rules/spec-standards.md`
- `devflow/rules/principles-standards.md`
- `devflow/rules/elite-dev-protocol.md`

## Preflight Checklist

1. Verify `<name>` argument is provided. If missing, ask the user.
2. Verify `devflow/devflow.config` exists. If not, warn that `/devflow:init` has not been run.
3. Check GitHub CLI (`gh`) is authenticated: `gh auth status`.

## Scope Selection

**Before any other step**, ask the user to select a scope:

> What are you building?
> 1. **Product** — New greenfield product (full system: backend, frontend, infra)
> 2. **Feature** — New feature within an existing product
> 3. **Library** — Backend library, SDK, or internal package (no UI, API-focused)

Store the selected scope. The scope changes what each step captures and which steps are skipped.

### Scope Behavior Matrix

| Step | Product | Feature | Library |
|------|---------|---------|---------|
| Init | Run | Run | Run |
| Principles | Run | Run | Run |
| Context | Run | Run | Run |
| PRD | Product PRD (vision, multiple features, market) | Feature PRD (problem, users, value prop) | Library Brief (purpose, consumers, API surface) |
| Spec | Product spec (feature list → priority matrix) | Feature spec (Given/When/Then user stories) | API Contract (endpoints/functions, input/output schemas, error handling, versioning) |
| Clarify | Run | Run | Run |
| Analyze | Run | Run | Run |
| Plan | Full architecture (all layers, infra, deploy) | Feature plan (affected layers, data model) | Library plan (package structure, dependencies, publish strategy) |
| Design | Ask (likely yes) | Ask | **Skip** (no UI) |
| Decompose | Decompose into features → then tasks per feature | Decompose into tasks | Decompose into tasks |
| Sync | Run | Run | Run |

## Task Agent Strategy

**CRITICAL:** Use the Task tool to spawn sub-agents for each major step. This provides:
- Better context management (each agent has its own context)
- Parallel execution where possible
- Resilience to context compaction
- Progress tracking via TaskCreate/TaskUpdate

### Execution Pattern

1. **Create tasks first** using TaskCreate for all steps
2. **Run independent tasks in parallel** using multiple Task tool calls in one message
3. **Run dependent tasks sequentially** waiting for blockers to complete
4. **Update task status** as each completes

### Parallelization Map

```
Independent (can run in parallel):
- Init, Principles, Context (all independent)

Sequential chains:
- PRD → Gate:PRD → Spec → Gate:Spec → Plan → Gate:Plan → Decompose → Gate:Epic → Sync

Within Decompose (parallel by type):
- DB tasks, API tasks, UI tasks, Test tasks (if no dependencies)
```

### Task Agent Usage

For each step, spawn a Task agent:
```
Task tool with subagent_type="general-purpose"
prompt: "Execute Step X: [description]. Write output to [path]. Return summary when done."
```

For parallel steps, include multiple Task calls in a single message.

## Instructions

Execute the following steps. Use TaskCreate to create tasks, then spawn Task agents to execute them. Check if artifacts exist and skip completed steps.

### Step 0: Scope Selection

Ask the user to select scope: **product**, **feature**, or **library**.

Record the scope in the PRD frontmatter as `scope: product|feature|library`. All subsequent steps read this value to adapt behavior.

### Step 1: Initialize (if needed)

Check if `devflow/devflow.config` exists.
- **If missing:** Run the `/devflow:init` logic — create directory structure, GitHub labels, validate auth.
- **If exists:** Skip. Print: `DevFlow already initialized. Skipping init.`

### Step 2: Principles (if needed)

Check if `devflow/templates/principles/principles.md` or equivalent project principles file exists.
- **If missing:** Ask the user: "Would you like to define project principles now, or skip?"
  - If yes: Run `/devflow:principles` logic — guide user through defining immutable project principles.
  - If skip: Continue without principles.
- **If exists:** Skip. Print: `Project principles already defined. Skipping.`

### Step 3: Context (if needed)

Check if `devflow/context/` contains any `.md` files.
- **If empty:** Run `/context:create` logic — analyze the codebase and generate baseline context documents.
- **If exists:** Skip. Print: `Context docs already exist. Skipping. Run /context:update to refresh.`

### Step 4: PRD

Check if `devflow/prds/<name>.md` exists.
- **If missing:** Run `/pm:prd-new <name>` logic, adapted by scope:

**Scope: product**
Brainstorm a Product PRD. Capture:
- Product vision and mission
- Target market and user personas
- Core feature set (high-level, not detailed)
- Business model / value proposition
- Technical constraints and non-negotiables
- Out-of-scope for v1
- Success metrics

**Scope: feature**
Brainstorm a Feature PRD. Capture:
- Problem statement
- Target users (within existing product)
- Key features / capabilities
- Value proposition
- Constraints
- Out-of-scope

**Scope: library**
Brainstorm a Library Brief. Capture:
- Purpose — what problem this library solves
- Consumers — who/what will use it (services, teams, external devs)
- API surface — key functions, classes, or endpoints it exposes
- Input/output contracts — what goes in, what comes out
- Dependencies — what it depends on, what depends on it
- Non-goals — what it explicitly does NOT do
- Distribution — how it's packaged and consumed (PyPI, internal, vendored)

Write to `devflow/prds/<name>.md` with frontmatter including `scope: <scope>`.

- **If exists:** Print: `PRD for <name> already exists. Skipping. Run /pm:prd-edit <name> to modify.`

### Step 4a: Gate — PRD

Run `/devflow:gate prd <name>`.

- **BLOCK:** Fix the issues identified in the gate report, update the PRD, and re-run the gate.
- **CONCERN:** Present concerns to the user. They choose: proceed, iterate on the PRD, or deep-dive into a specific concern.
- **PASS:** Continue to next step.

### Step 5: Spec

Check if `devflow/specs/<name>.md` exists.
- **If missing:** Run `/pm:spec-create <name>` logic, adapted by scope:

**Scope: product**
Create a Product Spec. Structure:
- Feature inventory (list all features from PRD)
- Priority matrix (P1/P2/P3 per feature)
- User stories per P1 feature (Given/When/Then)
- Key entities and relationships
- Cross-feature dependencies
- Success criteria per feature

**Scope: feature**
Create a Feature Spec. Structure:
- User stories with Given/When/Then acceptance criteria
- P1/P2/P3 priority for each story
- Functional requirements
- Key entities
- Success criteria

**Scope: library**
Create an API Contract. Structure:
- Public API reference — every public function/class/endpoint with:
  - Signature (params, types, return type)
  - Description
  - Example usage
  - Error cases
- Data schemas (Pydantic models / TypeScript interfaces)
- Error taxonomy (error codes, messages, HTTP status if applicable)
- Versioning strategy (semver, breaking change policy)
- Performance requirements (latency, throughput, memory)
- Compatibility matrix (Python versions, OS, dependencies)

Write to `devflow/specs/<name>.md` with proper frontmatter.
Present to user for review.

- **If exists:** Print: `Spec for <name> already exists. Skipping.`

### Step 5a: Gate — Spec

Run `/devflow:gate spec <name>`.

- **BLOCK:** Fix the issues (e.g., dropped PRD features, untestable criteria), update the spec, and re-run the gate.
- **CONCERN:** Present concerns to the user. They choose: proceed, iterate, or deep-dive.
- **PASS:** Continue.

### Step 6: Clarify (optional)

Ask the user: "Would you like to clarify ambiguities in the spec? (recommended for complex work)"
- **If yes:** Run `/pm:spec-clarify <name>` logic — structured Q&A (max 5 rounds) to resolve ambiguities. Update spec file.
- **If no:** Skip.

### Step 7: Analyze

Run `/pm:spec-analyze <name>` logic:
- Cross-check PRD ↔ Spec consistency
- Identify gaps, contradictions, missing requirements
- **Scope: library** — additionally check for: missing error cases, inconsistent naming, undocumented side effects, missing edge cases in API contracts
- Present findings to user
- If issues found, offer to fix them

### Step 8: Plan

Check if `devflow/specs/<name>-plan.md` exists.
- **If missing:** Run `/pm:plan <name>` logic, adapted by scope:

**Scope: product**
Generate a Full Architecture Plan:
- System architecture (services, databases, queues, caches)
- Stack decisions per layer (frontend, backend, infra)
- Data model (all entities, relationships, schema)
- Project structure (monorepo vs multi-repo, directory layout)
- API design (REST/GraphQL, auth, versioning)
- Infrastructure (hosting, CI/CD, monitoring)
- Principles compliance check

**Scope: feature**
Generate a Feature Plan:
- Affected layers (which services, components, tables change)
- Data model changes (new/modified entities)
- API changes (new/modified endpoints)
- Migration strategy (if schema changes)
- Principles compliance check

**Scope: library**
Generate a Library Plan:
- Package structure (src layout, module organization)
- Dependency management (pyproject.toml / setup.cfg)
- Internal architecture (layers, patterns — e.g., repository pattern, strategy pattern)
- Testing strategy (unit, integration, property-based, fixtures)
- CI/CD (lint, test, build, publish pipeline)
- Documentation plan (docstrings, README, API reference generation)
- Publish strategy (PyPI, private index, vendored)

Write to `devflow/specs/<name>-plan.md` with proper frontmatter.
Present plan to user for review.

- **If exists:** Print: `Technical plan for <name> already exists. Skipping.`

### Step 8a: Gate — Plan

Run `/devflow:gate plan <name>`.

- **BLOCK:** Fix the issues (e.g., unaddressed FRs, empty risk section), update the plan, and re-run the gate.
- **CONCERN:** Present concerns to the user. They choose: proceed, iterate, or deep-dive.
- **PASS:** Continue.

### Step 9: Design (conditional)

**Scope: library** — Skip entirely. Print: `Library scope — no design phase.`

**Scope: product** — Ask: "Ready to design the UI? (recommended)"

**Scope: feature** — Ask: "Does this feature include a user interface?"

- **If yes:** Run design sub-sequence:
  1. `/design:design-tokens` — Create/verify design token system
  2. `/design:design-shell` — Design app shell layout (product scope only, skip for feature if shell exists)
  3. Ask which sections need UI specs, then for each:
     - `/design:shape-section <section>` — Per-section UI spec
  4. `/design:export` — Generate handoff package
- **If no/skip:** Skip design phase entirely.

### Step 10: Epic Decompose

Check if `devflow/epics/<name>/epic.md` exists.
- **If missing:** Run `/pm:epic-decompose <name>` logic, adapted by scope:

**Scope: product**
- First decompose into features (one epic per major feature)
- Then decompose each feature into parallelizable tasks
- Create `devflow/epics/<name>/epic.md` as the product-level epic
- Create sub-epics per feature: `devflow/epics/<name>-<feature>/epic.md`

**Scope: feature**
- Break plan into parallelizable tasks with dependencies
- Create `devflow/epics/<name>/epic.md` and individual task files

**Scope: library**
- Break plan into tasks, typically:
  - Core module scaffolding
  - Individual API function/class implementations
  - Test suites per module
  - CI/CD pipeline setup
  - Documentation generation
  - Package build + publish config
- Create `devflow/epics/<name>/epic.md` and individual task files

- **If exists:** Print: `Epic for <name> already exists. Skipping.`

### Step 10a: Gate — Epic

Run `/devflow:gate epic <name>`.

- **BLOCK:** Fix the issues (e.g., cyclic dependencies, missing traces_to, parallel file conflicts), update tasks, and re-run the gate.
- **CONCERN:** Present concerns to the user. They choose: proceed, iterate, or deep-dive.
- **PASS:** Continue.

### Step 11: Epic Sync

Ask the user: "Push tasks to GitHub as issues?"
- **If yes:** Run `/pm:epic-sync <name>` logic — create GitHub issues with labels and cross-references.
  - **Scope: product** — also sync sub-epics per feature.
- **If no:** Skip. Tasks remain local in `devflow/epics/<name>/`.

### Step 12: Summary

Print a summary of all artifacts created, including gate results:

```
Brainstorming Phase Complete
  Scope: <product|feature|library>
  Name:  <name>

Artifacts created:
  - PRD:    devflow/prds/<name>.md
  - Spec:   devflow/specs/<name>.md
  - Plan:   devflow/specs/<name>-plan.md
  - Epic:   devflow/epics/<name>/epic.md
  - Tasks:  devflow/epics/<name>/001.md ... NNN.md
  - GitHub: [X issues created] (if synced)
  - Design: [listed if created, or "skipped"]

Gate Results:
  - gate:prd   — [PASS|CONCERN|BLOCK]
  - gate:spec  — [PASS|CONCERN|BLOCK]
  - gate:plan  — [PASS|CONCERN|BLOCK]
  - gate:epic  — [PASS|CONCERN|BLOCK]

Traceability:
  - PRD Features → Spec US: [X]% coverage
  - Spec FR → Plan Sections: [X]% coverage
  - Plan Sections → Tasks: [X]% coverage
```

Then suggest next steps based on scope:

**Scope: product**
```
Next steps:
  /init:project                # Scaffold the project
  /pm:epic-start <name>        # Launch parallel agents to build
```

**Scope: feature**
```
Next steps:
  /pm:epic-start <name>        # Launch parallel agents to build
```

**Scope: library**
```
Next steps:
  /pm:epic-start <name>        # Launch parallel agents to build
  # Library will be built with: package structure, tests, CI/CD, publish config
```

## Error Recovery

- If any step fails, print the error and ask the user whether to retry or skip.
- Already-completed steps are never re-run (idempotent by file-existence checks).
- The user can re-run `/devflow:kickstart <name>` safely — it picks up where it left off.
- If re-running, the scope is read from the existing PRD frontmatter (`scope:` field) rather than asking again.
