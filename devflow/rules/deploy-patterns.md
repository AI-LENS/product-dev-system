# Deployment Patterns

Standards for deployment, release management, and infrastructure for all DevFlow projects.

## Deployment Strategies

### Blue-Green Deployment
- Maintain two identical production environments (blue and green)
- Deploy new version to inactive environment
- Run smoke tests against inactive environment
- Switch traffic via load balancer or DNS
- Keep old environment running for instant rollback
- Tear down old environment only after confidence period (minimum 1 hour)

### Canary Releases
- Deploy new version to a small percentage of traffic (5-10%)
- Monitor error rates, latency, and key business metrics
- Gradually increase traffic: 5% -> 25% -> 50% -> 100%
- Each stage requires minimum observation period (15 minutes)
- Automatic rollback if error rate exceeds baseline by 2x
- Use weighted routing (e.g., nginx upstream weights, cloud load balancer rules)

## Rollback Procedures

### Immediate Rollback
1. Revert load balancer/DNS to previous deployment
2. Verify previous version is serving traffic
3. Investigate failure in non-production environment
4. Timeline: under 5 minutes for traffic switch

### Database Migration Rollback
1. All migrations must have a corresponding `downgrade()` function
2. Test rollback in staging before production deploy
3. Never drop columns/tables in the same release that removes code references
4. Backwards-compatible migration strategy:
   - Release 1: Add new column (nullable), deploy code that writes to both
   - Release 2: Backfill data, switch reads to new column
   - Release 3: Remove old column

## Health Checks

### FastAPI Health Endpoints
```python
from fastapi import FastAPI, status
from fastapi.responses import JSONResponse

app = FastAPI()

@app.get("/health", status_code=status.HTTP_200_OK)
async def health():
    """Liveness probe: app is running."""
    return {"status": "healthy"}

@app.get("/ready", status_code=status.HTTP_200_OK)
async def ready():
    """Readiness probe: app can serve traffic."""
    checks = {
        "database": await check_database(),
        "redis": await check_redis(),
    }
    all_healthy = all(checks.values())
    return JSONResponse(
        status_code=200 if all_healthy else 503,
        content={"status": "ready" if all_healthy else "not_ready", "checks": checks},
    )
```

### Health Check Configuration
- Liveness probe: `/health` — restart container if fails 3 times
- Readiness probe: `/ready` — remove from load balancer if fails
- Startup probe: `/health` — allow 30 seconds for cold start
- Check interval: 10 seconds
- Timeout per check: 5 seconds

## Zero-Downtime Deployments

- Use rolling updates: replace instances one at a time
- Ensure at least N-1 instances are always running
- Drain connections before stopping an instance (graceful shutdown)
- FastAPI graceful shutdown: handle SIGTERM, finish in-flight requests
- Database connections: use connection pooling, handle pool exhaustion gracefully
- Session management: externalize sessions to Redis (not in-memory)

## Environment Promotion

```
dev → staging → production
```

| Stage | Purpose | Data | Deploy Trigger |
|-------|---------|------|----------------|
| dev | Feature development | Synthetic/seed data | Push to feature branch |
| staging | Pre-release validation | Anonymized production clone | Merge to main |
| production | Live users | Real data | Manual approval + tag |

### Promotion Rules
- Code must pass all checks in current environment before promotion
- Staging must mirror production infrastructure (same Docker images, same configs)
- Production deploys require explicit approval from at least one team lead
- All production deploys happen during business hours (unless hotfix)

## Feature Flags

### Implementation Pattern
```python
from app.config import feature_flags

async def get_recommendations(user_id: int):
    if feature_flags.is_enabled("new_recommendation_engine", user_id=user_id):
        return await new_recommendation_service.get(user_id)
    return await legacy_recommendation_service.get(user_id)
```

### Flag Lifecycle
1. Create flag in configuration (default: off)
2. Deploy code behind flag
3. Enable for internal users (dogfooding)
4. Gradual rollout: 10% -> 50% -> 100%
5. Remove flag and legacy code path after full rollout
6. Flags older than 30 days without full rollout need review

## Database Migration Safety

### Safe Migration Practices
- Never rename a column directly (add new, migrate data, drop old)
- Never drop a column in the same release that stops writing to it
- Add indexes concurrently: `CREATE INDEX CONCURRENTLY`
- Set lock timeouts on ALTER TABLE: `SET lock_timeout = '5s'`
- Test migrations against a copy of production data volume
- Always include both `upgrade()` and `downgrade()` in Alembic migrations

### Migration Review Checklist
- Does the migration acquire locks on large tables?
- Is the migration backwards-compatible with the current running code?
- Can the migration be rolled back cleanly?
- Has the migration been tested against production-volume data?
- Does the migration include data backfill (if so, is it batched)?
