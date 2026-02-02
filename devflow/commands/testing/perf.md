---
allowed-tools: Bash, Read, Write, LS, Task
---

# Performance Benchmarks

Run performance benchmarks and generate a performance report.

## Usage
```
/testing:perf
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/testing-strategy.md` — Testing standards
- `devflow/rules/observability.md` — Metrics and performance thresholds
- `devflow/rules/standard-patterns.md` — Standard output patterns

## Instructions

### 1. Detect Project Components

Scan the project to determine what performance tests to run:

| Indicator | Component | Benchmark Type |
|-----------|-----------|---------------|
| `app/main.py` or FastAPI imports | Python API | Load test + response time |
| `requirements.txt` with ML libs | AI/ML pipeline | Inference latency |
| `angular.json` | Angular frontend | Bundle size + Lighthouse |
| `package.json` with React | React frontend | Bundle size + Lighthouse |
| `Dockerfile` | Container | Image size |

### 2. API Load Testing (Python/FastAPI)

**Check if locust is installed:**
```bash
pip show locust 2>/dev/null || pip install locust
```

**Create `tests/perf/locustfile.py`** (if not exists):
```python
"""Load test for FastAPI application."""
from locust import HttpUser, task, between


class APIUser(HttpUser):
    wait_time = between(0.5, 2.0)
    host = "http://localhost:8000"

    @task(3)
    def get_health(self):
        self.client.get("/health")

    @task(2)
    def list_items(self):
        self.client.get("/api/v1/items", params={"limit": 20})

    @task(1)
    def create_item(self):
        self.client.post("/api/v1/items", json={
            "name": "Test Item",
            "description": "Performance test item",
        })
```

**Run load test (headless mode):**
```bash
locust -f tests/perf/locustfile.py --headless -u 50 -r 10 --run-time 60s --host http://localhost:8000 --csv=tests/perf/results
```

Parameters: 50 users, spawn rate 10/s, 60 second duration.

**Parse results from `tests/perf/results_stats.csv`:**
- Requests per second
- Average response time
- P50, P95, P99 latency
- Error rate
- Failures per endpoint

### 3. API Response Time Analysis

**Run targeted response time checks:**
```bash
# Quick benchmark with curl (for each key endpoint)
for endpoint in /health /api/v1/items /api/v1/users; do
  echo "Testing $endpoint..."
  curl -o /dev/null -s -w "  Status: %{http_code}\n  Time: %{time_total}s\n  TTFB: %{time_starttransfer}s\n" "http://localhost:8000$endpoint"
done
```

**Thresholds:**
| Metric | Good | Acceptable | Poor |
|--------|------|-----------|------|
| P50 response time | < 100ms | 100-500ms | > 500ms |
| P95 response time | < 500ms | 500ms-2s | > 2s |
| P99 response time | < 1s | 1s-5s | > 5s |
| Error rate | < 0.1% | 0.1-1% | > 1% |

### 4. Memory Profiling (Python)

**Check if memory-profiler is installed:**
```bash
pip show memory-profiler 2>/dev/null || pip install memory-profiler
```

**Run memory profile on startup:**
```bash
python -c "
import tracemalloc
tracemalloc.start()

from app.main import app

snapshot = tracemalloc.take_snapshot()
stats = snapshot.statistics('lineno')
print('Top 10 memory allocations:')
for stat in stats[:10]:
    print(f'  {stat}')

current, peak = tracemalloc.get_traced_memory()
print(f'\nCurrent memory: {current / 1024 / 1024:.1f} MB')
print(f'Peak memory: {peak / 1024 / 1024:.1f} MB')
tracemalloc.stop()
"
```

### 5. Frontend Bundle Size Analysis

**Angular:**
```bash
ng build --configuration=production --stats-json
# Analyze bundle
npx webpack-bundle-analyzer dist/*/stats.json --mode static --report dist/bundle-report.html --no-open
```

**React (if applicable):**
```bash
npx react-scripts build
# Or with Vite
npx vite build --report
```

**Bundle size thresholds:**
| Bundle | Good | Acceptable | Poor |
|--------|------|-----------|------|
| Main bundle (gzipped) | < 100KB | 100-250KB | > 250KB |
| Vendor bundle (gzipped) | < 200KB | 200-500KB | > 500KB |
| Total initial load (gzipped) | < 300KB | 300-750KB | > 750KB |
| Lazy-loaded chunk | < 50KB | 50-150KB | > 150KB |

### 6. Lighthouse Score (Frontend)

**If Chrome/Chromium is available:**
```bash
npx lighthouse http://localhost:4200 --output json --output html --output-path=./tests/perf/lighthouse --chrome-flags="--headless --no-sandbox" --only-categories=performance,accessibility,best-practices
```

**Threshold targets:**
| Category | Target |
|----------|--------|
| Performance | >= 90 |
| Accessibility | >= 90 |
| Best Practices | >= 90 |

### 7. Docker Image Size (if applicable)

```bash
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | head -5
```

**Threshold:** Production image should be under 500MB (under 200MB for slim builds).

### 8. Generate Performance Report

**Create `tests/perf/report.md`:**

```markdown
# Performance Report

Generated: {datetime}

## API Performance

| Endpoint | P50 | P95 | P99 | RPS | Status |
|----------|-----|-----|-----|-----|--------|
| GET /health | {ms} | {ms} | {ms} | {rps} | {PASS/FAIL} |
| GET /api/v1/items | {ms} | {ms} | {ms} | {rps} | {PASS/FAIL} |

## Memory Profile
- Startup memory: {MB}
- Peak memory: {MB}
- Top allocations: {list}

## Frontend Bundle Size
- Main bundle: {KB} (gzipped)
- Vendor bundle: {KB} (gzipped)
- Total: {KB} (gzipped)
- Status: {PASS/FAIL}

## Lighthouse Scores
- Performance: {score}
- Accessibility: {score}
- Best Practices: {score}

## Recommendations
{prioritized list of improvements}
```

Report the summary to the user. Save the full report to `tests/perf/report.md`.

## Error Recovery

- If locust is not installed, install it and retry
- If the server is not running, tell the user to start it first
- If Lighthouse fails, skip that section and note it in the report
- If no frontend exists, skip bundle and Lighthouse analysis
