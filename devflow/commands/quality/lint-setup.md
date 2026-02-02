---
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - LS
---

# Lint Setup

## Usage
```
/quality:lint-setup
```

## Description
Detects the project type and configures linting, formatting, and type checking tools. Creates configuration files for the detected stack and optionally sets up pre-commit hooks.

## References
- `devflow/rules/backend-patterns.md` — Python backend structure
- `devflow/rules/frontend-patterns.md` — Frontend structure

## Execution

### Step 1: Detect Project Type
Scan the project to determine what stacks are present:

```bash
# Python backend
test -f requirements.txt -o -f pyproject.toml && echo "python"

# Angular frontend
test -f angular.json && echo "angular"

# React frontend
test -f package.json && grep -q '"react"' package.json && echo "react"
```

Store detected stacks. Multiple stacks can be present (e.g., Python backend + Angular frontend in a monorepo).

### Step 2: Configure Python Backend

If Python is detected, set up Ruff + mypy + pre-commit.

#### 2a: Create `.ruff.toml`
Check if `.ruff.toml` or `[tool.ruff]` in `pyproject.toml` already exists. If not, create `.ruff.toml`:

```toml
# Ruff configuration — linting and formatting
target-version = "py312"
line-length = 100

[lint]
select = [
    "E",      # pycodestyle errors
    "W",      # pycodestyle warnings
    "F",      # pyflakes
    "I",      # isort (import sorting)
    "N",      # pep8-naming
    "UP",     # pyupgrade
    "B",      # flake8-bugbear
    "SIM",    # flake8-simplify
    "T20",    # flake8-print (no print statements)
    "PTH",    # flake8-use-pathlib
    "RUF",    # Ruff-specific rules
]
ignore = [
    "E501",   # line too long (handled by formatter)
]

[lint.isort]
known-first-party = ["app"]

[lint.per-file-ignores]
"tests/**/*.py" = ["T20"]  # Allow print in tests
"alembic/**/*.py" = ["T20", "UP"]  # Relax rules for migrations

[format]
quote-style = "double"
indent-style = "space"
docstring-code-format = true
```

#### 2b: Create `mypy.ini` or add to `pyproject.toml`
If `mypy.ini` does not exist and `[tool.mypy]` is not in `pyproject.toml`:

```ini
[mypy]
python_version = 3.12
strict = true
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
disallow_incomplete_defs = true
check_untyped_defs = true

[mypy-alembic.*]
ignore_errors = true

[mypy-tests.*]
disallow_untyped_defs = false
```

#### 2c: Create `.pre-commit-config.yaml`
If `.pre-commit-config.yaml` does not exist:

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.8.6
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.14.1
    hooks:
      - id: mypy
        additional_dependencies:
          - pydantic
          - sqlalchemy[mypy]
          - fastapi

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-json
      - id: check-added-large-files
        args: ['--maxkb=1000']
      - id: no-commit-to-branch
        args: ['--branch', 'main']
```

#### 2d: Install pre-commit hooks
```bash
pip install pre-commit 2>/dev/null
pre-commit install 2>/dev/null
```

### Step 3: Configure Angular Frontend

If Angular is detected, set up ESLint + Prettier + Angular ESLint.

#### 3a: Check existing ESLint config
```bash
test -f .eslintrc.js -o -f .eslintrc.json -o -f eslint.config.js && echo "exists"
```

If no ESLint config exists, check if Angular ESLint schematics are available:
```bash
npx ng lint 2>&1 | head -5
```

If Angular ESLint is not set up:
```bash
ng add @angular-eslint/schematics --skip-confirmation 2>/dev/null
```

#### 3b: Create or update ESLint config
If using flat config (`eslint.config.js`):

```javascript
// eslint.config.js
const angular = require('angular-eslint');
const tseslint = require('typescript-eslint');
const prettier = require('eslint-config-prettier');

module.exports = tseslint.config(
  {
    files: ['**/*.ts'],
    extends: [
      ...tseslint.configs.recommended,
      ...angular.configs.tsRecommended,
      prettier,
    ],
    processor: angular.processInlineTemplates,
    rules: {
      '@angular-eslint/directive-selector': ['error', { type: 'attribute', prefix: 'app', style: 'camelCase' }],
      '@angular-eslint/component-selector': ['error', { type: 'element', prefix: 'app', style: 'kebab-case' }],
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/explicit-function-return-type': 'warn',
    },
  },
  {
    files: ['**/*.html'],
    extends: [
      ...angular.configs.templateRecommended,
      ...angular.configs.templateAccessibility,
    ],
    rules: {
      '@angular-eslint/template/click-events-have-key-events': 'error',
      '@angular-eslint/template/interactive-supports-focus': 'error',
      '@angular-eslint/template/label-has-associated-control': 'error',
    },
  },
);
```

If using legacy config (`.eslintrc.js`):

```javascript
// .eslintrc.js
module.exports = {
  root: true,
  overrides: [
    {
      files: ['*.ts'],
      extends: [
        'eslint:recommended',
        'plugin:@typescript-eslint/recommended',
        'plugin:@angular-eslint/recommended',
        'plugin:@angular-eslint/template/process-inline-templates',
        'prettier',
      ],
      rules: {
        '@angular-eslint/directive-selector': ['error', { type: 'attribute', prefix: 'app', style: 'camelCase' }],
        '@angular-eslint/component-selector': ['error', { type: 'element', prefix: 'app', style: 'kebab-case' }],
        '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      },
    },
    {
      files: ['*.html'],
      extends: [
        'plugin:@angular-eslint/template/recommended',
        'plugin:@angular-eslint/template/accessibility',
      ],
      rules: {
        '@angular-eslint/template/click-events-have-key-events': 'error',
        '@angular-eslint/template/interactive-supports-focus': 'error',
      },
    },
  ],
};
```

#### 3c: Create `.prettierrc`
If `.prettierrc` does not exist:

```json
{
  "singleQuote": true,
  "trailingComma": "all",
  "printWidth": 100,
  "tabWidth": 2,
  "semi": true,
  "bracketSpacing": true,
  "arrowParens": "always",
  "endOfLine": "lf",
  "overrides": [
    {
      "files": "*.html",
      "options": {
        "parser": "angular"
      }
    }
  ]
}
```

#### 3d: Create `.prettierignore`
If `.prettierignore` does not exist:

```
dist/
node_modules/
coverage/
.angular/
```

#### 3e: Install dependencies if missing
```bash
npm ls prettier eslint-config-prettier 2>/dev/null || npm install -D prettier eslint-config-prettier
```

### Step 4: Configure React Frontend

If React is detected (and not Angular), set up ESLint + Prettier.

#### 4a: Create `eslint.config.js`
If no ESLint config exists:

```javascript
// eslint.config.js
import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import react from 'eslint-plugin-react';
import reactHooks from 'eslint-plugin-react-hooks';
import jsxA11y from 'eslint-plugin-jsx-a11y';
import prettier from 'eslint-config-prettier';

export default tseslint.config(
  js.configs.recommended,
  ...tseslint.configs.recommended,
  prettier,
  {
    files: ['**/*.{ts,tsx}'],
    plugins: {
      react,
      'react-hooks': reactHooks,
      'jsx-a11y': jsxA11y,
    },
    rules: {
      ...react.configs.recommended.rules,
      ...reactHooks.configs.recommended.rules,
      ...jsxA11y.configs.recommended.rules,
      'react/react-in-jsx-scope': 'off',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      'jsx-a11y/anchor-is-valid': 'error',
      'jsx-a11y/click-events-have-key-events': 'error',
    },
    settings: {
      react: { version: 'detect' },
    },
  },
);
```

#### 4b: Create `.prettierrc`
Same as Angular (Step 3c) but without the Angular HTML parser override:

```json
{
  "singleQuote": true,
  "trailingComma": "all",
  "printWidth": 100,
  "tabWidth": 2,
  "semi": true,
  "bracketSpacing": true,
  "arrowParens": "always",
  "endOfLine": "lf"
}
```

#### 4c: Install dependencies if missing
```bash
npm ls eslint prettier typescript-eslint eslint-config-prettier eslint-plugin-react eslint-plugin-react-hooks eslint-plugin-jsx-a11y 2>/dev/null || \
  npm install -D eslint prettier typescript-eslint eslint-config-prettier eslint-plugin-react eslint-plugin-react-hooks eslint-plugin-jsx-a11y
```

### Step 5: Add npm Scripts
Check `package.json` and add lint/format scripts if missing:

```json
{
  "scripts": {
    "lint": "eslint . --fix",
    "format": "prettier --write \"src/**/*.{ts,tsx,html,css,json}\"",
    "format:check": "prettier --check \"src/**/*.{ts,tsx,html,css,json}\"",
    "typecheck": "tsc --noEmit"
  }
}
```

For Angular projects, prefer the `ng lint` command:
```json
{
  "scripts": {
    "lint": "ng lint --fix",
    "format": "prettier --write \"src/**/*.{ts,html,css,json}\"",
    "format:check": "prettier --check \"src/**/*.{ts,html,css,json}\""
  }
}
```

### Step 6: Output

```
Lint setup complete.

Detected stacks:
  - {Python backend / Angular frontend / React frontend}

Configurations created:
  {list of files created, skipping any that already existed}

Configurations skipped (already exist):
  {list of files that were not overwritten}

Commands available:
  {Python}:
    ruff check .              — Lint Python code
    ruff format .             — Format Python code
    mypy app/                 — Type check Python code
    pre-commit run --all      — Run all pre-commit hooks

  {Angular}:
    ng lint --fix             — Lint Angular code
    npm run format            — Format with Prettier
    npm run format:check      — Check formatting

  {React}:
    npm run lint              — Lint React code
    npm run format            — Format with Prettier
    npm run typecheck         — Type check TypeScript

Next: Run the lint command to see current issues
```

### Step 7: Error Handling

If a tool is not installed:
```
{tool} not found. Install it:
  {Python}: pip install ruff mypy pre-commit
  {Node}: npm install -D eslint prettier
```

If configuration conflicts are detected:
```
Existing {file} found with different settings.
  - Current: {summary of existing config}
  - Recommended: {summary of recommended config}
  - Action: Review and merge manually, or remove existing file and re-run /quality:lint-setup
```
