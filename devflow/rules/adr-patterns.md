# ADR Patterns and Standards

## Purpose
Architecture Decision Records (ADRs) capture significant architectural decisions made during the project lifecycle. They provide context, rationale, and consequences for future team members and stakeholders.

## When to Create an ADR

Create an ADR when making decisions about:
- **Technology choices** — selecting a framework, database, language, or service
- **Architectural patterns** — choosing between monolith vs microservices, event-driven vs request-response
- **Integration approaches** — how systems communicate, API design choices
- **Data strategies** — storage engines, caching layers, replication strategies
- **Security patterns** — authentication mechanisms, encryption standards, access control models
- **Infrastructure decisions** — cloud provider, container orchestration, CI/CD pipeline design
- **Convention adoption** — coding standards, branching strategies, testing approaches

Do NOT create an ADR for:
- Routine bug fixes
- Minor library version bumps
- Code style preferences already covered by linter config
- Implementation details that don't affect architecture

## Status Lifecycle

```
proposed → accepted → deprecated
                   → superseded (by ADR-XXX)
```

### Status Definitions

| Status      | Meaning                                                                 |
|-------------|-------------------------------------------------------------------------|
| proposed    | Decision is drafted and under review. Not yet binding.                  |
| accepted    | Decision is approved and active. All team members should follow it.     |
| deprecated  | Decision is no longer relevant. The context that drove it has changed.  |
| superseded  | Decision has been replaced by a newer ADR. Always reference the new ADR.|

### Transition Rules
- New ADRs always start as `proposed`
- Only move to `accepted` after team review or explicit approval
- When superseding, update the old ADR's status to `superseded` and add a reference to the new ADR
- When deprecating, document why in the old ADR's Consequences section

## Numbering Convention

- Format: `ADR-{NNN}` where NNN is a three-digit zero-padded number
- Sequence: `ADR-001`, `ADR-002`, `ADR-003`, ...
- Numbers are never reused, even if an ADR is deprecated or superseded
- Filename format: `ADR-{NNN}-{slug}.md` (e.g., `ADR-003-use-postgresql.md`)
- Slug rules: lowercase, hyphens only, max 60 characters, derived from title

## Required Sections

Every ADR must contain these sections:

### 1. YAML Frontmatter
```yaml
---
adr: ADR-{number}
title: {Decision Title}
status: proposed
created: {ISO 8601 datetime}
updated: {ISO 8601 datetime}
deciders: []
---
```

### 2. Status
Current status with brief note if deprecated or superseded.

### 3. Context
- What problem or requirement drives this decision?
- What constraints exist (technical, business, timeline)?
- What forces are in tension?

### 4. Decision
- Clear statement of what was decided
- Specific enough to be actionable

### 5. Options Considered
- At least 2 options, preferably 3
- Each with concrete pros and cons
- Include the chosen option

### 6. Consequences
Split into:
- **Positive** — benefits gained
- **Negative** — trade-offs accepted

### 7. References
- Related ADRs (especially if superseding one)
- Relevant specs, PRDs, or external documentation

## Cross-Referencing Rules

### Referencing Other ADRs
Use the full identifier in references:
```markdown
## References
- Supersedes [ADR-001](ADR-001-original-decision.md)
- Related to [ADR-005](ADR-005-caching-strategy.md)
```

### When Superseding
In the NEW ADR:
```markdown
## References
- Supersedes [ADR-001](ADR-001-original-decision.md)
```

In the OLD ADR, update:
1. Status to `superseded`
2. Add note at top of Status section:
```markdown
## Status
Superseded by [ADR-007](ADR-007-new-decision.md)
```
3. Update the `updated` timestamp

### Referencing from Specs or Code
```markdown
<!-- In spec documents -->
Architecture: See [ADR-003](../../devflow/adrs/ADR-003-use-postgresql.md)
```

```python
# In code comments (only for non-obvious architectural choices)
# Architecture Decision: ADR-003 — Use PostgreSQL for primary datastore
```

## Storage Location

All ADRs are stored in `devflow/adrs/` at the project root.

## Review Process

1. Author creates ADR with status `proposed`
2. Team reviews during architecture discussion or async via PR
3. If approved, author updates status to `accepted`
4. If rejected, author either revises or marks as `superseded` with the alternative ADR

## Quality Checklist

Before accepting an ADR, verify:
- [ ] Title is clear and descriptive
- [ ] Context explains the "why" sufficiently
- [ ] At least 2 options were genuinely considered
- [ ] Pros/cons are honest (not biased toward the chosen option)
- [ ] Consequences include real trade-offs (not just positives)
- [ ] References link to related ADRs and specs
- [ ] Frontmatter dates use real system time per `devflow/rules/datetime.md`
