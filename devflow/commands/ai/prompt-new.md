---
allowed-tools: Read, Write, LS, Glob, Bash
---

# Prompt New

Create a new versioned prompt template with system message, user template, output schema, and test cases.

## Usage
```
/ai:prompt-new <name>
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/ai-patterns.md` — Prompt engineering standards, structured output, versioning
- `devflow/rules/datetime.md` — For getting real current date/time

## Preflight Checklist

1. **Validate prompt name:**
   - `$ARGUMENTS` must be a non-empty string in kebab-case (lowercase, hyphens only)
   - If invalid: "Prompt name must be kebab-case. Examples: classify-ticket, summarize-document, extract-entities"

2. **Check for existing prompt:**
   - Check if `app/ai/prompts/$ARGUMENTS/` directory exists
   - If exists, check existing versions and ask: "Prompt '$ARGUMENTS' exists with version [N]. Create version [N+1]?"

3. **Verify directory structure:**
   - Ensure `app/ai/prompts/` directory exists
   - If not, create it: `mkdir -p app/ai/prompts/$ARGUMENTS`

## Instructions

You are a prompt engineer creating a production-grade prompt template for: **$ARGUMENTS**

### Step 1: Gather Requirements

Ask the user:
- **What does this prompt do?** (classify, summarize, generate, extract, transform, etc.)
- **What is the input?** (user text, document, structured data, conversation history)
- **What is the expected output?** (category, summary, JSON, text, etc.)
- **What model do you recommend?** (default: claude-sonnet-4-20250514 for cost/quality balance)
- **Any constraints?** (max length, tone, format, forbidden content)
- **Example inputs and outputs?** (at least 1 to understand the pattern)

If the user wants defaults, use sensible values based on the prompt name.

### Step 2: Design the System Message

Write a system message that:
- Defines a clear persona ("You are a ...")
- States the task concisely
- Lists constraints and rules
- Specifies the output format explicitly
- Includes few-shot examples if the pattern is not obvious

```yaml
system: |
  You are a [role] specialized in [domain].

  Your task is to [action] based on the provided [input type].

  Rules:
  - [Rule 1]
  - [Rule 2]
  - [Rule 3]

  Output format:
  Respond with a JSON object matching this schema:
  {
    "field1": "string — description",
    "field2": 0.0,  // number — description
    "field3": ["string"]  // array — description
  }

  Examples:
  Input: "[example input 1]"
  Output: {"field1": "value1", "field2": 0.95, "field3": ["tag1", "tag2"]}

  Input: "[example input 2]"
  Output: {"field1": "value2", "field2": 0.72, "field3": ["tag3"]}
```

### Step 3: Design the User Template

Create a user message template with clear variable placeholders:

```yaml
user_template: |
  [Action verb] the following [input type]:

  <input>
  {input_variable}
  </input>

  [Additional context if needed]:
  {context_variable}
```

Variable naming rules:
- Use `snake_case` for variable names
- Wrap input data in XML tags for clear delimiting
- Keep the template focused — one task per prompt
- Mark optional variables with a comment

### Step 4: Define Output Schema (Pydantic)

Create a Pydantic model for the expected output:

```python
# app/ai/prompts/<name>/schema.py
from pydantic import BaseModel, Field
from typing import Optional

class PromptNameOutput(BaseModel):
    """Output schema for the <name> prompt."""

    field1: str = Field(
        description="Description of field1"
    )
    field2: float = Field(
        ge=0.0, le=1.0,
        description="Confidence score between 0 and 1"
    )
    field3: list[str] = Field(
        default_factory=list,
        description="List of extracted tags"
    )
    reasoning: Optional[str] = Field(
        default=None,
        description="Chain-of-thought reasoning (optional, for debugging)"
    )
```

### Step 5: Create Test Cases

Write a minimum of 3 test cases covering:
1. **Happy path** — Typical, well-formed input
2. **Edge case** — Unusual but valid input (very short, very long, special characters)
3. **Boundary case** — Input that tests the limits of the prompt (ambiguous, multi-category)

```yaml
test_cases:
  - id: tc-001
    description: "Standard input with clear category"
    input:
      input_variable: "I cannot access my account after changing my password yesterday"
    expected:
      field1: "authentication"
      field2_min: 0.8
      field3_contains: ["password", "access"]
    tags: [happy-path]

  - id: tc-002
    description: "Very short input"
    input:
      input_variable: "slow"
    expected:
      field1: "performance"
      field2_max: 0.7  # Lower confidence expected for short input
    tags: [edge-case]

  - id: tc-003
    description: "Ambiguous input spanning multiple categories"
    input:
      input_variable: "My billing page is slow and I can't see my invoices because I keep getting logged out"
    expected:
      field1_one_of: ["authentication", "billing", "performance"]
      field2_max: 0.9  # Should not be over-confident
    tags: [boundary]
```

### Step 6: Model Recommendations

Based on the prompt complexity and requirements:

```yaml
models:
  recommended: claude-sonnet-4-20250514
  reason: "Good balance of quality and cost for classification tasks"
  alternatives:
    - model: gpt-4o-mini
      reason: "Cheaper, acceptable for simple classification"
      tradeoff: "Slightly lower accuracy on ambiguous cases"
    - model: claude-opus-4-20250514
      reason: "Highest quality for complex reasoning"
      tradeoff: "5x cost increase, use only if sonnet accuracy is insufficient"
```

### Step 7: Token Budget Estimate

Calculate expected token usage:

```yaml
token_budget:
  system_message: ~[N] tokens
  user_template_base: ~[N] tokens (excluding input)
  average_input: ~[N] tokens
  expected_output: ~[N] tokens
  total_per_request: ~[N] tokens
  estimated_cost_per_request: $[amount]
  monthly_estimate_at_1000_requests: $[amount]
```

### Step 8: Generate Files

Create the following files:

```
app/ai/prompts/<name>/
├── v1.yaml              # Complete prompt definition
├── schema.py            # Pydantic output model
├── config.yaml          # Active version config
└── tests/
    └── test_cases.yaml  # Test cases
```

**v1.yaml:**
```yaml
name: <name>
version: 1
description: "[Brief description of what this prompt does]"
created: "[ISO datetime]"
model: claude-sonnet-4-20250514
temperature: 0.3
max_tokens: [calculated budget]

system: |
  [System message from Step 2]

user_template: |
  [User template from Step 3]

output_schema: PromptNameOutput
variables:
  - name: input_variable
    type: string
    required: true
    description: "[What this variable contains]"

token_budget:
  system: [N]
  user_base: [N]
  avg_input: [N]
  max_output: [N]
```

**config.yaml:**
```yaml
active_version: 1
ab_test:
  enabled: false
  split: {}
  metric: accuracy
  min_samples: 100
```

### Step 9: Output

```
✅ Prompt created: $ARGUMENTS
  - Version: v1
  - Model: [recommended model]
  - Schema: [Pydantic model name] with [N] fields
  - Test cases: [N] cases ([N] happy, [N] edge, [N] boundary)
  - Est. cost: $[amount]/request
  - Files: app/ai/prompts/$ARGUMENTS/
Next: /ai:eval-run to test the prompt against the test cases
```

## Error Recovery

- If the user cannot provide examples, generate synthetic examples based on the described task
- If the Pydantic schema is complex, ask the user to confirm field names and types before generating
- If cost estimate seems high, suggest cheaper model alternatives
