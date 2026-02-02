# AI Agent Template

Template for building an LLM-powered agent with tool use, memory, and guardrails in Python + FastAPI.

## Overview

An AI agent combines an LLM with tools (functions it can call), memory (conversation history), and guardrails (safety constraints) to autonomously accomplish tasks through iterative reasoning and action.

## Architecture

```
User Input → Input Guardrails → Agent Loop → Output Guardrails → Response
                                     ↓ ↑
                              Tools ←→ LLM
                                     ↓ ↑
                                   Memory
```

## 1. Tool Definitions (Function Calling Format)

### Tool Schema

```python
# app/ai/agents/tools.py
from pydantic import BaseModel, Field
from typing import Any, Callable, Awaitable

class ToolParameter(BaseModel):
    name: str
    type: str  # "string", "integer", "boolean", "array", "object"
    description: str
    required: bool = True
    enum: list[str] | None = None
    default: Any = None

class ToolDefinition(BaseModel):
    """Schema for a tool the agent can call."""
    name: str = Field(description="Unique tool identifier, snake_case")
    description: str = Field(description="Clear description of what the tool does and when to use it")
    parameters: list[ToolParameter] = Field(default_factory=list)
    returns: str = Field(description="Description of what the tool returns")
    requires_confirmation: bool = Field(
        default=False,
        description="If True, agent must confirm with user before executing"
    )

class Tool:
    """Executable tool with schema and implementation."""
    def __init__(
        self,
        definition: ToolDefinition,
        handler: Callable[..., Awaitable[Any]],
    ):
        self.definition = definition
        self.handler = handler

    async def execute(self, **kwargs) -> Any:
        """Execute the tool with the given arguments."""
        return await self.handler(**kwargs)

    def to_function_schema(self) -> dict:
        """Convert to OpenAI/Anthropic function calling format."""
        properties = {}
        required = []
        for param in self.definition.parameters:
            prop = {"type": param.type, "description": param.description}
            if param.enum:
                prop["enum"] = param.enum
            properties[param.name] = prop
            if param.required:
                required.append(param.name)

        return {
            "name": self.definition.name,
            "description": self.definition.description,
            "parameters": {
                "type": "object",
                "properties": properties,
                "required": required,
            },
        }
```

### Example Tools

```python
# Database query tool
search_database = Tool(
    definition=ToolDefinition(
        name="search_database",
        description="Search the database for records matching a query. Use this when the user asks about existing data.",
        parameters=[
            ToolParameter(name="table", type="string", description="Table to search", enum=["users", "orders", "products"]),
            ToolParameter(name="query", type="string", description="Search query or filter expression"),
            ToolParameter(name="limit", type="integer", description="Max results to return", required=False, default=10),
        ],
        returns="List of matching records as JSON objects",
    ),
    handler=handle_search_database,
)

# API call tool
call_external_api = Tool(
    definition=ToolDefinition(
        name="call_external_api",
        description="Make a request to an external API. Use this when the user needs data from a third-party service.",
        parameters=[
            ToolParameter(name="service", type="string", description="Which service to call", enum=["weather", "maps", "news"]),
            ToolParameter(name="params", type="object", description="Request parameters"),
        ],
        returns="API response data as JSON",
        requires_confirmation=True,  # External calls need user approval
    ),
    handler=handle_external_api,
)

# File operation tool
read_file = Tool(
    definition=ToolDefinition(
        name="read_file",
        description="Read the contents of a file. Use this when the user asks about a specific file.",
        parameters=[
            ToolParameter(name="path", type="string", description="File path relative to project root"),
        ],
        returns="File contents as string",
    ),
    handler=handle_read_file,
)
```

## 2. System Prompt Structure

```python
# app/ai/agents/prompts.py

AGENT_SYSTEM_PROMPT = """You are an AI assistant with access to tools. Your goal is to help users by using the available tools when needed.

## Persona
{persona_description}

## Available Tools
{tool_descriptions}

## Instructions
1. Analyze the user's request carefully
2. Decide if you need to use a tool or can answer directly
3. If using a tool, explain why before calling it
4. After receiving tool results, synthesize the information into a helpful response
5. If a tool fails, explain what went wrong and suggest alternatives

## Rules
- Only use tools when necessary — if you can answer from your knowledge, do so
- Never fabricate tool results — if a tool call fails, say so honestly
- When multiple tools could work, prefer the most specific one
- Always explain your reasoning before and after tool use
- If a task requires multiple steps, explain the plan before starting
- Stop and ask the user if you are unsure about a destructive action

## Output Format
- Be concise but thorough
- Use markdown formatting for readability
- Include source references when using tool results
- Structure complex answers with headers and lists
"""

def build_system_prompt(
    persona: str,
    tools: list[Tool],
    additional_rules: list[str] | None = None,
) -> str:
    """Build the complete system prompt with persona and tool descriptions."""
    tool_descriptions = "\n".join(
        f"- **{t.definition.name}**: {t.definition.description}"
        for t in tools
    )
    prompt = AGENT_SYSTEM_PROMPT.format(
        persona_description=persona,
        tool_descriptions=tool_descriptions,
    )
    if additional_rules:
        rules_text = "\n".join(f"- {rule}" for rule in additional_rules)
        prompt += f"\n\n## Additional Rules\n{rules_text}"
    return prompt
```

## 3. Memory Management

### Conversation History

```python
# app/ai/agents/memory.py
from pydantic import BaseModel
from datetime import datetime

class ConversationMessage(BaseModel):
    role: str  # "user", "assistant", "system", "tool"
    content: str
    timestamp: datetime
    metadata: dict = {}  # tool_call_id, tool_name, etc.

class ConversationMemory:
    """Manages conversation history with token budget awareness."""

    def __init__(self, max_tokens: int = 8000):
        self.messages: list[ConversationMessage] = []
        self.max_tokens = max_tokens

    def add(self, role: str, content: str, **metadata) -> None:
        self.messages.append(ConversationMessage(
            role=role,
            content=content,
            timestamp=datetime.utcnow(),
            metadata=metadata,
        ))
        self._enforce_budget()

    def get_messages(self) -> list[dict]:
        """Return messages in LLM-compatible format."""
        return [{"role": m.role, "content": m.content} for m in self.messages]

    def _enforce_budget(self) -> None:
        """Trim history to stay within token budget."""
        total = sum(estimate_tokens(m.content) for m in self.messages)
        while total > self.max_tokens and len(self.messages) > 2:
            # Keep system message (index 0) and most recent message
            removed = self.messages.pop(1)  # Remove oldest non-system message
            total -= estimate_tokens(removed.content)

    def clear(self) -> None:
        """Clear all messages except system prompt."""
        system = [m for m in self.messages if m.role == "system"]
        self.messages = system
```

### Summarization for Long Conversations

```python
class SummarizingMemory(ConversationMemory):
    """Summarizes old messages instead of dropping them."""

    async def _enforce_budget(self) -> None:
        total = sum(estimate_tokens(m.content) for m in self.messages)
        if total <= self.max_tokens:
            return

        # Split into recent (keep) and old (summarize)
        system = [m for m in self.messages if m.role == "system"]
        non_system = [m for m in self.messages if m.role != "system"]

        # Keep the last N messages
        keep_count = min(6, len(non_system))
        to_summarize = non_system[:-keep_count]
        to_keep = non_system[-keep_count:]

        if not to_summarize:
            return

        # Summarize old messages
        summary = await self._summarize(to_summarize)
        summary_msg = ConversationMessage(
            role="system",
            content=f"Summary of earlier conversation:\n{summary}",
            timestamp=datetime.utcnow(),
            metadata={"type": "summary"},
        )

        self.messages = system + [summary_msg] + to_keep

    async def _summarize(self, messages: list[ConversationMessage]) -> str:
        """Use LLM to summarize a block of messages into a concise context."""
        # Call a cheap/fast model to generate a 2-3 sentence summary
        ...
```

### Persistent Memory (Cross-Session)

```python
class PersistentMemory:
    """Store and retrieve facts across sessions."""

    async def save_fact(self, key: str, value: str, session_id: str) -> None:
        """Save a user preference or important fact."""
        ...

    async def get_facts(self, session_id: str) -> dict[str, str]:
        """Retrieve all saved facts for a session."""
        ...

    async def get_relevant_facts(self, query: str, session_id: str) -> list[str]:
        """Retrieve facts relevant to the current query (semantic search)."""
        ...
```

## 4. Guardrails

### Input Validation

```python
# app/ai/agents/guardrails.py
from pydantic import BaseModel

class GuardrailResult(BaseModel):
    passed: bool
    reason: str | None = None
    sanitized_input: str | None = None

class InputGuardrails:
    """Validate and sanitize user input before sending to agent."""

    async def check(self, user_input: str) -> GuardrailResult:
        checks = [
            self._check_length(user_input),
            self._check_injection(user_input),
            self._check_pii(user_input),
            self._check_forbidden_topics(user_input),
        ]
        for result in checks:
            if not result.passed:
                return result
        return GuardrailResult(passed=True)

    def _check_length(self, text: str) -> GuardrailResult:
        """Reject inputs exceeding maximum token count."""
        if estimate_tokens(text) > 4000:
            return GuardrailResult(passed=False, reason="Input too long. Please shorten your message.")
        return GuardrailResult(passed=True)

    def _check_injection(self, text: str) -> GuardrailResult:
        """Detect prompt injection attempts."""
        injection_patterns = [
            "ignore previous instructions",
            "ignore all instructions",
            "you are now",
            "new system prompt",
            "disregard the above",
            "forget your instructions",
        ]
        lower = text.lower()
        for pattern in injection_patterns:
            if pattern in lower:
                return GuardrailResult(
                    passed=False,
                    reason="Your message was flagged by our safety system. Please rephrase.",
                )
        return GuardrailResult(passed=True)

    def _check_pii(self, text: str) -> GuardrailResult:
        """Warn about PII in input (optionally sanitize)."""
        import re
        # SSN pattern
        if re.search(r'\b\d{3}-\d{2}-\d{4}\b', text):
            return GuardrailResult(
                passed=False,
                reason="Please do not include Social Security Numbers in your message.",
            )
        # Credit card pattern
        if re.search(r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b', text):
            return GuardrailResult(
                passed=False,
                reason="Please do not include credit card numbers in your message.",
            )
        return GuardrailResult(passed=True)

    def _check_forbidden_topics(self, text: str) -> GuardrailResult:
        """Block requests for harmful content."""
        # Implement based on application requirements
        return GuardrailResult(passed=True)
```

### Output Filtering

```python
class OutputGuardrails:
    """Validate agent responses before returning to user."""

    async def check(self, response: str) -> GuardrailResult:
        checks = [
            self._check_pii_leakage(response),
            self._check_harmful_content(response),
            self._check_hallucination_markers(response),
        ]
        for result in checks:
            if not result.passed:
                return result
        return GuardrailResult(passed=True)

    def _check_pii_leakage(self, text: str) -> GuardrailResult:
        """Ensure the agent did not expose PII from its tools."""
        # Check for patterns that look like real PII
        ...

    def _check_harmful_content(self, text: str) -> GuardrailResult:
        """Run safety classifier on output."""
        ...

    def _check_hallucination_markers(self, text: str) -> GuardrailResult:
        """Detect confidence-lowering phrases that may indicate hallucination."""
        markers = ["I think", "I believe", "probably", "might be"]
        # Flag but do not block — add a disclaimer
        ...
```

## 5. Agent Loop

```python
# app/ai/agents/agent.py
from typing import AsyncIterator

class AgentConfig(BaseModel):
    max_iterations: int = 10         # Prevent infinite loops
    max_tool_calls: int = 5          # Limit tool calls per turn
    timeout_seconds: float = 30.0    # Total time limit per turn
    model: str = "claude-sonnet-4-20250514"
    temperature: float = 0.3
    stream: bool = True

class Agent:
    def __init__(
        self,
        config: AgentConfig,
        tools: list[Tool],
        memory: ConversationMemory,
        input_guardrails: InputGuardrails,
        output_guardrails: OutputGuardrails,
        provider: BaseLLMProvider,
    ):
        self.config = config
        self.tools = {t.definition.name: t for t in tools}
        self.memory = memory
        self.input_guard = input_guardrails
        self.output_guard = output_guardrails
        self.provider = provider

    async def run(self, user_input: str) -> str:
        """Execute the agent loop for a single user turn."""

        # 1. Input guardrails
        guard_result = await self.input_guard.check(user_input)
        if not guard_result.passed:
            return guard_result.reason

        # 2. Add user message to memory
        self.memory.add("user", user_input)

        # 3. Agent loop
        for iteration in range(self.config.max_iterations):
            # Call LLM with current messages and tool schemas
            response = await self.provider.complete(
                messages=self.memory.get_messages(),
                model=self.config.model,
                temperature=self.config.temperature,
                tools=[t.definition.to_function_schema() for t in self.tools.values()],
            )

            # Check if LLM wants to use a tool
            if response.tool_calls:
                for tool_call in response.tool_calls:
                    tool = self.tools.get(tool_call.name)
                    if not tool:
                        self.memory.add("tool", f"Error: Unknown tool '{tool_call.name}'",
                                       tool_call_id=tool_call.id)
                        continue

                    # Check if tool requires confirmation
                    if tool.definition.requires_confirmation:
                        # In a real implementation, pause and ask user
                        pass

                    # Execute tool
                    try:
                        result = await tool.execute(**tool_call.arguments)
                        self.memory.add("tool", str(result),
                                       tool_call_id=tool_call.id, tool_name=tool_call.name)
                    except Exception as e:
                        self.memory.add("tool", f"Tool error: {e}",
                                       tool_call_id=tool_call.id, tool_name=tool_call.name)
            else:
                # LLM produced a final response (no tool calls)
                final_response = response.content

                # 4. Output guardrails
                guard_result = await self.output_guard.check(final_response)
                if not guard_result.passed:
                    final_response = f"I apologize, but I cannot provide that response. {guard_result.reason}"

                # 5. Add to memory and return
                self.memory.add("assistant", final_response)
                return final_response

        return "I was unable to complete the task within the allowed number of steps. Please try breaking your request into smaller parts."
```

## 6. Error Handling

```python
class AgentError(Exception):
    """Base error for agent operations."""
    pass

class ToolExecutionError(AgentError):
    """A tool failed to execute."""
    def __init__(self, tool_name: str, original_error: Exception):
        self.tool_name = tool_name
        self.original_error = original_error
        super().__init__(f"Tool '{tool_name}' failed: {original_error}")

class GuardrailViolation(AgentError):
    """Input or output violated a guardrail."""
    pass

class BudgetExceeded(AgentError):
    """Token or cost budget exceeded."""
    pass

# Error handling in the agent loop
async def safe_tool_execute(tool: Tool, **kwargs) -> str:
    """Execute a tool with error handling and timeout."""
    try:
        result = await asyncio.wait_for(
            tool.execute(**kwargs),
            timeout=10.0,  # Per-tool timeout
        )
        return str(result)
    except asyncio.TimeoutError:
        return f"Tool '{tool.definition.name}' timed out after 10 seconds."
    except ToolExecutionError as e:
        return f"Tool error: {e}"
    except Exception as e:
        return f"Unexpected error calling '{tool.definition.name}': {type(e).__name__}: {e}"
```

## 7. Monitoring

```python
# app/ai/agents/monitoring.py
from pydantic import BaseModel
from datetime import datetime

class AgentTurnMetrics(BaseModel):
    session_id: str
    turn_number: int
    timestamp: datetime
    user_input_tokens: int
    total_llm_calls: int
    total_tool_calls: int
    tools_used: list[str]
    total_tokens: int
    total_cost_usd: float
    latency_ms: float
    iterations: int
    success: bool
    guardrail_flags: list[str]
    error: str | None = None

class AgentMonitor:
    """Collect and report agent performance metrics."""

    async def log_turn(self, metrics: AgentTurnMetrics) -> None:
        """Log a single agent turn's metrics."""
        # Write to database, logging system, or metrics service
        ...

    async def get_session_summary(self, session_id: str) -> dict:
        """Summarize an entire agent session."""
        ...

    async def alert_if_anomalous(self, metrics: AgentTurnMetrics) -> None:
        """Send alert if metrics are outside normal bounds."""
        if metrics.iterations >= 8:
            await self._alert("Agent near iteration limit", metrics)
        if metrics.total_cost_usd > 0.50:
            await self._alert("High cost agent turn", metrics)
        if metrics.latency_ms > 15000:
            await self._alert("Slow agent response", metrics)
```

## FastAPI Integration

```python
# app/api/v1/agent.py
from fastapi import APIRouter, Depends, WebSocket

router = APIRouter(prefix="/api/v1/agent", tags=["Agent"])

@router.post("/chat")
async def agent_chat(
    request: AgentChatRequest,
    agent: Agent = Depends(get_agent),
):
    """Send a message to the agent and get a response."""
    response = await agent.run(request.message)
    return AgentChatResponse(
        message=response,
        session_id=request.session_id,
    )

@router.websocket("/chat/ws")
async def agent_chat_ws(
    websocket: WebSocket,
    agent: Agent = Depends(get_agent),
):
    """WebSocket endpoint for streaming agent responses."""
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_json()
            async for chunk in agent.stream(data["message"]):
                await websocket.send_json({"type": "chunk", "content": chunk})
            await websocket.send_json({"type": "done"})
    except Exception:
        await websocket.close()
```
