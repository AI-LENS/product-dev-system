---
allowed-tools: Read, Write, LS, Glob, Bash
---

# Sample Data

Generate TypeScript interfaces, mock data, factory functions, and JSON fixtures for a section.

## Usage
```
/design:sample-data <section>
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/design-standards.md` — Component API conventions

## Preflight Checklist — MANDATORY PREREQUISITES

**⛔ BLOCKING: Cannot proceed without these prerequisites.**

1. **Validate section name:**
   - `$ARGUMENTS` must be a non-empty string
   - If empty: "Usage: `/design:sample-data <section>` — e.g., `/design:sample-data user-management`"

2. **Verify section spec exists:**
   - Check for `devflow/designs/$ARGUMENTS.md` (from `/design:shape-section`)
   - If missing: STOP. Print: "Section spec for '$ARGUMENTS' not found. Run `/design:shape-section $ARGUMENTS` first."

3. **Check for global data model:**
   - Check if `devflow/specs/<name>-plan.md` has a data model section
   - If exists: Use entity names from the plan for consistency
   - If missing: Warn but continue, create entities based on section spec

4. **Detect frontend framework:**
   - Check `package.json` for `@angular/core` or `react`
   - Determines file naming and import style

## Instructions

You are a data architect creating comprehensive mock data for the **$ARGUMENTS** section.

**⛔ ENFORCEMENT: You MUST present the proposed data structure and get user confirmation before generating files.**

### Step 1: Identify Entities & Present Proposal

From the spec and section design, extract all entities relevant to `$ARGUMENTS`. For each entity, determine:
- Entity name (PascalCase)
- All fields with types
- Relationships to other entities (one-to-one, one-to-many, many-to-many)
- Required vs optional fields
- Enum values for status/type fields

**MANDATORY: Present the proposed data structure to the user for confirmation:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 PROPOSED DATA STRUCTURE: $ARGUMENTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Based on the section spec, here's how I'm organizing the data:

**Entities:**

- **[Entity1]** — [Plain-language description of what this represents]
- **[Entity2]** — [Plain-language description]

**Relationships:**

- [Entity1] has many [Entity2]
- [Entity2] belongs to [Entity1]

**Actions Available:**

- View, edit, delete [entities]
- [Other actions from spec]

**Sample Data:**

I'll create [X] realistic records per entity with varied content.

Does this structure make sense? Any adjustments?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**🚦 GATE:** Do NOT proceed until user confirms the data structure.

### Step 2: TypeScript Interfaces

Create interfaces that match the backend Pydantic models:

```typescript
// src/app/models/<section>.models.ts

/** Unique identifier type */
export type UUID = string;

/** ISO 8601 datetime string */
export type ISODateTime = string;

/**
 * Represents a [EntityName] in the system.
 * Maps to: GET /api/v1/[resource]
 */
export interface EntityName {
  id: UUID;
  // Core fields
  name: string;
  description: string | null;
  status: EntityStatus;

  // Relationships
  parent_id: UUID | null;
  tags: string[];

  // Metadata
  created_at: ISODateTime;
  updated_at: ISODateTime;
  created_by: UUID;
}

/** Create DTO — fields required when creating a new entity */
export interface EntityNameCreate {
  name: string;
  description?: string;
  parent_id?: UUID;
  tags?: string[];
}

/** Update DTO — all fields optional for partial updates */
export interface EntityNameUpdate {
  name?: string;
  description?: string | null;
  status?: EntityStatus;
  parent_id?: UUID | null;
  tags?: string[];
}

/** Status enum for [EntityName] */
export enum EntityStatus {
  Active = 'active',
  Inactive = 'inactive',
  Archived = 'archived',
  Pending = 'pending',
}

/** Paginated response wrapper */
export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
  has_next: boolean;
  has_prev: boolean;
}

/** List query parameters */
export interface EntityListParams {
  page?: number;
  limit?: number;
  sort_by?: string;
  sort_order?: 'asc' | 'desc';
  search?: string;
  status?: EntityStatus;
}
```

Generate one set of interfaces per entity found in Step 1.

### Step 2b: Component Props Interface with Callbacks

**MANDATORY: Create a Props interface for screen components that includes callback props for all actions.**

```typescript
// =============================================================================
// Component Props (for screen designs)
// =============================================================================

/**
 * Props for the [SectionName] list/main component.
 * Includes data props and callback props for all actions.
 */
export interface EntityListProps {
  /** The list of entities to display */
  entities: EntityName[];

  /** Loading state */
  loading?: boolean;

  /** Error state */
  error?: string | null;

  // Action callbacks (optional - for portable components)
  /** Called when user wants to view an entity's details */
  onView?: (id: string) => void;

  /** Called when user wants to edit an entity */
  onEdit?: (id: string) => void;

  /** Called when user wants to delete an entity */
  onDelete?: (id: string) => void;

  /** Called when user wants to create a new entity */
  onCreate?: () => void;

  /** Called when user wants to archive an entity */
  onArchive?: (id: string) => void;

  /** Called when pagination changes */
  onPageChange?: (page: number) => void;

  /** Called when search/filter changes */
  onSearch?: (query: string) => void;
}
```

**Important:**
- Callbacks should be optional (`?`) for maximum portability
- Use optional chaining when calling: `onClick={() => onDelete?.(id)}`
- Include callbacks for ALL actions mentioned in the section spec
- JSDoc comments explain when each callback is triggered

### Step 3: Realistic Mock Data

Create 10-20 records per entity with realistic data. Rules for realism:
- **Names:** Use realistic but fictional names (not "Test User 1")
- **Emails:** Format `firstname.lastname@example.com`
- **Dates:** Spread across the last 6 months, created_at < updated_at
- **IDs:** Use UUID v4 format (`xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`)
- **Status distribution:** ~60% active, ~20% inactive, ~10% pending, ~10% archived
- **Descriptions:** Realistic 1-2 sentence descriptions, some null
- **Relationships:** Cross-reference IDs between related entities
- **Numbers:** Vary ranges realistically (not all the same)
- **Strings:** Vary length, include edge cases (very short, moderate, long)

```typescript
// src/app/mocks/<section>.mock.ts

import { EntityName, EntityStatus } from '../models/<section>.models';

export const MOCK_ENTITIES: EntityName[] = [
  {
    id: 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
    name: 'Quarterly Revenue Dashboard',
    description: 'Executive-level view of quarterly revenue metrics across all business units.',
    status: EntityStatus.Active,
    parent_id: null,
    tags: ['finance', 'executive', 'quarterly'],
    created_at: '2024-08-15T09:23:41Z',
    updated_at: '2024-11-02T14:18:05Z',
    created_by: 'f7e6d5c4-b3a2-4190-8765-432109876543',
  },
  // ... 9-19 more records with similar realism
];
```

### Step 4: Factory Functions

Create factory functions for generating test data dynamically:

```typescript
// src/app/mocks/<section>.factory.ts

import { EntityName, EntityNameCreate, EntityStatus } from '../models/<section>.models';

/** Counter for generating unique sequential data */
let entityCounter = 0;

/** Generate a random UUID v4 */
function uuid(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

/** Generate a random ISO datetime within the last N days */
function randomDate(daysBack: number = 180): string {
  const now = Date.now();
  const past = now - daysBack * 24 * 60 * 60 * 1000;
  const random = new Date(past + Math.random() * (now - past));
  return random.toISOString();
}

/** Pick a random item from an array */
function randomFrom<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

/**
 * Create a single EntityName with optional overrides.
 * All fields have sensible defaults; pass overrides for specific test scenarios.
 */
export function createEntity(overrides: Partial<EntityName> = {}): EntityName {
  entityCounter++;
  const createdAt = randomDate(180);

  return {
    id: uuid(),
    name: `Entity ${entityCounter}`,
    description: Math.random() > 0.2 ? `Description for entity ${entityCounter}` : null,
    status: randomFrom([
      EntityStatus.Active, EntityStatus.Active, EntityStatus.Active,
      EntityStatus.Inactive, EntityStatus.Pending, EntityStatus.Archived,
    ]),
    parent_id: Math.random() > 0.7 ? uuid() : null,
    tags: Array.from({ length: Math.floor(Math.random() * 4) }, () =>
      randomFrom(['finance', 'marketing', 'engineering', 'design', 'ops', 'hr'])
    ),
    created_at: createdAt,
    updated_at: randomDate(Math.floor(Math.random() * 30)),
    created_by: uuid(),
    ...overrides,
  };
}

/**
 * Create an array of entities.
 */
export function createEntities(count: number, overrides: Partial<EntityName> = {}): EntityName[] {
  return Array.from({ length: count }, () => createEntity(overrides));
}

/**
 * Create a valid EntityNameCreate DTO for form testing.
 */
export function createEntityInput(overrides: Partial<EntityNameCreate> = {}): EntityNameCreate {
  entityCounter++;
  return {
    name: `New Entity ${entityCounter}`,
    description: `Description for new entity ${entityCounter}`,
    parent_id: undefined,
    tags: ['test'],
    ...overrides,
  };
}

/**
 * Create a paginated response wrapper for testing list views.
 */
export function createPaginatedResponse<T>(
  items: T[],
  page: number = 1,
  limit: number = 10,
  total?: number
) {
  const totalCount = total ?? items.length;
  return {
    items: items.slice(0, limit),
    total: totalCount,
    page,
    limit,
    has_next: page * limit < totalCount,
    has_prev: page > 1,
  };
}
```

### Step 5: JSON Fixtures

Create static JSON fixtures for development server and E2E testing:

```
src/app/mocks/fixtures/
├── <section>-list.json          # Paginated list response (page 1, 10 items)
├── <section>-detail.json        # Single entity detail response
├── <section>-empty.json         # Empty list response (for empty state testing)
├── <section>-error-404.json     # Not found error response
├── <section>-error-422.json     # Validation error response
└── <section>-search-results.json # Search/filter result response
```

Each fixture follows the API response format:

**List fixture:**
```json
{
  "items": [ /* 10 realistic records */ ],
  "total": 47,
  "page": 1,
  "limit": 10,
  "has_next": true,
  "has_prev": false
}
```

**Error fixtures:**
```json
{
  "detail": "Entity not found",
  "status_code": 404
}
```

```json
{
  "detail": [
    {
      "loc": ["body", "name"],
      "msg": "field required",
      "type": "value_error.missing"
    }
  ],
  "status_code": 422
}
```

### Step 6: Angular HTTP Interceptor for Mocks (Optional)

If developing before backend is ready, create an interceptor:

```typescript
// src/app/mocks/mock.interceptor.ts
// Intercepts HTTP calls and returns fixture data
// Enabled via environment flag: environment.useMocks = true
// Adds realistic delay (200-500ms) to simulate network
```

### Step 7: Output

**FIRST: Create directories if they don't exist:**
```bash
mkdir -p src/app/models
mkdir -p src/app/mocks
mkdir -p src/app/mocks/fixtures
```

**THEN: Save files to:**
1. `src/app/models/<section>.models.ts` — TypeScript interfaces
2. `src/app/mocks/<section>.mock.ts` — Static mock data
3. `src/app/mocks/<section>.factory.ts` — Factory functions
4. `src/app/mocks/fixtures/<section>-list.json` — Paginated list response
5. `src/app/mocks/fixtures/<section>-detail.json` — Single entity response
6. `src/app/mocks/fixtures/<section>-empty.json` — Empty state response
7. `src/app/mocks/fixtures/<section>-error-404.json` — Not found error
8. `src/app/mocks/fixtures/<section>-error-422.json` — Validation error
9. `src/app/mocks/fixtures/<section>-search-results.json` — Search results

**VERIFY all files were created:**
```bash
ls -la src/app/models/<section>.models.ts
ls -la src/app/mocks/<section>.mock.ts
ls -la src/app/mocks/<section>.factory.ts
ls -la src/app/mocks/fixtures/<section>-*.json
```

If any file is missing, stop and investigate before proceeding.

```
✅ Sample data generated: $ARGUMENTS
  - Interfaces: [count] entities with DTOs
  - Mock records: [count] records across [count] entities
  - Factory functions: create, createMany, createInput, createPaginatedResponse
  - Fixtures: list, detail, empty, error-404, error-422, search-results
Next: /design:design-screen $ARGUMENTS to build screen components
```

## Error Recovery

- If entity definitions are ambiguous, list assumptions and ask user to confirm before generating
- If file paths conflict with existing code, ask whether to merge or replace
- If related entities are in other sections, create minimal stubs with TODO comments
