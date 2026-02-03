---
allowed-tools: Bash, Read, Write, Glob, AskUserQuestion
---

# Init

Initialize Product-dev-system for the current project. Sets up GitHub labels and validates configuration.

## Usage

```
/devflow:init
```

## Instructions

### Step 1: Verify Directory Structure

Create `.claude/` directories if missing:

```bash
mkdir -p .claude/prds
mkdir -p .claude/specs
mkdir -p .claude/epics
mkdir -p .claude/context
mkdir -p .claude/adrs
```

### Step 2: Check Git Repository

Check if this is a git repository:

```bash
git rev-parse --git-dir 2>/dev/null
```

**If NOT a git repository**, use AskUserQuestion to ask:

> This directory is not a git repository. What would you like to do?
>
> 1. **Initialize git + create GitHub repo** - I'll set up git and create a new GitHub repository
> 2. **Initialize git only** - Just run `git init`, I'll add remote later
> 3. **Skip** - Continue without git/GitHub integration

**Option 1: Initialize git + create GitHub repo**
```bash
git init
```
Then ask:
1. Repository name (suggest current folder name)
2. Organization (use AskUserQuestion):
   > Where should the repository be created?
   > 1. **Personal account** - Create under your GitHub username
   > 2. **Organization** - I'll specify the organization name

If personal:
```bash
gh repo create <name> --private --source=. --push
```

If organization, ask for org name, then:
```bash
gh repo create <org>/<name> --private --source=. --push
```

**Option 2: Initialize git only**
```bash
git init
```
Continue to Step 3 but skip label creation.

**Option 3: Skip**
Continue to success message, note that GitHub features are unavailable.

### Step 3: Check GitHub Remote

If git exists, check for remote:

```bash
git remote get-url origin 2>/dev/null
```

**If no remote**, use AskUserQuestion:

> Git repository exists but no GitHub remote. What would you like to do?
>
> 1. **Create new GitHub repo** - Create a new repository on GitHub
> 2. **Add existing repo** - I'll provide the repository URL
> 3. **Skip** - Continue without GitHub integration

**Option 1: Create new GitHub repo**
Ask for:
1. Repository name (suggest current folder name)
2. Organization (personal or org name)

If personal:
```bash
gh repo create <name> --private --source=. --push
```

If organization:
```bash
gh repo create <org>/<name> --private --source=. --push
```

**Option 2: Add existing repo**
Ask for the URL, then:
```bash
git remote add origin <url>
```

### Step 4: Verify GitHub CLI

If we have a remote, check GitHub CLI:

```bash
gh auth status
```

If not authenticated, tell user to run `gh auth login` and retry.

### Step 5: Create GitHub Labels

If GitHub is configured, create labels:

```bash
gh label create "epic" --description "Parent issue for a feature" --color "8B5CF6" --force 2>/dev/null || true
gh label create "task" --description "Individual work item" --color "3B82F6" --force 2>/dev/null || true
gh label create "P1" --description "Priority 1 - Must have" --color "EF4444" --force 2>/dev/null || true
gh label create "P2" --description "Priority 2 - Should have" --color "F59E0B" --force 2>/dev/null || true
gh label create "P3" --description "Priority 3 - Nice to have" --color "10B981" --force 2>/dev/null || true
gh label create "blocked" --description "Blocked by dependency" --color "DC2626" --force 2>/dev/null || true
gh label create "in-progress" --description "Currently being worked on" --color "8B5CF6" --force 2>/dev/null || true
```

### Step 6: Success Message

Print summary based on what was configured:

**With GitHub:**
```
✅ Product-dev-system initialized

Repository: owner/repo
Labels: epic, task, P1, P2, P3, blocked, in-progress
Directories: .claude/prds, specs, epics, context, adrs

Next steps:
  /devflow:kickstart <name>  - Run full brainstorming phase
  /pm:prd-new <name>         - Start a new PRD
```

**Without GitHub:**
```
✅ Product-dev-system initialized (local only)

Directories: .claude/prds, specs, epics, context, adrs

⚠️  GitHub not configured - issue sync disabled
    Run /devflow:init again after setting up git remote

Next steps:
  /devflow:kickstart <name>  - Run full brainstorming phase
  /pm:prd-new <name>         - Start a new PRD
```
