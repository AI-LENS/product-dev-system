# Test Patterns

Detailed test patterns for each layer of the application stack.

## Unit Tests — Python (pytest)

### Structure: Arrange-Act-Assert
```python
def test_calculate_discount_premium_user_returns_20_percent():
    # Arrange
    user = UserFactory(tier="premium")
    order = OrderFactory(total=100.00, user=user)

    # Act
    discount = calculate_discount(order)

    # Assert
    assert discount == 20.00
```

### Parametrize for Variants
```python
@pytest.mark.parametrize("tier,expected_discount", [
    ("free", 0.0),
    ("basic", 5.0),
    ("premium", 20.0),
    ("enterprise", 30.0),
])
def test_calculate_discount_by_tier(tier, expected_discount):
    user = UserFactory(tier=tier)
    order = OrderFactory(total=100.00, user=user)
    assert calculate_discount(order) == expected_discount
```

### Mock External Services Only
```python
# Good: mock the HTTP call to external payment API
@patch("app.services.payment.httpx.AsyncClient.post")
async def test_charge_card_success(mock_post):
    mock_post.return_value = httpx.Response(200, json={"id": "ch_123"})
    result = await charge_card(amount=50.00, token="tok_test")
    assert result.charge_id == "ch_123"

# Bad: don't mock internal services
# @patch("app.services.order.OrderRepository.create")  # Avoid this
```

### conftest.py for Shared Fixtures
```python
# tests/conftest.py
import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.db import get_test_db, Base, engine

@pytest.fixture(autouse=True)
async def db_session():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

@pytest.fixture
def auth_headers():
    token = create_test_token(user_id=1, role="admin")
    return {"Authorization": f"Bearer {token}"}
```

## Unit Tests — JavaScript/TypeScript (Jest)

### Describe Blocks with Context
```typescript
describe('UserService', () => {
  let service: UserService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [UserService],
    });
    service = TestBed.inject(UserService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  describe('getUser', () => {
    it('should return user when API responds with 200', () => {
      const mockUser = { id: 1, name: 'Test User' };
      service.getUser(1).subscribe(user => {
        expect(user).toEqual(mockUser);
      });
      const req = httpMock.expectOne('/api/users/1');
      expect(req.request.method).toBe('GET');
      req.flush(mockUser);
    });

    it('should throw error when API responds with 404', () => {
      service.getUser(999).subscribe({
        error: (err) => {
          expect(err.status).toBe(404);
        },
      });
      const req = httpMock.expectOne('/api/users/999');
      req.flush('Not found', { status: 404, statusText: 'Not Found' });
    });
  });
});
```

### jest.mock for Module-Level Mocking
```typescript
jest.mock('../api/client', () => ({
  apiClient: {
    get: jest.fn(),
    post: jest.fn(),
  },
}));

import { apiClient } from '../api/client';

describe('fetchUsers', () => {
  it('should call API and return users', async () => {
    (apiClient.get as jest.Mock).mockResolvedValue({ data: [{ id: 1 }] });
    const users = await fetchUsers();
    expect(users).toHaveLength(1);
    expect(apiClient.get).toHaveBeenCalledWith('/users');
  });
});
```

## Integration Tests

### FastAPI TestClient with Real Database
```python
import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.mark.asyncio
async def test_create_and_retrieve_user(client: AsyncClient):
    # Create
    response = await client.post("/api/users", json={
        "email": "test@example.com",
        "name": "Test User",
    })
    assert response.status_code == 201
    user_id = response.json()["id"]

    # Retrieve
    response = await client.get(f"/api/users/{user_id}")
    assert response.status_code == 200
    assert response.json()["email"] == "test@example.com"
```

### factory_boy for Test Data
```python
import factory
from app.models import User, Order

class UserFactory(factory.Factory):
    class Meta:
        model = User

    email = factory.Sequence(lambda n: f"user{n}@example.com")
    name = factory.Faker("name")
    tier = "free"
    is_active = True

class OrderFactory(factory.Factory):
    class Meta:
        model = Order

    user = factory.SubFactory(UserFactory)
    total = factory.Faker("pydecimal", left_digits=3, right_digits=2, positive=True)
    status = "pending"
```

## E2E Tests (Playwright)

### Page Objects Pattern
```typescript
// pages/login.page.ts
import { Page, Locator } from '@playwright/test';

export class LoginPage {
  readonly page: Page;
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly errorMessage: Locator;

  constructor(page: Page) {
    this.page = page;
    this.emailInput = page.locator('[data-testid="email-input"]');
    this.passwordInput = page.locator('[data-testid="password-input"]');
    this.submitButton = page.locator('[data-testid="submit-button"]');
    this.errorMessage = page.locator('[data-testid="error-message"]');
  }

  async goto() {
    await this.page.goto('/login');
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }
}
```

### Stable Selectors and Screenshot on Failure
```typescript
import { test, expect } from '@playwright/test';
import { LoginPage } from './pages/login.page';

test.describe('Authentication', () => {
  test('successful login redirects to dashboard', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login('user@example.com', 'password123');
    await expect(page).toHaveURL('/dashboard');
    await expect(page.locator('[data-testid="welcome-message"]')).toBeVisible();
  });

  test('invalid credentials show error', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login('user@example.com', 'wrong-password');
    await expect(loginPage.errorMessage).toHaveText('Invalid credentials');
  });
});

// playwright.config.ts handles screenshot on failure automatically:
// use: { screenshot: 'only-on-failure', trace: 'on-first-retry' }
```

### Retry Flaky Steps
```typescript
test('dashboard loads data', async ({ page }) => {
  await page.goto('/dashboard');
  // Retry assertion until timeout (default 5s)
  await expect(page.locator('[data-testid="data-table"]')).toBeVisible();
  // Use polling for dynamic content
  await expect(async () => {
    const rows = await page.locator('[data-testid="table-row"]').count();
    expect(rows).toBeGreaterThan(0);
  }).toPass({ timeout: 10000 });
});
```

## AI Evaluation Tests

### Golden Dataset Comparison
```python
@pytest.mark.parametrize("input_text,expected_output", load_golden_dataset("tests/golden/summarize.jsonl"))
def test_summarize_matches_golden(input_text, expected_output, ai_service):
    result = ai_service.summarize(input_text)
    similarity = compute_similarity(result, expected_output)
    assert similarity >= 0.85, f"Similarity {similarity:.2f} below threshold 0.85"
```

### Metric Thresholds
```python
def test_classification_accuracy_above_threshold(ai_service, eval_dataset):
    correct = 0
    total = len(eval_dataset)
    for item in eval_dataset:
        prediction = ai_service.classify(item["input"])
        if prediction == item["expected"]:
            correct += 1
    accuracy = correct / total
    assert accuracy >= 0.90, f"Accuracy {accuracy:.2f} below threshold 0.90"
```

### Regression Detection
```python
def test_no_regression_from_baseline(ai_service, baseline_metrics):
    current = run_eval_suite(ai_service)
    for metric_name, baseline_value in baseline_metrics.items():
        current_value = current[metric_name]
        regression = baseline_value - current_value
        assert regression <= 0.02, (
            f"Regression detected in {metric_name}: "
            f"baseline={baseline_value:.3f}, current={current_value:.3f}"
        )
```
