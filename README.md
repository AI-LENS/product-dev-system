# DevFlow by AI LENS

End-to-end product development system for Claude Code.

## What It Does

Orchestrates the full product lifecycle — from brainstorming to shipping — using structured commands and AI agents.

```
Brainstorming (Human + AI)              Execution (Agents)
─────────────────────────────────────────────────────────────
PRD → Spec → Plan → Design → Tasks  →  Build → Test → Ship
         ↓                                    ↓
    Quality Gates                      Mandatory Testing
```

## Quick Start

```bash
# 1. Clone this repo
git clone https://github.com/AI-LENS/Product-dev-system.git

# 2. Go to your project and run installer
cd /path/to/your-project
bash /path/to/Product-dev-system/install/devflow.sh

# 3. Initialize in Claude Code
/devflow:init

# 4. Start building
/devflow:kickstart my-app
```

## Two Phases

### Phase A: Brainstorming

```bash
/devflow:kickstart my-app
```

This runs:
1. **PRD** — Define problem, users, features (with probe questions)
2. **Spec** — User stories with Given/When/Then acceptance criteria
3. **Plan** — Architecture, data model, API design
4. **ADRs** — Record architectural decisions
5. **Design** — UI tokens, shell, screen specs (if applicable)
6. **Tasks** — Break into parallelizable work items

Each step has a **quality gate** that must pass before proceeding.

### Phase B: Execution

```bash
/devflow:execute my-app
```

This runs:
1. **Bootstrap** — Scaffold project (product scope)
2. **Build** — Phase by phase, full-stack (DB + API + UI per feature)
3. **Test** — Unit, integration, E2E, regression after each phase
4. **Quality** — Lint, security, ADR compliance
5. **Docs** — Mintlify documentation
6. **Ship** — CI/CD, Docker, deployment

**Key principle:** Each phase is a complete feature (not just DB, then all API, then all UI). This enables end-to-end testing per phase.

## Testing Requirements

Every phase must pass before proceeding:

| Test Type | When | Threshold |
|-----------|------|-----------|
| Unit | After each task | 80% coverage |
| Integration | After each feature | All endpoints |
| E2E | After each phase | All acceptance criteria |
| Regression | After each phase | 100% previous tests pass |

## Tech Stack (Defaults)

| Layer | Technology |
|-------|-----------|
| Frontend | Angular 19+ / React + Tailwind + DaisyUI |
| Backend | Python + FastAPI |
| Database | PostgreSQL + SQLAlchemy + Alembic |
| Auth | JWT with refresh tokens |

## Directory Structure

After installation:

```
your-project/
├── .claude/              # System (commands, rules, agents)
│   ├── commands/         # Slash commands
│   ├── rules/            # Coding standards
│   ├── agents/           # AI agents
│   └── templates/        # Doc templates
│
└── devflow/              # Your artifacts
    ├── prds/             # Product requirements
    ├── specs/            # Specifications + plans
    ├── epics/            # Tasks
    ├── adrs/             # Architecture decisions
    ├── design/           # UI specs (tokens, shell, sections)
    └── context/          # Codebase context
```

## Key Commands

| Command | Purpose |
|---------|---------|
| `/devflow:kickstart <name>` | Run full brainstorming phase |
| `/devflow:execute <name>` | Run full execution phase |
| `/pm:status` | Check project progress |
| `/arch:adr-new "decision"` | Create architecture decision |
| `/context:prime` | Reload context after interruption |

## Resumable

Both phases are resumable. If interrupted:

```bash
# Just run the same command again
/devflow:kickstart my-app   # Skips completed steps
/devflow:execute my-app     # Continues from last phase
```

## Prerequisites

| Tool | Required |
|------|----------|
| Git | Yes |
| GitHub CLI (`gh`) | Yes |
| Python 3.10+ | Yes |
| Claude Code | Yes |

## Acknowledgments

Shoutout to [DesignOS](https://github.com/designos) and [SpecKit](https://github.com/speckit) for the inspiration and some components that influenced this project.

## License

MIT — AI LENS
