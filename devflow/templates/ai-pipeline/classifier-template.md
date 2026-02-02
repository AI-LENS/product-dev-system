# Classification Pipeline Template

Template for building a text classification system using LLMs in Python + FastAPI.

## Overview

A classification pipeline categorizes text inputs into predefined categories using either few-shot LLM prompting or fine-tuned models, with confidence scoring and fallback handling.

## Architecture

```
Input Text → Preprocessing → Classification → Confidence Check → Result
                                   ↓                    ↓
                          Model (few-shot           Fallback
                          or fine-tuned)        (human review)
```

## 1. Category Definitions

### Schema

```python
# app/ai/classifiers/categories.py
from pydantic import BaseModel, Field
from enum import Enum

class CategoryDefinition(BaseModel):
    """Define a classification category."""
    name: str = Field(description="Machine-readable category name, snake_case")
    label: str = Field(description="Human-readable display label")
    description: str = Field(description="Detailed description of what belongs in this category")
    examples: list[str] = Field(
        min_length=2,
        description="Example inputs that belong to this category (minimum 2)"
    )
    keywords: list[str] = Field(
        default_factory=list,
        description="Common keywords associated with this category"
    )
    parent: str | None = Field(
        default=None,
        description="Parent category for hierarchical classification"
    )
```

### Example Categories

```python
TICKET_CATEGORIES = [
    CategoryDefinition(
        name="authentication",
        label="Authentication",
        description="Issues related to login, logout, password, MFA, SSO, account access, and session management.",
        examples=[
            "I cannot log in to my account after changing my password",
            "My two-factor authentication code is not working",
            "I am getting 'session expired' every 5 minutes",
        ],
        keywords=["login", "password", "MFA", "SSO", "session", "locked out", "access"],
    ),
    CategoryDefinition(
        name="billing",
        label="Billing & Payments",
        description="Issues related to invoices, subscriptions, charges, refunds, payment methods, and pricing.",
        examples=[
            "I was charged twice for my subscription this month",
            "How do I update my credit card information?",
            "I need a refund for the last payment",
        ],
        keywords=["invoice", "charge", "refund", "subscription", "payment", "pricing", "receipt"],
    ),
    CategoryDefinition(
        name="performance",
        label="Performance",
        description="Issues related to slow loading, timeouts, errors, crashes, and system reliability.",
        examples=[
            "The dashboard takes over 30 seconds to load",
            "I keep getting 500 error on the reports page",
            "The app crashes when I try to export data",
        ],
        keywords=["slow", "timeout", "crash", "error", "loading", "unresponsive", "lag"],
    ),
    CategoryDefinition(
        name="feature_request",
        label="Feature Request",
        description="Requests for new functionality, improvements to existing features, or integrations.",
        examples=[
            "It would be great if the dashboard supported dark mode",
            "Can you add a Slack integration for notifications?",
            "I wish I could export reports as PDF",
        ],
        keywords=["wish", "request", "add", "suggest", "improve", "would be nice", "integrate"],
    ),
    CategoryDefinition(
        name="bug_report",
        label="Bug Report",
        description="Reports of incorrect behavior, data issues, UI glitches, or unexpected results.",
        examples=[
            "The total in the summary does not match the individual line items",
            "When I click 'Save', the form resets but the data is not saved",
            "The date picker shows the wrong month",
        ],
        keywords=["bug", "broken", "wrong", "incorrect", "not working", "glitch", "issue"],
    ),
    CategoryDefinition(
        name="other",
        label="Other",
        description="Anything that does not fit into the above categories. Use this sparingly.",
        examples=[
            "What is your company's privacy policy?",
            "I have a general question about the product roadmap",
        ],
        keywords=[],
    ),
]
```

## 2. Training Data Format

### For Few-Shot (No Training Needed)

Few-shot classification uses examples directly in the prompt. The category definitions above provide the training data. More examples improve accuracy.

### For Fine-Tuning (If Needed)

```python
class TrainingExample(BaseModel):
    text: str
    category: str
    confidence: float = 1.0  # 1.0 for human-labeled, <1.0 for silver data

class TrainingDataset(BaseModel):
    examples: list[TrainingExample]
    categories: list[CategoryDefinition]
    version: str
    created_at: str
    label_source: str  # "human", "llm_generated", "mixed"

# Format: JSONL for fine-tuning
# {"text": "I can't log in", "category": "authentication"}
# {"text": "Charged twice", "category": "billing"}
```

### Data Collection Strategy

```markdown
1. **Seed data:** Write 10-20 examples per category manually (highest quality)
2. **LLM augmentation:** Use a strong model to generate 50-100 synthetic examples per category
3. **Production data:** Label real inputs using the few-shot classifier, human-verify a sample
4. **Active learning:** Prioritize labeling inputs with low confidence scores
5. **Target:** 100+ examples per category for few-shot, 500+ for fine-tuning
```

## 3. Model Selection

### Few-Shot vs Fine-Tuned Decision Tree

```
Q: Do you have <100 labeled examples per category?
  → Yes: Use few-shot classification
  → No:
    Q: Is latency critical (<100ms)?
      → Yes: Fine-tune a small model (distilbert, all-MiniLM)
      → No:
        Q: Are categories complex/overlapping?
          → Yes: Use few-shot with a strong model (claude-sonnet, gpt-4o)
          → No: Fine-tune a medium model or use few-shot with a cheap model
```

### Model Options

| Approach | Model | Latency | Cost | Accuracy | When to Use |
|----------|-------|---------|------|----------|-------------|
| Few-shot | claude-sonnet-4-20250514 | ~1-2s | $$  | High | Default starting point |
| Few-shot | gpt-4o-mini | ~0.5-1s | $   | Good | Cost-sensitive, simple categories |
| Fine-tuned | distilbert | ~10ms | Free (self-hosted) | Good | High volume, latency-critical |
| Fine-tuned | gpt-4o-mini (OpenAI) | ~0.3s | $   | Very Good | Need better than base, moderate volume |
| Embedding + KNN | text-embedding-3-small | ~100ms | $   | Good | Simple categories, very high volume |

## 4. Classification Pipeline

### Few-Shot Implementation

```python
# app/ai/classifiers/pipeline.py
from pydantic import BaseModel, Field

class ClassificationResult(BaseModel):
    category: str = Field(description="Predicted category name")
    confidence: float = Field(ge=0.0, le=1.0, description="Confidence score")
    reasoning: str = Field(description="Why this category was chosen")
    secondary_category: str | None = Field(
        default=None,
        description="Second most likely category, if close"
    )
    secondary_confidence: float | None = Field(default=None)

class ClassificationPipeline:
    def __init__(
        self,
        categories: list[CategoryDefinition],
        provider: BaseLLMProvider,
        model: str = "claude-sonnet-4-20250514",
        confidence_threshold: float = 0.7,
        fallback_category: str = "other",
    ):
        self.categories = categories
        self.provider = provider
        self.model = model
        self.confidence_threshold = confidence_threshold
        self.fallback_category = fallback_category
        self._system_prompt = self._build_system_prompt()

    def _build_system_prompt(self) -> str:
        categories_text = ""
        for cat in self.categories:
            examples_text = "\n".join(f'  - "{ex}"' for ex in cat.examples[:3])
            categories_text += f"""
**{cat.name}** ({cat.label}): {cat.description}
Examples:
{examples_text}
"""
        return f"""You are a text classifier. Classify the input into exactly one category.

Categories:
{categories_text}

Rules:
- Choose the single most appropriate category
- Provide a confidence score from 0.0 to 1.0
- If the input could belong to multiple categories, choose the primary one and note the secondary
- If confidence is below 0.5, classify as "other"
- Provide brief reasoning for your choice

Respond with JSON:
{{"category": "category_name", "confidence": 0.0, "reasoning": "why", "secondary_category": "name_or_null", "secondary_confidence": 0.0}}"""

    async def classify(self, text: str) -> ClassificationResult:
        """Classify a single text input."""
        response = await self.provider.complete(
            messages=[
                LLMMessage(role="system", content=self._system_prompt),
                LLMMessage(role="user", content=f"Classify this text:\n\n{text}"),
            ],
            model=self.model,
            temperature=0.1,  # Low temperature for consistent classification
            max_tokens=256,
        )
        result = parse_structured_output(response.content, ClassificationResult)
        return result

    async def classify_batch(self, texts: list[str]) -> list[ClassificationResult]:
        """Classify multiple texts. Uses concurrent requests for speed."""
        import asyncio
        tasks = [self.classify(text) for text in texts]
        return await asyncio.gather(*tasks)
```

### Embedding-Based Classification (Alternative)

```python
class EmbeddingClassifier:
    """Classify by comparing input embedding to category exemplar embeddings."""

    def __init__(self, categories: list[CategoryDefinition], embedding_service: EmbeddingService):
        self.categories = categories
        self.embedding_service = embedding_service
        self.category_embeddings: dict[str, list[list[float]]] = {}

    async def build_index(self) -> None:
        """Pre-compute embeddings for all category examples."""
        for cat in self.categories:
            embeddings = await self.embedding_service.embed_batch(cat.examples)
            self.category_embeddings[cat.name] = embeddings

    async def classify(self, text: str) -> ClassificationResult:
        """Classify by nearest neighbor among category exemplars."""
        input_embedding = await self.embedding_service.embed_query(text)

        best_category = None
        best_score = -1.0

        for cat_name, exemplar_embeddings in self.category_embeddings.items():
            # Average similarity to all exemplars in this category
            similarities = [cosine_similarity(input_embedding, ex) for ex in exemplar_embeddings]
            avg_similarity = sum(similarities) / len(similarities)
            if avg_similarity > best_score:
                best_score = avg_similarity
                best_category = cat_name

        return ClassificationResult(
            category=best_category,
            confidence=best_score,
            reasoning=f"Highest average similarity ({best_score:.3f}) to {best_category} examples",
        )
```

## 5. Evaluation Metrics

### Standard Metrics

```python
from sklearn.metrics import (
    accuracy_score,
    precision_recall_fscore_support,
    confusion_matrix,
    classification_report,
)

class ClassifierEvaluation(BaseModel):
    accuracy: float
    precision_macro: float
    recall_macro: float
    f1_macro: float
    precision_weighted: float
    recall_weighted: float
    f1_weighted: float
    per_category: dict[str, dict[str, float]]  # {category: {precision, recall, f1, support}}
    confusion_matrix: list[list[int]]
    total_samples: int
    misclassified_examples: list[dict]  # For error analysis

def evaluate_classifier(
    predictions: list[ClassificationResult],
    ground_truth: list[str],
    categories: list[str],
) -> ClassifierEvaluation:
    """Evaluate classifier performance against labeled data."""
    pred_labels = [p.category for p in predictions]

    accuracy = accuracy_score(ground_truth, pred_labels)
    precision_m, recall_m, f1_m, _ = precision_recall_fscore_support(
        ground_truth, pred_labels, average="macro", zero_division=0
    )
    precision_w, recall_w, f1_w, _ = precision_recall_fscore_support(
        ground_truth, pred_labels, average="weighted", zero_division=0
    )

    report = classification_report(ground_truth, pred_labels, output_dict=True, zero_division=0)
    per_category = {
        cat: {
            "precision": report[cat]["precision"],
            "recall": report[cat]["recall"],
            "f1": report[cat]["f1-score"],
            "support": report[cat]["support"],
        }
        for cat in categories if cat in report
    }

    # Collect misclassified examples for error analysis
    misclassified = []
    for pred, true, result in zip(pred_labels, ground_truth, predictions):
        if pred != true:
            misclassified.append({
                "predicted": pred,
                "actual": true,
                "confidence": result.confidence,
                "reasoning": result.reasoning,
            })

    return ClassifierEvaluation(
        accuracy=accuracy,
        precision_macro=precision_m,
        recall_macro=recall_m,
        f1_macro=f1_m,
        precision_weighted=precision_w,
        recall_weighted=recall_w,
        f1_weighted=f1_w,
        per_category=per_category,
        confusion_matrix=confusion_matrix(ground_truth, pred_labels, labels=categories).tolist(),
        total_samples=len(ground_truth),
        misclassified_examples=misclassified[:20],  # Cap at 20 for readability
    )
```

### Target Metrics

| Metric | Minimum | Good | Excellent |
|--------|---------|------|-----------|
| Accuracy | 80% | 90% | 95%+ |
| Precision (macro) | 75% | 85% | 92%+ |
| Recall (macro) | 75% | 85% | 92%+ |
| F1 (macro) | 75% | 85% | 92%+ |
| Per-category F1 | 70% | 80% | 90%+ |

## 6. Confidence Thresholds

### Threshold Strategy

```python
class ConfidenceRouter:
    """Route classification results based on confidence."""

    def __init__(
        self,
        high_threshold: float = 0.85,
        low_threshold: float = 0.5,
    ):
        self.high = high_threshold
        self.low = low_threshold

    def route(self, result: ClassificationResult) -> str:
        """
        Returns:
          "auto" — High confidence, apply classification automatically
          "review" — Medium confidence, queue for human review
          "reject" — Low confidence, cannot classify reliably
        """
        if result.confidence >= self.high:
            return "auto"
        elif result.confidence >= self.low:
            return "review"
        else:
            return "reject"
```

### Threshold Tuning

```markdown
1. Start with default thresholds (high=0.85, low=0.5)
2. Run evaluation on test set
3. Analyze the precision/recall trade-off:
   - If too many misclassifications in "auto": raise high threshold
   - If too many items in "review": lower high threshold
   - If "reject" catches valid inputs: lower low threshold
4. Plot precision vs. recall at different thresholds to find optimal point
5. Re-evaluate after any prompt or model changes
```

## 7. Fallback Handling

```python
class FallbackHandler:
    """Handle cases where classification fails or has low confidence."""

    async def handle(self, text: str, result: ClassificationResult, route: str) -> dict:
        if route == "auto":
            return {"action": "apply", "category": result.category}

        elif route == "review":
            # Queue for human review
            review_item = await self.create_review_item(
                text=text,
                predicted=result.category,
                confidence=result.confidence,
                secondary=result.secondary_category,
            )
            return {
                "action": "queued_for_review",
                "review_id": review_item.id,
                "predicted": result.category,
            }

        elif route == "reject":
            # Apply fallback category or escalate
            return {
                "action": "fallback",
                "category": "other",
                "note": "Low confidence classification — requires manual review",
            }

    async def create_review_item(self, **kwargs) -> ReviewItem:
        """Create a human review queue item."""
        ...
```

## FastAPI Integration

```python
# app/api/v1/classify.py
from fastapi import APIRouter, Depends

router = APIRouter(prefix="/api/v1/classify", tags=["Classification"])

@router.post("/")
async def classify_text(
    request: ClassifyRequest,
    pipeline: ClassificationPipeline = Depends(get_classifier),
    router: ConfidenceRouter = Depends(get_confidence_router),
    fallback: FallbackHandler = Depends(get_fallback_handler),
):
    """Classify input text into a category."""
    result = await pipeline.classify(request.text)
    route = router.route(result)
    action = await fallback.handle(request.text, result, route)

    return ClassifyResponse(
        category=result.category,
        confidence=result.confidence,
        reasoning=result.reasoning,
        action=action["action"],
        review_id=action.get("review_id"),
    )

@router.post("/batch")
async def classify_batch(
    request: ClassifyBatchRequest,
    pipeline: ClassificationPipeline = Depends(get_classifier),
):
    """Classify multiple texts in a single request."""
    results = await pipeline.classify_batch(request.texts)
    return ClassifyBatchResponse(
        results=[
            ClassifyResponse(
                category=r.category,
                confidence=r.confidence,
                reasoning=r.reasoning,
            )
            for r in results
        ]
    )

@router.get("/categories")
async def list_categories():
    """List all available classification categories."""
    return [
        {"name": c.name, "label": c.label, "description": c.description}
        for c in TICKET_CATEGORIES
    ]
```
