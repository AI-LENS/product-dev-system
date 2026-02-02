---
allowed-tools: Bash, Read, Write, LS
---

# E2E Test Setup

Configure end-to-end testing with Playwright (preferred) or Cypress.

## Usage
```
/testing:e2e-setup
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/testing-strategy.md` — E2E test guidelines (10% of test effort)
- `devflow/rules/test-patterns.md` — E2E Playwright patterns (page objects, stable selectors)
- `devflow/rules/standard-patterns.md` — Standard output patterns

## Instructions

### 1. Install Playwright

```bash
npm init playwright@latest --yes
```

If that fails or the user prefers manual setup:
```bash
npm install --save-dev @playwright/test
npx playwright install --with-deps chromium
```

### 2. Create Playwright Configuration

**Create `playwright.config.ts`:**
```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html', { open: 'never' }],
    ['list'],
  ],
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:4200',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'mobile-chrome',
      use: { ...devices['Pixel 5'] },
    },
  ],
  webServer: {
    command: process.env.CI ? 'npm run start' : 'npm run start',
    url: 'http://localhost:4200',
    reuseExistingServer: !process.env.CI,
    timeout: 120000,
  },
});
```

### 3. Create Directory Structure

```
e2e/
  pages/
    login.page.ts
    dashboard.page.ts
    base.page.ts
  fixtures/
    auth.fixture.ts
  example.spec.ts
```

**Create `e2e/pages/base.page.ts`:**
```typescript
import { Page, Locator } from '@playwright/test';

export class BasePage {
  readonly page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async waitForPageLoad() {
    await this.page.waitForLoadState('networkidle');
  }

  async getByTestId(testId: string): Promise<Locator> {
    return this.page.locator(`[data-testid="${testId}"]`);
  }

  async navigateTo(path: string) {
    await this.page.goto(path);
    await this.waitForPageLoad();
  }
}
```

**Create `e2e/pages/login.page.ts`:**
```typescript
import { Page, Locator } from '@playwright/test';
import { BasePage } from './base.page';

export class LoginPage extends BasePage {
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly errorMessage: Locator;

  constructor(page: Page) {
    super(page);
    this.emailInput = page.locator('[data-testid="email-input"]');
    this.passwordInput = page.locator('[data-testid="password-input"]');
    this.submitButton = page.locator('[data-testid="login-submit"]');
    this.errorMessage = page.locator('[data-testid="login-error"]');
  }

  async goto() {
    await this.navigateTo('/login');
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }
}
```

**Create `e2e/pages/dashboard.page.ts`:**
```typescript
import { Page, Locator } from '@playwright/test';
import { BasePage } from './base.page';

export class DashboardPage extends BasePage {
  readonly welcomeMessage: Locator;
  readonly navMenu: Locator;
  readonly logoutButton: Locator;

  constructor(page: Page) {
    super(page);
    this.welcomeMessage = page.locator('[data-testid="welcome-message"]');
    this.navMenu = page.locator('[data-testid="nav-menu"]');
    this.logoutButton = page.locator('[data-testid="logout-button"]');
  }

  async goto() {
    await this.navigateTo('/dashboard');
  }
}
```

**Create `e2e/fixtures/auth.fixture.ts`:**
```typescript
import { test as base, Page } from '@playwright/test';
import { LoginPage } from '../pages/login.page';

type AuthFixtures = {
  authenticatedPage: Page;
};

export const test = base.extend<AuthFixtures>({
  authenticatedPage: async ({ page }, use) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login(
      process.env.TEST_USER_EMAIL || 'test@example.com',
      process.env.TEST_USER_PASSWORD || 'testpassword123',
    );
    await page.waitForURL('/dashboard');
    await use(page);
  },
});

export { expect } from '@playwright/test';
```

**Create `e2e/example.spec.ts`:**
```typescript
import { test, expect } from '@playwright/test';
import { LoginPage } from './pages/login.page';
import { DashboardPage } from './pages/dashboard.page';

test.describe('Application E2E Tests', () => {
  test('homepage loads successfully', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle(/.+/);
  });

  test('login page renders correctly', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await expect(loginPage.emailInput).toBeVisible();
    await expect(loginPage.passwordInput).toBeVisible();
    await expect(loginPage.submitButton).toBeVisible();
  });

  test('invalid login shows error message', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login('invalid@example.com', 'wrongpassword');
    await expect(loginPage.errorMessage).toBeVisible();
  });
});
```

### 4. CI Configuration

**Add to `.github/workflows/e2e.yml`** (or suggest addition to existing CI):
```yaml
name: E2E Tests
on:
  pull_request:
    branches: [main]

jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Install Playwright browsers
        run: npx playwright install --with-deps chromium

      - name: Run E2E tests
        run: npx playwright test --project=chromium
        env:
          CI: true
          BASE_URL: http://localhost:4200

      - name: Upload test results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 7
```

### 5. Add npm Scripts

Suggest adding to `package.json`:
```json
{
  "scripts": {
    "e2e": "playwright test",
    "e2e:headed": "playwright test --headed",
    "e2e:ui": "playwright test --ui",
    "e2e:report": "playwright show-report"
  }
}
```

### 6. Post-Setup

```
E2E testing configured:
  - Framework: Playwright
  - Config: playwright.config.ts
  - Test directory: e2e/
  - Page objects: e2e/pages/
  - Sample test: e2e/example.spec.ts
  - CI workflow: .github/workflows/e2e.yml

Next steps:
  - Run E2E tests: npx playwright test
  - Debug with UI: npx playwright test --ui
  - Add data-testid attributes to components for stable selectors
  - Write page objects for each major page
```

## Error Recovery

- If Playwright install fails, suggest: `npx playwright install --with-deps`
- If browser download is blocked by firewall, suggest setting `PLAYWRIGHT_BROWSERS_PATH`
- If the dev server port differs from 4200, update `baseURL` in playwright.config.ts
