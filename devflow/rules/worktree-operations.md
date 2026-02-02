# Worktree Operations

Git worktrees enable parallel development by allowing multiple working directories for the same repository.

## Creating Worktrees

Always create worktrees from a clean main branch:
```bash
git checkout main
git pull origin main
git worktree add ../epic-{name} -b epic/{name}
```

The worktree will be created as a sibling directory to maintain clean separation.

## Working in Worktrees

### Agent Commits
- Agents commit directly to the worktree
- Use small, focused commits
- Commit message format: `Issue #{number}: {description}`
- Example: `Issue #1234: Add user authentication schema`

### File Operations
```bash
cd ../epic-{name}
git add {files}
git commit -m "Issue #{number}: {change}"
git status
```

## Parallel Work in Same Worktree

Multiple agents can work in the same worktree if they touch different files:
```bash
# Agent A works on API
git add src/api/*
git commit -m "Issue #1234: Add user endpoints"

# Agent B works on UI (no conflict)
git add src/ui/*
git commit -m "Issue #1235: Add dashboard component"
```

## Merging Worktrees

When epic is complete:
```bash
cd {main-repo}
git checkout main
git pull origin main
git merge epic/{name}
git worktree remove ../epic-{name}
git branch -d epic/{name}
```

## Handling Conflicts

```bash
git status
# Human resolves conflicts
git add {resolved-files}
git commit
```

## Worktree Management

### List Active Worktrees
```bash
git worktree list
```

### Remove Stale Worktree
```bash
git worktree prune
git worktree remove --force ../epic-{name}
```

## Best Practices

1. **One worktree per epic** — Not per issue
2. **Clean before create** — Always start from updated main
3. **Commit frequently** — Small commits are easier to merge
4. **Delete after merge** — Don't leave stale worktrees
5. **Use descriptive branches** — `epic/feature-name` not `feature`
