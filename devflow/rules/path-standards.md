# Path Standards Specification

## Core Principles

### Privacy Protection
- **Prohibit** absolute paths containing usernames
- **Prohibit** exposing local directory structure in public documentation
- **Prohibit** including complete local paths in GitHub Issue comments

### Portability
- **Prefer** relative paths for referencing project files
- **Ensure** documentation works across different development environments
- **Avoid** environment-specific path formats

## Path Format Standards

### Project File References
```markdown
# Correct
- `src/api/users.py`
- `devflow/commands/pm/init.md`

# Incorrect
- `/Users/username/project/src/api/users.py`
```

### Cross-Project/Worktree References
```markdown
# Correct
- `../project-name/src/api/users.py`
- `../worktree-name/src/components/Button.tsx`

# Incorrect
- `/Users/username/projects/worktree-name/src/components/Button.tsx`
```

## Path Variable Standards
```yaml
project_root: "."
worktree_path: "../{name}"
```

## Automatic Cleanup

```bash
normalize_paths() {
  local content="$1"
  content=$(echo "$content" | sed "s|/Users/[^/]*/[^/]*/|../|g")
  content=$(echo "$content" | sed "s|/home/[^/]*/[^/]*/|../|g")
  content=$(echo "$content" | sed "s|C:\\\\Users\\\\[^\\\\]*\\\\[^\\\\]*\\\\|..\\\\|g")
  echo "$content"
}
```

## Validation

```bash
check_absolute_paths() {
  echo "Checking for absolute path violations..."
  rg -n "/Users/|/home/|C:\\\\\\\\" devflow/ || echo "✅ No absolute paths found"
}
```

## Important Notes

- Always clean paths before syncing to GitHub
- Use relative paths in all generated documentation
- Strip user-specific paths from issue bodies and comments
