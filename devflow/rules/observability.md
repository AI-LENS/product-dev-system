# Observability Patterns

Standards for logging, metrics, tracing, and alerting across all DevFlow projects.

## Structured Logging

### Python (structlog)
```python
import structlog

logger = structlog.get_logger()

# Configure once at startup
structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer(),
    ],
    wrapper_class=structlog.make_filtering_bound_logger(logging.INFO),
)

# Usage in application code
logger.info("user_created", user_id=user.id, email=user.email)
logger.warning("rate_limit_approaching", endpoint="/api/search", current=95, limit=100)
logger.error("payment_failed", order_id=order.id, provider="stripe", error=str(e))
```

### Correlation IDs
```python
from fastapi import Request
from uuid import uuid4
import structlog

@app.middleware("http")
async def correlation_id_middleware(request: Request, call_next):
    correlation_id = request.headers.get("X-Correlation-ID", str(uuid4()))
    structlog.contextvars.clear_contextvars()
    structlog.contextvars.bind_contextvars(correlation_id=correlation_id)
    response = await call_next(request)
    response.headers["X-Correlation-ID"] = correlation_id
    return response
```

### Log Levels

| Level | When to Use | Examples |
|-------|------------|----------|
| DEBUG | Development only, verbose internals | SQL queries, cache hits, serialization details |
| INFO | Request lifecycle, business events | User created, order placed, job started |
| WARNING | Degraded state, approaching limits | Rate limit near, cache miss fallback, slow query |
| ERROR | Operation failures, caught exceptions | Payment failed, API timeout, validation error |
| CRITICAL | System-level failures, requires immediate action | Database unreachable, out of memory, certificate expired |

### Log Format (JSON)
```json
{
  "timestamp": "2025-01-15T10:30:00Z",
  "level": "info",
  "event": "request_completed",
  "correlation_id": "abc-123-def",
  "method": "POST",
  "path": "/api/users",
  "status_code": 201,
  "duration_ms": 45,
  "user_id": 42
}
```

## Metrics (Prometheus Format)

### Key Metrics to Track
```python
from prometheus_client import Counter, Histogram, Gauge

# Request metrics
REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status_code"],
)
REQUEST_DURATION = Histogram(
    "http_request_duration_seconds",
    "HTTP request duration in seconds",
    ["method", "endpoint"],
    buckets=[0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0],
)

# Business metrics
ACTIVE_USERS = Gauge("active_users", "Currently active users")
QUEUE_DEPTH = Gauge("task_queue_depth", "Number of tasks waiting in queue", ["queue_name"])

# Error metrics
ERROR_COUNT = Counter("errors_total", "Total errors", ["type", "component"])
```

### FastAPI Metrics Middleware
```python
import time
from fastapi import Request

@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start = time.perf_counter()
    response = await call_next(request)
    duration = time.perf_counter() - start

    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.url.path,
        status_code=response.status_code,
    ).inc()
    REQUEST_DURATION.labels(
        method=request.method,
        endpoint=request.url.path,
    ).observe(duration)

    return response
```

## Distributed Tracing (OpenTelemetry)

### FastAPI Integration
```python
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter

def setup_tracing(app: FastAPI):
    provider = TracerProvider()
    exporter = OTLPSpanExporter(endpoint="http://otel-collector:4317")
    provider.add_span_processor(BatchSpanProcessor(exporter))
    trace.set_tracer_provider(provider)

    FastAPIInstrumentor.instrument_app(app)
    HTTPXClientInstrumentor().instrument()
    SQLAlchemyInstrumentor().instrument(engine=engine)
```

### Custom Spans
```python
tracer = trace.get_tracer(__name__)

async def process_order(order_id: int):
    with tracer.start_as_current_span("process_order") as span:
        span.set_attribute("order.id", order_id)

        with tracer.start_as_current_span("validate_inventory"):
            await validate_inventory(order_id)

        with tracer.start_as_current_span("charge_payment"):
            await charge_payment(order_id)

        span.set_attribute("order.status", "completed")
```

## Alerting

### Alert Thresholds

| Alert | Condition | Severity | Response |
|-------|-----------|----------|----------|
| High error rate | Error rate > 5% for 5 minutes | Critical | Page on-call |
| Elevated latency | P95 > 2s for 10 minutes | Warning | Notify channel |
| P99 latency spike | P99 > 5s for 5 minutes | Critical | Page on-call |
| Resource usage | CPU > 80% for 15 minutes | Warning | Scale up |
| Database connections | Pool > 90% utilized | Warning | Investigate |
| Disk space | Usage > 85% | Warning | Clean up or expand |
| Health check failure | 3 consecutive failures | Critical | Auto-restart + page |

### Alert Configuration (Prometheus/Alertmanager style)
```yaml
groups:
  - name: api_alerts
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status_code=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate on {{ $labels.endpoint }}"
          description: "Error rate is {{ $value | humanizePercentage }} on {{ $labels.endpoint }}"

      - alert: HighLatency
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 2
        for: 10m
        labels:
          severity: warning
```

## Frontend Observability

### Error Boundary Reporting
```typescript
// Angular: Global error handler
@Injectable()
export class GlobalErrorHandler implements ErrorHandler {
  constructor(private errorReporter: ErrorReporterService) {}

  handleError(error: any): void {
    this.errorReporter.report({
      message: error.message,
      stack: error.stack,
      timestamp: new Date().toISOString(),
      url: window.location.href,
      userAgent: navigator.userAgent,
    });
    console.error('Unhandled error:', error);
  }
}
```

### Performance Marks and Core Web Vitals
```typescript
// Track Core Web Vitals
import { onCLS, onFID, onLCP, onFCP, onTTFB } from 'web-vitals';

function reportMetric(metric: { name: string; value: number }) {
  fetch('/api/metrics/vitals', {
    method: 'POST',
    body: JSON.stringify({ name: metric.name, value: metric.value }),
    headers: { 'Content-Type': 'application/json' },
  });
}

onCLS(reportMetric);
onFID(reportMetric);
onLCP(reportMetric);
onFCP(reportMetric);
onTTFB(reportMetric);
```

### Vital Thresholds

| Metric | Good | Needs Improvement | Poor |
|--------|------|-------------------|------|
| LCP (Largest Contentful Paint) | < 2.5s | 2.5s - 4.0s | > 4.0s |
| FID (First Input Delay) | < 100ms | 100ms - 300ms | > 300ms |
| CLS (Cumulative Layout Shift) | < 0.1 | 0.1 - 0.25 | > 0.25 |

## Dashboard Patterns

### Primary Dashboard Panels
1. **Request rate** — Requests per second, broken down by endpoint
2. **Error rate** — 4xx and 5xx rates as percentage of total requests
3. **Latency percentiles** — P50, P95, P99 response times over time
4. **Active users** — Concurrent sessions / active WebSocket connections
5. **Database** — Query duration P95, connection pool usage, slow query count
6. **Queue** — Depth, processing rate, dead letter count
7. **Infrastructure** — CPU, memory, disk, network per service

### Dashboard Organization
- **Overview:** Top-level health across all services (red/yellow/green)
- **Per-service:** Detailed metrics for each microservice
- **Business:** User signups, conversions, revenue (if applicable)
- **Infrastructure:** Resource utilization, scaling events, costs
