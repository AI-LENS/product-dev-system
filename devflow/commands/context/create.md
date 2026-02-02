---
allowed-tools: Bash, Read, Write, LS
---

# Create Initial Context

This command creates the initial project context documentation in `.claude/context/` by analyzing the current project state and establishing comprehensive baseline documentation.

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/datetime.md` - For getting real current date/time

## Preflight Checklist

Before proceeding, complete these validation steps.
Do not bother the user with preflight checks progress. Just do them and move on.

### 1. Context Directory Check
- Run: `ls -la .claude/context/ 2>/dev/null`
- If directory exists and has files:
  - Count existing files: `ls -1 .claude/context/*.md 2>/dev/null | wc -l`
  - Ask user: "Found {count} existing context files. Overwrite all context? (yes/no)"
  - Only proceed with explicit 'yes' confirmation
  - If user says no, suggest: "Use /context:update to refresh existing context"

### 2. Project Type Detection
- Check for project indicators:
  - Python: `test -f requirements.txt || test -f pyproject.toml && echo "Python project detected"`
  - Node.js: `test -f package.json && echo "Node.js project detected"`
  - Rust: `test -f Cargo.toml && echo "Rust project detected"`
  - Go: `test -f go.mod && echo "Go project detected"`
  - Java: `test -f pom.xml || test -f build.gradle && echo "Java project detected"`
  - .NET: `ls *.sln *.csproj 2>/dev/null && echo ".NET project detected"`
  - Ruby: `test -f Gemfile && echo "Ruby project detected"`
  - PHP: `test -f composer.json && echo "PHP project detected"`
  - Dart: `test -f pubspec.yaml && echo "Dart/Flutter project detected"`
  - Swift: `test -f Package.swift && echo "Swift project detected"`
- Run: `git status 2>/dev/null` to confirm this is a git repository
- If not a git repo, ask: "Not a git repository. Continue anyway? (yes/no)"

### 3. Directory Creation
- If `.claude/context/` doesn't exist, create it: `mkdir -p .claude/context/`
- Verify write permissions: `touch .claude/context/.test && rm .claude/context/.test`
- If permission denied: "Cannot create context directory. Check permissions."

### 4. Get Current DateTime
- Run: `date -u +"%Y-%m-%dT%H:%M:%SZ"`
- Store this value for use in all context file frontmatter

## Instructions

### 1. Pre-Analysis Validation
- Confirm project root directory is correct (presence of .git, config files, etc.)
- Check for existing documentation that can inform context (README.md, docs/)
- If README.md doesn't exist, ask user for project description

### 2. Systematic Project Analysis

Gather information in this order:

**Project Detection:**
- Run: `find . -maxdepth 2 \( -name 'package.json' -o -name 'requirements.txt' -o -name 'pyproject.toml' -o -name 'pom.xml' -o -name 'build.gradle' -o -name '*.sln' -o -name 'Cargo.toml' -o -name 'go.mod' -o -name 'composer.json' -o -name 'pubspec.yaml' -o -name 'Dockerfile' -o -name 'docker-compose.yml' -o -name 'Package.swift' \) 2>/dev/null`
- Run: `git remote -v 2>/dev/null` to get repository information
- Run: `git branch --show-current 2>/dev/null` to get current branch

**Codebase Analysis:**
- Run: `find . -type f \( -name '*.py' -o -name '*.js' -o -name '*.ts' -o -name '*.jsx' -o -name '*.tsx' -o -name '*.rs' -o -name '*.go' -o -name '*.java' -o -name '*.kt' -o -name '*.cs' -o -name '*.rb' -o -name '*.php' -o -name '*.swift' -o -name '*.dart' \) 2>/dev/null | head -20`
- Run: `ls -la` to see root directory structure
- Read README.md if it exists

### 3. Context File Creation with Frontmatter

Each context file MUST include frontmatter with real datetime:

```yaml
---
created: [Use REAL datetime from date command]
last_updated: [Use REAL datetime from date command]
version: 1.0
author: DevFlow PM System
---
```

Generate the following initial context files:

- **`progress.md`** - Current project status, completed work, immediate next steps
  - Include: Current branch, recent commits, outstanding changes

- **`project-structure.md`** - Directory structure and file organization
  - Include: Key directories, file naming patterns, module organization

- **`tech-context.md`** - Dependencies, technologies, and development tools
  - Include: Language version, framework versions, dev dependencies

- **`system-patterns.md`** - Existing architectural patterns and design decisions
  - Include: Design patterns observed, architectural style, data flow

- **`product-context.md`** - Product requirements, target users, core functionality
  - Include: User personas, core features, use cases

- **`project-brief.md`** - Project scope, goals, key objectives
  - Include: What it does, why it exists, success criteria

- **`project-overview.md`** - High-level summary of features and capabilities
  - Include: Feature list, current state, integration points

- **`project-vision.md`** - Long-term vision and strategic direction
  - Include: Future goals, potential expansions, strategic priorities

- **`project-style-guide.md`** - Coding standards, conventions, style preferences
  - Include: Naming conventions, file structure patterns, comment style

### 4. Quality Validation

After creating each file:
- Verify file was created successfully
- Check file is not empty (minimum 10 lines of content)
- Ensure frontmatter is present and valid
- Validate markdown formatting is correct

### 5. Error Handling

**Common Issues:**
- **No write permissions:** "Cannot write to .claude/context/. Check permissions."
- **Disk space:** "Insufficient disk space for context files."
- **File creation failed:** "Failed to create {filename}. Error: {error}"

If any file fails to create:
- Report which files were successfully created
- Provide option to continue with partial context
- Never leave corrupted or incomplete files

### 6. Post-Creation Summary

```
Context Creation Complete

Created context in: .claude/context/
Files created: {count}/9

Context Summary:
  - Project Type: {detected_type}
  - Language: {primary_language}
  - Git Status: {clean/changes}
  - Dependencies: {count} packages

File Details:
  progress.md ({lines} lines) - Current status and recent work
  project-structure.md ({lines} lines) - Directory organization
  tech-context.md ({lines} lines) - Technology stack
  system-patterns.md ({lines} lines) - Architecture patterns
  product-context.md ({lines} lines) - Product requirements
  project-brief.md ({lines} lines) - Project scope
  project-overview.md ({lines} lines) - Feature overview
  project-vision.md ({lines} lines) - Strategic direction
  project-style-guide.md ({lines} lines) - Code conventions

Created: {timestamp}
Next: Use /context:prime to load context in new sessions
Tip: Run /context:update regularly to keep context current
```

## Context Gathering Commands

Use these commands to gather project information:
- Target directory: `.claude/context/` (create if needed)
- Current git status: `git status --short`
- Recent commits: `git log --oneline -10`
- Project README: Read `README.md` if exists
- Package files: Check for package.json, requirements.txt, pyproject.toml, etc.
- Documentation scan: `find . -type f -name '*.md' -path '*/docs/*' 2>/dev/null | head -10`
- Test detection: `find . \( -path '*/.*' -prune \) -o \( -type d \( -name 'test' -o -name 'tests' -o -name '__tests__' \) -o -type f \( -name '*test*' -o -name '*spec*' \) \) -print 2>/dev/null | head -10`

## Important Notes

- **Always use real datetime** from system clock, never placeholders
- **Ask for confirmation** before overwriting existing context
- **Validate each file** is created successfully
- **Provide detailed summary** of what was created
- **Handle errors gracefully** with specific guidance

$ARGUMENTS
