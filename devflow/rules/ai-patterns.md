# AI/LLM Integration Patterns

Standards and patterns for integrating AI/LLM capabilities into Python + FastAPI applications.

## Multi-Provider Abstraction

Never hard-code a single AI provider. Use an abstraction layer that supports provider switching:

```python
# app/ai/providers/base.py
from abc import ABC, abstractmethod
from pydantic import BaseModel
from typing import AsyncIterator

class LLMMessage(BaseModel):
    role: str  # "system", "user", "assistant"
    content: str

class LLMResponse(BaseModel):
    content: str
    model: str
    provider: str
    usage: dict  # {"prompt_tokens": int, "completion_tokens": int, "total_tokens": int}
    latency_ms: float

class BaseLLMProvider(ABC):
    """Abstract base for all LLM providers."""

    @abstractmethod
    async def complete(
        self,
        messages: list[LLMMessage],
        model: str | None = None,
        temperature: float = 0.7,
        max_tokens: int = 1024,
    ) -> LLMResponse:
        ...

    @abstractmethod
    async def stream(
        self,
        messages: list[LLMMessage],
        model: str | None = None,
        temperature: float = 0.7,
        max_tokens: int = 1024,
    ) -> AsyncIterator[str]:
        ...
```

### Supported Providers

```python
# app/ai/providers/anthropic.py
class AnthropicProvider(BaseLLMProvider):
    """Anthropic Claude provider."""
    # Uses: anthropic Python SDK
    # Models: claude-sonnet-4-20250514, claude-opus-4-20250514
    # Auth: ANTHROPIC_API_KEY env var

# app/ai/providers/openai.py
class OpenAIProvider(BaseLLMProvider):
    """OpenAI GPT provider."""
    # Uses: openai Python SDK
    # Models: gpt-4o, gpt-4o-mini
    # Auth: OPENAI_API_KEY env var

# app/ai/providers/local.py
class LocalProvider(BaseLLMProvider):
    """Local model provider (Ollama, vLLM, etc.)."""
    # Uses: HTTP client to local endpoint
    # Models: llama3, mistral, etc.
    # Auth: None (local)
```

### Provider Registry

```python
# app/ai/registry.py
from app.core.config import settings

class ProviderRegistry:
    """Manage and select LLM providers."""

    _providers: dict[str, BaseLLMProvider] = {}

    def register(self, name: str, provider: BaseLLMProvider) -> None:
        self._providers[name] = provider

    def get(self, name: str | None = None) -> BaseLLMProvider:
        name = name or settings.DEFAULT_LLM_PROVIDER
        if name not in self._providers:
            raise ValueError(f"Provider '{name}' not registered. Available: {list(self._providers.keys())}")
        return self._providers[name]

registry = ProviderRegistry()
```

## Prompt Engineering Standards

### Message Structure

Always use the system/user/assistant role pattern:

```python
messages = [
    LLMMessage(role="system", content="You are a helpful assistant that..."),
    LLMMessage(role="user", content="The actual user request..."),
]
```

**System message rules:**
- Define the persona and constraints
- Specify the output format
- List what the model should NOT do
- Keep under 500 tokens for efficiency

**User message rules:**
- Provide context first, then the request
- Use clear delimiters for input data (XML tags, triple backticks, or markdown headers)
- Be explicit about desired output format

### Few-Shot Prompting

When the model needs to follow a specific pattern, provide 2-3 examples:

```python
system = """You classify support tickets into categories.
Respond with only the category name.

Examples:
Input: "I can't log in to my account"
Output: authentication

Input: "The page loads very slowly"
Output: performance

Input: "I want to cancel my subscription"
Output: billing
"""
```

### Chain-of-Thought

For complex reasoning tasks, instruct step-by-step thinking:

```python
system = """Analyze the user's request step by step:
1. Identify the core problem
2. List possible solutions
3. Evaluate each solution
4. Recommend the best approach

Format your response as:
## Analysis
[step-by-step reasoning]

## Recommendation
[final recommendation]
"""
```

## Structured Output with Pydantic

### Using Instructor Library (Preferred)

```python
import instructor
from anthropic import Anthropic
from pydantic import BaseModel, Field

class TicketClassification(BaseModel):
    category: str = Field(description="The ticket category")
    confidence: float = Field(ge=0, le=1, description="Confidence score")
    reasoning: str = Field(description="Why this category was chosen")

client = instructor.from_anthropic(Anthropic())

result = client.messages.create(
    model="claude-sonnet-4-20250514",
    max_tokens=1024,
    messages=[{"role": "user", "content": ticket_text}],
    response_model=TicketClassification,
)
# result is a validated TicketClassification instance
```

### Manual JSON Parsing (Fallback)

```python
import json
from pydantic import BaseModel, ValidationError

async def parse_structured_output(
    response: str,
    model_class: type[BaseModel],
) -> BaseModel:
    """Extract JSON from LLM response and validate with Pydantic."""
    # Try direct JSON parse
    try:
        data = json.loads(response)
        return model_class.model_validate(data)
    except (json.JSONDecodeError, ValidationError):
        pass

    # Try extracting JSON from markdown code block
    import re
    json_match = re.search(r"```(?:json)?\s*([\s\S]*?)```", response)
    if json_match:
        try:
            data = json.loads(json_match.group(1))
            return model_class.model_validate(data)
        except (json.JSONDecodeError, ValidationError) as e:
            raise ValueError(f"Failed to parse structured output: {e}")

    raise ValueError("No valid JSON found in response")
```

## Token Budget Management

### Token Counting

```python
import tiktoken

def count_tokens(text: str, model: str = "gpt-4") -> int:
    """Count tokens for a given text and model."""
    try:
        encoding = tiktoken.encoding_for_model(model)
    except KeyError:
        encoding = tiktoken.get_encoding("cl100k_base")
    return len(encoding.encode(text))

def estimate_anthropic_tokens(text: str) -> int:
    """Rough estimate for Anthropic models (no official tokenizer)."""
    # Approximation: ~4 characters per token for English
    return len(text) // 4
```

### Truncation Strategies

```python
def truncate_to_budget(
    messages: list[LLMMessage],
    max_tokens: int,
    strategy: str = "trim_middle",
) -> list[LLMMessage]:
    """Truncate messages to fit within token budget."""

    if strategy == "trim_oldest":
        # Keep system message + most recent messages
        system = [m for m in messages if m.role == "system"]
        others = [m for m in messages if m.role != "system"]
        # Remove oldest non-system messages until under budget
        while count_tokens(str(others)) > max_tokens and len(others) > 1:
            others.pop(0)
        return system + others

    elif strategy == "trim_middle":
        # Keep system + first user message + last N messages
        system = [m for m in messages if m.role == "system"]
        others = [m for m in messages if m.role != "system"]
        if len(others) <= 2:
            return messages
        first = others[0]
        # Keep adding from the end until budget is reached
        kept = [first]
        for msg in reversed(others[1:]):
            if count_tokens(str(kept + [msg])) < max_tokens:
                kept.insert(1, msg)
            else:
                break
        return system + kept

    elif strategy == "summarize":
        # Summarize older messages into a single context message
        # Requires an LLM call — use for long conversations
        pass

    return messages
```

### Budget Configuration

```python
# app/core/config.py
class AISettings(BaseModel):
    # Token budgets per request type
    CHAT_MAX_INPUT_TOKENS: int = 4096
    CHAT_MAX_OUTPUT_TOKENS: int = 1024
    ANALYSIS_MAX_INPUT_TOKENS: int = 8192
    ANALYSIS_MAX_OUTPUT_TOKENS: int = 2048
    RAG_CONTEXT_TOKENS: int = 3000
    RAG_QUERY_TOKENS: int = 500
```

## Retry and Fallback Strategies

### Exponential Backoff

```python
import asyncio
from typing import TypeVar

T = TypeVar("T")

async def retry_with_backoff(
    func,
    max_retries: int = 3,
    base_delay: float = 1.0,
    max_delay: float = 30.0,
    retryable_errors: tuple = (Exception,),
) -> T:
    """Retry an async function with exponential backoff."""
    last_error = None
    for attempt in range(max_retries):
        try:
            return await func()
        except retryable_errors as e:
            last_error = e
            if attempt < max_retries - 1:
                delay = min(base_delay * (2 ** attempt), max_delay)
                await asyncio.sleep(delay)
    raise last_error
```

### Provider Fallback Chain

```python
async def complete_with_fallback(
    messages: list[LLMMessage],
    providers: list[str] = ["anthropic", "openai", "local"],
    **kwargs,
) -> LLMResponse:
    """Try each provider in order until one succeeds."""
    errors = []
    for provider_name in providers:
        try:
            provider = registry.get(provider_name)
            return await retry_with_backoff(
                lambda: provider.complete(messages, **kwargs)
            )
        except Exception as e:
            errors.append(f"{provider_name}: {e}")
            continue
    raise RuntimeError(f"All providers failed: {'; '.join(errors)}")
```

## Streaming Patterns (SSE for FastAPI)

```python
from fastapi import APIRouter
from fastapi.responses import StreamingResponse
from sse_starlette.sse import EventSourceResponse

router = APIRouter()

@router.post("/api/v1/ai/chat/stream")
async def stream_chat(request: ChatRequest):
    """Stream AI response via Server-Sent Events."""

    async def event_generator():
        provider = registry.get()
        async for chunk in provider.stream(
            messages=request.messages,
            model=request.model,
            temperature=request.temperature,
        ):
            yield {"event": "message", "data": chunk}
        yield {"event": "done", "data": "[DONE]"}

    return EventSourceResponse(event_generator())
```

Frontend consumption (Angular):
```typescript
const eventSource = new EventSource('/api/v1/ai/chat/stream');
eventSource.onmessage = (event) => {
  if (event.data === '[DONE]') {
    eventSource.close();
    return;
  }
  appendToResponse(event.data);
};
```

## Evaluation Metrics

### Standard Metrics

| Metric | Description | Target | How to Measure |
|--------|-------------|--------|----------------|
| Accuracy | Correct outputs / total outputs | > 90% | Human review or reference dataset |
| Relevance | Output addresses the input query | > 95% | Cosine similarity to reference answers |
| Safety | No harmful, biased, or inappropriate content | 100% | Keyword + classifier check |
| Latency (p50) | Median response time | < 2s | Request timing middleware |
| Latency (p95) | 95th percentile response time | < 5s | Request timing middleware |
| Hallucination rate | Fabricated facts / total claims | < 5% | Fact-checking against source docs |
| Format compliance | Outputs matching expected schema | > 98% | Pydantic validation success rate |

### Evaluation Pipeline

```python
# app/ai/evaluation.py
class EvalResult(BaseModel):
    test_case_id: str
    input: str
    expected: str
    actual: str
    passed: bool
    metrics: dict[str, float]  # accuracy, latency_ms, token_count
    error: str | None = None

async def run_eval_suite(
    test_cases: list[EvalCase],
    provider: BaseLLMProvider,
    model: str,
) -> list[EvalResult]:
    """Run all test cases and collect metrics."""
    results = []
    for case in test_cases:
        start = time.monotonic()
        try:
            response = await provider.complete(case.messages, model=model)
            latency = (time.monotonic() - start) * 1000
            passed = case.check(response.content)
            results.append(EvalResult(
                test_case_id=case.id,
                input=case.messages[-1].content,
                expected=case.expected,
                actual=response.content,
                passed=passed,
                metrics={"latency_ms": latency, "tokens": response.usage["total_tokens"]},
            ))
        except Exception as e:
            results.append(EvalResult(
                test_case_id=case.id, input=case.messages[-1].content,
                expected=case.expected, actual="", passed=False,
                metrics={}, error=str(e),
            ))
    return results
```

## Cost Tracking

### Per-Request Logging

```python
# app/ai/cost.py
from datetime import datetime

# Pricing per 1M tokens (update as providers change pricing)
PRICING = {
    "claude-sonnet-4-20250514": {"input": 3.00, "output": 15.00},
    "claude-opus-4-20250514": {"input": 15.00, "output": 75.00},
    "gpt-4o": {"input": 2.50, "output": 10.00},
    "gpt-4o-mini": {"input": 0.15, "output": 0.60},
}

def calculate_cost(model: str, prompt_tokens: int, completion_tokens: int) -> float:
    """Calculate cost in USD for a single request."""
    prices = PRICING.get(model, {"input": 0, "output": 0})
    input_cost = (prompt_tokens / 1_000_000) * prices["input"]
    output_cost = (completion_tokens / 1_000_000) * prices["output"]
    return round(input_cost + output_cost, 6)

# Log every request
class AIUsageLog(BaseModel):
    timestamp: datetime
    provider: str
    model: str
    feature: str  # Which feature/endpoint triggered this
    prompt_tokens: int
    completion_tokens: int
    total_tokens: int
    cost_usd: float
    latency_ms: float
    success: bool
    error: str | None = None
```

### Monthly Budget Enforcement

```python
class BudgetManager:
    """Track and enforce monthly AI spending limits."""

    async def check_budget(self, feature: str) -> bool:
        """Return True if the feature is within budget."""
        current_spend = await self.get_monthly_spend(feature)
        limit = settings.AI_MONTHLY_BUDGET.get(feature, settings.AI_DEFAULT_MONTHLY_BUDGET)
        return current_spend < limit

    async def get_monthly_spend(self, feature: str | None = None) -> float:
        """Get total spend for current month, optionally filtered by feature."""
        # Query AIUsageLog table for current month
        ...
```

## Prompt Versioning and A/B Testing

### Prompt File Structure

```
app/ai/prompts/
├── classify_ticket/
│   ├── v1.yaml          # Original prompt
│   ├── v2.yaml          # Improved prompt
│   └── config.yaml      # Active version, A/B split
├── summarize/
│   ├── v1.yaml
│   └── config.yaml
└── ...
```

### Prompt Version File

```yaml
# app/ai/prompts/classify_ticket/v1.yaml
name: classify_ticket
version: 1
description: Classify support tickets into categories
model: claude-sonnet-4-20250514
temperature: 0.3
max_tokens: 256

system: |
  You are a support ticket classifier. Classify the ticket into one of these categories:
  authentication, billing, performance, feature_request, bug_report, other.
  Respond with JSON: {"category": "...", "confidence": 0.0-1.0, "reasoning": "..."}

user_template: |
  Classify this support ticket:
  <ticket>
  {ticket_text}
  </ticket>

output_schema: TicketClassification

test_cases:
  - input: "I can't log in to my account"
    expected_category: authentication
  - input: "The dashboard takes 30 seconds to load"
    expected_category: performance
  - input: "Please cancel my subscription"
    expected_category: billing
```

### A/B Testing Config

```yaml
# app/ai/prompts/classify_ticket/config.yaml
active_version: 2
ab_test:
  enabled: true
  split:
    v1: 20   # 20% traffic
    v2: 80   # 80% traffic
  metric: accuracy
  min_samples: 100
```

## RAG Patterns

### Chunking Strategy

```python
def chunk_document(
    text: str,
    chunk_size: int = 512,      # tokens per chunk
    chunk_overlap: int = 64,    # overlap between consecutive chunks
    strategy: str = "recursive", # "fixed", "recursive", "semantic"
) -> list[str]:
    """Split document into chunks for embedding."""
    if strategy == "fixed":
        # Split by character count (simple but may break mid-sentence)
        ...
    elif strategy == "recursive":
        # Split by paragraphs, then sentences, then words
        # Preferred for most use cases
        ...
    elif strategy == "semantic":
        # Use sentence embeddings to find natural break points
        # Best quality but slower
        ...
```

### Embedding and Retrieval

```python
# Use a consistent embedding model across indexing and querying
EMBEDDING_MODEL = "text-embedding-3-small"  # OpenAI
# or: "voyage-3" (Voyage AI)
# or: local sentence-transformers model

async def retrieve(
    query: str,
    top_k: int = 5,
    similarity_threshold: float = 0.7,
    filters: dict | None = None,
) -> list[RetrievedChunk]:
    """Retrieve relevant chunks from vector store."""
    query_embedding = await embed(query)
    results = await vector_store.search(
        embedding=query_embedding,
        top_k=top_k * 2,  # Over-fetch for reranking
        filters=filters,
    )
    # Filter by similarity threshold
    results = [r for r in results if r.score >= similarity_threshold]
    # Rerank with cross-encoder (optional, improves precision)
    results = await rerank(query, results, top_k=top_k)
    return results
```

### Reranking

```python
async def rerank(
    query: str,
    chunks: list[RetrievedChunk],
    top_k: int = 5,
) -> list[RetrievedChunk]:
    """Rerank retrieved chunks using a cross-encoder model."""
    # Options: Cohere rerank API, local cross-encoder, or LLM-based reranking
    # Cross-encoder is most accurate for reranking
    pairs = [(query, chunk.text) for chunk in chunks]
    scores = cross_encoder.predict(pairs)
    ranked = sorted(zip(chunks, scores), key=lambda x: x[1], reverse=True)
    return [chunk for chunk, score in ranked[:top_k]]
```

## General Rules

1. **Never expose API keys in responses** — All provider keys come from environment variables only
2. **Always validate LLM output** — Parse with Pydantic, handle malformed responses gracefully
3. **Log every LLM call** — Provider, model, tokens, cost, latency, success/failure
4. **Set token limits per endpoint** — Prevent runaway costs from unbounded generation
5. **Use the cheapest model that works** — Start with smaller/cheaper models, upgrade only if quality requires it
6. **Cache identical requests** — Hash prompt + model + temperature for cache key, TTL based on use case
7. **Implement circuit breakers** — If a provider fails N times in M minutes, stop trying for a cooldown period
8. **Never send PII to external providers without consent** — Sanitize inputs if necessary
9. **Version all prompts** — Every prompt change is tracked, testable, and rollback-capable
10. **Test prompts like code** — Every prompt has minimum 3 test cases with expected outputs
