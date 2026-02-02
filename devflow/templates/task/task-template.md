---
name: {Task Title}
status: open
created: {datetime}
updated: {datetime}
github:
depends_on: []
parallel: true
conflicts_with: []
---

# Task: {Task Title}

## Description

{Clear, concise description of what needs to be done. Include enough context for a developer to understand the scope without reading the full epic.}

## Acceptance Criteria

- [ ] {Specific, testable criterion 1}
- [ ] {Specific, testable criterion 2}
- [ ] {Specific, testable criterion 3}
- [ ] {Specific, testable criterion 4}

## Technical Details

### Implementation Approach
{How this should be implemented. Reference architecture patterns, design decisions.}

### Key Considerations
- {Important consideration 1}
- {Important consideration 2}

### Files Affected
- `{path/to/file1}` - {what changes}
- `{path/to/file2}` - {what changes}

### Related Requirements
- {FR-xxx}: {requirement title}
- {FR-xxx}: {requirement title}

## Dependencies

### Task Dependencies
- [ ] #{task_number} - {task title} (must complete first)

### External Dependencies
- {External service, library, or resource needed}

## Effort Estimate

- **Size:** {XS (< 2h) / S (2-4h) / M (4-8h) / L (8-16h) / XL (16-32h)}
- **Hours:** {estimated hours}
- **Parallel:** {true/false - can this run alongside other tasks?}
- **Complexity:** {Low / Medium / High}

## Definition of Done

- [ ] Code implemented following project style guide
- [ ] Unit tests written and passing (>= 80% coverage for new code)
- [ ] Integration tests passing
- [ ] No linting errors or warnings
- [ ] Documentation updated (docstrings, API docs)
- [ ] Code reviewed and approved
- [ ] All acceptance criteria verified
