---
allowed-tools: Read, Write, LS, Glob, Bash
---

# Cost Report

Analyze AI/LLM token usage, spending, and provide optimization recommendations.

## Usage
```
/ai:cost-report
```

Optionally specify a time range:
```
/ai:cost-report --period=30d
/ai:cost-report --period=7d
/ai:cost-report --from=2024-11-01 --to=2024-11-30
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/ai-patterns.md` — Cost tracking, token budget management

## Preflight Checklist

1. **Locate usage logs:**
   - Check for `AIUsageLog` table in the database
   - Check for log files in `app/ai/logs/` or `logs/ai/`
   - Check for usage data in application logging system
   - If no usage data found: "No AI usage data found. Ensure cost tracking middleware is logging requests. See `devflow/rules/ai-patterns.md` for setup."

2. **Determine time period:**
   - Default: current calendar month
   - If `--period` flag provided, calculate date range
   - If `--from`/`--to` provided, use those dates

## Instructions

You are a FinOps analyst generating a comprehensive AI cost report.

### Step 1: Gather Usage Data

Query usage logs for the specified period:

```python
# Data points to collect per request:
# - timestamp
# - provider (anthropic, openai, local)
# - model (claude-sonnet-4-20250514, gpt-4o, etc.)
# - feature (which endpoint/function triggered the call)
# - prompt_tokens
# - completion_tokens
# - total_tokens
# - cost_usd
# - latency_ms
# - success (bool)
```

If usage logs are not yet implemented, analyze the codebase to estimate costs:
- Find all LLM call sites
- Estimate tokens per call based on prompt templates
- Project monthly volume based on expected traffic

### Step 2: Token Usage by Provider and Model

```markdown
## Token Usage

### By Provider
| Provider | Requests | Input Tokens | Output Tokens | Total Tokens | Cost |
|----------|----------|-------------|--------------|-------------|------|
| Anthropic | 12,450 | 8,234,000 | 2,891,000 | 11,125,000 | $47.23 |
| OpenAI | 3,200 | 1,890,000 | 654,000 | 2,544,000 | $8.12 |
| Local | 890 | 445,000 | 178,000 | 623,000 | $0.00 |
| **Total** | **16,540** | **10,569,000** | **3,723,000** | **14,292,000** | **$55.35** |

### By Model
| Model | Requests | Avg Tokens/Req | Cost/Req | Total Cost | % of Spend |
|-------|----------|---------------|----------|------------|------------|
| claude-sonnet-4-20250514 | 10,200 | 672 | $0.003 | $32.45 | 58.6% |
| gpt-4o-mini | 3,200 | 795 | $0.002 | $8.12 | 14.7% |
| claude-opus-4-20250514 | 2,250 | 1,024 | $0.007 | $14.78 | 26.7% |
| **Total** | **16,540** | | | **$55.35** | **100%** |
```

### Step 3: Cost by Feature/Endpoint

```markdown
## Cost by Feature

| Feature | Requests | Avg Tokens | Total Cost | % of Spend | Cost/User Action |
|---------|----------|-----------|------------|------------|------------------|
| Chat completion | 8,500 | 890 | $28.90 | 52.2% | $0.0034 |
| Document summary | 3,200 | 1,450 | $15.60 | 28.2% | $0.0049 |
| Ticket classify | 4,000 | 312 | $5.85 | 10.6% | $0.0015 |
| Entity extraction | 840 | 524 | $5.00 | 9.0% | $0.0060 |
| **Total** | **16,540** | | **$55.35** | **100%** | |

### Top Expensive Requests
| Timestamp | Feature | Model | Tokens | Cost | Note |
|-----------|---------|-------|--------|------|------|
| 2024-11-12 14:23 | Chat | opus | 8,432 | $0.52 | Very long conversation |
| 2024-11-08 09:15 | Summary | opus | 6,210 | $0.41 | Large document |
| 2024-11-15 16:45 | Chat | opus | 5,891 | $0.38 | Complex reasoning |
```

### Step 4: Monthly Spend Projection

```markdown
## Monthly Projection

### Current Month
- Days elapsed: [N]
- Current spend: $[amount]
- Daily average: $[amount]
- Projected month-end: $[amount]
- Monthly budget: $[budget from config]
- Budget utilization: [percentage]%

### Trend
| Month | Requests | Total Cost | Avg Cost/Day | MoM Change |
|-------|----------|------------|-------------|------------|
| Sep 2024 | 8,200 | $28.50 | $0.95 | — |
| Oct 2024 | 12,100 | $41.20 | $1.33 | +44.6% |
| Nov 2024 (proj) | 16,540 | $55.35 | $1.85 | +34.3% |

### Growth Alert
[If monthly growth exceeds 25%, flag it]
⚠️ Spending is growing [N]% month-over-month. At this rate:
- Next month: $[projected]
- In 3 months: $[projected]
- In 6 months: $[projected]
```

### Step 5: Optimization Recommendations

Analyze usage patterns and suggest concrete optimizations:

```markdown
## Optimization Recommendations

### 1. Model Downgrade Opportunities
**Potential savings: $[amount]/month**

| Feature | Current Model | Suggested Model | Quality Impact | Savings |
|---------|--------------|----------------|---------------|---------|
| Ticket classify | claude-sonnet | gpt-4o-mini | Minimal (simple task) | $4.20/mo |
| Entity extraction | claude-opus | claude-sonnet | Test needed | $8.50/mo |

Action: Run `/ai:eval-run` with the cheaper model to verify quality.

### 2. Caching Opportunities
**Potential savings: $[amount]/month**

- [N]% of classification requests have identical inputs
- Implement response cache with 1-hour TTL for:
  - Ticket classification (cache key: hash of ticket text)
  - Entity extraction (cache key: hash of document)
- Estimated cache hit rate: [N]%

### 3. Prompt Optimization
**Potential savings: $[amount]/month**

| Prompt | Current Tokens | Optimized Tokens | Savings |
|--------|---------------|-----------------|---------|
| chat_system | 450 | 280 | 38% fewer system tokens |
| summary_system | 380 | 220 | 42% fewer system tokens |

Suggestions:
- Shorten system messages without losing instruction quality
- Remove redundant examples in few-shot prompts
- Use structured delimiters instead of verbose instructions

### 4. Token Budget Enforcement
**Potential savings: $[amount]/month**

- [N] requests exceeded 4,000 tokens (p99)
- Implement max_tokens limits per endpoint
- Add input truncation for chat history (keep last N messages)

### 5. Batching Opportunities
**Potential savings: $[amount]/month**

- [Feature] makes [N] sequential LLM calls that could be batched
- Combine into a single call with multi-task prompt
```

### Step 6: Error and Waste Analysis

```markdown
## Waste Analysis

### Failed Requests
| Provider | Failed | Total | Failure Rate | Wasted Cost |
|----------|--------|-------|-------------|-------------|
| Anthropic | 125 | 12,450 | 1.0% | $0.48 |
| OpenAI | 45 | 3,200 | 1.4% | $0.15 |

### Failure Reasons
| Reason | Count | Cost | Fix |
|--------|-------|------|-----|
| Rate limit (429) | 89 | $0.00 | Improve retry backoff |
| Parse error | 52 | $0.42 | Fix output schema prompt |
| Timeout | 29 | $0.21 | Reduce max_tokens or input size |

### Retries
- Total retries: [N]
- Retry cost: $[amount]
- Most retried endpoint: [name] ([N] retries)
```

### Step 7: Output Report

Save the full report to `app/ai/reports/cost-report-[date].md`.

```
✅ AI Cost Report generated
  - Period: [date range]
  - Total spend: $[amount]
  - Top feature: [name] ([percentage]% of spend)
  - Projected monthly: $[amount]
  - Optimization potential: $[amount]/month savings
  - Report: app/ai/reports/cost-report-[date].md
```

If budget is close to or exceeding limits:
```
⚠️ Budget Alert: Spending at [N]% of monthly budget ($[current]/$[limit])
  Projected to exceed budget by [date]
  Top recommendation: [single most impactful optimization]
```

## Error Recovery

- If no usage logs exist, perform a static analysis of the codebase to estimate costs
- If database is unreachable, check for any local log files
- If pricing data is outdated, use the most recent known pricing and flag it
