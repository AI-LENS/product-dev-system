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

---

## Pipeline Overview — PRESENT BEFORE STARTING

**⛔ MANDATORY: Before starting ANY step, present the complete pipeline with progress tracking.**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 BRAINSTORMING PIPELINE: <name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP | NAME           | ARTIFACT                          | STATUS
-----|----------------|-----------------------------------|--------
0    | Scope          | PRD frontmatter: scope            | ⏳ Pending
1    | Initialize     | devflow/devflow.config            | ⏳ Pending
2    | Principles     | devflow/templates/principles/     | ⏳ Pending
3    | Context        | devflow/context/*.md              | ⏳ Pending
4    | PRD            | devflow/prds/<name>.md            | ⏳ Pending
4a   | Gate: PRD      | —                                 | ⏳ Pending
5    | Spec           | devflow/specs/<name>.md           | ⏳ Pending
5a   | Gate: Spec     | —                                 | ⏳ Pending
6    | Clarify        | (updates spec)                    | ⏳ Pending
7    | Analyze        | —                                 | ⏳ Pending
8    | Plan           | devflow/specs/<name>-plan.md      | ⏳ Pending
8a   | Gate: Plan     | —                                 | ⏳ Pending
8b   | ADRs           | devflow/adrs/ADR-*.md             | ⏳ Pending
9    | Design         | (5 sub-steps)                     | ⏳ Pending
10   | Decompose      | devflow/epics/<name>/             | ⏳ Pending
10a  | Gate: Epic     | —                                 | ⏳ Pending
11   | Sync           | GitHub Issues                     | ⏳ Pending
12   | Summary        | —                                 | ⏳ Pending

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Update this tracker after EVERY step:** Change ⏳ to ✅ when complete, 🔄 for current step.

---

## Directory Setup — MANDATORY FIRST ACTION

**⛔ BEFORE ANY ARTIFACT CREATION, ensure all directories exist:**

```bash
mkdir -p devflow/prds
mkdir -p devflow/specs
mkdir -p devflow/epics
mkdir -p devflow/adrs
mkdir -p devflow/context
mkdir -p devflow/designs
mkdir -p devflow/templates/principles
```

If any mkdir fails, STOP and investigate before proceeding.

---

## Artifact Chain — INPUT → OUTPUT Dependencies

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ ARTIFACT DEPENDENCY CHAIN — Each step REQUIRES artifacts from previous     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Step 0: Scope Selection                                                    │
│    OUTPUT: scope (stored in PRD frontmatter)                                │
│    ▼                                                                        │
│  Step 4: PRD                                                                │
│    INPUT:  scope                                                            │
│    OUTPUT: devflow/prds/<name>.md                                           │
│    VERIFY: File exists, has frontmatter with scope                          │
│    ▼                                                                        │
│  Step 5: Spec                                                               │
│    INPUT:  devflow/prds/<name>.md ← MUST READ BEFORE WRITING                │
│    OUTPUT: devflow/specs/<name>.md                                          │
│    VERIFY: File exists, has user stories, traces to PRD                     │
│    ▼                                                                        │
│  Step 8: Plan                                                               │
│    INPUT:  devflow/specs/<name>.md + devflow/prds/<name>.md                 │
│    OUTPUT: devflow/specs/<name>-plan.md                                     │
│    VERIFY: File exists, has architecture, traces to spec                    │
│    ▼                                                                        │
│  Step 9: Design                                                             │
│    INPUT:  devflow/specs/<name>-plan.md + devflow/specs/<name>.md           │
│    OUTPUT: devflow/designs/*.md + src/app/models/*.ts + src/app/mocks/*.ts  │
│    VERIFY: All design artifacts exist per section list                      │
│    ▼                                                                        │
│  Step 10: Decompose                                                         │
│    INPUT:  ALL above artifacts                                              │
│    OUTPUT: devflow/epics/<name>/epic.md + task files                        │
│    VERIFY: Epic exists, tasks trace to FRs/US                               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**⛔ ENFORCEMENT: Before writing ANY artifact, you MUST read its input artifacts first.**

---

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

**FIRST: Verify directory exists:**
```bash
mkdir -p devflow/prds
```

**THEN: Check if `devflow/prds/<name>.md` exists.**
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

**ARTIFACT VERIFICATION — MANDATORY:**
```bash
ls -la devflow/prds/<name>.md
# Verify file exists and is non-empty
```

If file missing or empty: STOP. Investigate. Do NOT proceed.

- **If exists:** Print: `PRD for <name> already exists. Skipping. Run /pm:prd-edit <name> to modify.`

**Present Progress Update:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ STEP 4 COMPLETE: PRD Created
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Artifact: devflow/prds/<name>.md
Scope: <product|feature|library>

Key sections:
  • Problem/Purpose: [summary]
  • Users/Consumers: [list]
  • Features/API Surface: [count] items
  • Constraints: [list]
  • Out of Scope: [list]

Next: Step 4a — PRD Gate (quality check)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**🚦 CONFIRMATION REQUIRED:** Ask user: "Are you satisfied with this PRD?"

### Step 4a: Gate — PRD

Run `/devflow:gate prd <name>`.

- **BLOCK:** Fix the issues identified in the gate report, update the PRD, and re-run the gate.
- **CONCERN:** Present concerns to the user. They choose: proceed, iterate on the PRD, or deep-dive into a specific concern.
- **PASS:** Continue to next step.

### Step 5: Spec

**⛔ PREREQUISITE CHECK — MANDATORY:**
```bash
# Verify PRD exists (input artifact)
ls -la devflow/prds/<name>.md
```
If PRD does NOT exist: STOP. Print: "Cannot create spec — PRD not found. Run Step 4 first."

**THEN: Load PRD artifact**
Read `devflow/prds/<name>.md` — this is the input for spec creation. Extract:
- Problem statement / purpose
- User personas / consumers
- Feature list / API surface
- Constraints

**THEN: Ensure directory exists:**
```bash
mkdir -p devflow/specs
```

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

**ARTIFACT VERIFICATION — MANDATORY:**
```bash
ls -la devflow/specs/<name>.md
# Verify file exists and is non-empty
```

If file missing or empty: STOP. Investigate. Do NOT proceed.

- **If exists:** Print: `Spec for <name> already exists. Skipping.`

**Present Progress Update:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ STEP 5 COMPLETE: Spec Created
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Artifact: devflow/specs/<name>.md
Input Used: devflow/prds/<name>.md ✓

Key sections:
  • User Stories: [N] stories with Given/When/Then
  • Functional Requirements: [N] FRs
  • Key Entities: [list]
  • Priority: P1=[N], P2=[N], P3=[N]

Traceability:
  • PRD features → Spec US: [X]% coverage

Next: Step 5a — Spec Gate (quality check)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**🚦 CONFIRMATION REQUIRED:** Ask user: "Are you satisfied with this spec?"

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

**⛔ PREREQUISITE CHECK:**
```bash
ls -la devflow/prds/<name>.md    # Must exist
ls -la devflow/specs/<name>.md   # Must exist
```
If EITHER is missing: STOP. Cannot create plan without PRD and Spec.

**THEN: Load Spec and PRD artifacts**
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

**ARTIFACT VERIFICATION:**
```bash
ls -la devflow/specs/<name>-plan.md
```
If missing: STOP. Investigate. Do NOT proceed.

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

### Step 9: Design — MANDATORY (NOT OPTIONAL)

**⛔ CRITICAL: Design phase is MANDATORY for product and feature scopes. It CANNOT be skipped.**

The design phase ensures all UI decisions are made BEFORE implementation, preventing:
- Generic, unmemorable UIs
- Design decisions buried in code
- Inconsistent user experiences
- Costly rework during implementation

**Scope: library** — Skip design phase. Print: `Library scope — no UI, skipping design phase.`

**Scope: product/feature** — Design is REQUIRED. Do NOT ask if user wants to skip. Proceed with the full design sequence below.

---

#### Design Phase Prerequisites

**FIRST: Load and verify these artifacts exist:**
- `devflow/prds/<name>.md` — User personas, constraints, product vision
- `devflow/specs/<name>.md` — User stories (what users need to do)
- `devflow/specs/<name>-plan.md` — Tech stack, project structure, data model

If any are missing: STOP. Cannot proceed with design without these artifacts.

---

#### Design Sub-Sequence — ALL STEPS ARE MANDATORY

**⛔ ENFORCEMENT: Every step below MUST be completed. No skipping. No shortcuts.**

```
┌────────────────────────────────────────────────────────────────────────────┐
│ DESIGN PHASE FLOW — MANDATORY SEQUENCE                                    │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  Step 9.1: Design Tokens                                                   │
│    │  Colors, typography, spacing, visual identity                         │
│    │  11 mandatory probing questions                                       │
│    │  🚦 GATE: All questions answered + user confirmed                     │
│    ▼                                                                       │
│  Step 9.2: Design Shell (product scope, or if no shell exists)            │
│    │  Navigation, layout, responsive behavior                              │
│    │  18 mandatory probing questions                                       │
│    │  🚦 GATE: All questions answered + user confirmed                     │
│    ▼                                                                       │
│  Step 9.2a: Section Identification                                        │
│    │  Extract all sections from plan/spec                                  │
│    │  🚦 GATE: Section list confirmed by user                              │
│    ▼                                                                       │
│  Step 9.3: Shape Sections (for EACH section)                              │
│    │  User flows, UI requirements, interactions                            │
│    │  17 mandatory probing questions PER SECTION                           │
│    │  Output: devflow/designs/<section>.md                                 │
│    │  🚦 GATE: All questions answered + user confirmed (per section)       │
│    ▼                                                                       │
│  Step 9.4: Sample Data (for EACH section)                                 │
│    │  Realistic mock data + TypeScript interfaces                          │
│    │  Output: models, mocks, factories, fixtures                           │
│    │  🚦 GATE: All files generated + user confirmed                        │
│    ▼                                                                       │
│  Step 9.5: Design Screens (for EACH section)                              │
│    │  Actual screen components with design tokens applied                  │
│    │  Output: src/app/features/<section>/                                  │
│    │  🚦 GATE: All screens created + user confirmed                        │
│    ▼                                                                       │
│  ✅ Design Phase Complete — Artifacts ready for Execution                  │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

---

#### Step 9.1: Design Tokens — MANDATORY

Run `/design:design-tokens`

**Purpose:** Establish visual identity (colors, typography, spacing) BEFORE any UI work.

**Requirements:**
- **11 mandatory probing questions** covering:
  - Brand personality and target audience
  - Emotional response desired
  - Primary, secondary, neutral colors
  - Typography preferences
  - Visual density and corner styles
  - Dark mode requirements
- ALL questions must be answered — no defaults without explicit request
- User must confirm the token summary

**🚦 GATE:** Do NOT proceed to Step 9.2 until user confirms tokens.

---

#### Step 9.2: Design Shell — MANDATORY (product) / CONDITIONAL (feature)

Run `/design:design-shell`

**Scope: product** — MANDATORY. The shell is the foundation of the entire UI.
**Scope: feature** — Check if shell exists. If yes, skip. If no, MANDATORY.

**Requirements:**
- **18 mandatory probing questions** covering:
  - Application type, session behavior, navigation depth
  - Primary navigation items, global actions
  - User menu, multi-tenant switching
  - Notifications, real-time requirements
  - Device support (desktop, tablet, mobile)
  - Logo, brand colors, footer
- ALL questions must be answered
- User must confirm the shell design

**🚦 GATE:** Do NOT proceed to Step 9.3 until user confirms shell.

---

#### Step 9.2a: Section Identification — MANDATORY BEFORE PROCEEDING

**⛔ CRITICAL: You MUST identify all sections BEFORE proceeding with Steps 9.3-9.5.**

**Section Extraction Process:**

1. **Read the Plan** (`devflow/specs/<name>-plan.md`):
   - Look for "Features", "Sections", "Modules", or "Pages" headings
   - Extract each distinct UI area that users interact with

2. **Read the Spec** (`devflow/specs/<name>.md`):
   - Look for user stories grouped by area
   - Identify unique screens/sections mentioned

3. **Compile Section List:**
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   📋 IDENTIFIED SECTIONS FOR DESIGN
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Based on the plan and spec, the following sections need design:

   1. [section-name-1] — [brief description]
   2. [section-name-2] — [brief description]
   3. [section-name-3] — [brief description]
   ...

   Total: [N] sections

   Each section will go through:
     → Shape Section (17 questions)
     → Sample Data (types + mock data)
     → Design Screen (components)

   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```

4. **Get User Confirmation:**
   Use AskUserQuestion:
   ```
   Question: "Are these the correct sections to design?"
   Header: "Sections"
   Options:
     - "Yes, proceed with these [N] sections" (Recommended)
     - "Add more sections"
     - "Remove some sections"
   ```

**Store the section list** — you will iterate over it in Steps 9.3, 9.4, and 9.5.

---

#### Step 9.3: Shape Sections — MANDATORY FOR EACH SECTION

**⛔ ITERATE THROUGH EVERY SECTION — NO EXCEPTIONS**

For EACH section in the list from Step 9.2a, run `/design:shape-section <section>`

**Execution Pattern:**
```
for each section in section_list:
    1. Run /design:shape-section <section>
    2. Answer ALL 17 probing questions
    3. VERIFY artifact created: devflow/designs/<section>.md
    4. Get user confirmation for this section
    5. Only then move to next section
```

**Purpose:** Define user flows, UI requirements, and interactions for each feature area.

**Requirements per section:**
- **17 mandatory probing questions** covering:
  - Section purpose, user roles, access patterns
  - Data volume, freshness, relationships
  - CRUD operations, critical actions, workflow states
  - Empty states, error handling, loading states
  - Layout preferences, detail views, navigation
  - Mobile and accessibility requirements
- ALL questions answered for EACH section
- User must confirm each section spec

**Artifact Verification:**
```bash
# After each section, verify the file exists:
ls -la devflow/designs/<section>.md
```

If file does NOT exist, STOP and investigate before proceeding.

**Section Progress Tracker:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 SHAPE SECTIONS PROGRESS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Section                | Status      | Artifact
-----------------------|-------------|---------------------------
[section-1]            | ✅ Complete | devflow/designs/section-1.md
[section-2]            | ✅ Complete | devflow/designs/section-2.md
[section-3]            | 🔄 Current  | (in progress)
[section-4]            | ⏳ Pending  | —
[section-5]            | ⏳ Pending  | —

Progress: 2/5 sections complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**🚦 GATE per section:** Do NOT proceed to next section until:
1. All 17 questions answered ✓
2. `devflow/designs/<section>.md` exists ✓
3. User explicitly confirms section spec ✓

**🚦 GATE for Step 9.3 completion:** ALL sections must be shaped before proceeding to Step 9.4.

---

#### Step 9.4: Sample Data — MANDATORY FOR EACH SECTION

**⛔ PREREQUISITE CHECK — MANDATORY BEFORE EACH SECTION**

For EACH section in the list, run `/design:sample-data <section>`

**Execution Pattern:**
```
for each section in section_list:
    1. VERIFY prerequisite exists: devflow/designs/<section>.md
       - If MISSING: STOP. "Cannot generate sample data for '<section>' —
         section spec not found. Run /design:shape-section <section> first."
    2. Run /design:sample-data <section>
    3. Present proposed data structure, get user confirmation
    4. VERIFY artifacts created:
       - src/app/models/<section>.models.ts
       - src/app/mocks/<section>.mock.ts
       - src/app/mocks/<section>.factory.ts
       - src/app/mocks/fixtures/<section>-list.json
    5. Get user confirmation
    6. Only then move to next section
```

**Purpose:** Generate realistic mock data AND TypeScript interfaces for type safety.

**Requirements per section:**

1. **Read section spec** from `devflow/designs/<section>.md`
2. **Extract entities** and their relationships
3. **Present data structure** to user for confirmation BEFORE generating files
4. **Generate TypeScript interfaces** (`src/app/models/<section>.models.ts`):
   - Entity interfaces matching backend models
   - Create/Update DTOs
   - Props interfaces with callback types
   - Enums for status/type fields
5. **Generate mock data** (`src/app/mocks/<section>.mock.ts`):
   - 10-20 realistic records per entity
   - Varied statuses, dates, relationships
6. **Generate factory functions** (`src/app/mocks/<section>.factory.ts`):
   - `create<Entity>()` for single entity
   - `create<Entities>(count)` for arrays
   - `createPaginatedResponse()` for lists
7. **Generate JSON fixtures** (`src/app/mocks/fixtures/`):
   - `<section>-list.json` — paginated list
   - `<section>-detail.json` — single item
   - `<section>-empty.json` — empty state
   - `<section>-error-404.json` — not found
   - `<section>-error-422.json` — validation error

**Artifact Verification:**
```bash
# After each section, verify ALL files exist:
ls -la src/app/models/<section>.models.ts
ls -la src/app/mocks/<section>.mock.ts
ls -la src/app/mocks/<section>.factory.ts
ls -la src/app/mocks/fixtures/<section>-*.json
```

**Section Progress Tracker:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 SAMPLE DATA PROGRESS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Section     | Prereq    | Models | Mocks | Factory | Fixtures
------------|-----------|--------|-------|---------|----------
[section-1] | ✅ Found  | ✅     | ✅    | ✅      | ✅ (5 files)
[section-2] | ✅ Found  | ✅     | ✅    | ✅      | ✅ (5 files)
[section-3] | ✅ Found  | 🔄     | ⏳    | ⏳      | ⏳
[section-4] | ⏳ Pending| —      | —     | —       | —
[section-5] | ⏳ Pending| —      | —     | —       | —

Progress: 2/5 sections complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**🚦 GATE per section:** Do NOT proceed to next section until:
1. Section spec exists (`devflow/designs/<section>.md`) ✓
2. Data structure confirmed by user ✓
3. ALL artifacts created (models, mocks, factory, fixtures) ✓
4. User explicitly confirms ✓

**🚦 GATE for Step 9.4 completion:** ALL sections must have sample data before proceeding to Step 9.5.

---

#### Step 9.5: Design Screens — MANDATORY FOR EACH SECTION

**⛔ PREREQUISITE CHECK — MANDATORY BEFORE EACH SECTION**

For EACH section in the list, run `/design:design-screen <section>`

**Execution Pattern:**
```
for each section in section_list:
    1. VERIFY prerequisites exist:
       - devflow/designs/<section>.md (section spec)
       - src/app/models/<section>.models.ts (TypeScript types)
       - src/app/mocks/<section>.mock.ts (mock data)
       If ANY missing: STOP and list what's missing.
    2. Run /design:design-screen <section>
    3. VERIFY screen components created
    4. Get user confirmation
    5. Only then move to next section
```

**Purpose:** Create actual screen components with design tokens applied.

**Requirements per section:**
- Apply design tokens (colors, typography) to all components
- Create props-based components (portable, reusable)
- Import and use types from `<section>.models.ts`
- Use mock data from `<section>.mock.ts` for development
- Include all UI states (loading, error, empty, success)
- Mobile responsive using Tailwind breakpoints
- Light and dark mode support
- User must confirm each screen design

**Artifact Verification:**
```bash
# After each section, verify screen components exist
ls -la src/app/features/<section>/
# Should contain: component files, page files, routing
```

**Section Progress Tracker:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 DESIGN SCREENS PROGRESS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Section     | Spec | Types | Mocks | Screens | States
------------|------|-------|-------|---------|--------
[section-1] | ✅   | ✅    | ✅    | ✅      | loading/error/empty ✅
[section-2] | ✅   | ✅    | ✅    | ✅      | loading/error/empty ✅
[section-3] | ✅   | ✅    | ✅    | 🔄      | (in progress)
[section-4] | ✅   | ✅    | ✅    | ⏳      | —
[section-5] | ✅   | ✅    | ✅    | ⏳      | —

Progress: 2/5 sections complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**🚦 GATE per section:** Do NOT proceed to next section until:
1. All prerequisites exist (spec, types, mocks) ✓
2. Screen components created ✓
3. All UI states implemented (loading, error, empty) ✓
4. User explicitly confirms ✓

**🚦 GATE for Step 9.5 completion:** ALL sections must have screens before proceeding to Design Phase Summary.

---

#### Design Phase Summary

After completing all design steps (9.1-9.5), present:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ DESIGN PHASE COMPLETE: <name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Artifacts Created:
  ✓ Design Tokens:
    - tailwind.config.js (color palette, DaisyUI themes)
    - src/styles/tokens.css (CSS custom properties)
  ✓ Design Shell:
    - src/app/layout/ (shell components)
  ✓ Sections Shaped: [N] sections
    - devflow/designs/<section>.md (per section spec)
  ✓ Sample Data: [N] sections
    - src/app/models/<section>.models.ts (TypeScript interfaces)
    - src/app/mocks/<section>.mock.ts (mock data)
    - src/app/mocks/<section>.factory.ts (factory functions)
    - src/app/mocks/fixtures/<section>-*.json (JSON fixtures)
  ✓ Screen Designs: [N] component sets
    - src/app/features/<section>/ (per section)

Questions Answered:
  - Design Tokens: 11/11 ✓
  - Design Shell: 18/18 ✓
  - Sections: 17 × [N] = [total] ✓

These artifacts are ready for the Execution Phase.
No separate export step needed — artifacts in place.

All design decisions documented BEFORE implementation.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**🚦 CONFIRMATION REQUIRED:** Ask user to confirm design phase complete.

### Step 10: Epic Decompose

**FIRST: Load all upstream artifacts**
Read:
- `devflow/specs/<name>-plan.md` — Architecture, data model, API design (PRIMARY INPUT)
- `devflow/specs/<name>.md` — User stories, FRs for traceability
- `devflow/prds/<name>.md` — Original scope for context
- `devflow/designs/*.md` — Section UI specs (if created)

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
