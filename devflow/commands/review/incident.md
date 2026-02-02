---
allowed-tools: Bash, Read, Write, LS
---

# Incident Report

Create a structured incident report and postmortem document.

## Usage
```
/review:incident
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/observability.md` — Logging, metrics, alerting context
- `devflow/rules/deploy-patterns.md` — Rollback procedures
- `devflow/rules/datetime.md` — For getting real current date/time
- `devflow/rules/standard-patterns.md` — Standard output patterns

## Instructions

### 1. Gather Incident Information

Ask the user the following questions (wait for responses before proceeding):

1. **What happened?** Brief description of the incident
2. **When was it detected?** Date/time of first detection
3. **What was the impact?** Users affected, services degraded, data loss
4. **What was the severity?**
   - **SEV1 (Critical):** Complete service outage, data loss, security breach
   - **SEV2 (Major):** Partial outage, significant degradation for many users
   - **SEV3 (Minor):** Degraded experience for subset of users, workaround exists
   - **SEV4 (Low):** Minimal impact, cosmetic issues, noticed internally
5. **What was the root cause?** (if known)
6. **How was it resolved?** Steps taken to fix
7. **Is it fully resolved?** Or still partially degraded

### 2. Create Incident Directory

```bash
mkdir -p .claude/incidents
```

### 3. Generate Incident Report

Get the current datetime:
```bash
date -u +"%Y-%m-%dT%H:%M:%SZ"
```

Generate an incident ID from the date:
```bash
date -u +"%Y%m%d"
```

**Create `.claude/incidents/INC-{YYYYMMDD}-{short-slug}.md`:**

```markdown
---
id: INC-{YYYYMMDD}-{short-slug}
title: {brief title}
severity: {SEV1/SEV2/SEV3/SEV4}
status: {resolved/monitoring/investigating}
created: {ISO datetime}
resolved: {ISO datetime or "ongoing"}
duration: {time from detection to resolution}
owner: {team or person}
---

# Incident Report: {title}

## Summary

**Severity:** {SEV level}
**Status:** {resolved/monitoring/investigating}
**Duration:** {detection to resolution time}
**Impact:** {description of user/business impact}

## Timeline

All times in UTC.

| Time | Event |
|------|-------|
| {HH:MM} | Incident detected: {how it was detected — alert, user report, monitoring} |
| {HH:MM} | Investigation started: {first responder actions} |
| {HH:MM} | Root cause identified: {what was found} |
| {HH:MM} | Mitigation applied: {what was done to stop the bleeding} |
| {HH:MM} | Fix deployed: {what was deployed} |
| {HH:MM} | Incident resolved: {confirmation of resolution} |

## Impact Assessment

### Users Affected
- **Count:** {number or percentage of users affected}
- **Duration:** {how long users experienced the issue}
- **Symptoms:** {what users saw — error pages, slow responses, missing data}

### Business Impact
- {Revenue impact, if any}
- {SLA violation, if any}
- {Data integrity issues, if any}
- {Reputational impact, if any}

### Services Affected
| Service | Impact | Duration |
|---------|--------|----------|
| {service name} | {down/degraded} | {duration} |

## Root Cause Analysis

### What happened
{Detailed technical explanation of what went wrong}

### Why it happened
{Chain of causation — use 5 Whys technique}

1. **Why** did {symptom} occur? Because {cause 1}.
2. **Why** did {cause 1} occur? Because {cause 2}.
3. **Why** did {cause 2} occur? Because {cause 3}.
4. **Why** did {cause 3} occur? Because {cause 4}.
5. **Why** did {cause 4} occur? Because {root cause}.

### Contributing factors
- {Factor 1: e.g., missing monitoring for this failure mode}
- {Factor 2: e.g., no automated rollback configured}
- {Factor 3: e.g., insufficient testing of edge case}

## Resolution

### Immediate fix
{What was done to resolve the incident}

### Verification
{How we confirmed the fix worked}

## Action Items

| Priority | Action | Owner | Due Date | Status |
|----------|--------|-------|----------|--------|
| P0 | {Immediate fix to prevent recurrence} | {owner} | {date} | {open/done} |
| P1 | {Add monitoring/alerting for this failure mode} | {owner} | {date} | {open/done} |
| P1 | {Add test coverage for the failing scenario} | {owner} | {date} | {open/done} |
| P2 | {Improve documentation/runbook} | {owner} | {date} | {open/done} |
| P2 | {Address contributing factors} | {owner} | {date} | {open/done} |

## Lessons Learned

### What went well
- {e.g., Alert fired promptly, team responded quickly}
- {e.g., Rollback procedure worked as expected}

### What could be improved
- {e.g., Detection took too long — need better monitoring}
- {e.g., Communication during incident was unclear}
- {e.g., Runbook was outdated}

### What was lucky
- {e.g., Happened during low-traffic hours}
- {e.g., A team member happened to be online}

## Prevention

### Short-term (this week)
- {Specific action to prevent immediate recurrence}

### Medium-term (this month)
- {Monitoring improvements}
- {Test coverage additions}
- {Process changes}

### Long-term (this quarter)
- {Architectural changes to eliminate the failure mode}
- {Tooling improvements}
```

### 4. Post-Creation

```
Incident report created: .claude/incidents/INC-{id}.md

Next steps:
  1. Review and fill in any remaining details
  2. Share with the team for review
  3. Schedule postmortem meeting within 48 hours (for SEV1/SEV2)
  4. Track action items to completion
  5. Update the report when action items are completed
```

## Error Recovery

- If `.claude/incidents/` cannot be created, suggest an alternative path
- If the user cannot answer all questions, fill in what is known and mark others as "TBD"
- If this is an ongoing incident, mark status as "investigating" and suggest updating later
