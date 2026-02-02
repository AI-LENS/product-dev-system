# DevFlow by AI LENS

End-to-end product development system for Claude Code. Standalone repo. Zero external dependencies.

## What is DevFlow?

DevFlow is a command/agent system that orchestrates the full product development lifecycle using Claude Code. It provides structured commands for every phase — from brainstorming product requirements to shipping production code.

The pipeline is split into two clear phases, with **quality gates** at every transition:

```
Phase A: Brainstorming (Human + AI)          Phase B: Execution (Agents)
PRD → G → Spec → G → Plan → G → Tasks → G → Build → G → Test → G → Review → G → Ship
              G = quality gate                    agents consume artifacts here
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

## Quality Gates

Every artifact-producing step passes through a quality gate before the pipeline advances. Gates prevent bad artifacts from propagating downstream.

### How Gates Work

```
/devflow:gate <gate-name> <feature-name>
```

Each gate reads the subject artifact and all upstream artifacts, runs checks, performs a pre-mortem analysis, validates traceability, and produces a verdict.

### Verdicts

| Verdict | Meaning | Pipeline Effect |
|---------|---------|-----------------|
| **PASS** | All checks satisfied | Continue. Near-silent output. |
| **CONCERN** | Non-critical issues found | User decides: proceed, iterate, or deep-dive. |
| **BLOCK** | Critical issue that will cause downstream failure | Pipeline halts. Must fix and re-run. |

### Gate Modes

Configured via `gate_mode` in `devflow/devflow.config`:

| Mode | BLOCK behavior | CONCERN behavior |
|------|---------------|-----------------|
| `strict` | Mandatory halt. No override. | Shown, user decides. |
| `standard` (default) | Must provide written rationale to override. Rationale logged. | Shown, user decides. |
| `permissive` | Downgraded to CONCERN. All advisory. | Shown, user decides. |

### Gate Catalog

**Phase A gates** (planning artifact quality):

| Gate | Validates | Key Checks |
|------|-----------|-----------|
| `gate:prd` | PRD completeness | Problem specificity, concrete personas, non-empty out-of-scope, honest constraints, falsifiable value prop |
| `gate:spec` | Spec traceability | PRD features → US mappings, testable acceptance criteria, sane priority distribution, entity consistency |
| `gate:plan` | Architecture coverage | FR coverage in plan sections, rationale on decisions, data model completeness, honest risk assessment |
| `gate:epic` | Task decomposition | Plan sections → task mappings, `traces_to` fields, DAG validation, parallel file isolation, no orphaned sections |

**Phase B gates** (execution quality):

| Gate | Validates | Key Checks |
|------|-----------|-----------|
| `gate:bootstrap` | Project scaffolding | Server starts, DB connects, pytest discovers tests, structure matches plan, `.env.example` documented |
| `gate:task` | Individual task completion | Acceptance criteria met with evidence, tests pass, pattern compliance, no orphan TODOs |
| `gate:build` | Aggregate code quality | All tasks complete, full test suite passes, cross-task integration, no merge conflicts |
| `gate:test` | Test coverage | >= 80% coverage on new code, zero failures, no flaky tests, edge cases covered |
| `gate:quality` | Code standards | Zero lint errors, zero high/critical security findings, no secrets in codebase |
| `gate:review` | Release readiness | All checklist items addressed, no unresolved comments, breaking changes documented |

### Traceability Chain

Gates validate end-to-end requirement traceability:

```
PRD Feature → US-xxx (Spec) → FR-xxx (Spec) → Plan Section → Task (traces_to: FR-xxx) → Code
```

- **Forward orphan** (requirement with no implementation) = **BLOCK**
- **Backward orphan** (implementation with no requirement) = **CONCERN**

### Pre-Mortem Protocol

Each gate generates 3-5 failure scenarios asking: *"What would make this fail in production?"*

- Unmitigated + HIGH impact = **BLOCK**
- Unmitigated + MEDIUM/LOW impact = **CONCERN**

### Gate Logging

Results are appended to artifact frontmatter under the `gates:` key, creating an audit trail:

```yaml
gates:
  - gate: prd
    verdict: PASS
    timestamp: 2025-01-15T10:30:00Z
    concerns: []
    blocks: []
```

Re-running a gate appends a new entry (does not overwrite).

---

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
| **Gate: PRD** | `/devflow:gate prd <feature>` | Verdict: PASS / CONCERN / BLOCK |
| Spec | `/pm:spec-create <feature>` | `devflow/specs/<feature>.md` |
| **Gate: Spec** | `/devflow:gate spec <feature>` | Verdict: PASS / CONCERN / BLOCK |
| Clarify | `/pm:spec-clarify <feature>` | Updated spec |
| Analyze | `/pm:spec-analyze <feature>` | Consistency report |
| Plan | `/pm:plan <feature>` | `devflow/specs/<feature>-plan.md` |
| **Gate: Plan** | `/devflow:gate plan <feature>` | Verdict: PASS / CONCERN / BLOCK |
| Design | `/design:*` (optional) | Design tokens, shells, screens |
| Decompose | `/pm:epic-decompose <feature>` | `devflow/epics/<feature>/*.md` |
| **Gate: Epic** | `/devflow:gate epic <feature>` | Verdict: PASS / CONCERN / BLOCK |
| Sync | `/pm:epic-sync <feature>` | GitHub issues |

Or run the entire phase with one command: **`/devflow:kickstart <feature>`**

### Phase B: Execution (Agents work autonomously)

Goal: Agents consume artifacts from Phase A and build/test/ship.

**Input:** Artifacts from Phase A
**Output:** Working code, tests, deployable system

| Step | Command | What happens |
|------|---------|-------------|
| Bootstrap | `/init:project` | Scaffold (product scope only) |
| **Gate: Bootstrap** | `/devflow:gate bootstrap <name>` | Verify scaffold works |
| Build | `/pm:epic-start <name>` | Parallel agents in worktrees |
| **Gate: Task** | `/devflow:gate task <name>` | Per-task validation during build |
| **Gate: Build** | `/devflow:gate build <name>` | Aggregate build validation |
| Test | `/testing:run` | Execute test suite |
| **Gate: Test** | `/devflow:gate test <name>` | Coverage and pass-rate check |
| Quality | `/quality:security-check` | OWASP audit + linting |
| **Gate: Quality** | `/devflow:gate quality <name>` | Zero errors, zero secrets |
| Review | `/review:pr-checklist` | PR review |
| **Gate: Review** | `/devflow:gate review <name>` | Release readiness check |
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
│   ├── devflow/     # System commands (init, principles, kickstart, gate)
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
├── rules/           # 27+ rule files (includes elite-dev-protocol)
├── scripts/         # Bash helpers
├── hooks/           # Git worktree hooks
├── skills/          # Claude Code skills
├── templates/       # Document templates (includes gate report template)
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
