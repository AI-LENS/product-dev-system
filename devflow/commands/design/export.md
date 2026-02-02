---
allowed-tools: Read, Write, LS, Glob, Bash
---

# Design Export

Generate a complete handoff package documenting the design system, components, and implementation instructions.

## Usage
```
/design:export
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/design-standards.md` — Naming conventions, component API standards

## Preflight Checklist

1. **Check for design artifacts:**
   - Design tokens: `tailwind.config.js`, `src/styles/tokens.css`
   - Section designs: `devflow/designs/*.md`
   - Screen components: `src/app/features/*/`
   - Mock data: `src/app/mocks/`
   - If nothing found: "No design artifacts found. Run `/design:design-tokens` first to start the design phase."

2. **Inventory existing components:**
   - Scan `src/app/features/` for all feature modules
   - Scan `src/app/shared/` for shared components
   - Count total components, pages, services

## Instructions

You are a design systems documentarian creating a complete handoff package for developers.

### Step 1: Component Inventory

Scan the codebase and create a comprehensive inventory:

```markdown
# Component Inventory

## Design Tokens
- Color palette: [count] colors with [count] shades each
- Typography: [font family], [count] sizes
- Spacing: [count] values
- Shadows: [count] levels
- Themes: light, dark

## Shell Components
| Component | Path | Status | Tests |
|-----------|------|--------|-------|
| AppLayout | src/app/shell/app-layout/ | Complete | 4 tests |
| Sidebar | src/app/shell/sidebar/ | Complete | 6 tests |
| TopBar | src/app/shell/top-bar/ | Complete | 3 tests |
| UserMenu | src/app/shell/user-menu/ | Complete | 5 tests |
| Breadcrumb | src/app/shell/breadcrumb/ | Complete | 3 tests |
| Skeleton | src/app/shared/skeleton/ | Complete | 2 tests |

## Feature: [Section Name]
| Component | Type | Path | Status | Tests |
|-----------|------|------|--------|-------|
| ListPage | Page | src/app/features/section/pages/list-page/ | Complete | 5 tests |
| DetailPage | Page | src/app/features/section/pages/detail-page/ | Complete | 4 tests |
| StatusBadge | Presentational | src/app/features/section/components/status-badge/ | Complete | 2 tests |
| ... | ... | ... | ... | ... |

## Shared Components
| Component | Path | Used By | Tests |
|-----------|------|---------|-------|
| ConfirmDialog | src/app/shared/confirm-dialog/ | 3 features | 3 tests |
| DataTable | src/app/shared/data-table/ | 5 features | 8 tests |
| ... | ... | ... | ... |

## Summary
- Total components: [count]
- Total pages: [count]
- Total tests: [count]
- Test coverage estimate: [percentage]
```

Save to `devflow/designs/export/component-inventory.md`.

### Step 2: Design System Documentation

Create a living design system document:

```markdown
# Design System

## Color Palette
### Primary
[Visual representation using text blocks]
- primary-50: #eef2ff — Backgrounds, hover states
- primary-100: #e0e7ff — Light backgrounds
- primary-500: #6366f1 — Default buttons, links
- primary-700: #4338ca — Hover states for primary buttons
- primary-900: #312e81 — Active states

### Semantic Colors
- Success: #22c55e — Confirmations, positive status
- Warning: #f59e0b — Warnings, pending status
- Error: #ef4444 — Errors, destructive actions
- Info: #3b82f6 — Informational messages

## Typography
- **Headings:** Inter, semi-bold to bold
  - H1: 2.25rem/1.25 (36px) — Page titles
  - H2: 1.5rem/1.3 (24px) — Section titles
  - H3: 1.25rem/1.4 (20px) — Card titles
  - H4: 1.125rem/1.4 (18px) — Subsection titles
- **Body:** Inter, regular
  - Base: 1rem/1.5 (16px) — Default text
  - Small: 0.875rem/1.5 (14px) — Secondary text, labels
  - XS: 0.75rem/1.5 (12px) — Captions, timestamps
- **Code:** JetBrains Mono, regular
  - Inline: 0.875rem — Code snippets
  - Block: 0.875rem — Code blocks

## Spacing
- 4px grid system
- Component padding: 16px-24px
- Section gaps: 24px-32px
- Page margins: 24px (mobile: 16px)

## Components
### Buttons
- Primary: `btn btn-primary` — Main actions
- Secondary: `btn btn-secondary` — Supporting actions
- Ghost: `btn btn-ghost` — Tertiary, cancel actions
- Error: `btn btn-error` — Destructive actions
- Sizes: btn-sm (32px), default (40px), btn-lg (48px)

### Forms
- Input: `input input-bordered` — Default text input
- Select: `select select-bordered` — Dropdown select
- Textarea: `textarea textarea-bordered` — Multi-line input
- Validation: `input-error` class + error message below

### Feedback
- Alert: `alert alert-info|success|warning|error`
- Toast: positioned top-right, auto-dismiss 5s
- Modal: `modal` with `modal-box` content

### Data Display
- Table: `table table-zebra` with `hover` rows
- Badge: `badge badge-success|warning|error|ghost`
- Card: `card bg-base-100 shadow-md`
- Stat: `stats shadow` for dashboard metrics
```

Save to `devflow/designs/export/design-system.md`.

### Step 3: Implementation Prompts

For each component, generate a standalone implementation prompt that another developer (or AI) could use to build it from scratch:

```markdown
# Implementation Prompt: [ComponentName]

## Context
This component is part of the [section] feature. It [purpose description].

## Requirements
- Framework: Angular 17+ with standalone components (or NgModule)
- Styling: DaisyUI classes + Tailwind utilities
- State management: [approach — component state, service, NgRx if applicable]

## Inputs
| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| items | EntityName[] | Yes | - | List of items to display |
| loading | boolean | No | false | Show skeleton state |
| pageSize | number | No | 10 | Items per page |

## Outputs
| Name | Type | Description |
|------|------|-------------|
| itemSelected | EntityName | Emitted when user clicks a row |
| pageChanged | number | Emitted when pagination changes |
| sortChanged | {field: string, order: 'asc'|'desc'} | Emitted when sort header clicked |

## Behavior
1. [Describe component behavior step by step]
2. [Include edge cases: empty data, error state, loading]
3. [Include interaction details: hover, click, keyboard]

## Accessibility
- [Specific a11y requirements for this component]

## Test Cases
1. Should render [count] items when data is provided
2. Should show skeleton when loading is true
3. Should emit itemSelected when row is clicked
4. Should be keyboard navigable
5. Should display empty state when items is empty array

## Dependencies
- [List of services, models, other components needed]
```

Save each prompt to `devflow/designs/export/prompts/<component-name>.md`.

### Step 4: Test Instructions

For each section, generate test instructions:

```markdown
# Test Instructions: [Section Name]

## Unit Tests
Run: `ng test --include=src/app/features/<section>/**/*.spec.ts`

### Test Scenarios
1. **List Page**
   - Loads data on init and displays items
   - Shows loading skeleton during fetch
   - Displays error alert on API failure with retry button
   - Shows empty state when no results
   - Search filters items (debounced 300ms)
   - Sort toggles between asc/desc
   - Pagination navigates pages correctly

2. **Detail Page**
   - Loads single item by route param ID
   - Displays all fields correctly
   - Edit button navigates to edit form
   - Delete button shows confirmation dialog
   - Back button returns to list

3. **Create/Edit Form**
   - Renders all form fields with correct types
   - Validates required fields on submit
   - Shows field-level error messages
   - Submit sends correct payload to API
   - Cancel navigates back without saving
   - Pre-fills form data in edit mode

## Integration Tests
- API service returns correctly typed responses
- Router navigates between list → detail → edit flows
- Auth guard prevents unauthorized access

## E2E Test Suggestions
- Full CRUD flow: create → view → edit → delete
- Search and filter combinations
- Pagination through multiple pages
- Responsive layout at mobile/tablet/desktop breakpoints
```

Save to `devflow/designs/export/tests/<section-name>.md`.

### Step 5: Storybook Stories (If Applicable)

If the project uses Storybook (`@storybook/angular` or `@storybook/react` in dependencies), generate stories:

```typescript
// <component>.stories.ts
import type { Meta, StoryObj } from '@storybook/angular';
import { ComponentName } from './component-name.component';
import { createEntities } from '../../../mocks/<section>.factory';

const meta: Meta<ComponentName> = {
  title: 'Features/Section/ComponentName',
  component: ComponentName,
  tags: ['autodocs'],
  argTypes: {
    items: { control: 'object' },
    loading: { control: 'boolean' },
  },
};

export default meta;
type Story = StoryObj<ComponentName>;

export const Default: Story = {
  args: {
    items: createEntities(5),
    loading: false,
  },
};

export const Loading: Story = {
  args: {
    items: [],
    loading: true,
  },
};

export const Empty: Story = {
  args: {
    items: [],
    loading: false,
  },
};

export const Error: Story = {
  args: {
    items: [],
    loading: false,
    error: 'Failed to load data',
  },
};
```

If Storybook is not installed, skip this step and note: "Storybook not detected. To add stories later, install `@storybook/angular` and re-run export."

### Step 6: Output Package

Save all export files to `devflow/designs/export/`:

```
devflow/designs/export/
├── component-inventory.md
├── design-system.md
├── prompts/
│   ├── <component-name>.md
│   └── ...
├── tests/
│   ├── <section-name>.md
│   └── ...
└── stories/                      # Only if Storybook detected
    ├── <component>.stories.ts
    └── ...
```

```
✅ Design export complete
  - Component inventory: [count] components documented
  - Design system: colors, typography, spacing, components
  - Implementation prompts: [count] component prompts
  - Test instructions: [count] section test plans
  - Storybook: [count] stories (or "skipped — not installed")
  Package: devflow/designs/export/
```

## Error Recovery

- If no components exist yet, generate the export based on design files (wireframes, section designs) as a planning document
- If some sections are incomplete, export what exists and note gaps
- If file writing fails, output all content to chat for manual save
