# Product-dev-system

End-to-end product development system for Claude Code by AI LENS.

## What is it?

A command/agent system that orchestrates the full product development lifecycle using Claude Code. Structured commands for every phase — from brainstorming requirements to shipping code.

```
Phase A: Brainstorming (Human + AI)          Phase B: Execution (Agents)
PRD → Spec → Plan → Tasks                →   Build → Test → Review → Ship
```

## Installation

```bash
# 1. Clone this repo
git clone https://github.com/AI-LENS/Product-dev-system.git

# 2. Go to your project and run the installer
cd /path/to/your-project
bash /path/to/Product-dev-system/install/devflow.sh

# 3. Initialize in Claude Code
/devflow:init
```

**Windows:**
```cmd
git clone https://github.com/AI-LENS/Product-dev-system.git
cd C:\path\to\your-project
C:\path\to\Product-dev-system\install\devflow.bat
```

**What the installer does:**
- Checks prerequisites (Git, GitHub CLI, Python)
- Creates `.claude/` folder in your project
- Copies commands, rules, agents, scripts, templates

**To update:** Pull latest and re-run the installer.

## Prerequisites

| Tool | Required | Install |
|------|----------|---------|
| Git | Yes | [git-scm.com](https://git-scm.com/) |
| GitHub CLI (`gh`) | Yes | [cli.github.com](https://cli.github.com/) |
| Python 3.10+ | Yes | [python.org](https://www.python.org/) |
| Claude Code | Yes | [claude.ai/code](https://claude.ai/code) |

## Quick Start

```bash
# Run the full brainstorming phase
/devflow:kickstart my-app

# Or run steps individually
/devflow:init
/pm:prd-new my-feature
/pm:spec-create my-feature
/pm:plan my-feature
/pm:epic-decompose my-feature
```

## Tech Stack (Defaults)

| Layer | Technology |
|-------|-----------|
| Frontend | Angular + DaisyUI + Tailwind (or React) |
| Backend | Python + FastAPI |
| Database | PostgreSQL + SQLAlchemy + Alembic |
| AI | Multi-provider (Anthropic/OpenAI) |

## Two Phases

### Phase A: Brainstorming

| Step | Command | Output |
|------|---------|--------|
| Setup | `/devflow:init` | Config, dirs |
| PRD | `/pm:prd-new <name>` | Product requirements |
| Spec | `/pm:spec-create <name>` | Detailed spec |
| Plan | `/pm:plan <name>` | Technical plan |
| Tasks | `/pm:epic-decompose <name>` | Work items |
| Sync | `/pm:epic-sync <name>` | GitHub issues |

Or run all at once: `/devflow:kickstart <name>`

**Resumable:** If interrupted, run the same command again - it skips completed steps.

### Phase B: Execution

| Step | Command | What happens |
|------|---------|-------------|
| Bootstrap | `/init:project` | Scaffold project |
| Local Deploy | automatic | Start local servers |
| Build | `/pm:epic-start <name>` | Parallel agents |
| **Verify** | interactive | Check each feature locally |
| Test | `/testing:run` | Run tests |
| Quality | `/quality:security-check` | Security audit |
| **Docs** | Mintlify | Beginner-friendly docs |
| Review | `/review:pr-checklist` | PR review |
| Ship | `/deploy:setup` | Local + prod deployment |

Or run all at once: `/devflow:execute <name>`

**Elite workflow:** Build → Deploy locally → Verify feature → Repeat

**Resumable:** If interrupted, run the same command again - it checks task status and continues.

## Agents

| Agent | Purpose |
|-------|---------|
| `parallel-worker` | Coordinates parallel work |
| `code-analyzer` | Code analysis, bug hunting |
| `test-runner` | Test execution |
| `db-task-worker` | Database operations |
| `api-task-worker` | API endpoints |
| `ui-task-worker` | Frontend components |
| `ai-task-worker` | AI/LLM integration |

## Directory Structure

After installation, your project gets:

```
.claude/              # System files
├── commands/         # Slash commands
├── rules/            # Coding standards
├── agents/           # AI agents
├── scripts/          # Bash helpers
└── templates/        # Doc templates

devflow/              # Your artifacts
├── prds/             # Product requirements
├── specs/            # Specifications
├── epics/            # Tasks
├── context/          # Codebase context
└── adrs/             # Architecture decisions
```

## Recovering from Context Clear

If Claude Code asks to clear/compact and you lose context:

```bash
# 1. Reload project context
/context:prime

# 2. Resume your work
/devflow:kickstart <name>   # or
/devflow:execute <name>
```

Both commands detect existing artifacts and continue from where you left off.

**Tips to avoid context issues:**
- Run `/context:update` at the end of each session
- Use specific commands (`/pm:prd-new`) instead of long kickstart runs
- Check `/pm:status` to see current progress before resuming

## License

MIT — AI LENS
