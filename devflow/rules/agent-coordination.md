# Agent Coordination

Rules for multiple agents working in parallel within the same epic worktree.

## Parallel Execution Principles

1. **File-level parallelism** — Agents working on different files never conflict
2. **Explicit coordination** — When same file needed, coordinate explicitly
3. **Fail fast** — Surface conflicts immediately, don't try to be clever
4. **Human resolution** — Conflicts are resolved by humans, not agents

## Work Stream Assignment

Each agent is assigned a work stream from the issue analysis:
```yaml
Stream A: Database Layer
  Files: src/db/*, migrations/*
  Agent: db-task-worker

Stream B: API Layer
  Files: src/api/*
  Agent: api-task-worker
```

Agents should only modify files in their assigned patterns.

## File Access Coordination

### Check Before Modify
```bash
git status {file}
if [[ $(git status --porcelain {file}) ]]; then
  echo "Waiting for {file} to be available..."
  sleep 30
fi
```

### Atomic Commits
```bash
# Good — Single purpose commit
git add src/api/users.py src/tests/test_users.py
git commit -m "Issue #1234: Add user CRUD endpoints"

# Bad — Mixed concerns
git add src/api/* src/db/* src/ui/*
git commit -m "Issue #1234: Multiple changes"
```

## Communication Between Agents

### Through Commits
```bash
git log --oneline -10
git pull origin epic/{name}
```

### Through Progress Files
```markdown
# devflow/epics/{epic}/updates/{issue}/stream-A.md
---
stream: Database Layer
agent: db-task-worker
started: {datetime}
status: in_progress
---

## Completed
- Created user table schema
- Added migration files

## Working On
- Adding indexes

## Blocked
- None
```

## Handling Conflicts

### Conflict Detection
```bash
git commit -m "Issue #1234: Update"
# Error: conflicts exist
echo "❌ Conflict detected in {files}"
echo "Human intervention needed"
```

### Conflict Resolution
Always defer to humans:
1. Agent detects conflict
2. Agent reports issue
3. Agent pauses work
4. Human resolves
5. Agent continues

Never attempt automatic merge resolution.

## Synchronization Points

### Natural Sync Points
- After each commit
- Before starting new file
- When switching work streams
- Every 30 minutes of work

### Explicit Sync
```bash
git pull --rebase origin epic/{name}
if [[ $? -ne 0 ]]; then
  echo "❌ Sync failed — human help needed"
  exit 1
fi
```

## Parallel Commit Strategy

### No Conflicts Possible
```bash
Agent-A: git commit -m "Issue #1234: Update database"
Agent-B: git commit -m "Issue #1235: Update UI"
Agent-C: git commit -m "Issue #1236: Add tests"
```

### Sequential When Needed
```bash
# Agent A commits first
git add src/models/user.py
git commit -m "Issue #1234: Update models"

# Agent B waits, then proceeds
git pull
git add src/api/users.py
git commit -m "Issue #1235: Use updated models"
```

## Best Practices

1. **Commit early and often** — Smaller commits = fewer conflicts
2. **Stay in your lane** — Only modify assigned files
3. **Communicate changes** — Update progress files
4. **Pull frequently** — Stay synchronized with other agents
5. **Fail loudly** — Report issues immediately
6. **Never force** — No `--force` flags ever
