# DevFlow Agents

DevFlow uses 8 specialized agents that work within Claude Code sessions. Each agent has a specific domain of expertise and operates within git worktrees for parallel execution.

## Agent Overview

| Agent | Color | Domain | Key Tools |
|-------|-------|--------|-----------|
| parallel-worker | green | Coordination | Task, Agent, Bash |
| code-analyzer | red | Bug hunting | Read, Grep, Search |
| file-analyzer | yellow | Summarization | Read, Grep |
| test-runner | blue | Testing | Bash, Read, Task |
| db-task-worker | cyan | Database | Bash, Read, Write |
| api-task-worker | blue | Backend API | Read, Write, Bash |
| ui-task-worker | purple | Frontend UI | Read, Write, Glob |
| ai-task-worker | purple | AI/LLM | Read, Write, Bash |

## Agent Details

### parallel-worker
**Role:** Orchestrates multiple sub-agents working on different parts of an issue simultaneously.

- Reads issue analysis to understand work streams
- Spawns sub-agents per stream (db, api, ui, etc.)
- Monitors completion and handles dependencies
- Consolidates results into a concise summary
- Shields the main thread from implementation details

### code-analyzer
**Role:** Deep code analysis for bug detection, logic tracing, and vulnerability identification.

- Reviews code changes for potential bugs
- Traces logic flow across multiple files
- Detects patterns: null refs, race conditions, resource leaks
- Outputs structured findings with severity and fix suggestions

### file-analyzer
**Role:** Extracts and summarizes critical information from files to reduce context usage.

- Analyzes log files, test outputs, verbose results
- Produces hierarchical summaries (80-90% token reduction)
- Preserves exact error messages and line numbers
- Groups related issues and quantifies patterns

### test-runner
**Role:** Executes tests and provides actionable failure analysis.

- Detects project type (Python/pytest, JS/Jest, Angular/Karma)
- Runs tests with verbose output and log capture
- Categorizes failures by severity
- Suggests specific fixes for each failure

### db-task-worker
**Role:** Implements database tasks — schema design, migrations, queries.

- Creates SQLAlchemy models following `devflow/rules/db-patterns.md`
- Generates Alembic migrations
- Optimizes queries (N+1 prevention, indexing)
- Creates seed data scripts

### api-task-worker
**Role:** Implements FastAPI backend tasks — endpoints, services, schemas.

- Creates complete vertical slices (router + service + schema + test)
- Follows `devflow/rules/api-design.md` and `devflow/rules/backend-patterns.md`
- Implements Pydantic request/response models
- Generates OpenAPI-documented endpoints

### ui-task-worker
**Role:** Implements frontend components with design system compliance.

- Supports Angular + DaisyUI and React + Tailwind
- Follows `devflow/rules/frontend-patterns.md` and `devflow/rules/design-standards.md`
- Ensures WCAG 2.1 AA accessibility compliance
- Creates components with loading, error, and empty states

### ai-task-worker
**Role:** Implements AI/LLM integration — prompts, providers, evaluation.

- Sets up multi-provider abstraction (Anthropic/OpenAI)
- Creates versioned prompt templates with test cases
- Implements structured output with Pydantic
- Builds evaluation pipelines and cost tracking

## How Agents Coordinate

Agents follow `devflow/rules/agent-coordination.md`:

1. **File-level parallelism** — Each agent works on assigned files only
2. **Atomic commits** — Small, focused commits per change
3. **Progress tracking** — Updates in `devflow/epics/{epic}/updates/`
4. **Conflict avoidance** — Agents stay in their lane
5. **Human escalation** — Merge conflicts always go to humans
