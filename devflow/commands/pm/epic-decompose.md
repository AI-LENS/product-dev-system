---
allowed-tools: Bash, Read, Write, LS, Task, AskUserQuestion
---

# Epic Decompose

Break plan into parallelizable, actionable tasks.

## Usage
```
/pm:epic-decompose <feature_name>
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/datetime.md` - For getting real current date/time

## Preflight Checklist

Before proceeding, complete these validation steps.
Do not bother the user with preflight checks progress. Just do them and move on.

1. **Verify plan or spec exists:**
   - Check if `devflow/specs/$ARGUMENTS-plan.md` exists (preferred)
   - If no plan, check if `devflow/specs/$ARGUMENTS.md` exists
   - If neither found, tell user: "Plan/Spec not found: $ARGUMENTS. Create it first with: /pm:plan $ARGUMENTS"
   - Stop execution if neither exists

2. **Verify or create epic directory:**
   - Check if `devflow/epics/$ARGUMENTS/` directory exists
   - If not, create it: `mkdir -p devflow/epics/$ARGUMENTS/`

3. **Check for existing tasks:**
   - Check if any numbered task files (001.md, 002.md, etc.) already exist in `devflow/epics/$ARGUMENTS/`
   - If tasks exist, list them and ask: "Found {count} existing tasks. Delete and recreate all tasks? (yes/no)"
   - Only proceed with explicit 'yes' confirmation
   - If user says no, suggest: "View existing tasks with: /pm:epic-show $ARGUMENTS"

4. **Get Current DateTime:**
   - Run: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

## Instructions

You are decomposing a plan/spec into specific, actionable tasks for: **$ARGUMENTS**

### 1. Read the Plan/Spec

- Load the plan from `devflow/specs/$ARGUMENTS-plan.md` (or spec if no plan)
- Load the spec from `devflow/specs/$ARGUMENTS.md`
- Understand the architecture, data model, API design, and project structure
- Review functional requirements (FR-xxx) and their priorities

### 2. Create Epic File

Create `devflow/epics/$ARGUMENTS/epic.md`:

```markdown
---
name: $ARGUMENTS
status: planning
created: [Current ISO date/time]
updated: [Current ISO date/time]
github:
progress: 0%
prd: devflow/prds/$ARGUMENTS.md
spec: devflow/specs/$ARGUMENTS.md
plan: devflow/specs/$ARGUMENTS-plan.md
---

# Epic: [Feature Name]

## Overview
[Brief description from spec/plan]

## Technical Approach
[Summary of architecture decisions from plan]

## Task Breakdown Preview
[High-level list of task categories]
```

### 2b. Task Decomposition Strategy — PROBE QUESTIONING (MANDATORY)

**CRITICAL:** Task breakdown affects development velocity. Validate approach with user using AskUserQuestion.

#### Phase 1: Scope Confirmation

**Question 1: Development Phases**
> Based on the plan, I can organize work as:
>
> **Option A: Feature-based phases** (Recommended for most projects)
> - Phase 1: Auth (DB + API + UI for auth)
> - Phase 2: Core Feature (full stack for core)
> - Phase 3: Secondary Features
> - Each phase is independently testable
>
> **Option B: Layer-based phases** (Faster initial setup)
> - Phase 1: All DB/Models
> - Phase 2: All API endpoints
> - Phase 3: All UI components
> - Harder to test until all layers complete
>
> Which approach?
> - Feature-based phases (Recommended)
> - Layer-based phases
> - Hybrid (mix based on dependencies)

**Question 2: Task Granularity**
> How granular should tasks be?
> - Fine (1-2 hours each, many tasks) - Better for tracking, more overhead
> - Medium (4-8 hours each) - Balanced (Recommended)
> - Coarse (1-2 days each, fewer tasks) - Less tracking, faster to create

**Question 3: Testing Strategy per Task**
> How should tests be included?
> - Each task includes its own tests (Recommended - TDD friendly)
> - Separate testing tasks after implementation
> - Testing phase at the end

#### Phase 2: Feature Priority Confirmation

**Question 4: Feature Order**
> Based on dependencies, I suggest this build order:
>
> 1. [Feature A] - Foundation, required by others
> 2. [Feature B] - Core functionality
> 3. [Feature C] - Depends on A
> 4. [Feature D] - Can be parallel with C
>
> Is this order correct?
> - Yes, proceed with this order
> - Reorder (specify changes)
> - Some features can be skipped for MVP

**Question 5: MVP Scope**
> For initial implementation, should we:
> - Build everything in plan (full scope)
> - P1 features only (MVP)
> - P1 + specific P2 features (specify which)

#### Phase 3: Task Validation Preview

After creating draft tasks, present summary:

**Question 6: Task Review**
> Here are the draft tasks:
>
> **Phase 1: [Feature] ([N] tasks)**
> - Task 001: [Title] - [Effort]
> - Task 002: [Title] - [Effort]
> ...
>
> **Phase 2: [Feature] ([N] tasks)**
> ...
>
> **Total: [N] tasks, ~[X] hours estimated**
>
> Review and confirm:
> - Looks good, create all tasks
> - Break down [specific task] further
> - Combine [these tasks] into one
> - Remove/defer [specific tasks]

### 3. Analyze for Parallel Creation

Determine task grouping strategy:
- **Database/Model tasks:** Schema, models, migrations (often first)
- **API/Service tasks:** Endpoints, business logic (depends on models)
- **Frontend tasks:** Components, pages, state (depends on API)
- **Testing tasks:** Unit, integration, e2e (can parallel with impl)
- **Infrastructure tasks:** Docker, CI/CD, deployment (often parallel)
- **Documentation tasks:** API docs, README (often last)

### 4. Create Task Files

For each task, create a file: `devflow/epics/$ARGUMENTS/{number}.md`

```markdown
---
name: [Task Title]
status: open
created: [Current ISO date/time]
updated: [Current ISO date/time]
github:
depends_on: []
parallel: true
conflicts_with: []
---

# Task: [Task Title]

## Description
Clear, concise description of what needs to be done.

## Acceptance Criteria
- [ ] Specific criterion 1
- [ ] Specific criterion 2
- [ ] Specific criterion 3

## Technical Details
- Implementation approach
- Key considerations
- Code locations/files affected
- Relevant FRs: FR-001, FR-002

## Dependencies
- [ ] Task/Issue dependencies
- [ ] External dependencies

## Effort Estimate
- Size: XS/S/M/L/XL
- Hours: estimated hours
- Parallel: true/false

## Definition of Done
- [ ] Code implemented
- [ ] Tests written and passing
- [ ] Documentation updated
- [ ] Code reviewed
```

### 5. Task Naming Convention
Save tasks as: `devflow/epics/$ARGUMENTS/{task_number}.md`
- Use sequential numbering: 001.md, 002.md, etc.
- Keep task titles short but descriptive

### 6. Frontmatter Guidelines
- **name**: Descriptive task title (without "Task:" prefix)
- **status**: Always start with "open" for new tasks
- **created/updated**: REAL datetime from `date -u +"%Y-%m-%dT%H:%M:%SZ"`
- **github**: Leave empty -- updated during sync
- **depends_on**: List task numbers that must complete first, e.g., [001, 002]
- **parallel**: true if this can run alongside other tasks without conflicts
- **conflicts_with**: Task numbers that modify the same files

### 7. Task Types to Consider
- **Setup tasks**: Environment, dependencies, scaffolding
- **Data tasks**: SQLAlchemy models, Alembic migrations, seed data
- **API tasks**: FastAPI endpoints, Pydantic schemas, services
- **Auth tasks**: JWT implementation, middleware, permissions
- **UI tasks**: Components, pages, styling, state management
- **Testing tasks**: Unit tests, integration tests, fixtures
- **Documentation tasks**: API docs, README, deployment guide
- **Infrastructure tasks**: Docker, CI/CD, environment config

### 8. Parallelization Strategy

Mark tasks with `parallel: true` if they can be worked on simultaneously.

**Typical parallel groups:**
- Group A: Database models + migrations (sequential within group)
- Group B: API endpoints (parallel with each other, depends on Group A)
- Group C: Frontend components (parallel with each other, depends on Group B)
- Group D: Tests (parallel with implementation)
- Group E: Docker + CI/CD (parallel with everything)

### 9. Execution Strategy

Choose based on task count and complexity:

**Small Epic (< 5 tasks)**: Create sequentially
**Medium Epic (5-10 tasks)**: Batch into 2-3 groups, spawn agents per batch
**Large Epic (> 10 tasks)**: Analyze dependencies, group independent tasks, launch parallel agents (max 5 concurrent)

### 10. Update Epic with Task Summary

After creating all tasks, update the epic file:

```markdown
## Tasks Created
- [ ] 001.md - {Task Title} (parallel: true/false)
- [ ] 002.md - {Task Title} (parallel: true/false)
- etc.

Total tasks: {count}
Parallel tasks: {parallel_count}
Sequential tasks: {sequential_count}
Estimated total effort: {sum of hours}
```

### 11. Quality Validation

Before finalizing tasks, verify:
- [ ] All tasks have clear acceptance criteria
- [ ] Task sizes are reasonable (1-3 days each)
- [ ] Dependencies are logical and achievable
- [ ] Parallel tasks don't conflict with each other
- [ ] Combined tasks cover all spec FRs
- [ ] No circular dependencies exist

### 12. Post-Decomposition

After successfully creating tasks:
1. Confirm: "Created {count} tasks for epic: $ARGUMENTS"
2. Show summary:
   - Total tasks created
   - Parallel vs sequential breakdown
   - Total estimated effort
   - Dependency graph overview
3. Suggest next step: "Ready to sync to GitHub? Run: /pm:epic-sync $ARGUMENTS"

## Error Recovery

If any step fails:
- If task creation partially completes, list which tasks were created
- Provide option to clean up partial tasks
- Never leave the epic in an inconsistent state

Aim for tasks that can be completed in 1-3 days each. Break down larger tasks into smaller, manageable pieces for the "$ARGUMENTS" epic.
