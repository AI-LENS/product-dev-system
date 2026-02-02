---
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - LS
---

# AI/LLM Layer Setup

## Usage
```
/init:ai
```

## Description
Sets up an AI/LLM integration layer for a Python + FastAPI backend. Creates a multi-provider abstraction supporting Anthropic and OpenAI, prompt template management, structured output schemas using Pydantic, API key configuration, basic chat/completion/embedding interfaces, and a cost tracking skeleton.

## Prerequisites
- Backend project exists with `backend/app/` structure
- Python environment available

If prerequisites are not met:
```
❌ backend/app/ not found. Run /init:project first.
```

## Execution

### Step 1: Verify Structure
```bash
test -d backend/app || echo "MISSING_BACKEND"
```

### Step 2: Create AI Module Directory Structure
```bash
mkdir -p backend/app/ai/{providers,prompts,schemas}
```

Target structure:
```
backend/app/ai/
├── __init__.py
├── client.py          # Multi-provider client abstraction
├── config.py          # AI-specific configuration
├── cost_tracker.py    # Usage and cost tracking
├── providers/
│   ├── __init__.py
│   ├── base.py        # Abstract base provider
│   ├── anthropic.py   # Anthropic Claude provider
│   └── openai.py      # OpenAI GPT provider
├── prompts/
│   ├── __init__.py
│   └── templates.py   # Prompt template management
└── schemas/
    ├── __init__.py
    └── responses.py   # Structured output Pydantic models
```

### Step 3: Create Provider Base Class

#### backend/app/ai/providers/base.py
```python
from abc import ABC, abstractmethod
from typing import AsyncIterator

from app.ai.schemas.responses import (
    ChatMessage,
    ChatResponse,
    EmbeddingResponse,
)


class BaseAIProvider(ABC):
    """Abstract base class for AI/LLM providers."""

    provider_name: str = "base"

    @abstractmethod
    async def chat(
        self,
        messages: list[ChatMessage],
        model: str | None = None,
        temperature: float = 0.7,
        max_tokens: int = 1024,
        system: str | None = None,
    ) -> ChatResponse:
        """Send a chat completion request."""
        ...

    @abstractmethod
    async def chat_stream(
        self,
        messages: list[ChatMessage],
        model: str | None = None,
        temperature: float = 0.7,
        max_tokens: int = 1024,
        system: str | None = None,
    ) -> AsyncIterator[str]:
        """Send a streaming chat completion request. Yields text chunks."""
        ...

    @abstractmethod
    async def embed(
        self,
        texts: list[str],
        model: str | None = None,
    ) -> EmbeddingResponse:
        """Generate embeddings for a list of texts."""
        ...
```

#### backend/app/ai/providers/__init__.py
```python
from app.ai.providers.base import BaseAIProvider
from app.ai.providers.anthropic import AnthropicProvider
from app.ai.providers.openai import OpenAIProvider

__all__ = ["BaseAIProvider", "AnthropicProvider", "OpenAIProvider"]
```

### Step 4: Create Anthropic Provider

#### backend/app/ai/providers/anthropic.py
```python
from typing import AsyncIterator

import anthropic

from app.ai.providers.base import BaseAIProvider
from app.ai.schemas.responses import (
    ChatMessage,
    ChatResponse,
    EmbeddingResponse,
    UsageInfo,
)
from app.ai.config import ai_settings


class AnthropicProvider(BaseAIProvider):
    """Anthropic Claude provider implementation."""

    provider_name = "anthropic"

    def __init__(self, api_key: str | None = None):
        self.api_key = api_key or ai_settings.ANTHROPIC_API_KEY
        self.client = anthropic.AsyncAnthropic(api_key=self.api_key)
        self.default_model = ai_settings.ANTHROPIC_DEFAULT_MODEL

    async def chat(
        self,
        messages: list[ChatMessage],
        model: str | None = None,
        temperature: float = 0.7,
        max_tokens: int = 1024,
        system: str | None = None,
    ) -> ChatResponse:
        model = model or self.default_model

        api_messages = [{"role": m.role, "content": m.content} for m in messages]

        kwargs = {
            "model": model,
            "messages": api_messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
        }
        if system:
            kwargs["system"] = system

        response = await self.client.messages.create(**kwargs)

        content = response.content[0].text if response.content else ""

        return ChatResponse(
            content=content,
            model=response.model,
            provider=self.provider_name,
            usage=UsageInfo(
                prompt_tokens=response.usage.input_tokens,
                completion_tokens=response.usage.output_tokens,
                total_tokens=response.usage.input_tokens + response.usage.output_tokens,
            ),
            finish_reason=response.stop_reason or "end_turn",
        )

    async def chat_stream(
        self,
        messages: list[ChatMessage],
        model: str | None = None,
        temperature: float = 0.7,
        max_tokens: int = 1024,
        system: str | None = None,
    ) -> AsyncIterator[str]:
        model = model or self.default_model

        api_messages = [{"role": m.role, "content": m.content} for m in messages]

        kwargs = {
            "model": model,
            "messages": api_messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
        }
        if system:
            kwargs["system"] = system

        async with self.client.messages.stream(**kwargs) as stream:
            async for text in stream.text_stream:
                yield text

    async def embed(
        self,
        texts: list[str],
        model: str | None = None,
    ) -> EmbeddingResponse:
        raise NotImplementedError(
            "Anthropic does not provide a native embedding API. "
            "Use OpenAI or a dedicated embedding provider."
        )
```

### Step 5: Create OpenAI Provider

#### backend/app/ai/providers/openai.py
```python
from typing import AsyncIterator

import openai

from app.ai.providers.base import BaseAIProvider
from app.ai.schemas.responses import (
    ChatMessage,
    ChatResponse,
    EmbeddingResponse,
    UsageInfo,
)
from app.ai.config import ai_settings


class OpenAIProvider(BaseAIProvider):
    """OpenAI GPT provider implementation."""

    provider_name = "openai"

    def __init__(self, api_key: str | None = None):
        self.api_key = api_key or ai_settings.OPENAI_API_KEY
        self.client = openai.AsyncOpenAI(api_key=self.api_key)
        self.default_model = ai_settings.OPENAI_DEFAULT_MODEL
        self.default_embedding_model = ai_settings.OPENAI_EMBEDDING_MODEL

    async def chat(
        self,
        messages: list[ChatMessage],
        model: str | None = None,
        temperature: float = 0.7,
        max_tokens: int = 1024,
        system: str | None = None,
    ) -> ChatResponse:
        model = model or self.default_model

        api_messages = []
        if system:
            api_messages.append({"role": "system", "content": system})
        api_messages.extend({"role": m.role, "content": m.content} for m in messages)

        response = await self.client.chat.completions.create(
            model=model,
            messages=api_messages,
            temperature=temperature,
            max_tokens=max_tokens,
        )

        choice = response.choices[0]
        usage = response.usage

        return ChatResponse(
            content=choice.message.content or "",
            model=response.model,
            provider=self.provider_name,
            usage=UsageInfo(
                prompt_tokens=usage.prompt_tokens if usage else 0,
                completion_tokens=usage.completion_tokens if usage else 0,
                total_tokens=usage.total_tokens if usage else 0,
            ),
            finish_reason=choice.finish_reason or "stop",
        )

    async def chat_stream(
        self,
        messages: list[ChatMessage],
        model: str | None = None,
        temperature: float = 0.7,
        max_tokens: int = 1024,
        system: str | None = None,
    ) -> AsyncIterator[str]:
        model = model or self.default_model

        api_messages = []
        if system:
            api_messages.append({"role": "system", "content": system})
        api_messages.extend({"role": m.role, "content": m.content} for m in messages)

        stream = await self.client.chat.completions.create(
            model=model,
            messages=api_messages,
            temperature=temperature,
            max_tokens=max_tokens,
            stream=True,
        )

        async for chunk in stream:
            if chunk.choices and chunk.choices[0].delta.content:
                yield chunk.choices[0].delta.content

    async def embed(
        self,
        texts: list[str],
        model: str | None = None,
    ) -> EmbeddingResponse:
        model = model or self.default_embedding_model

        response = await self.client.embeddings.create(
            model=model,
            input=texts,
        )

        embeddings = [item.embedding for item in response.data]

        return EmbeddingResponse(
            embeddings=embeddings,
            model=response.model,
            provider=self.provider_name,
            usage=UsageInfo(
                prompt_tokens=response.usage.prompt_tokens,
                completion_tokens=0,
                total_tokens=response.usage.total_tokens,
            ),
        )
```

### Step 6: Create Response Schemas

#### backend/app/ai/schemas/responses.py
```python
from pydantic import BaseModel, Field


class ChatMessage(BaseModel):
    """A single message in a chat conversation."""
    role: str = Field(description="Message role: 'user', 'assistant', or 'system'")
    content: str = Field(description="Message content")


class UsageInfo(BaseModel):
    """Token usage information from an API call."""
    prompt_tokens: int = 0
    completion_tokens: int = 0
    total_tokens: int = 0


class ChatResponse(BaseModel):
    """Response from a chat completion request."""
    content: str
    model: str
    provider: str
    usage: UsageInfo
    finish_reason: str


class EmbeddingResponse(BaseModel):
    """Response from an embedding request."""
    embeddings: list[list[float]]
    model: str
    provider: str
    usage: UsageInfo


class StructuredOutput(BaseModel):
    """Base class for structured outputs from AI. Extend this for specific use cases."""
    raw_content: str = Field(description="The raw text response from the model")
    confidence: float = Field(default=1.0, ge=0.0, le=1.0, description="Confidence score if applicable")


class ClassificationResult(StructuredOutput):
    """Example structured output for text classification tasks."""
    label: str
    categories: list[str] = []
    reasoning: str = ""


class ExtractionResult(StructuredOutput):
    """Example structured output for entity/data extraction tasks."""
    entities: list[dict] = []
    metadata: dict = {}


class SummarizationResult(StructuredOutput):
    """Example structured output for summarization tasks."""
    summary: str
    key_points: list[str] = []
    word_count: int = 0
```

#### backend/app/ai/schemas/__init__.py
```python
from app.ai.schemas.responses import (
    ChatMessage,
    ChatResponse,
    EmbeddingResponse,
    UsageInfo,
    StructuredOutput,
    ClassificationResult,
    ExtractionResult,
    SummarizationResult,
)

__all__ = [
    "ChatMessage",
    "ChatResponse",
    "EmbeddingResponse",
    "UsageInfo",
    "StructuredOutput",
    "ClassificationResult",
    "ExtractionResult",
    "SummarizationResult",
]
```

### Step 7: Create AI Configuration

#### backend/app/ai/config.py
```python
from pydantic_settings import BaseSettings


class AISettings(BaseSettings):
    """Configuration for AI/LLM providers."""

    # Provider selection
    DEFAULT_PROVIDER: str = "anthropic"  # "anthropic" or "openai"

    # Anthropic
    ANTHROPIC_API_KEY: str = ""
    ANTHROPIC_DEFAULT_MODEL: str = "claude-sonnet-4-20250514"

    # OpenAI
    OPENAI_API_KEY: str = ""
    OPENAI_DEFAULT_MODEL: str = "gpt-4o"
    OPENAI_EMBEDDING_MODEL: str = "text-embedding-3-small"

    # Cost tracking
    COST_TRACKING_ENABLED: bool = True
    COST_LOG_FILE: str = "ai_costs.jsonl"

    # Rate limiting
    MAX_REQUESTS_PER_MINUTE: int = 60
    MAX_TOKENS_PER_REQUEST: int = 4096

    class Config:
        env_prefix = "AI_"
        env_file = ".env"
        case_sensitive = True


ai_settings = AISettings()
```

### Step 8: Create Multi-Provider Client

#### backend/app/ai/client.py
```python
from typing import AsyncIterator

from app.ai.config import ai_settings
from app.ai.providers.base import BaseAIProvider
from app.ai.providers.anthropic import AnthropicProvider
from app.ai.providers.openai import OpenAIProvider
from app.ai.schemas.responses import (
    ChatMessage,
    ChatResponse,
    EmbeddingResponse,
)
from app.ai.cost_tracker import CostTracker


class AIClient:
    """
    Multi-provider AI client. Abstracts over Anthropic and OpenAI.

    Usage:
        ai = AIClient()  # uses default provider from config

        response = await ai.chat([
            ChatMessage(role="user", content="Hello!")
        ])
        print(response.content)

        # Override provider for a specific call
        response = await ai.chat(
            messages=[ChatMessage(role="user", content="Hello!")],
            provider="openai",
        )

        # Streaming
        async for chunk in ai.chat_stream(messages):
            print(chunk, end="")
    """

    _providers: dict[str, BaseAIProvider] = {}

    def __init__(self, default_provider: str | None = None):
        self.default_provider = default_provider or ai_settings.DEFAULT_PROVIDER
        self.cost_tracker = CostTracker() if ai_settings.COST_TRACKING_ENABLED else None

    def _get_provider(self, provider: str | None = None) -> BaseAIProvider:
        """Get or lazily initialize a provider by name."""
        name = provider or self.default_provider

        if name not in self._providers:
            if name == "anthropic":
                self._providers[name] = AnthropicProvider()
            elif name == "openai":
                self._providers[name] = OpenAIProvider()
            else:
                raise ValueError(f"Unknown AI provider: {name}. Supported: anthropic, openai")

        return self._providers[name]

    async def chat(
        self,
        messages: list[ChatMessage],
        model: str | None = None,
        temperature: float = 0.7,
        max_tokens: int = 1024,
        system: str | None = None,
        provider: str | None = None,
    ) -> ChatResponse:
        """Send a chat completion request to the specified or default provider."""
        p = self._get_provider(provider)
        response = await p.chat(
            messages=messages,
            model=model,
            temperature=temperature,
            max_tokens=max_tokens,
            system=system,
        )

        if self.cost_tracker:
            self.cost_tracker.track(response)

        return response

    async def chat_stream(
        self,
        messages: list[ChatMessage],
        model: str | None = None,
        temperature: float = 0.7,
        max_tokens: int = 1024,
        system: str | None = None,
        provider: str | None = None,
    ) -> AsyncIterator[str]:
        """Send a streaming chat request. Yields text chunks."""
        p = self._get_provider(provider)
        async for chunk in p.chat_stream(
            messages=messages,
            model=model,
            temperature=temperature,
            max_tokens=max_tokens,
            system=system,
        ):
            yield chunk

    async def embed(
        self,
        texts: list[str],
        model: str | None = None,
        provider: str | None = None,
    ) -> EmbeddingResponse:
        """Generate embeddings. Defaults to OpenAI since Anthropic lacks embedding API."""
        embed_provider = provider or "openai"
        p = self._get_provider(embed_provider)
        response = await p.embed(texts=texts, model=model)

        if self.cost_tracker:
            self.cost_tracker.track_embedding(response)

        return response
```

### Step 9: Create Prompt Template System

#### backend/app/ai/prompts/templates.py
```python
"""
Prompt template management for structured AI interactions.

Usage:
    from app.ai.prompts.templates import PromptTemplate, PromptLibrary

    # Define a template
    summarize = PromptTemplate(
        name="summarize",
        system="You are a concise summarizer. Respond with only the summary.",
        user_template="Summarize the following text in {max_sentences} sentences:\n\n{text}",
    )

    # Render it
    messages = summarize.render(text="Long article...", max_sentences=3)

    # Use with AIClient
    response = await ai.chat(messages, system=summarize.system)
"""

from dataclasses import dataclass, field

from app.ai.schemas.responses import ChatMessage


@dataclass
class PromptTemplate:
    """A reusable prompt template with variable substitution."""

    name: str
    user_template: str
    system: str | None = None
    description: str = ""
    variables: list[str] = field(default_factory=list)

    def __post_init__(self):
        # Auto-detect variables from template if not explicitly provided
        if not self.variables:
            import re
            self.variables = re.findall(r"\{(\w+)\}", self.user_template)

    def render(self, **kwargs) -> list[ChatMessage]:
        """Render the template with provided variables. Returns a list of ChatMessages."""
        missing = set(self.variables) - set(kwargs.keys())
        if missing:
            raise ValueError(f"Missing template variables for '{self.name}': {missing}")

        user_content = self.user_template.format(**kwargs)
        return [ChatMessage(role="user", content=user_content)]

    def render_with_history(self, history: list[ChatMessage], **kwargs) -> list[ChatMessage]:
        """Render template and prepend conversation history."""
        rendered = self.render(**kwargs)
        return history + rendered


class PromptLibrary:
    """Registry of prompt templates for the application."""

    _templates: dict[str, PromptTemplate] = {}

    @classmethod
    def register(cls, template: PromptTemplate) -> None:
        """Register a prompt template."""
        cls._templates[template.name] = template

    @classmethod
    def get(cls, name: str) -> PromptTemplate:
        """Retrieve a prompt template by name."""
        if name not in cls._templates:
            raise KeyError(f"Prompt template '{name}' not found. Available: {list(cls._templates.keys())}")
        return cls._templates[name]

    @classmethod
    def list_templates(cls) -> list[str]:
        """List all registered template names."""
        return list(cls._templates.keys())


# Pre-built templates — extend as needed

PromptLibrary.register(PromptTemplate(
    name="summarize",
    system="You are a concise summarizer. Produce clear, accurate summaries without editorializing.",
    user_template="Summarize the following text in {max_sentences} sentences:\n\n{text}",
    description="Summarize arbitrary text to a target length.",
))

PromptLibrary.register(PromptTemplate(
    name="classify",
    system=(
        "You are a text classifier. Respond with ONLY a JSON object: "
        '{"label": "<label>", "confidence": <0.0-1.0>, "reasoning": "<brief explanation>"}'
    ),
    user_template="Classify the following text into one of these categories: {categories}\n\nText: {text}",
    description="Classify text into predefined categories.",
))

PromptLibrary.register(PromptTemplate(
    name="extract",
    system=(
        "You are a data extraction assistant. Extract structured data from the provided text. "
        "Respond with ONLY a JSON object matching the requested schema."
    ),
    user_template="Extract the following fields from the text: {fields}\n\nText: {text}",
    description="Extract structured data from unstructured text.",
))

PromptLibrary.register(PromptTemplate(
    name="code_review",
    system=(
        "You are a senior software engineer performing a code review. "
        "Focus on correctness, security, performance, and maintainability. "
        "Be specific and actionable in your feedback."
    ),
    user_template="Review the following {language} code:\n\n```{language}\n{code}\n```",
    description="Review code for quality and issues.",
))
```

#### backend/app/ai/prompts/__init__.py
```python
from app.ai.prompts.templates import PromptTemplate, PromptLibrary

__all__ = ["PromptTemplate", "PromptLibrary"]
```

### Step 10: Create Cost Tracker

#### backend/app/ai/cost_tracker.py
```python
"""
AI usage and cost tracking.

Logs each API call with token counts and estimated costs to a JSONL file.
Provides methods to query total spend by provider, model, and time period.
"""

import json
from datetime import datetime, timezone
from pathlib import Path

from app.ai.config import ai_settings
from app.ai.schemas.responses import ChatResponse, EmbeddingResponse

# Approximate costs per 1K tokens (USD) — update as pricing changes
COST_PER_1K_TOKENS: dict[str, dict[str, float]] = {
    # Anthropic
    "claude-sonnet-4-20250514": {"input": 0.003, "output": 0.015},
    "claude-3-5-haiku-20241022": {"input": 0.001, "output": 0.005},
    # OpenAI
    "gpt-4o": {"input": 0.005, "output": 0.015},
    "gpt-4o-mini": {"input": 0.00015, "output": 0.0006},
    "text-embedding-3-small": {"input": 0.00002, "output": 0.0},
    "text-embedding-3-large": {"input": 0.00013, "output": 0.0},
}


class CostTracker:
    """Tracks AI API usage and estimated costs."""

    def __init__(self, log_file: str | None = None):
        self.log_file = Path(log_file or ai_settings.COST_LOG_FILE)
        self.session_costs: list[dict] = []

    def _estimate_cost(self, model: str, prompt_tokens: int, completion_tokens: int) -> float:
        """Estimate the cost of an API call based on token usage."""
        pricing = COST_PER_1K_TOKENS.get(model)
        if not pricing:
            return 0.0

        input_cost = (prompt_tokens / 1000) * pricing["input"]
        output_cost = (completion_tokens / 1000) * pricing["output"]
        return round(input_cost + output_cost, 6)

    def track(self, response: ChatResponse) -> None:
        """Record a chat completion API call."""
        cost = self._estimate_cost(
            response.model,
            response.usage.prompt_tokens,
            response.usage.completion_tokens,
        )

        entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "provider": response.provider,
            "model": response.model,
            "type": "chat",
            "prompt_tokens": response.usage.prompt_tokens,
            "completion_tokens": response.usage.completion_tokens,
            "total_tokens": response.usage.total_tokens,
            "estimated_cost_usd": cost,
        }

        self.session_costs.append(entry)
        self._write_log(entry)

    def track_embedding(self, response: EmbeddingResponse) -> None:
        """Record an embedding API call."""
        cost = self._estimate_cost(
            response.model,
            response.usage.prompt_tokens,
            0,
        )

        entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "provider": response.provider,
            "model": response.model,
            "type": "embedding",
            "prompt_tokens": response.usage.prompt_tokens,
            "completion_tokens": 0,
            "total_tokens": response.usage.total_tokens,
            "estimated_cost_usd": cost,
        }

        self.session_costs.append(entry)
        self._write_log(entry)

    def _write_log(self, entry: dict) -> None:
        """Append a log entry to the JSONL file."""
        with open(self.log_file, "a") as f:
            f.write(json.dumps(entry) + "\n")

    def get_session_total(self) -> dict:
        """Get cost summary for the current session."""
        total_cost = sum(e["estimated_cost_usd"] for e in self.session_costs)
        total_tokens = sum(e["total_tokens"] for e in self.session_costs)
        return {
            "total_calls": len(self.session_costs),
            "total_tokens": total_tokens,
            "estimated_cost_usd": round(total_cost, 6),
        }

    def get_log_summary(self) -> dict:
        """Read the full log file and return aggregate statistics."""
        if not self.log_file.exists():
            return {"total_calls": 0, "total_tokens": 0, "estimated_cost_usd": 0.0}

        entries = []
        with open(self.log_file) as f:
            for line in f:
                line = line.strip()
                if line:
                    entries.append(json.loads(line))

        total_cost = sum(e.get("estimated_cost_usd", 0) for e in entries)
        total_tokens = sum(e.get("total_tokens", 0) for e in entries)

        by_provider: dict[str, float] = {}
        for e in entries:
            provider = e.get("provider", "unknown")
            by_provider[provider] = by_provider.get(provider, 0) + e.get("estimated_cost_usd", 0)

        return {
            "total_calls": len(entries),
            "total_tokens": total_tokens,
            "estimated_cost_usd": round(total_cost, 6),
            "by_provider": {k: round(v, 6) for k, v in by_provider.items()},
        }
```

### Step 11: Create AI Module Init

#### backend/app/ai/__init__.py
```python
from app.ai.client import AIClient
from app.ai.schemas.responses import ChatMessage, ChatResponse

__all__ = ["AIClient", "ChatMessage", "ChatResponse"]
```

### Step 12: Add AI Dependencies to requirements.txt
Append to `backend/requirements.txt` if not already present:
```
anthropic>=0.39.0
openai>=1.50.0
```

### Step 13: Update .env.example
Add AI configuration variables:
```env
# AI/LLM Configuration
AI_DEFAULT_PROVIDER=anthropic
AI_ANTHROPIC_API_KEY=sk-ant-your-key-here
AI_ANTHROPIC_DEFAULT_MODEL=claude-sonnet-4-20250514
AI_OPENAI_API_KEY=sk-your-key-here
AI_OPENAI_DEFAULT_MODEL=gpt-4o
AI_OPENAI_EMBEDDING_MODEL=text-embedding-3-small
AI_COST_TRACKING_ENABLED=true
AI_COST_LOG_FILE=ai_costs.jsonl
```

### Step 14: Add to .gitignore
Ensure these are in `.gitignore`:
```
ai_costs.jsonl
```

### Step 15: Output
```
✅ AI/LLM layer initialized
  - Providers: Anthropic (Claude) + OpenAI (GPT)
  - Features: chat, streaming, embeddings
  - Prompts: template system with 4 built-in templates
  - Schemas: structured output models (classification, extraction, summarization)
  - Cost tracking: JSONL logging with per-model pricing

Files created:
  - backend/app/ai/__init__.py
  - backend/app/ai/client.py (multi-provider client)
  - backend/app/ai/config.py (AI settings)
  - backend/app/ai/cost_tracker.py (usage + cost logging)
  - backend/app/ai/providers/base.py (abstract provider)
  - backend/app/ai/providers/anthropic.py (Claude integration)
  - backend/app/ai/providers/openai.py (GPT integration)
  - backend/app/ai/prompts/templates.py (prompt templates)
  - backend/app/ai/schemas/responses.py (Pydantic models)

Next steps:
  1. Add API keys to .env: AI_ANTHROPIC_API_KEY and AI_OPENAI_API_KEY
  2. Install packages: pip install anthropic openai
  3. Test: from app.ai import AIClient; ai = AIClient()
  4. Add custom prompts in backend/app/ai/prompts/templates.py
```
