---
allowed-tools: Bash, Read, Write, LS
---

# Define Project Principles

Establish immutable project principles that guide all development decisions.

## Usage
```
/devflow:principles
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/datetime.md` - For getting real current date/time
- `devflow/rules/principles-standards.md` - For principle format and enforcement

## Preflight Checklist

Before proceeding, complete these validation steps.
Do not bother the user with preflight checks progress. Just do them and move on.

### 1. Check Existing Principles
- Check if `devflow/templates/principles/active-principles.md` already exists
- If it exists, ask user: "Active principles already defined. Do you want to overwrite them? (yes/no)"
- Only proceed with explicit 'yes' confirmation

### 2. Verify Directory Structure
- Check if `devflow/templates/principles/` directory exists
- If not, create it: `mkdir -p devflow/templates/principles/`

### 3. Get Current DateTime
- Run: `date -u +"%Y-%m-%dT%H:%M:%SZ"`
- Store this value for use in frontmatter

## Instructions

### 1. Discovery Interview

Ask the user about their project principles. Present each category and let them choose:

**Development Philosophy:**
- Test-first / TDD: Write tests before implementation
- Simplicity-first: Prefer the simplest solution that works
- Library-first: Use existing libraries over custom code
- Convention over configuration: Follow established patterns
- YAGNI: Don't build what you don't need yet

**Code Quality:**
- Type safety: Strict typing everywhere
- Immutability preferred: Favor immutable data structures
- Pure functions: Minimize side effects
- Single responsibility: One purpose per function/class
- DRY: Don't repeat yourself

**Architecture:**
- API-first design: Define contracts before implementation
- Separation of concerns: Clear layer boundaries
- Dependency injection: Loose coupling between modules
- Event-driven: Prefer async event patterns
- Microservices vs Monolith: State the preference

**Operations:**
- CI/CD mandatory: All changes go through pipeline
- Infrastructure as code: No manual infra changes
- Observable by default: Logging, metrics, tracing built-in
- Security by design: Security considered from the start
- Zero-downtime deployments: Rolling updates required

**Team:**
- Code review required: No direct merges to main
- Documentation as code: Docs live with source
- Trunk-based development: Short-lived branches
- Pair programming encouraged: Complex work done in pairs

### 2. Clarification

For each selected principle, ask:
- **Priority**: Is this a hard rule or a guideline?
- **Enforcement**: How should this be checked? (linting, review, tests, CI)
- **Exceptions**: Are there known exceptions?

### 3. Write Principles File

Save to `devflow/templates/principles/active-principles.md`:

```markdown
---
name: project-principles
status: active
created: [Current ISO date/time]
updated: [Current ISO date/time]
version: 1.0
author: [Project team]
---

# Project Principles

These principles are immutable once established. All development decisions must align with these principles. Violations require explicit team approval and documentation.

## Principle 1: [Name]

**Category:** [Development/Quality/Architecture/Operations/Team]
**Priority:** [Hard Rule / Guideline]
**Description:** [Clear statement of the principle]

**Enforcement:**
- [How this principle is enforced - linting, CI, review, etc.]

**Examples:**
- Good: [Example of following this principle]
- Bad: [Example of violating this principle]

**Exceptions:**
- [Known acceptable exceptions, if any]

---

[Repeat for each principle]

## Principles Compliance Checklist

Before any PR is merged, verify:
- [ ] All hard-rule principles are satisfied
- [ ] Any guideline deviations are documented
- [ ] No principle contradictions exist
- [ ] New code follows established patterns

## Change Process

Principles can only be changed through:
1. Team-wide discussion
2. Documented rationale for the change
3. Impact analysis on existing code
4. Unanimous agreement or majority vote
5. Update to this file with change history
```

### 4. Quality Checks

Before saving, verify:
- [ ] At least 3 principles are defined
- [ ] Each principle has a clear description
- [ ] Each principle has enforcement mechanism
- [ ] No contradictions between principles
- [ ] Priority levels are assigned (hard rule vs guideline)

### 5. Post-Creation

After successfully creating the principles file:
1. Confirm: "Principles established: devflow/templates/principles/active-principles.md"
2. Show summary: List all principles with priorities
3. Suggest next step: "Create your first PRD with: /pm:prd-new <feature-name>"

## Error Recovery

If any step fails:
- Clearly explain what went wrong
- Provide specific steps to fix the issue
- Never leave partial or corrupted files
