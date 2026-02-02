# Principles Format and Enforcement Standards

Standards for defining, evaluating, and enforcing project principles in the DevFlow system.

## Principle Definition Format

Every principle MUST follow this structure:

```markdown
#### Principle {N}: {Name}

**Category:** {Development/Quality/Architecture/Operations/Team}
**Priority:** {Hard Rule / Guideline}
**Description:** {One clear sentence describing the principle}

**Enforcement:**
- {How this principle is enforced - must be actionable}

**Examples:**
- **Good:** {Concrete example of following this principle}
- **Bad:** {Concrete example of violating this principle}

**Exceptions:**
- {Known exceptions, or "None"}
```

## Priority Levels

### Hard Rule
- MUST be followed in all cases
- Violations block PR merges
- Exceptions require documented team approval
- Enforced by automated checks where possible
- Examples: "All code must have tests", "No secrets in code"

### Guideline
- SHOULD be followed in most cases
- Violations require explanation in PR description
- Individual developer judgment accepted
- Enforced by code review
- Examples: "Prefer composition over inheritance", "Keep functions under 20 lines"

## Categories

### Development
Principles about how code is written:
- Test-first / TDD
- Simplicity-first
- Library-first (use existing libraries)
- YAGNI (don't build what you don't need)
- Convention over configuration

### Quality
Principles about code quality standards:
- Type safety
- Immutability preferred
- Pure functions
- Single responsibility
- DRY (Don't Repeat Yourself)

### Architecture
Principles about system design:
- API-first design
- Separation of concerns
- Dependency injection
- Event-driven patterns
- Monolith vs Microservices preference

### Operations
Principles about deployment and infrastructure:
- CI/CD mandatory
- Infrastructure as code
- Observable by default (logging, metrics, tracing)
- Security by design
- Zero-downtime deployments

### Team
Principles about team collaboration:
- Code review required
- Documentation as code
- Trunk-based development
- Pair programming for complex work

## Evaluation Rules

### When Creating Specs
- Each spec requirement must be checked against all Hard Rule principles
- Contradictions must be flagged as critical issues
- Guideline tensions should be noted as warnings

### When Creating Plans
- Architecture decisions must reference relevant principles
- Tech stack choices must align with principles
- Deviations must have documented rationale

### When Creating Tasks
- Task acceptance criteria should enforce relevant principles
- Definition of Done must include principle compliance

### When Reviewing Code
- PR checklist must include principles compliance check
- Violations of Hard Rules block merge
- Violations of Guidelines require explanation

## Enforcement Mechanisms

### Automated Enforcement
For principles that can be checked automatically:
- Linting rules (configured in project linter)
- Pre-commit hooks (fail fast)
- CI pipeline checks (gate on merge)
- Static analysis tools

### Manual Enforcement
For principles that require human judgment:
- Code review checklist items
- Architecture review for significant changes
- Sprint retrospective principle audit

## Change Process

Principles are intended to be stable. Changes require:

1. **Written Proposal:** Why the change is needed, impact analysis
2. **Discussion Period:** Minimum 48 hours for team input
3. **Impact Analysis:** What existing code would violate the new principle
4. **Approval:** Team consensus (no strong objections)
5. **Documentation:** Update principles file with change history
6. **Grace Period:** Existing code has {N} sprints to comply

## Minimum Requirements

A valid principles file must have:
- At least 3 principles defined
- At least 1 Hard Rule
- Each principle has enforcement mechanism
- Each principle has good and bad examples
- No contradictions between principles
- Change process documented

## File Location

Active principles are stored at:
```
devflow/templates/principles/active-principles.md
```

The template for creating new principles files is at:
```
devflow/templates/principles/principles-template.md
```
