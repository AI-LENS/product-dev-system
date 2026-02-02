# Integration Testing Patterns

Patterns for testing interactions between system components.

## Contract Testing (Frontend <-> API)

### OpenAPI Schema Validation
Validate that the frontend API client matches the backend OpenAPI schema:
```python
# test_contract.py
import json
from openapi_spec_validator import validate

def test_openapi_schema_is_valid(client):
    response = client.get("/openapi.json")
    schema = response.json()
    validate(schema)

def test_api_response_matches_schema(client):
    response = client.get("/api/users/1")
    assert response.status_code == 200
    # Validate response body matches the schema definition
    validate_response_against_schema(response.json(), "UserResponse", schema)
```

### Frontend Contract Verification
```typescript
// Ensure TypeScript interfaces match API response shapes
import { UserResponse } from './models/user';
import schema from '../openapi.json';

describe('API Contract', () => {
  it('UserResponse interface matches OpenAPI schema', () => {
    const schemaProperties = schema.components.schemas.UserResponse.properties;
    const sampleResponse: UserResponse = {
      id: 1,
      email: 'test@example.com',
      name: 'Test User',
      created_at: '2025-01-01T00:00:00Z',
    };
    // Verify all schema-required fields exist in our interface
    for (const field of schema.components.schemas.UserResponse.required) {
      expect(sampleResponse).toHaveProperty(field);
    }
  });
});
```

## API Mocking for Frontend Tests (MSW)

### Mock Service Worker Setup
```typescript
// mocks/handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('/api/users', () => {
    return HttpResponse.json([
      { id: 1, email: 'alice@example.com', name: 'Alice' },
      { id: 2, email: 'bob@example.com', name: 'Bob' },
    ]);
  }),

  http.post('/api/users', async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json(
      { id: 3, ...body },
      { status: 201 },
    );
  }),

  http.get('/api/users/:id', ({ params }) => {
    const { id } = params;
    if (id === '999') {
      return HttpResponse.json(
        { detail: 'User not found' },
        { status: 404 },
      );
    }
    return HttpResponse.json({ id: Number(id), email: 'user@example.com', name: 'User' });
  }),
];

// mocks/server.ts
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);

// test setup (jest.setup.ts)
import { server } from './mocks/server';

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

### Per-Test Override
```typescript
import { http, HttpResponse } from 'msw';
import { server } from '../mocks/server';

test('shows error state when API fails', async () => {
  server.use(
    http.get('/api/users', () => {
      return HttpResponse.json({ detail: 'Internal error' }, { status: 500 });
    }),
  );
  // Component should render error state
  render(<UserList />);
  expect(await screen.findByText('Failed to load users')).toBeInTheDocument();
});
```

## Database Test Fixtures

### Transaction Rollback Pattern
```python
import pytest
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

@pytest.fixture
async def db_session():
    """Each test gets a transaction that rolls back automatically."""
    engine = create_async_engine(TEST_DATABASE_URL)
    async with engine.connect() as conn:
        transaction = await conn.begin()
        session = AsyncSession(bind=conn, expire_on_commit=False)
        yield session
        await transaction.rollback()
        await session.close()
    await engine.dispose()
```

### factory_boy with SQLAlchemy
```python
import factory
from factory.alchemy import SQLAlchemyModelFactory
from app.models import User, Order

class UserFactory(SQLAlchemyModelFactory):
    class Meta:
        model = User
        sqlalchemy_session_persistence = "commit"

    email = factory.Sequence(lambda n: f"user{n}@test.com")
    name = factory.Faker("name")
    is_active = True

class OrderFactory(SQLAlchemyModelFactory):
    class Meta:
        model = Order
        sqlalchemy_session_persistence = "commit"

    user = factory.SubFactory(UserFactory)
    total = factory.LazyFunction(lambda: round(random.uniform(10, 500), 2))
    status = "pending"

# Usage in tests
def test_user_orders(db_session):
    user = UserFactory(session=db_session)
    orders = OrderFactory.create_batch(3, session=db_session, user=user)
    assert len(user.orders) == 3
```

## External Service Mocking

### Python HTTP Mocking (responses library)
```python
import responses
from app.services.geocoding import geocode_address

@responses.activate
def test_geocode_returns_coordinates():
    responses.add(
        responses.GET,
        "https://api.geocoder.example.com/v1/search",
        json={"results": [{"lat": 40.7128, "lon": -74.0060}]},
        status=200,
    )
    result = geocode_address("New York, NY")
    assert result.lat == pytest.approx(40.7128)
    assert result.lon == pytest.approx(-74.0060)

@responses.activate
def test_geocode_handles_api_failure():
    responses.add(
        responses.GET,
        "https://api.geocoder.example.com/v1/search",
        json={"error": "rate limited"},
        status=429,
    )
    with pytest.raises(GeocodingError, match="rate limited"):
        geocode_address("New York, NY")
```

### Python Async HTTP Mocking (respx for httpx)
```python
import respx
import httpx

@respx.mock
async def test_external_api_call():
    respx.get("https://api.example.com/data").mock(
        return_value=httpx.Response(200, json={"key": "value"})
    )
    result = await fetch_external_data()
    assert result["key"] == "value"
```

## Event-Driven Testing

### Async Message Verification
```python
import pytest
from unittest.mock import AsyncMock
from app.events import EventBus, OrderCreatedEvent

@pytest.fixture
def event_bus():
    return EventBus()

async def test_order_creation_publishes_event(event_bus):
    handler = AsyncMock()
    event_bus.subscribe(OrderCreatedEvent, handler)

    await create_order(event_bus, order_data={"item": "widget", "qty": 2})

    handler.assert_called_once()
    event = handler.call_args[0][0]
    assert isinstance(event, OrderCreatedEvent)
    assert event.item == "widget"
    assert event.quantity == 2

async def test_event_handlers_execute_in_order(event_bus):
    execution_order = []

    async def handler_a(event):
        execution_order.append("a")

    async def handler_b(event):
        execution_order.append("b")

    event_bus.subscribe(OrderCreatedEvent, handler_a, priority=1)
    event_bus.subscribe(OrderCreatedEvent, handler_b, priority=2)

    await event_bus.publish(OrderCreatedEvent(item="widget", quantity=1))
    assert execution_order == ["a", "b"]
```

## Test Environment Isolation

### Docker-Based Test Environment
```yaml
# docker-compose.test.yml
services:
  test-db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: testdb
      POSTGRES_USER: test
      POSTGRES_PASSWORD: test
    ports:
      - "5433:5432"
    tmpfs:
      - /var/lib/postgresql/data  # RAM-backed for speed

  test-redis:
    image: redis:7-alpine
    ports:
      - "6380:6379"
```

### Test Database Configuration
```python
# tests/conftest.py
import os

TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL",
    "postgresql+asyncpg://test:test@localhost:5433/testdb"
)

TEST_REDIS_URL = os.getenv(
    "TEST_REDIS_URL",
    "redis://localhost:6380/0"
)
```

### Isolation Rules
- Each test suite gets its own database schema (or transaction rollback)
- Redis test database uses a separate DB index (e.g., db=1)
- File system operations use `tmp_path` fixture (pytest) or temp directories
- Environment variables are isolated per test using `monkeypatch` (pytest)
- Network calls to external services are always mocked (never real in tests)
