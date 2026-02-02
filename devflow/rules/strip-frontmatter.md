# Strip Frontmatter

Standard approach for removing YAML frontmatter before sending content to GitHub.

## The Problem

YAML frontmatter contains internal metadata that should not appear in GitHub issues:
- status, created, updated fields
- Internal references and IDs
- Local file paths

## The Solution

```bash
sed '1,/^---$/d; 1,/^---$/d' input.md > output.md
```

This removes:
1. The opening `---` line
2. All YAML content
3. The closing `---` line

## When to Strip Frontmatter

Always strip frontmatter when:
- Creating GitHub issues from markdown files
- Posting file content as comments
- Displaying content to external users
- Syncing to any external system

## Examples

### Creating an issue from a file
```bash
remote_url=$(git remote get-url origin 2>/dev/null || echo "")
REPO=$(echo "$remote_url" | sed 's|.*github.com[:/]||' | sed 's|\.git$||')
[ -z "$REPO" ] && REPO="user/repo"
sed '1,/^---$/d; 1,/^---$/d' task.md > /tmp/clean.md
gh issue create --repo "$REPO" --body-file /tmp/clean.md
```

### Posting a comment
```bash
sed '1,/^---$/d; 1,/^---$/d' progress.md > /tmp/comment.md
gh issue comment 123 --body-file /tmp/comment.md
```

## Important Notes

- Always test with a sample file first
- Keep original files intact
- Use temporary files for cleaned content
- Some files may not have frontmatter — the command handles this gracefully
