# DevFlow by AI LENS

End-to-end product development system for Claude Code. Standalone repo. Zero external dependencies.

## What is DevFlow?

DevFlow is a command/agent system that orchestrates the full product development lifecycle using Claude Code. It provides structured commands for every phase — from brainstorming product requirements to shipping production code.

The pipeline is split into two clear phases:

```
Phase A: Brainstorming (Human + AI)     Phase B: Execution (Agents)
PRD → Spec → Plan → Design → Tasks  →  Build → Test → Review → Ship
         artifacts produced here     →  agents consume artifacts here
```

## Installation Model

DevFlow is a **template repo**. You clone it once, then install into each project.

```bash
# 1. Clone DevFlow (once — this is your source of truth)
git clone https://github.com/AI-LENS/Product-dev-system.git ~/devflow

# 2. Go to your project
cd /path/to/your-project

# 3. Install DevFlow into your project's .claude/ directory
bash ~/devflow/install/devflow.sh

# 4. Initialize
/devflow:init
```

**How it works:**
- `install/devflow.sh` copies commands, rules, agents, scripts, and templates into your project's `.claude/` directory
- Each project gets its own copy of DevFlow files
- To update: pull latest in the DevFlow repo, re-run the installer
- You do NOT copy the entire DevFlow repo into each project

## Opinionated Defaults

| Layer | Technology |
|-------|-----------|
| Frontend (primary) | Angular + DaisyUI + Tailwind |
| Frontend (secondary) | React + Tailwind |
| Backend | Python + FastAPI |
| Database | PostgreSQL + SQLAlchemy + Alembic |
| AI Layer | Multi-provider (Anthropic/OpenAI) |

## Quick Start

```bash
# Option A: Run the full brainstorming phase in one command
/devflow:kickstart my-app          # asks: product, feature, or library?

# Option B: Run steps individually
/devflow:init
/pm:prd-new my-feature
/pm:spec-create my-feature
/pm:plan my-feature
/pm:epic-decompose my-feature
/pm:epic-sync my-feature
```

### Scope Selector

Kickstart adapts the entire pipeline based on what you're building:

| Scope | PRD captures | Spec captures | Design | Example |
|-------|-------------|---------------|--------|---------|
| **Product** | Vision, market, feature set | Feature priority matrix, user stories | Yes | "Build a SaaS dashboard" |
| **Feature** | Problem, users, value prop | Given/When/Then stories, entities | Ask | "Add team invitations" |
| **Library** | Purpose, consumers, API surface | API contracts, schemas, error taxonomy | Skip | "Build a caching SDK" |

## Two-Phase Pipeline

### Phase A: Brainstorming (Human + AI collaboration)

Goal: Produce all planning artifacts needed for agents to execute autonomously.

**Input:** A feature idea (string)
**Output:** Complete artifact set — PRD, spec, plan, tasks, GitHub issues, design (optional)

| Step | Command | Output |
|------|---------|--------|
| Setup | `/devflow:init` | Config, dirs, labels |
| Principles | `/devflow:principles` | Immutable project rules |
| Context | `/context:create` | Codebase baseline |
| PRD | `/pm:prd-new <feature>` | `devflow/prds/<feature>.md` |
| Spec | `/pm:spec-create <feature>` | `devflow/specs/<feature>.md` |
| Clarify | `/pm:spec-clarify <feature>` | Updated spec |
| Analyze | `/pm:spec-analyze <feature>` | Consistency report |
| Plan | `/pm:plan <feature>` | `devflow/specs/<feature>-plan.md` |
| Design | `/design:*` (optional) | Design tokens, shells, screens |
| Decompose | `/pm:epic-decompose <feature>` | `devflow/epics/<feature>/*.md` |
| Sync | `/pm:epic-sync <feature>` | GitHub issues |

Or run the entire phase with one command: **`/devflow:kickstart <feature>`**

### Phase B: Execution (Agents work autonomously)

Goal: Agents consume artifacts from Phase A and build/test/ship.

**Input:** Artifacts from Phase A
**Output:** Working code, tests, deployable system

| Step | Command | What happens |
|------|---------|-------------|
| Bootstrap | `/init:project` | Scaffold (product scope only) |
| Build | `/pm:epic-start <name>` | Parallel agents in worktrees |
| Test | `/testing:run` | Execute test suite |
| Quality | `/quality:security-check` | OWASP audit |
| Review | `/review:pr-checklist` | PR review |
| Ship | `/deploy:setup` | CI/CD pipeline |

Or run the entire phase with one command: **`/devflow:execute <name>`**

Execute is optional — it asks before each step and you can skip any. It reads the scope from your PRD frontmatter and adapts (e.g., library skips bootstrap and UI workers, product runs full infra).

### Ongoing Commands

| Command | Description |
|---------|-------------|
| `/context:update` | Refresh context docs |
| `/context:prime` | Load context in new sessions |
| `/pm:status` | Project dashboard |
| `/pm:next` | Next priority task |
| `/pm:standup` | Daily standup report |
| `/pm:validate` | System integrity check |
| `/pm:search <query>` | Search across all artifacts |

## Directory Structure

```
devflow/
├── agents/          # 8 specialized agents
├── commands/        # 13 command groups, 50+ commands
│   ├── devflow/     # System commands (init, principles, kickstart)
│   ├── pm/          # PRD, spec, plan, epic, issue lifecycle
│   ├── context/     # Session context management
│   ├── design/      # Visual design phase
│   ├── init/        # Project bootstrap
│   ├── arch/        # Architecture decisions
│   ├── db/          # Database operations
│   ├── api/         # API scaffolding
│   ├── ai/          # AI/LLM tooling
│   ├── testing/     # Test execution
│   ├── quality/     # Linting, security
│   ├── deploy/      # CI/CD, Docker
│   └── review/      # PR review, release
├── rules/           # 27 rule files
├── scripts/         # Bash helpers
├── hooks/           # Git worktree hooks
├── skills/          # Claude Code skills
├── templates/       # Document templates
├── context/         # Project context docs
├── epics/           # Epic tracking
├── prds/            # Product requirements
├── specs/           # Specifications
└── adrs/            # Architecture decisions
```

## Agents

| Agent | Specialization |
|-------|---------------|
| `parallel-worker` | Coordinates parallel work streams in worktrees |
| `code-analyzer` | Deep-dive code analysis and bug hunting |
| `file-analyzer` | Log/file summarization for context efficiency |
| `test-runner` | Test execution and failure analysis |
| `db-task-worker` | Database schema, migrations, queries |
| `api-task-worker` | FastAPI endpoints, services, schemas |
| `ui-task-worker` | Frontend components, accessibility |
| `ai-task-worker` | AI/LLM integration, prompts, evaluation |

## Prerequisites

- Git
- GitHub CLI (`gh`)
- Python 3.10+
- Claude Code

## License

MIT License — Copyright (c) 2025 AI LENS
# product-dev-system
