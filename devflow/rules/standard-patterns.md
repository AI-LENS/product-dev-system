# Standard Patterns for Commands

Common patterns that all DevFlow commands should follow.

## Core Principles

1. **Fail Fast** — Check critical prerequisites, then proceed
2. **Trust the System** — Don't over-validate things that rarely fail
3. **Clear Errors** — When something fails, say exactly what and how to fix it
4. **Minimal Output** — Show what matters, skip decoration

## Standard Validations

### Minimal Preflight
Only check what's absolutely necessary:
```markdown
## Quick Check
1. If command needs specific directory/file:
   - Check it exists: `test -f {file} || echo "❌ {file} not found"`
   - If missing, tell user exact command to fix it
2. If command needs GitHub:
   - Assume `gh` is authenticated (it usually is)
   - Only check on actual failure
```

### DateTime Handling
```markdown
Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`
```
Reference `devflow/rules/datetime.md` for full details.

### Error Messages
Keep them short and actionable:
```markdown
❌ {What failed}: {Exact solution}
Example: "❌ Epic not found: Run /pm:epic-decompose feature-name"
```

## Standard Output Formats

### Success Output
```markdown
✅ {Action} complete
  - {Key result 1}
  - {Key result 2}
Next: {Single suggested action}
```

### List Output
```markdown
{Count} {items} found:
- {item 1}: {key detail}
- {item 2}: {key detail}
```

### Progress Output
```markdown
{Action}... {current}/{total}
```

## File Operations

### Check and Create
```markdown
mkdir -p devflow/{directory} 2>/dev/null
```

### Read with Fallback
```markdown
if [ -f {file} ]; then
  # Read and use file
else
  # Use sensible default
fi
```

## GitHub Operations

### Trust gh CLI
```markdown
gh {command} || echo "❌ GitHub CLI failed. Run: gh auth login"
```

### Simple Issue Operations
```markdown
gh issue view {number} --json state,title,body
```

## Common Patterns to Avoid

### DON'T: Over-validate
```markdown
# Bad
1. Check directory exists
2. Check permissions
3. Check git status
4. Check GitHub auth
5. Check rate limits
```

### DO: Check essentials
```markdown
# Good
1. Check target exists
2. Try the operation
3. Handle failure clearly
```

### DON'T: Verbose output
```markdown
# Bad
🎯 Starting operation...
📋 Validating prerequisites...
✅ Step 1 complete
```

### DO: Concise output
```markdown
# Good
✅ Done: 3 files created
Failed: auth.test.py (syntax error - line 42)
```

## Quick Reference

### Essential Tools Only
- Read/List operations: `Read, LS`
- File creation: `Read, Write, LS`
- GitHub operations: Add `Bash`
- Complex analysis: Add `Task` (sparingly)

### Status Indicators
- ✅ Success (use sparingly)
- ❌ Error (always with solution)
- ⚠️ Warning (only if action needed)
- No emoji for normal output

### Exit Strategies
- Success: Brief confirmation
- Failure: Clear error + exact fix
- Partial: Show what worked, what didn't

## Remember

**Simple is not simplistic** — We handle errors properly, we just don't prevent every edge case. We trust that:
- The file system usually works
- GitHub CLI is usually authenticated
- Git repositories are usually valid
- Users know what they're doing

Focus on the happy path, fail gracefully when things go wrong.
