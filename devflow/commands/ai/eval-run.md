---
allowed-tools: Read, Write, LS, Glob, Bash
---

# Eval Run

Run the AI evaluation suite against all prompt templates and report results.

## Usage
```
/ai:eval-run
```

Optionally target a specific prompt:
```
/ai:eval-run <prompt-name>
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/ai-patterns.md` — Evaluation metrics, cost tracking

## Preflight Checklist

1. **Locate prompt templates:**
   - Scan `app/ai/prompts/` for directories containing `v*.yaml` files
   - If `$ARGUMENTS` is provided, only evaluate that specific prompt
   - If no prompts found: "No prompts found in `app/ai/prompts/`. Run `/ai:prompt-new <name>` first."

2. **Check for test cases:**
   - Each prompt directory must contain `tests/test_cases.yaml`
   - If missing for any prompt, warn: "No test cases for '[name]'. Skipping."

3. **Verify provider configuration:**
   - Check `.env` or `app/core/config.py` for API key configuration
   - At minimum, one provider must be configured
   - If no keys found, warn: "No LLM provider API keys configured. Set ANTHROPIC_API_KEY or OPENAI_API_KEY in .env"

## Instructions

You are a quality assurance engineer running automated evaluations on AI prompts.

### Step 1: Load Test Cases

For each prompt to evaluate:

```python
# Load prompt definition
prompt_config = load_yaml(f"app/ai/prompts/{name}/v{version}.yaml")
test_cases = load_yaml(f"app/ai/prompts/{name}/tests/test_cases.yaml")
schema = load_schema(f"app/ai/prompts/{name}/schema.py")
```

### Step 2: Run Evaluation Suite

For each test case, execute the prompt and measure:

#### 2a: Accuracy Test
- Send the test case input to the LLM with the prompt
- Parse the response with the Pydantic schema
- Compare against expected output using the test case assertions:
  - `expected.field1` — Exact match
  - `expected.field1_one_of` — Value is in the allowed set
  - `expected.field2_min` — Numeric field >= threshold
  - `expected.field2_max` — Numeric field <= threshold
  - `expected.field3_contains` — Array contains all specified values

```
Test: tc-001 "Standard input with clear category"
  ✅ field1: "authentication" == "authentication"
  ✅ field2: 0.92 >= 0.8 (min threshold)
  ✅ field3: ["password", "access"] contained in ["password", "access", "account"]
  Result: PASS (3/3 assertions)
```

#### 2b: Hallucination Detection
For prompts that reference source material (RAG, summarization):
- Extract all factual claims from the output
- Cross-reference each claim against the input/source material
- Flag claims not supported by the source as potential hallucinations

```
Hallucination check:
  Claims found: 5
  Supported: 4
  Unsupported: 1 — "The user has been locked out for 48 hours" (not in input)
  Hallucination rate: 20%
```

#### 2c: Safety Check
Scan outputs for:
- PII (email addresses, phone numbers, SSN patterns) that should not be generated
- Harmful content (using a keyword/pattern list)
- Prompt injection attempts in the output
- Refusal when the model should have answered (false negative safety)

```
Safety check:
  PII detected: None
  Harmful content: None
  Injection: None
  Result: PASS
```

#### 2d: Latency Benchmark
Measure end-to-end latency for each test case:
- Time from request sent to full response received
- Record p50, p90, p95, p99 across all test cases
- Flag any test case exceeding 5 seconds

```
Latency:
  p50: 1.2s
  p90: 2.1s
  p95: 3.4s
  p99: 4.8s
  Slowest: tc-003 (4.8s) — long input
```

#### 2e: Cost Tracking
Calculate cost for each test case:
- Prompt tokens + completion tokens
- Cost in USD based on model pricing
- Aggregate for the full test suite

```
Cost:
  Total tokens: 4,521 (3,200 input + 1,321 output)
  Total cost: $0.0234
  Per test case avg: $0.0078
```

### Step 3: Format Compliance

Check that every response successfully parses with the Pydantic schema:

```
Format compliance:
  Total responses: 3
  Valid JSON: 3/3
  Schema valid: 3/3
  Compliance rate: 100%
```

### Step 4: Generate Report

Compile all results into a structured report:

```markdown
# AI Evaluation Report

**Date:** [current date/time]
**Prompts evaluated:** [count]
**Total test cases:** [count]

## Summary

| Prompt | Version | Tests | Pass | Fail | Accuracy | Latency (p50) | Cost |
|--------|---------|-------|------|------|----------|---------------|------|
| classify-ticket | v2 | 5 | 4 | 1 | 80% | 1.2s | $0.039 |
| summarize-doc | v1 | 3 | 3 | 0 | 100% | 2.5s | $0.087 |

## Detailed Results

### classify-ticket (v2)

**Model:** claude-sonnet-4-20250514
**Temperature:** 0.3

| Test Case | Result | Assertions | Latency | Tokens | Cost |
|-----------|--------|------------|---------|--------|------|
| tc-001: Standard input | PASS | 3/3 | 1.1s | 412 | $0.007 |
| tc-002: Very short input | PASS | 2/2 | 0.8s | 298 | $0.005 |
| tc-003: Ambiguous input | FAIL | 2/3 | 2.1s | 587 | $0.010 |

**Failed test details:**
- tc-003: field2 (confidence) = 0.95, expected max 0.9
  Suggestion: Add instruction to lower confidence for ambiguous inputs

**Hallucination:** 0/3 cases
**Safety:** 3/3 passed
**Format compliance:** 100%

### Recommendations
1. [Specific improvements based on failures]
2. [Cost optimization suggestions]
3. [Model alternatives if quality is sufficient with cheaper option]

## Metrics Summary
- Overall accuracy: [percentage]
- Hallucination rate: [percentage]
- Safety pass rate: [percentage]
- Format compliance: [percentage]
- Average latency: [time]
- Total evaluation cost: $[amount]
```

Save report to `app/ai/evaluations/eval-[date].md`.

### Step 5: Pass/Fail Determination

Overall evaluation passes if ALL of these are met:
- Accuracy >= 80% across all prompts
- Hallucination rate <= 5%
- Safety pass rate = 100%
- Format compliance >= 95%
- p95 latency <= 5 seconds

```
✅ Evaluation PASSED
  - Accuracy: 90% (target: 80%)
  - Hallucination: 0% (target: <5%)
  - Safety: 100% (target: 100%)
  - Format: 100% (target: 95%)
  - Latency p95: 3.4s (target: <5s)
  Report: app/ai/evaluations/eval-2024-11-15.md
```

Or:

```
❌ Evaluation FAILED
  - Accuracy: 70% (target: 80%) — FAILED
  - Hallucination: 0% (target: <5%)
  - Safety: 100% (target: 100%)
  - Format: 100% (target: 95%)
  - Latency p95: 6.2s (target: <5s) — FAILED
  Failures: 2 metrics below threshold
  Report: app/ai/evaluations/eval-2024-11-15.md
  Next: Fix failing prompts and re-run /ai:eval-run
```

## Error Recovery

- If a provider is unreachable, skip that provider and note it in the report
- If a test case causes an exception, mark it as FAIL with the error message
- If the schema file cannot be loaded, attempt to infer types from test case expected values
- If all test cases fail parsing, likely the prompt needs output format adjustments — suggest specific fixes
