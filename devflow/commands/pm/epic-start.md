---
allowed-tools: Bash, Read, Write, LS, Task
---

# Epic Start

Launch parallel agents to work on epic tasks in a shared branch.

## Usage
```
/pm:epic-start <epic_name>
```

## Quick Check

1. **Verify epic exists:**
   ```bash
   test -f devflow/epics/$ARGUMENTS/epic.md || echo "Epic not found. Run: /pm:epic-decompose $ARGUMENTS"
   ```

2. **Check GitHub sync:**
   Look for `github:` field in epic frontmatter.
   If missing: "Epic not synced. Run: /pm:epic-sync $ARGUMENTS first"

3. **Check for branch:**
   ```bash
   git branch -a | grep "epic/$ARGUMENTS"
   ```

4. **Check for uncommitted changes:**
   ```bash
   git status --porcelain
   ```
   If output is not empty: "You have uncommitted changes. Please commit or stash them before starting an epic"

## Instructions

### 1. Create or Enter Branch

Follow `devflow/rules/branch-operations.md`:

```bash
if [ -n "$(git status --porcelain)" ]; then
  echo "You have uncommitted changes. Please commit or stash them before starting an epic."
  exit 1
fi

if ! git branch -a | grep -q "epic/$ARGUMENTS"; then
  git checkout main
  git pull origin main
  git checkout -b epic/$ARGUMENTS
  git push -u origin epic/$ARGUMENTS
  echo "Created branch: epic/$ARGUMENTS"
else
  git checkout epic/$ARGUMENTS
  git pull origin epic/$ARGUMENTS
  echo "Using existing branch: epic/$ARGUMENTS"
fi
```

### 2. Identify Ready Issues

Read all task files in `devflow/epics/$ARGUMENTS/`:
- Parse frontmatter for `status`, `depends_on`, `parallel` fields
- Check GitHub issue status if needed
- Build dependency graph

Categorize issues:
- **Ready**: No unmet dependencies, not started
- **Blocked**: Has unmet dependencies
- **In Progress**: Already being worked on
- **Complete**: Finished

### 3. Analyze Ready Issues

For each ready issue without analysis:
```bash
if ! test -f devflow/epics/$ARGUMENTS/{issue}-analysis.md; then
  echo "Analyzing issue #{issue}..."
fi
```

### 4. Launch Parallel Agents

For each ready issue with analysis, use Task tool to launch work streams:

```yaml
Task:
  description: "Issue #{issue} Stream {X}"
  subagent_type: "{agent_type}"
  prompt: |
    Working in branch: epic/$ARGUMENTS
    Issue: #{issue} - {title}
    Stream: {stream_name}

    Your scope:
    - Files: {file_patterns}
    - Work: {stream_description}

    Read full requirements from:
    - devflow/epics/$ARGUMENTS/{task_file}
    - devflow/epics/$ARGUMENTS/{issue}-analysis.md

    Follow coordination rules in devflow/rules/agent-coordination.md

    Commit frequently with message format:
    "Issue #{issue}: {specific change}"

    Update progress in:
    devflow/epics/$ARGUMENTS/updates/{issue}/stream-{X}.md
```

### 5. Track Active Agents

Create/update `devflow/epics/$ARGUMENTS/execution-status.md`:

```markdown
---
started: {datetime}
branch: epic/$ARGUMENTS
---

# Execution Status

## Active Agents
- Agent-1: Issue #1234 Stream A (Database) - Started {time}
- Agent-2: Issue #1234 Stream B (API) - Started {time}

## Queued Issues
- Issue #1236 - Waiting for #1234

## Completed
- {None yet}
```

### 6. Monitor and Coordinate

```
Agents launched successfully!

Monitor progress:
  /pm:epic-status $ARGUMENTS

View branch changes:
  git status

Merge when complete:
  git merge epic/$ARGUMENTS
```

### 7. Handle Dependencies

As agents complete streams:
- Check if any blocked issues are now ready
- Launch new agents for newly-ready work
- Update execution-status.md

## Output Format

```
Epic Execution Started: $ARGUMENTS

Branch: epic/$ARGUMENTS

Launching {total} agents across {issue_count} issues:

Issue #1234: Database Schema
  Stream A: Schema creation (Agent-1) - Started
  Stream B: Migrations (Agent-2) - Started

Issue #1235: API Endpoints
  Stream A: User endpoints (Agent-3) - Started
  Stream B: Post endpoints (Agent-4) - Started

Blocked Issues ({count}):
  - #{num}: {title} (depends on #{dep})

Monitor with: /pm:epic-status $ARGUMENTS
```

## Error Handling

If agent launch fails:
```
Failed to start Agent-{id}
  Issue: #{issue}
  Stream: {stream}
  Error: {reason}

Continue with other agents? (yes/no)
```

## Important Notes

- Follow `devflow/rules/branch-operations.md` for git operations
- Follow `devflow/rules/agent-coordination.md` for parallel work
- Agents work in the SAME branch (not separate branches)
- Maximum parallel agents should be reasonable (5-10)
- Monitor system resources if launching many agents
