# DevFlow Hooks

## Bash Worktree Fix Hook

Automatically fixes the Bash tool's directory reset issue when working in git worktrees.

### Problem

The Bash tool resets to the main project directory after every command, making it impossible to work in worktrees without manually prefixing every command with `cd /path/to/worktree &&`.

### Solution

The pre-tool-use hook detects when you're in a worktree and injects the necessary `cd` prefix to all Bash commands.

### How It Works

1. **Detection**: Before any Bash command executes, the hook checks if `.git` is a file (worktree) or directory (main repo)
2. **Injection**: If in a worktree, prepends `cd /absolute/path/to/worktree && ` to the command
3. **Transparency**: Agents don't need to know about this — it happens automatically

### Configuration

Add to your `.claude/settings.json`:

```json
{
  "hooks": {
    "pre-tool-use": {
      "Bash": {
        "enabled": true,
        "script": ".claude/hooks/bash-worktree-fix.sh",
        "apply_to_subagents": true
      }
    }
  }
}
```

### Testing

```bash
# Enable debug mode
export CLAUDE_HOOK_DEBUG=true

# Test in main repo (should pass through)
.claude/hooks/bash-worktree-fix.sh "ls -la"

# Test in worktree (should inject cd)
cd /path/to/worktree
.claude/hooks/bash-worktree-fix.sh "npm install"
# Output: cd "/path/to/worktree" && npm install
```

### Features

- Background processes (`&`)
- Piped commands (`|`)
- Environment variable prefixes (`VAR=value command`)
- Commands that already have `cd`
- Commands using absolute paths
- Debug logging with `CLAUDE_HOOK_DEBUG=true`

### Edge Cases

1. **Double-prefix prevention**: Won't add prefix if command already starts with `cd`
2. **Special commands**: Skips for `pwd`, `echo`, `export`, etc.
3. **Background processes**: Correctly handles `&` at the end of commands
