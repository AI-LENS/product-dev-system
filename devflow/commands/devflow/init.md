---
allowed-tools: Bash, Read, Write, Glob
---

# Init

Initialize Product-dev-system for the current project. Sets up GitHub labels and validates configuration.

## Usage

```
/devflow:init
```

## Instructions

### Step 1: Verify GitHub CLI

Check GitHub CLI is installed and authenticated:

```bash
gh auth status
```

If not authenticated, prompt user to run `gh auth login`.

### Step 2: Detect Repository

Verify this is a git repository with a GitHub remote:

```bash
git remote get-url origin
```

Extract the `owner/repo` format. If no remote found, warn the user.

### Step 3: Create GitHub Labels

Create the required labels for issue tracking. Run these commands (ignore errors if labels already exist):

```bash
gh label create "epic" --description "Parent issue for a feature" --color "8B5CF6" --force 2>/dev/null || true
gh label create "task" --description "Individual work item" --color "3B82F6" --force 2>/dev/null || true
gh label create "P1" --description "Priority 1 - Must have" --color "EF4444" --force 2>/dev/null || true
gh label create "P2" --description "Priority 2 - Should have" --color "F59E0B" --force 2>/dev/null || true
gh label create "P3" --description "Priority 3 - Nice to have" --color "10B981" --force 2>/dev/null || true
gh label create "blocked" --description "Blocked by dependency" --color "DC2626" --force 2>/dev/null || true
gh label create "in-progress" --description "Currently being worked on" --color "8B5CF6" --force 2>/dev/null || true
```

### Step 4: Verify Directory Structure

Check that `.claude/` directories exist. If missing, create them:

```bash
mkdir -p .claude/prds
mkdir -p .claude/specs
mkdir -p .claude/epics
mkdir -p .claude/context
mkdir -p .claude/adrs
```

### Step 5: Confirm Success

Print summary:

```
✅ Product-dev-system initialized

Repository: owner/repo
Labels: epic, task, P1, P2, P3, blocked, in-progress

Next steps:
  /devflow:principles    - Define project principles
  /context:create        - Analyze codebase
  /pm:prd-new <name>     - Start a new PRD
  /devflow:kickstart <name> - Run full brainstorming phase
```

## Error Recovery

| Error | Action |
|-------|--------|
| `gh` not found | Tell user to install GitHub CLI: https://cli.github.com/ |
| Not authenticated | Tell user to run `gh auth login` |
| No git remote | Warn but continue - labels won't be created |
| Label creation fails | Continue - labels may already exist |
