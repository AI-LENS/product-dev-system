---
name: {checklist-name}
type: {pre-merge / pre-deploy / pre-release / review}
created: {datetime}
updated: {datetime}
version: 1.0
---

# Checklist: {Checklist Name}

## Code Quality

- [ ] Code follows project style guide and naming conventions
- [ ] No commented-out code or debug statements left in
- [ ] Functions and methods have clear docstrings
- [ ] Complex logic has inline comments explaining "why"
- [ ] No hardcoded values -- use configuration or constants
- [ ] Error messages are clear and actionable
- [ ] No code duplication -- shared logic is extracted
- [ ] Cyclomatic complexity is reasonable (< 10 per function)

## Testing

- [ ] Unit tests written for all new functions/methods
- [ ] Unit test coverage >= 80% for new code
- [ ] Integration tests cover API endpoints
- [ ] Edge cases and error paths are tested
- [ ] Tests are deterministic (no flaky tests)
- [ ] Test data is isolated (no shared mutable state)
- [ ] All tests pass locally before pushing
- [ ] Performance-critical paths have benchmark tests

## Security

- [ ] No secrets or credentials in code or config files
- [ ] Input validation on all user-provided data
- [ ] SQL injection prevention (parameterized queries / ORM)
- [ ] XSS prevention (output encoding)
- [ ] CSRF protection enabled for state-changing operations
- [ ] Authentication required for protected endpoints
- [ ] Authorization checks enforce proper access control
- [ ] Sensitive data is encrypted at rest and in transit
- [ ] Rate limiting applied to public endpoints
- [ ] Dependencies checked for known vulnerabilities

## Documentation

- [ ] API endpoints documented with request/response examples
- [ ] README updated if setup steps changed
- [ ] Breaking changes documented in CHANGELOG
- [ ] New environment variables documented in .env.example
- [ ] Architecture decisions recorded (ADR if significant)
- [ ] User-facing changes documented for release notes

## Deployment

- [ ] Database migrations are reversible
- [ ] Migration tested on a copy of production data
- [ ] Feature flags used for gradual rollout (if applicable)
- [ ] Health check endpoints are working
- [ ] Monitoring and alerting configured for new features
- [ ] Rollback plan documented and tested
- [ ] Environment-specific configuration reviewed
- [ ] CI/CD pipeline passes all stages

## Performance

- [ ] Database queries are optimized (no N+1 queries)
- [ ] Appropriate indexes exist for query patterns
- [ ] Large datasets use pagination
- [ ] Caching applied where appropriate
- [ ] API response times within NFR limits
- [ ] No memory leaks in long-running processes

## Accessibility (if applicable)

- [ ] Semantic HTML elements used
- [ ] ARIA labels on interactive elements
- [ ] Keyboard navigation works correctly
- [ ] Color contrast meets WCAG AA standards
- [ ] Screen reader testing completed
