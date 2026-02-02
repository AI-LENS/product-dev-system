# Review Workflow

Standards for pull request review, merge strategy, and release management.

## PR Size Limits

- **Maximum:** 400 lines changed (additions + deletions)
- **Ideal:** 100-250 lines changed
- If a PR exceeds 400 lines, split it into smaller, logically independent PRs
- Exceptions: auto-generated code (migrations, lockfiles) does not count toward the limit
- Large refactors: create a tracking issue and submit as a series of stacked PRs

## Required Checks Before Review

All of the following must pass before a PR is eligible for human review:

1. **Lint** — ruff check (Python), ESLint (frontend)
2. **Type check** — mypy (Python), tsc --noEmit (TypeScript)
3. **Tests** — Full test suite passes with no failures
4. **Build** — Docker image builds successfully
5. **Coverage** — New code meets 80% minimum coverage threshold

If any check fails, the PR is blocked from merge. Fix issues before requesting review.

## Review Checklist

### Security
- [ ] Authentication/authorization enforced on all new endpoints
- [ ] Input validation on all user-supplied data (Pydantic models, form validators)
- [ ] No SQL injection vectors (parameterized queries, ORM usage)
- [ ] No XSS vectors (output encoding, CSP headers, Angular sanitization)
- [ ] No secrets or credentials in code or config files
- [ ] Rate limiting on public-facing endpoints
- [ ] CORS configuration is restrictive (not wildcard in production)

### Performance
- [ ] No N+1 query patterns (use eager loading / joinedload)
- [ ] Database queries have appropriate indexes
- [ ] Large payloads are paginated
- [ ] Expensive operations are async or queued
- [ ] No unbounded loops or recursion
- [ ] Frontend bundle size impact is reasonable

### Accessibility
- [ ] ARIA labels on interactive elements
- [ ] Keyboard navigation works for all flows
- [ ] Color contrast meets WCAG AA (4.5:1 for text)
- [ ] Form inputs have associated labels
- [ ] Screen reader tested for new UI components

### API Contract
- [ ] Backwards-compatible changes (no breaking changes to existing endpoints)
- [ ] New endpoints documented with OpenAPI annotations
- [ ] Request/response schemas use Pydantic models
- [ ] Error responses follow consistent format
- [ ] Versioning strategy applied for breaking changes (if unavoidable)

### Database
- [ ] Migration has both upgrade and downgrade paths
- [ ] Migration is backwards-compatible with current running code
- [ ] No destructive operations (DROP, TRUNCATE) without explicit approval
- [ ] Large data migrations are batched
- [ ] Indexes added for new query patterns

### Testing
- [ ] New code has adequate test coverage (80% minimum)
- [ ] Edge cases covered (empty inputs, boundary values, errors)
- [ ] Error paths tested (network failures, invalid data, timeouts)
- [ ] No flaky tests introduced

## Approval Requirements

| Change Type | Required Approvals |
|-------------|-------------------|
| Feature code | 1 approval minimum |
| Infrastructure / CI/CD | 2 approvals minimum |
| Database migrations | 2 approvals minimum |
| Security-sensitive code | 2 approvals (1 from security-aware reviewer) |
| Documentation only | 1 approval minimum |
| Dependency updates | 1 approval minimum |

## Merge Strategy

- **Squash merge to main** — All feature branch commits become a single commit on main
- Commit message format: conventional commits
  ```
  feat(api): add user preferences endpoint

  - POST /api/users/{id}/preferences
  - Supports theme, language, notification settings
  - Includes validation and 400 error handling

  Closes #123
  ```
- Allowed prefixes: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `ci`, `perf`
- Delete feature branch after merge

## Release Branch Management

### Release Flow
```
main → release/vX.Y.Z → tag vX.Y.Z
```

1. Create release branch from main: `git checkout -b release/v1.2.0 main`
2. Only bug fixes go into release branch (no new features)
3. Update version number and changelog
4. Run full test suite + manual QA
5. Merge release branch to main
6. Tag the merge commit: `git tag v1.2.0`
7. Deploy tagged commit to production

### Versioning (Semantic Versioning)
- **MAJOR (X):** Breaking API changes
- **MINOR (Y):** New features, backwards-compatible
- **PATCH (Z):** Bug fixes, backwards-compatible

## Hotfix Process

1. Branch from the production tag: `git checkout -b hotfix/v1.2.1 v1.2.0`
2. Apply the minimal fix
3. Add test for the bug
4. Get expedited review (1 approval minimum, 2 for security issues)
5. Tag: `git tag v1.2.1`
6. Deploy hotfix to production
7. Cherry-pick the fix to main: `git cherry-pick <commit-hash>` onto main
8. Verify main CI passes after cherry-pick

## Stale PR Policy

- PRs open for more than 7 days without activity get a reminder comment
- PRs open for more than 14 days get flagged for closure or rebase
- Author is responsible for keeping PRs up to date with main
