# DevFlow Architecture

## System Overview

DevFlow is a Claude Code command/agent system. It consists of markdown command files, agent definitions, rules, scripts, and templates that Claude Code executes within user sessions.

```
User Session
  └── Claude Code
       ├── Commands (devflow/commands/)   → Instructions Claude follows
       ├── Agents (devflow/agents/)       → Specialized sub-agents
       ├── Rules (devflow/rules/)         → Constraints and patterns
       ├── Scripts (devflow/scripts/)     → Bash automation
       └── Templates (devflow/templates/) → File scaffolds
```

## Installation Model

```
DevFlow Repo (source of truth)
  │
  │  install/devflow.sh
  │
  ├──→ Project A/.claude/   (copy of devflow/ contents)
  ├──→ Project B/.claude/   (copy of devflow/ contents)
  └──→ Project C/.claude/   (copy of devflow/ contents)
```

- Clone DevFlow once, keep it updated
- Run `install/devflow.sh` per project to copy into `.claude/`
- Each project gets its own independent copy

## Two-Phase Pipeline

```
┌──────────────────────────────────────────────────────────────────┐
│              PHASE A: BRAINSTORMING (Human + AI)                  │
│                                                                   │
│  Produces artifacts. Interactive. Sequential.                     │
│                                                                   │
│  /devflow:kickstart <feature>  (runs all steps below)            │
│                                                                   │
│  ┌──────┐   ┌──────┐   ┌──────┐   ┌────────┐   ┌───────┐       │
│  │ PRD  │──→│ Spec │──→│ Plan │──→│ Design │──→│ Tasks │       │
│  └──────┘   └──────┘   └──────┘   └────────┘   └───────┘       │
│                                                    │              │
│  Output: devflow/prds/  devflow/specs/  devflow/epics/           │
│          + GitHub Issues                                          │
└──────────────────────────────┬───────────────────────────────────┘
                               │ artifacts
┌──────────────────────────────▼───────────────────────────────────┐
│              PHASE B: EXECUTION (Agents)                          │
│                                                                   │
│  Consumes artifacts. Autonomous. Parallel.                        │
│                                                                   │
│  /devflow:execute <name>  (runs all steps below, optional)       │
│                                                                   │
│  ┌───────────┐   ┌──────┐   ┌─────────┐   ┌────────┐   ┌─────┐│
│  │ Bootstrap │──→│Build │──→│  Test   │──→│ Review │──→│Ship ││
│  └───────────┘   └──┬───┘   └─────────┘   └────────┘   └─────┘│
│                      │                                           │
│                      ├── db-task-worker                           │
│                      ├── api-task-worker                          │
│                      ├── ui-task-worker                           │
│                      └── ai-task-worker                           │
└──────────────────────────────────────────────────────────────────┘
```

## Artifact Flow

```
devflow/prds/{feature}.md          ← PRD (brainstormed)
    ↓
devflow/specs/{feature}.md         ← Spec (formalized)
    ↓
devflow/specs/{feature}-plan.md    ← Plan (technical)
    ↓
devflow/epics/{feature}/epic.md    ← Epic (container)
devflow/epics/{feature}/001.md     ← Tasks (work items)
devflow/epics/{feature}/002.md
    ↓
GitHub Issues                      ← Synced for tracking
    ↓
Git Worktree/Branch                ← Code changes
```

## Agent Coordination Model

```
Main Thread (user session)
  │
  ├── parallel-worker (coordinator)
  │     ├── db-task-worker ──→ models, migrations
  │     ├── api-task-worker ──→ endpoints, services
  │     ├── ui-task-worker ──→ components, pages
  │     └── ai-task-worker ──→ prompts, providers
  │
  ├── code-analyzer ──→ bug detection, review
  ├── file-analyzer ──→ log summarization
  └── test-runner ──→ test execution + analysis
```

Key coordination rules:
- Each agent works on assigned files only
- Agents commit independently to the same branch
- Conflicts are escalated to humans, never auto-resolved
- Progress tracked in `devflow/epics/{epic}/updates/`

## Tech Stack Defaults

```
Frontend (Primary)          Frontend (Secondary)
┌───────────────────┐      ┌───────────────────┐
│ Angular           │      │ React              │
│ DaisyUI           │      │ Tailwind           │
│ Tailwind CSS      │      │ Zustand            │
│ NgRx              │      │ React Hook Form    │
└───────────────────┘      └───────────────────┘

Backend (Always)            Database (Default)
┌───────────────────┐      ┌───────────────────┐
│ Python 3.10+      │      │ PostgreSQL 16      │
│ FastAPI           │      │ SQLAlchemy         │
│ Pydantic          │      │ Alembic            │
│ uvicorn           │      │ asyncpg            │
└───────────────────┘      └───────────────────┘

AI Layer (Optional)
┌───────────────────┐
│ Anthropic Claude  │
│ OpenAI GPT        │
│ Pydantic schemas  │
│ Cost tracking     │
└───────────────────┘
```

## Rules System

Rules are constraints that commands and agents must follow:

| Category | Rules |
|----------|-------|
| Core | standard-patterns, datetime, frontmatter-operations, path-standards, strip-frontmatter |
| Git | github-operations, worktree-operations, branch-operations, agent-coordination |
| PM | spec-standards, principles-standards, adr-patterns |
| Backend | api-design, backend-patterns, db-patterns, env-management |
| Frontend | frontend-patterns, design-standards |
| AI | ai-patterns |
| Security | security-baseline, auth-patterns |
| Quality | testing-strategy, test-patterns, test-execution |
| DevOps | deploy-patterns, observability, review-workflow, integration-patterns |

## Design Decisions

1. **Template repo** — DevFlow is installed into projects via `install/devflow.sh`, not vendored as a dependency
2. **Two-phase pipeline** — Brainstorming (human-driven, produces artifacts) is cleanly separated from Execution (agent-driven, consumes artifacts)
3. **Markdown-based** — All commands, rules, and agents are markdown files read by Claude Code
4. **Bash scripts** — Simple automation for status, listing, and initialization
5. **YAML frontmatter** — Metadata on all files for parsing and status tracking
6. **Worktree-based parallelism** — Multiple agents work in separate worktrees for isolation
7. **Python + FastAPI always** — Non-negotiable backend choice for consistency
8. **Template repo protection** — All GitHub write operations check against the template repo
