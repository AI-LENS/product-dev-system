# Changelog

All notable changes to DevFlow are documented in this file.

## [1.0.0] - 2025-01-01

### Added

#### Foundation
- Project structure with `devflow/` directory layout
- `devflow.config` — repository detection and GitHub CLI integration
- `settings.json.example` and `settings.local.json` — Claude Code configuration
- `install/devflow.sh` and `install/devflow.bat` — cross-platform installers
- `hooks/bash-worktree-fix.sh` — automatic worktree path injection
- `scripts/common/common.sh` — shared bash utilities

#### PM Pipeline (30 commands)
- PRD workflow: `prd-new`, `prd-list`, `prd-edit`, `prd-status`
- Spec workflow: `spec-create`, `spec-clarify`, `spec-analyze`
- Planning: `plan`, `principles`
- Epic management: `epic-decompose`, `epic-sync`, `epic-show`, `epic-start`, `epic-list`, `epic-status`, `epic-close`
- Issue management: `issue-show`, `issue-start`, `issue-sync`, `issue-close`
- Workflow: `status`, `next`, `blocked`, `in-progress`, `standup`, `validate`, `help`, `search`, `code-rabbit`
- Context: `create`, `update`, `prime`

#### Architecture (3 commands)
- `adr-new`, `adr-list`, `stack-audit`

#### Design (6 commands)
- `design-tokens`, `design-shell`, `shape-section`, `sample-data`, `design-screen`, `export`

#### Project Bootstrap (5 commands)
- `project`, `database`, `auth`, `ai`, `deploy`

#### Database (3 commands)
- `migrate`, `seed`, `schema-check`

#### API (1 command)
- `scaffold` — FastAPI endpoint generation

#### AI/LLM (3 commands)
- `prompt-new`, `eval-run`, `cost-report`

#### Testing (6 commands)
- `prime`, `run`, `coverage`, `e2e-setup`, `perf`, `ai-eval`

#### Quality (2 commands)
- `lint-setup`, `security-check`

#### Review (3 commands)
- `pr-checklist`, `release`, `incident`

#### Deploy (3 commands)
- `setup`, `docker`, `env-check`

#### Agents (8 total)
- `parallel-worker`, `code-analyzer`, `file-analyzer`, `test-runner`
- `db-task-worker`, `api-task-worker`, `ui-task-worker`, `ai-task-worker`

#### Rules (27 total)
- Core: standard-patterns, datetime, frontmatter-operations, path-standards, strip-frontmatter
- Git: github-operations, worktree-operations, branch-operations, agent-coordination
- PM: spec-standards, principles-standards, adr-patterns
- Backend: api-design, backend-patterns, db-patterns, env-management
- Frontend: frontend-patterns, design-standards
- AI: ai-patterns
- Security: security-baseline, auth-patterns
- Quality: testing-strategy, test-patterns, test-execution
- DevOps: deploy-patterns, observability, review-workflow, integration-patterns

#### Templates (11 total)
- spec-template, plan-template, task-template, principles-template, checklist-template
- adr-template
- ci-template.yml, Dockerfile-template, docker-compose-template.yml
- rag-template, agent-template, classifier-template

#### Skills
- `frontend-design` — visual design skill for Claude Code
