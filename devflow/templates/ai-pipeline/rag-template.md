# RAG Pipeline Template

Template for building a Retrieval-Augmented Generation pipeline in Python + FastAPI.

## Overview

RAG enhances LLM responses by grounding them in retrieved source documents, reducing hallucination and providing up-to-date information.

## Pipeline Architecture

```
Document Ingestion → Chunking → Embedding → Vector Store
                                                  ↓
User Query → Query Embedding → Retrieval → Reranking → Generation → Response
```

## 1. Document Ingestion Strategy

### Supported Formats

```python
# app/ai/rag/ingestion.py
from enum import Enum

class DocumentType(str, Enum):
    PDF = "pdf"
    MARKDOWN = "markdown"
    HTML = "html"
    TEXT = "text"
    DOCX = "docx"
    CSV = "csv"

PARSERS = {
    DocumentType.PDF: "pypdf2 or pdfplumber — extract text preserving structure",
    DocumentType.MARKDOWN: "markdown-it — parse to plain text, preserve headers as metadata",
    DocumentType.HTML: "beautifulsoup4 — strip tags, preserve structure",
    DocumentType.TEXT: "direct read — no parsing needed",
    DocumentType.DOCX: "python-docx — extract paragraphs and tables",
    DocumentType.CSV: "pandas — convert rows to text records",
}
```

### Ingestion Pipeline

```python
from pydantic import BaseModel
from datetime import datetime

class Document(BaseModel):
    id: str
    content: str
    metadata: dict  # source, title, author, date, page, section
    doc_type: DocumentType
    ingested_at: datetime

class IngestionConfig(BaseModel):
    source_directory: str
    supported_types: list[DocumentType]
    metadata_extractors: list[str]  # filename, headers, frontmatter
    deduplication: bool = True  # Skip documents already indexed
    batch_size: int = 50

async def ingest_documents(config: IngestionConfig) -> list[Document]:
    """
    1. Scan source directory for supported file types
    2. Parse each file to extract text content
    3. Extract metadata (title from filename, headers, etc.)
    4. Deduplicate against existing documents in vector store
    5. Return list of Document objects ready for chunking
    """
    ...
```

## 2. Chunking Approach

### Configuration

```python
class ChunkingConfig(BaseModel):
    strategy: str = "recursive"  # "fixed", "recursive", "semantic"
    chunk_size: int = 512        # Target tokens per chunk
    chunk_overlap: int = 64      # Overlap tokens between chunks
    min_chunk_size: int = 100    # Discard chunks smaller than this
    separators: list[str] = ["\n\n", "\n", ". ", " "]  # For recursive strategy
```

### Strategies

**Fixed-size chunking:**
```python
def chunk_fixed(text: str, size: int, overlap: int) -> list[str]:
    """Split text into fixed-size token windows with overlap."""
    tokens = tokenize(text)
    chunks = []
    start = 0
    while start < len(tokens):
        end = start + size
        chunk_tokens = tokens[start:end]
        chunks.append(detokenize(chunk_tokens))
        start = end - overlap
    return chunks
```

**Recursive chunking (recommended):**
```python
def chunk_recursive(text: str, size: int, overlap: int, separators: list[str]) -> list[str]:
    """
    Split text hierarchically:
    1. Try splitting by double newline (paragraphs)
    2. If chunks are still too large, split by single newline
    3. Then by sentence (". ")
    4. Then by word (" ")
    Preserves semantic coherence better than fixed-size.
    """
    ...
```

**Semantic chunking (highest quality):**
```python
def chunk_semantic(text: str, size: int, embedding_model) -> list[str]:
    """
    1. Split text into sentences
    2. Embed each sentence
    3. Find natural break points where embedding similarity drops
    4. Group sentences between break points into chunks
    Best for maintaining topic coherence within chunks.
    """
    ...
```

### Chunk Metadata

Each chunk retains:
```python
class Chunk(BaseModel):
    id: str                    # UUID
    document_id: str           # Parent document ID
    content: str               # The chunk text
    chunk_index: int           # Position within the document
    token_count: int           # Actual token count
    metadata: dict             # Inherited from document + chunk-specific
    # metadata includes: source, title, page_number, section_header, etc.
```

## 3. Embedding Model Selection

| Model | Provider | Dimensions | Speed | Quality | Cost |
|-------|----------|-----------|-------|---------|------|
| text-embedding-3-small | OpenAI | 1536 | Fast | Good | $0.02/1M tokens |
| text-embedding-3-large | OpenAI | 3072 | Medium | Better | $0.13/1M tokens |
| voyage-3 | Voyage AI | 1024 | Fast | Best | $0.06/1M tokens |
| all-MiniLM-L6-v2 | Local (sentence-transformers) | 384 | Very Fast | Acceptable | Free |
| nomic-embed-text | Local (Ollama) | 768 | Fast | Good | Free |

**Recommendation:**
- **Production (cloud):** `text-embedding-3-small` — best cost/quality ratio
- **Production (quality):** `voyage-3` — highest retrieval accuracy
- **Development/testing:** `all-MiniLM-L6-v2` — free, fast, good enough for dev

```python
class EmbeddingConfig(BaseModel):
    model: str = "text-embedding-3-small"
    provider: str = "openai"  # "openai", "voyage", "local"
    dimensions: int = 1536
    batch_size: int = 100     # Embed N chunks per API call
    normalize: bool = True    # L2 normalize vectors
```

### Embedding Service

```python
# app/ai/rag/embeddings.py
class EmbeddingService:
    async def embed_text(self, text: str) -> list[float]:
        """Embed a single text string."""
        ...

    async def embed_batch(self, texts: list[str]) -> list[list[float]]:
        """Embed multiple texts in a single API call."""
        ...

    async def embed_query(self, query: str) -> list[float]:
        """Embed a query (some models use different embedding for queries vs documents)."""
        ...
```

## 4. Vector Store Setup

### Options

| Store | Type | Scaling | Filtering | Setup |
|-------|------|---------|-----------|-------|
| pgvector | PostgreSQL extension | Millions of vectors | SQL WHERE | Easy (add to existing PG) |
| Qdrant | Dedicated vector DB | Billions | Rich filtering | Docker container |
| ChromaDB | Embedded | Thousands | Basic | pip install, no server |
| Pinecone | Managed cloud | Billions | Metadata filters | API key only |

**Recommendation:**
- **If already using PostgreSQL:** pgvector — no new infrastructure
- **If scaling is critical:** Qdrant — best performance at scale
- **For development:** ChromaDB — zero setup

### pgvector Setup

```python
# app/ai/rag/vectorstore.py
from sqlalchemy import Column, String, Integer, JSON
from pgvector.sqlalchemy import Vector

class ChunkEmbedding(Base):
    __tablename__ = "chunk_embeddings"

    id = Column(String, primary_key=True)
    document_id = Column(String, index=True)
    content = Column(String)
    embedding = Column(Vector(1536))  # Match embedding dimensions
    metadata = Column(JSON)
    chunk_index = Column(Integer)

# Create index for similarity search
# CREATE INDEX ON chunk_embeddings USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
```

### Vector Store Interface

```python
class VectorStore:
    async def upsert(self, chunks: list[Chunk], embeddings: list[list[float]]) -> int:
        """Insert or update chunks with their embeddings. Returns count."""
        ...

    async def search(
        self,
        embedding: list[float],
        top_k: int = 10,
        filters: dict | None = None,
        similarity_threshold: float = 0.0,
    ) -> list[SearchResult]:
        """Find most similar chunks. Returns results sorted by similarity."""
        ...

    async def delete(self, document_id: str) -> int:
        """Delete all chunks for a document. Returns count deleted."""
        ...
```

## 5. Retrieval Configuration

```python
class RetrievalConfig(BaseModel):
    top_k: int = 10                     # Number of chunks to retrieve
    similarity_threshold: float = 0.7   # Minimum similarity score (0-1)
    rerank: bool = True                 # Enable reranking step
    rerank_top_k: int = 5              # Final number after reranking
    max_context_tokens: int = 3000     # Token budget for retrieved context
    filters: dict | None = None        # Metadata filters (source, date range, etc.)
    hybrid_search: bool = False        # Combine vector + keyword search
    keyword_weight: float = 0.3        # Weight for keyword results in hybrid
```

### Retrieval Pipeline

```python
async def retrieve(query: str, config: RetrievalConfig) -> list[RetrievedChunk]:
    """
    1. Embed the query
    2. Search vector store for top_k * 2 candidates
    3. Filter by similarity threshold
    4. (Optional) Hybrid: also run keyword search, merge and deduplicate
    5. Rerank candidates to top_k
    6. Truncate context to max_context_tokens
    7. Return final chunks with scores and metadata
    """
    ...
```

## 6. Reranking

### Options

| Reranker | Type | Quality | Latency | Cost |
|----------|------|---------|---------|------|
| Cohere Rerank | API | Excellent | ~200ms | $1/1000 queries |
| cross-encoder/ms-marco | Local model | Very Good | ~100ms | Free |
| LLM-based reranking | Any LLM | Good | ~1-2s | Varies |

```python
class Reranker:
    async def rerank(
        self,
        query: str,
        chunks: list[RetrievedChunk],
        top_k: int = 5,
    ) -> list[RetrievedChunk]:
        """
        Score each chunk's relevance to the query using a cross-encoder.
        Return top_k chunks sorted by relevance score.
        """
        ...
```

## 7. Generation Prompt

```yaml
name: rag-generate
version: 1
description: Generate an answer grounded in retrieved context

system: |
  You are a helpful assistant that answers questions based on the provided context.

  Rules:
  - Only use information from the provided context to answer
  - If the context does not contain enough information, say "I don't have enough information to answer that"
  - Cite your sources by referencing the chunk metadata (e.g., [Source: document.pdf, page 3])
  - Do not make up information that is not in the context
  - If the question is ambiguous, ask for clarification

user_template: |
  Context:
  <context>
  {retrieved_chunks}
  </context>

  Question: {user_query}

  Answer the question based only on the context above. Cite your sources.
```

### Context Formatting

```python
def format_context(chunks: list[RetrievedChunk]) -> str:
    """Format retrieved chunks for the generation prompt."""
    context_parts = []
    for i, chunk in enumerate(chunks, 1):
        source = chunk.metadata.get("source", "unknown")
        page = chunk.metadata.get("page_number", "")
        section = chunk.metadata.get("section_header", "")
        header = f"[Source {i}: {source}"
        if page:
            header += f", page {page}"
        if section:
            header += f", section: {section}"
        header += "]"
        context_parts.append(f"{header}\n{chunk.content}")
    return "\n\n---\n\n".join(context_parts)
```

## 8. Evaluation Criteria

### Retrieval Quality

| Metric | Description | Target |
|--------|-------------|--------|
| Recall@K | % of relevant chunks retrieved in top K | > 80% |
| Precision@K | % of retrieved chunks that are relevant | > 60% |
| MRR | Mean Reciprocal Rank of first relevant chunk | > 0.7 |
| NDCG | Normalized Discounted Cumulative Gain | > 0.75 |

### Generation Quality

| Metric | Description | Target |
|--------|-------------|--------|
| Faithfulness | % of claims supported by context | > 95% |
| Answer relevance | Does the answer address the question? | > 90% |
| Context utilization | % of relevant context used in answer | > 70% |
| Completeness | Does the answer cover all aspects? | > 80% |

### Evaluation Dataset

Create a test set with:
```python
class RAGTestCase(BaseModel):
    id: str
    query: str
    relevant_document_ids: list[str]      # Ground truth: which docs are relevant
    expected_answer_contains: list[str]    # Key phrases expected in answer
    expected_answer_not_contains: list[str] # Phrases that indicate hallucination
```

Minimum 20 test cases covering:
- Simple factual questions (direct retrieval)
- Multi-hop questions (require combining multiple chunks)
- Questions with no answer in corpus (should say "I don't know")
- Ambiguous questions (should ask for clarification or handle gracefully)

## FastAPI Integration

```python
# app/api/v1/rag.py
from fastapi import APIRouter, Depends
from app.ai.rag.pipeline import RAGPipeline

router = APIRouter(prefix="/api/v1/rag", tags=["RAG"])

@router.post("/query")
async def rag_query(
    request: RAGQueryRequest,
    pipeline: RAGPipeline = Depends(get_rag_pipeline),
):
    """Query the RAG pipeline."""
    result = await pipeline.query(
        query=request.query,
        filters=request.filters,
        top_k=request.top_k,
    )
    return RAGQueryResponse(
        answer=result.answer,
        sources=result.sources,
        confidence=result.confidence,
    )

@router.post("/ingest")
async def ingest_document(
    request: IngestRequest,
    pipeline: RAGPipeline = Depends(get_rag_pipeline),
):
    """Ingest a new document into the RAG pipeline."""
    result = await pipeline.ingest(
        content=request.content,
        metadata=request.metadata,
        doc_type=request.doc_type,
    )
    return IngestResponse(
        document_id=result.document_id,
        chunks_created=result.chunk_count,
    )
```
