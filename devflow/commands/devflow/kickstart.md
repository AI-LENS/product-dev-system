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

## Scope Selection — MANDATORY FIRST STEP

**Before any other step**, use AskUserQuestion to select scope:

```
Question: What are you building?
Header: "Scope"
Options:
- Product (Recommended for new apps): New greenfield product - full system with backend, frontend, database, and infrastructure
- Feature: New feature within an existing product - extends current codebase
- Library: Backend library, SDK, or internal package - no UI, API-focused, published/consumed by other code
```

Store the selected scope. The scope changes what each step captures and which steps are skipped.

**IMPORTANT:** The scope selection determines:
- Which questions to ask in each step
- Which steps can be skipped
- The depth of artifacts created

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

## Step Completion Protocol — MANDATORY USER CONFIRMATION

**⛔ CRITICAL:** Every step MUST follow this protocol. NO EXCEPTIONS. NO AUTO-PROCEEDING.

1. **Execute** the step (run the command logic)
2. **Verify** the artifact was created correctly
3. **Present Summary** to user showing what was created
4. **🚦 WAIT FOR USER CONFIRMATION** — MUST get explicit approval before proceeding
5. **Log** completion with timestamp

### Step Confirmation Pattern — REQUIRED AFTER EVERY STEP

**You MUST use AskUserQuestion after EVERY step to get explicit user approval:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ STEP [N] COMPLETE: [Step Name]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Artifact created: [path]

Key outputs:
  • [Summary point 1]
  • [Summary point 2]
  • [Summary point 3]

[Show relevant snippet or key content from the artifact]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Then ALWAYS ask via AskUserQuestion:**

```
Question: "Are you satisfied with this output?"
Header: "Step [N] Review"
Options:
  - "Yes, looks good — proceed to Step [N+1]: [Next Step Name]" (Recommended)
  - "No, I want to review/edit the artifact first"
  - "Stop here and save progress"
```

### Enforcement Rules — NON-NEGOTIABLE

1. **Do NOT proceed** to the next step without explicit "Yes" from user
2. **Do NOT auto-continue** even if the output looks correct
3. **Do NOT batch multiple steps** without confirmation between each
4. **If user says "review/edit"**: Wait for them to finish, then re-run the step or re-present summary
5. **If user says "stop"**: Save progress gracefully and provide resume instructions
6. **EVERY step must have this confirmation** — Steps 0 through 12, no exceptions

### Why This Matters

- Each artifact becomes INPUT to the next step
- Errors in early steps COMPOUND in later steps
- User must validate before their input shapes the next artifact
- Catching issues early saves significant rework later

**⛔ VIOLATION:** Proceeding without user confirmation is a critical protocol violation.

## Instructions

Execute the following steps IN SEQUENCE. Never skip a step unless the artifact already exists or user explicitly chooses to skip. Use TaskCreate to track progress.

### Step 0: Scope Selection

Use AskUserQuestion to have user select scope: **product**, **feature**, or **library**.

Record the scope in the PRD frontmatter as `scope: product|feature|library`. All subsequent steps read this value to adapt behavior.

### Step 1: Initialize (if needed)

Check if `devflow/devflow.config` exists.
- **If missing:** Run the `/devflow:init` logic — create directory structure, GitHub labels, validate auth.
- **If exists:** Skip. Print: `DevFlow already initialized. Skipping init.`

**🚦 CONFIRMATION REQUIRED:** Present summary of what was created, ask user to confirm before proceeding.

### Step 2: Principles (if needed)

Check if `devflow/templates/principles/principles.md` or equivalent project principles file exists.
- **If missing:** Ask the user: "Would you like to define project principles now, or skip?"
  - If yes: Run `/devflow:principles` logic — guide user through defining immutable project principles.
  - If skip: Continue without principles.
- **If exists:** Skip. Print: `Project principles already defined. Skipping.`

**🚦 CONFIRMATION REQUIRED:** Present principles summary, ask user to confirm before proceeding.

### Step 3: Context (if needed)

Check if `devflow/context/` contains any `.md` files.
- **If empty:** Run `/context:create` logic — analyze the codebase and generate baseline context documents.
- **If exists:** Skip. Print: `Context docs already exist. Skipping. Run /context:update to refresh.`

**🚦 CONFIRMATION REQUIRED:** Present context summary, ask user to confirm before proceeding.

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

**🚦 CONFIRMATION REQUIRED:** Present full PRD summary with key sections, ask user: "Are you satisfied with this PRD?"

### Step 4a: Gate — PRD

Run `/devflow:gate prd <name>`.

- **BLOCK:** Fix the issues identified in the gate report, update the PRD, and re-run the gate.
- **CONCERN:** Present concerns to the user. They choose: proceed, iterate on the PRD, or deep-dive into a specific concern.
- **PASS:** Continue to next step.

### Step 5: Spec

**FIRST: Load PRD artifact**
Read `devflow/prds/<name>.md` — this is the input for spec creation.

Check if `devflow/specs/<name>.md` exists.
- **If missing:** Run `/pm:spec-create <name>` logic, adapted by scope.

  **Input:** PRD (problem, users, features, constraints)
  **Output:** Spec (user stories, acceptance criteria, FRs, entities)

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

- **If exists:** Print: `Spec for <name> already exists. Skipping.`

**🚦 CONFIRMATION REQUIRED:** Present full spec summary (user stories count, FRs, entities), ask user: "Are you satisfied with this spec?"

### Step 5a: Gate — Spec

Run `/devflow:gate spec <name>`.

- **BLOCK:** Fix the issues (e.g., dropped PRD features, untestable criteria), update the spec, and re-run the gate.
- **CONCERN:** Present concerns to the user. They choose: proceed, iterate, or deep-dive.
- **PASS:** Continue.

### Step 6: Clarify (optional)

Ask the user: "Would you like to clarify ambiguities in the spec? (recommended for complex work)"
- **If yes:** Run `/pm:spec-clarify <name>` logic — structured Q&A (max 5 rounds) to resolve ambiguities. Update spec file.
- **If no:** Skip.

**🚦 CONFIRMATION REQUIRED:** If clarify was run, present updated spec sections, ask user: "Are the clarifications correct?"

### Step 7: Analyze

**Load both PRD and Spec for comparison:**
- `devflow/prds/<name>.md` — Original requirements
- `devflow/specs/<name>.md` — Formalized spec

Run `/pm:spec-analyze <name>` logic:
- Cross-check PRD ↔ Spec consistency
- Identify gaps, contradictions, missing requirements
- **Scope: library** — additionally check for: missing error cases, inconsistent naming, undocumented side effects, missing edge cases in API contracts
- Present findings to user
- If issues found, offer to fix them

**🚦 CONFIRMATION REQUIRED:** Present analysis findings, ask user: "Are you satisfied with the analysis? Any issues to address before planning?"

### Step 8: Plan

**FIRST: Load Spec and PRD artifacts**
Read:
- `devflow/specs/<name>.md` — User stories, FRs, entities (PRIMARY INPUT)
- `devflow/prds/<name>.md` — Constraints, assumptions (for context)
- `devflow/templates/principles/active-principles.md` — Principles to comply with

Check if `devflow/specs/<name>-plan.md` exists.
- **If missing:** Run `/pm:plan <name>` logic, adapted by scope.

  **Input:** Spec (FRs, entities), PRD (constraints), Principles
  **Output:** Plan (architecture, data model, API design, project structure)

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

- **If exists:** Print: `Technical plan for <name> already exists. Skipping.`

**🚦 CONFIRMATION REQUIRED:** Present full plan summary (architecture, data model, API design), ask user: "Are you satisfied with this technical plan?"

### Step 8a: Gate — Plan

Run `/devflow:gate plan <name>`.

- **BLOCK:** Fix the issues (e.g., unaddressed FRs, empty risk section), update the plan, and re-run the gate.
- **CONCERN:** Present concerns to the user. They choose: proceed, iterate, or deep-dive.
- **PASS:** Continue.

### Step 8b: Generate ADRs — MANDATORY

**CRITICAL:** Every significant architectural decision from the plan MUST be captured as an ADR in `devflow/adrs/`.

#### ADR Extraction Process

1. **Scan the plan** for decisions in these categories:
   - **Technology choices** — database, framework, language versions
   - **Architecture patterns** — microservices vs monolith, event-driven, etc.
   - **Data model decisions** — schema design choices, relationships
   - **Integration decisions** — third-party services, APIs
   - **Security decisions** — auth approach, encryption, etc.
   - **API design decisions** — REST/GraphQL, versioning strategy

2. **Create ADR directory if needed:**
   ```bash
   mkdir -p devflow/adrs
   ```

3. **For EACH decision**, run `/arch:adr-new "<decision>"`:
   - This will prompt for context, options, and rationale
   - The ADR is saved to `devflow/adrs/ADR-NNN-<slug>.md`

4. **Verify ADR creation:**
   ```bash
   ls -la devflow/adrs/ADR-*.md
   ```

#### ADR Output Format

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 ARCHITECTURE DECISIONS RECORDED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ADRs created from plan:
  ✓ devflow/adrs/ADR-001-use-postgresql.md
    Title: Use PostgreSQL as primary database
    Status: proposed

  ✓ devflow/adrs/ADR-002-use-fastapi.md
    Title: Use FastAPI for backend API
    Status: proposed

  ✓ devflow/adrs/ADR-003-use-angular.md
    Title: Use Angular 19 with standalone components
    Status: proposed

  ✓ devflow/adrs/ADR-004-jwt-authentication.md
    Title: JWT-based authentication with refresh tokens
    Status: proposed

  ✓ devflow/adrs/ADR-005-feature-folder-structure.md
    Title: Feature-based folder structure
    Status: proposed

Total: 5 ADRs created
Location: devflow/adrs/

Next: ADRs will be updated to "accepted" during execution
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### Minimum ADR Requirements

| Scope | Minimum ADRs | Required Categories |
|-------|--------------|---------------------|
| **Product** | 5+ | Stack, architecture, auth, data model, deployment |
| **Feature** | 1-3 | If new patterns or tech introduced |
| **Library** | 2-3 | API design, packaging, versioning |

**If fewer ADRs than minimum:** Use AskUserQuestion to ask:
> Only [N] ADRs were extracted. For a [scope] scope, we need at least [minimum].
>
> Missing categories:
> - [category 1]
> - [category 2]
>
> Should we:
> - Add more ADRs for these categories
> - Proceed with current ADRs (not recommended)

#### ADR → Code Verification

During execution, gates will verify:
- Code follows all accepted ADRs
- No ADR violations
- ADR status updated from "proposed" to "accepted" when implemented

### Step 9: Design (conditional)

**Scope: library** — Skip entirely. Print: `Library scope — no design phase.`

**Scope: product/feature:**

**FIRST: Load artifacts for design context**
Read:
- `devflow/specs/<name>.md` — User stories (what users need to do)
- `devflow/specs/<name>-plan.md` — Tech stack, project structure
- `devflow/prds/<name>.md` — User personas, constraints

**Scope: product** — Ask: "Ready to design the UI? (recommended)"

**Scope: feature** — Ask: "Does this feature include a user interface?"

- **If yes:** Run design sub-sequence with MANDATORY probing questions:

  **⚠️ CRITICAL: Each design command has mandatory probing questions that MUST be answered.**
  **Do NOT rush through design. Do NOT skip questions. Do NOT use defaults without explicit user request.**

  1. `/design:design-tokens` — Create/verify design token system
     - **11 mandatory questions** about brand, colors, typography
     - Gate: All questions answered before generating tokens

  2. `/design:design-shell` — Design app shell layout (product scope only, skip for feature if shell exists)
     - **18 mandatory questions** about navigation, layout, responsiveness
     - Gate: All questions answered before generating shell

  3. Ask which sections need UI specs, then for each:
     - `/design:shape-section <section>` — Per-section UI spec
     - **17 mandatory questions** about data, actions, edge cases, layout
     - Gate: All questions answered before generating section spec

  4. `/design:export` — Generate handoff package

  **Design Phase Gate:** All design artifacts created with full question coverage.

- **If no/skip:** Skip design phase entirely.

### Step 10: Epic Decompose

**FIRST: Load all upstream artifacts**
Read:
- `devflow/specs/<name>-plan.md` — Architecture, data model, API design (PRIMARY INPUT)
- `devflow/specs/<name>.md` — User stories, FRs for traceability
- `devflow/prds/<name>.md` — Original scope for context
- `devflow/design/*.md` — UI specs (if created)

Check if `devflow/epics/<name>/epic.md` exists.
- **If missing:** Run `/pm:epic-decompose <name>` logic, adapted by scope.

  **Input:** Plan (architecture sections), Spec (FRs), Design (UI specs)
  **Output:** Epic with tasks, each task traces_to FR-xxx and plan section

**For large applications (15+ tasks or scope=product)**, organize by FEATURES (not layers):

```markdown
## Development Phases (Feature-Based)

Each phase = complete feature with full stack (DB + API + UI).
This enables true end-to-end testing per phase.

### Phase 1: Auth Feature
Priority: P1 (must complete first)
Tasks: 001-005
Full stack:
- DB: users, sessions tables + migrations
- API: /auth/login, /auth/register, /auth/logout, /auth/me
- UI: Login page, Register page, Auth guard, Auth state
- Tests: Complete auth flow E2E

### Phase 2: Dashboard Feature
Priority: P1
Depends on: Phase 1 (needs auth)
Tasks: 006-011
Full stack:
- DB: dashboard config, widgets
- API: /dashboard, /widgets CRUD
- UI: Dashboard page, Widget components, Layout
- Tests: Authenticated user can use dashboard E2E

### Phase 3: [Core Business Feature]
Priority: P1
Depends on: Phase 1
Tasks: 012-018
Full stack:
- DB: <domain tables>
- API: <domain endpoints>
- UI: <domain pages and components>
- Tests: Core business flow E2E

### Phase 4: [Secondary Feature]
Priority: P2
Depends on: Phase 2 or 3
Tasks: 019-024
Full stack for feature...

### Phase 5: Settings & Polish
Priority: P3
Depends on: All above
Tasks: 025-028
- Settings feature (full stack)
- Error handling improvements
- Performance optimization
- Final E2E regression
```

**Why feature-based phases:**
- Each phase is independently deployable and testable
- User sees complete working features, not half-done APIs
- E2E tests verify real user flows
- Easier to demo progress to stakeholders

Each task file should include `phase: <N>` and `feature: <name>` in frontmatter.

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

**🚦 CONFIRMATION REQUIRED:** Present epic summary (phases, task count, dependencies), ask user: "Are you satisfied with this task breakdown?"

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

**🚦 CONFIRMATION REQUIRED:** Present sync results (issues created, labels applied), ask user: "Are the GitHub issues correct?"

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

**All scopes:**
```
Next step:
  /devflow:execute <name>      # Run execution phase (build, test, deploy)

This will:
  - Build phase-by-phase (feature-complete phases)
  - Run comprehensive tests at each phase
  - Deploy locally for verification
  - Generate documentation
  - Prepare for production
```

## Error Recovery

- If any step fails, print the error and ask the user whether to retry or skip.
- Already-completed steps are never re-run (idempotent by file-existence checks).
- The user can re-run `/devflow:kickstart <name>` safely — it picks up where it left off.
- If re-running, the scope is read from the existing PRD frontmatter (`scope:` field) rather than asking again.
