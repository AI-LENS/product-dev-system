# Branch Operations

Git branches enable parallel development with isolated changes.

## Creating Branches

Always create branches from a clean main branch:
```bash
git checkout main
git pull origin main
git checkout -b epic/{name}
git push -u origin epic/{name}
```

## Working in Branches

### Agent Commits
- Agents commit directly to the branch
- Use small, focused commits
- Commit message format: `Issue #{number}: {description}`

### File Operations
```bash
git add {files}
git commit -m "Issue #{number}: {change}"
git status
git log --oneline -5
```

## Parallel Work in Same Branch

Multiple agents can work in the same branch if they coordinate file access:
```bash
# Agent A works on API
git add src/api/*
git commit -m "Issue #1234: Add user endpoints"

# Agent B pulls latest, then works on UI
git pull origin epic/{name}
git add src/ui/*
git commit -m "Issue #1235: Add dashboard component"
```

## Merging Branches

```bash
git checkout main
git pull origin main
git merge epic/{name}
git branch -d epic/{name}
git push origin --delete epic/{name}
```

## Handling Conflicts

```bash
git status
# Human resolves conflicts
git add {resolved-files}
git commit
```

## Branch Management

### List Active Branches
```bash
git branch -a
```

### Remove Stale Branch
```bash
git branch -d epic/{name}
git push origin --delete epic/{name}
```

### Check Branch Status
```bash
git branch -v
git log --oneline main..epic/{name}
```

## Best Practices

1. **One branch per epic** — Not per issue
2. **Clean before create** — Always start from updated main
3. **Commit frequently** — Small commits are easier to merge
4. **Pull before push** — Get latest changes to avoid conflicts
5. **Use descriptive branches** — `epic/feature-name` not `feature`
