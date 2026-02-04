---
allowed-tools: Bash, Read, Write, LS, AskUserQuestion
---

# PRD New

Launch brainstorming for new product requirement document.

## Usage
```
/pm:prd-new <feature_name>
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/datetime.md` - For getting real current date/time

## Preflight Checklist

Before proceeding, complete these validation steps.
Do not bother the user with preflight checks progress ("I'm not going to ..."). Just do them and move on.

### Input Validation
1. **Validate feature name format:**
   - Must contain only lowercase letters, numbers, and hyphens
   - Must start with a letter
   - No spaces or special characters allowed
   - If invalid, tell user: "Feature name must be kebab-case (lowercase letters, numbers, hyphens only). Examples: user-auth, payment-v2, notification-system"

2. **Check for existing PRD:**
   - Check if `devflow/prds/$ARGUMENTS.md` already exists
   - If it exists, ask user: "PRD '$ARGUMENTS' already exists. Do you want to overwrite it? (yes/no)"
   - Only proceed with explicit 'yes' confirmation
   - If user says no, suggest: "Use a different name or run: /pm:prd-edit $ARGUMENTS to edit the existing PRD"

3. **Verify directory structure:**
   - Check if `devflow/prds/` directory exists
   - If not, create it first
   - If unable to create, tell user: "Cannot create PRD directory. Please manually create: devflow/prds/"

## Instructions

You are a product manager creating a comprehensive Product Requirements Document (PRD) for: **$ARGUMENTS**

Follow this structured approach:

### 1. Discovery & Context — PROBLEM DEEP-DIVE (MANDATORY)

**CRITICAL:** This is the most important step. You MUST thoroughly understand the problem before defining solutions. Use AskUserQuestion systematically.

#### Phase 1: Problem Statement (3-5 questions)

Use AskUserQuestion to probe the problem:

**Question 1: Problem Origin**
> What specific pain point or opportunity triggered this?
> - Existing workflow is too slow/manual
> - Users are requesting this feature
> - Competitive pressure
> - New market opportunity
> - Technical debt causing issues
> - Compliance/regulatory requirement

**Question 2: Impact Assessment**
> How severe is this problem today?
> - Critical: Blocking users, causing revenue loss
> - High: Significant friction, workarounds needed
> - Medium: Annoyance but manageable
> - Low: Nice-to-have improvement

**Question 3: Current State**
> How are users solving this problem today?
> - Manual process (describe)
> - Third-party tool
> - They can't (feature gap)
> - Internal workaround

**Question 4: Success Vision**
> What does success look like when this is solved?
> - Specific outcome (e.g., "Users can X in under Y minutes")
> - Metric improvement (e.g., "Reduce support tickets by 50%")
> - User sentiment (e.g., "Users no longer complain about X")

#### Phase 2: User Understanding (2-3 questions)

**Question 5: Primary Users**
> Who are the primary users of this solution?
> Options should be specific roles, not generic "users"
> Examples: Admin users, End customers, API consumers, Internal team members

**Question 6: User Context**
> What is true about these users?
> - Technical skill level
> - Frequency of use (daily, weekly, occasionally)
> - Environment (mobile, desktop, both)
> - Urgency (real-time needs vs batch)

#### Phase 3: Constraints Discovery (2-3 questions)

**Question 7: Technical Constraints**
> Are there any technical constraints we must respect?
> - Must integrate with existing system X
> - Cannot change database schema
> - Must support legacy API
> - Performance requirements (latency, throughput)
> - No constraints - greenfield

**Question 8: Business Constraints**
> Are there business/timeline constraints?
> - Hard deadline (compliance, launch, etc.)
> - Budget limitations
> - Team size limitations
> - Must not break existing functionality

**Question 9: Out of Scope Confirmation**
> What should we explicitly NOT build?
> (This prevents scope creep and sets clear boundaries)

#### Phase 4: Tech Stack Confirmation

**Question 10: Backend Stack**
> Backend technology (default: Python + FastAPI)?
> - Python + FastAPI (Recommended)
> - Python + Django
> - Node.js + Express
> - Other (specify)

**Question 11: Frontend Stack**
> Frontend technology (if applicable)?
> - Angular + DaisyUI + Tailwind (Recommended for complex apps)
> - React + Tailwind (Recommended for simpler apps)
> - No frontend (API/library only)
> - Other (specify)

**Question 12: Database**
> Database (default: PostgreSQL)?
> - PostgreSQL (Recommended)
> - MySQL
> - MongoDB
> - SQLite (dev only)
> - Other (specify)

### 2. PRD Structure
Create a comprehensive PRD with these sections:

#### Executive Summary
- Brief overview and value proposition
- Target audience
- Expected impact

#### Problem Statement
- What problem are we solving?
- Why is this important now?
- Current workarounds or pain points

#### User Stories
- Primary user personas
- Detailed user journeys
- Pain points being addressed
- Format: As a [persona], I want [action] so that [benefit]

#### Requirements
**Functional Requirements**
- Core features and capabilities
- User interactions and flows
- API requirements (if applicable)
- Data requirements

**Non-Functional Requirements**
- Performance expectations (response times, throughput)
- Security considerations (auth, encryption, OWASP)
- Scalability needs (users, data volume)
- Reliability (uptime, recovery)
- Accessibility (WCAG compliance level)

#### Success Criteria
- Measurable outcomes
- Key metrics and KPIs
- Acceptance thresholds

#### Constraints & Assumptions
- Technical limitations
- Timeline constraints
- Resource limitations
- Budget constraints
- Technology assumptions (Python+FastAPI backend, PostgreSQL, etc.)

#### Out of Scope
- What we're explicitly NOT building
- Deferred features for future iterations

#### Dependencies
- External dependencies (third-party APIs, services)
- Internal team dependencies
- Infrastructure dependencies

### 3. File Format with Frontmatter
Save the completed PRD to: `devflow/prds/$ARGUMENTS.md` with this exact structure:

```markdown
---
name: $ARGUMENTS
description: [Brief one-line description of the PRD]
status: backlog
created: [Current ISO date/time]
updated: [Current ISO date/time]
---

# PRD: $ARGUMENTS

## Executive Summary
[Content...]

## Problem Statement
[Content...]

## User Stories
[Content...]

## Requirements

### Functional Requirements
[Content...]

### Non-Functional Requirements
[Content...]

## Success Criteria
[Content...]

## Constraints & Assumptions
[Content...]

## Out of Scope
[Content...]

## Dependencies
[Content...]
```

### 4. Frontmatter Guidelines
- **name**: Use the exact feature name (same as $ARGUMENTS)
- **description**: Write a concise one-line summary of what this PRD covers
- **status**: Always start with "backlog" for new PRDs
- **created**: Get REAL current datetime by running: `date -u +"%Y-%m-%dT%H:%M:%SZ"`
  - Never use placeholder text
  - Must be actual system time in ISO 8601 format
- **updated**: Same as created for new PRDs

### 5. Quality Checks

Before saving the PRD, verify:
- [ ] All sections are complete (no placeholder text)
- [ ] User stories include acceptance criteria
- [ ] Success criteria are measurable
- [ ] Dependencies are clearly identified
- [ ] Out of scope items are explicitly listed
- [ ] Non-functional requirements have specific numbers
- [ ] Tech stack assumptions are documented

### 6. PRD Review & Validation (MANDATORY)

Before finalizing, present the PRD summary to the user and validate:

**Use AskUserQuestion:**
> I've drafted the PRD based on our discussion. Please review:
>
> **Problem:** [1-sentence summary]
> **Users:** [Primary user types]
> **Core Features:** [Bullet list]
> **Success Metrics:** [Key metrics]
> **Out of Scope:** [Key exclusions]
>
> Does this accurately capture what you want to build?
> - Yes, proceed to save
> - Needs changes (specify what)
> - Start over with different focus

If changes needed, iterate until user confirms.

### 7. Post-Creation

After successfully creating the PRD:
1. Confirm: "PRD created: devflow/prds/$ARGUMENTS.md"
2. Show brief summary of what was captured:
   - Problem statement
   - Primary users
   - Core features count
   - Success criteria count
   - Constraints identified
3. **IMPORTANT:** Suggest the NEXT step in sequence:
   - "Next step: Create a formal spec: /pm:spec-create $ARGUMENTS"
   - "This will transform your PRD into detailed user stories with acceptance criteria."

## Error Recovery

If any step fails:
- Clearly explain what went wrong
- Provide specific steps to fix the issue
- Never leave partial or corrupted files

## Key Principle

**Problem-first, solution-second.** The PRD must clearly articulate the problem BEFORE defining features. Every feature should trace back to a validated user pain point discovered in the probe questioning phase.
