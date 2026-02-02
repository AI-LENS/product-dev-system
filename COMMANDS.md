# DevFlow Command Reference

Complete reference for all DevFlow commands organized by pipeline phase.

## Phase A: Brainstorming (Human + AI collaboration)

These commands produce planning artifacts. Run sequentially, or use `/devflow:kickstart` to run them all. Kickstart asks for scope (product / feature / library) and adapts each step accordingly.

### System Commands (`/devflow:*`)

| Command | Usage | Description |
|---------|-------|-------------|
| `/devflow:init` | `/devflow:init` | Initialize DevFlow (dirs, labels, GitHub auth) |
| `/devflow:principles` | `/devflow:principles` | Define immutable project principles |
| `/devflow:kickstart` | `/devflow:kickstart <name>` | Run entire Brainstorming Phase (asks scope: product/feature/library) |
| `/devflow:execute` | `/devflow:execute <name>` | Run entire Execution Phase (optional — asks before each step) |

### Context Commands (`/context:*`)

| Command | Usage | Description |
|---------|-------|-------------|
| `/context:create` | `/context:create` | Generate baseline context docs |
| `/context:update` | `/context:update` | Refresh context with changes |
| `/context:prime` | `/context:prime` | Load context in new sessions |

### PRD Management (`/pm:prd-*`)

| Command | Usage | Description |
|---------|-------|-------------|
| `/pm:prd-new` | `/pm:prd-new <feature>` | Brainstorm and create PRD |
| `/pm:prd-list` | `/pm:prd-list` | List all PRDs |
| `/pm:prd-edit` | `/pm:prd-edit <feature>` | Edit existing PRD |
| `/pm:prd-status` | `/pm:prd-status` | Show PRD statuses |

### Spec Management (`/pm:spec-*`)

| Command | Usage | Description |
|---------|-------|-------------|
| `/pm:spec-create` | `/pm:spec-create <feature>` | Formalize PRD into structured spec |
| `/pm:spec-clarify` | `/pm:spec-clarify <feature>` | Resolve ambiguities (max 5 Q&A) |
| `/pm:spec-analyze` | `/pm:spec-analyze <feature>` | Cross-artifact consistency check |

### Planning (`/pm:plan`)

| Command | Usage | Description |
|---------|-------|-------------|
| `/pm:plan` | `/pm:plan <feature>` | Spec → technical plan |

### Architecture Commands (`/arch:*`)

| Command | Usage | Description |
|---------|-------|-------------|
| `/arch:adr-new` | `/arch:adr-new <decision>` | Record architecture decision |
| `/arch:adr-list` | `/arch:adr-list` | List all ADRs |
| `/arch:stack-audit` | `/arch:stack-audit` | Verify tech stack health |

### Design Commands (`/design:*`)

| Command | Usage | Description |
|---------|-------|-------------|
| `/design:design-tokens` | `/design:design-tokens` | Create design token system |
| `/design:design-shell` | `/design:design-shell` | Design app shell layout |
| `/design:shape-section` | `/design:shape-section <section>` | Per-section UI spec |
| `/design:sample-data` | `/design:sample-data <section>` | Mock data + interfaces |
| `/design:design-screen` | `/design:design-screen <section>` | Build screen components |
| `/design:export` | `/design:export` | Generate handoff package |

### Epic Decomposition (`/pm:epic-*`)

| Command | Usage | Description |
|---------|-------|-------------|
| `/pm:epic-decompose` | `/pm:epic-decompose <feature>` | Break plan into tasks |
| `/pm:epic-sync` | `/pm:epic-sync <feature>` | Push tasks to GitHub |
| `/pm:epic-show` | `/pm:epic-show <feature>` | Show epic details |
| `/pm:epic-list` | `/pm:epic-list` | List all epics |
| `/pm:epic-status` | `/pm:epic-status <feature>` | Show epic progress |
| `/pm:epic-close` | `/pm:epic-close <feature>` | Close completed epic |

---

## Phase B: Execution (Agents work autonomously)

These commands consume artifacts from Phase A. Agents build, test, and ship. Run individually, or use `/devflow:execute <name>` to run the full sequence (asks before each step, skippable).

### Bootstrap Commands (`/init:*`) — greenfield only

| Command | Usage | Description |
|---------|-------|-------------|
| `/init:project` | `/init:project` | Scaffold full project |
| `/init:database` | `/init:database` | SQLAlchemy + Alembic setup |
| `/init:auth` | `/init:auth` | JWT auth for FastAPI |
| `/init:ai` | `/init:ai` | AI/LLM layer setup |
| `/init:deploy` | `/init:deploy` | CI/CD scaffold |

### Build Commands (`/pm:epic-start`, `/pm:issue-*`)

| Command | Usage | Description |
|---------|-------|-------------|
| `/pm:epic-start` | `/pm:epic-start <feature>` | Launch parallel agents in worktrees |
| `/pm:issue-show` | `/pm:issue-show <number>` | Show issue details |
| `/pm:issue-start` | `/pm:issue-start <number>` | Start work on issue |
| `/pm:issue-sync` | `/pm:issue-sync <number>` | Sync progress to GitHub |
| `/pm:issue-close` | `/pm:issue-close <number>` | Close issue |

### Database Commands (`/db:*`)

| Command | Usage | Description |
|---------|-------|-------------|
| `/db:migrate` | `/db:migrate [action]` | Manage Alembic migrations |
| `/db:seed` | `/db:seed [env]` | Seed database |
| `/db:schema-check` | `/db:schema-check` | Validate schema consistency |

### API Commands (`/api:*`)

| Command | Usage | Description |
|---------|-------|-------------|
| `/api:scaffold` | `/api:scaffold <resource>` | Scaffold FastAPI endpoints |

### AI Commands (`/ai:*`)

| Command | Usage | Description |
|---------|-------|-------------|
| `/ai:prompt-new` | `/ai:prompt-new <name>` | Create prompt template |
| `/ai:eval-run` | `/ai:eval-run [prompt]` | Run AI evaluation suite |
| `/ai:cost-report` | `/ai:cost-report` | AI cost analysis |

### Testing Commands (`/testing:*`)

| Command | Usage | Description |
|---------|-------|-------------|
| `/testing:prime` | `/testing:prime` | Configure test framework |
| `/testing:run` | `/testing:run [path]` | Execute tests |
| `/testing:coverage` | `/testing:coverage` | Coverage + gap analysis |
| `/testing:e2e-setup` | `/testing:e2e-setup` | Configure E2E testing |
| `/testing:perf` | `/testing:perf` | Performance benchmarks |
| `/testing:ai-eval` | `/testing:ai-eval` | AI output evaluation |

### Quality Commands (`/quality:*`)

| Command | Usage | Description |
|---------|-------|-------------|
| `/quality:lint-setup` | `/quality:lint-setup` | Configure linting |
| `/quality:security-check` | `/quality:security-check` | OWASP security audit |

### Review Commands (`/review:*`)

| Command | Usage | Description |
|---------|-------|-------------|
| `/review:pr-checklist` | `/review:pr-checklist` | PR review checklist |
| `/review:release` | `/review:release` | Pre-release validation |
| `/review:incident` | `/review:incident` | Incident report |

### Deploy Commands (`/deploy:*`)

| Command | Usage | Description |
|---------|-------|-------------|
| `/deploy:setup` | `/deploy:setup` | Generate CI/CD pipeline |
| `/deploy:docker` | `/deploy:docker` | Dockerfile + compose |
| `/deploy:env-check` | `/deploy:env-check` | Validate env vars |

---

## Ongoing / Workflow Commands

| Command | Usage | Description |
|---------|-------|-------------|
| `/pm:status` | `/pm:status` | Project dashboard |
| `/pm:next` | `/pm:next` | Next priority task |
| `/pm:blocked` | `/pm:blocked` | Show blocked tasks |
| `/pm:in-progress` | `/pm:in-progress` | List active work |
| `/pm:standup` | `/pm:standup` | Daily standup report |
| `/pm:validate` | `/pm:validate` | System integrity check |
| `/pm:help` | `/pm:help` | Show command help |
| `/pm:search` | `/pm:search <query>` | Search all artifacts |
| `/pm:code-rabbit` | `/pm:code-rabbit` | Configure CodeRabbit |
