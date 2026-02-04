---
allowed-tools: Read, Write, LS, Glob, Bash
---

# Shape Section

Create a detailed UI specification for a specific section of the application.

## Usage
```
/design:shape-section <section>
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/design-standards.md` — Component conventions, a11y requirements

## Preflight Checklist

1. **Validate section name:**
   - `$ARGUMENTS` must be a non-empty string
   - If empty: "Usage: `/design:shape-section <section>` — e.g., `/design:shape-section user-management`"

2. **Locate the spec:**
   - Search for spec file: look in `devflow/specs/`, `devflow/specs/`, or project root for a spec file that references `$ARGUMENTS`
   - Also check PRDs in `devflow/prds/` or `devflow/prds/`
   - If no spec found, warn: "No spec found for '$ARGUMENTS'. Proceeding with user input only — provide user stories when prompted."

3. **Check for existing section design:**
   - Look for `devflow/designs/$ARGUMENTS/` or similar directory
   - If exists, ask: "Design for '$ARGUMENTS' already exists. Overwrite or extend?"

## Instructions

You are a UX designer translating user stories and requirements into concrete UI specifications for the **$ARGUMENTS** section.

### Step 1: Extract User Stories

Read the project spec/PRD and extract all user stories related to `$ARGUMENTS`.

For each user story, capture:
- **Story ID** (e.g., US-001)
- **As a** [role]
- **I want** [action]
- **So that** [benefit]
- **Acceptance criteria** (Given/When/Then format)

If no spec is found, ask the user to provide:
- What does this section do?
- Who uses it?
- What are the key actions a user performs?
- What data is displayed?

### Step 2: Screen List

Derive a list of screens from the user stories. Each screen entry:

```markdown
### Screen: [Screen Name]
- **Route:** `/section/path`
- **Purpose:** One-line description of what this screen does
- **User stories:** US-001, US-003 (which stories this screen fulfills)
- **Access:** Who can see this screen (roles/permissions)
- **Entry points:** How does the user get here (nav link, button click, URL)
```

Common screen types to consider:
- **List/Index** — Table or card grid of items with search, filter, sort, pagination
- **Detail/View** — Single item display with all fields, related data, actions
- **Create/New** — Form to create a new item
- **Edit** — Form to modify an existing item (can reuse create form)
- **Settings** — Configuration for this section
- **Dashboard** — Summary/overview with metrics and quick actions

### Step 3: User Flows

For each user story with Given/When/Then acceptance criteria, create a user flow:

```markdown
### Flow: [Flow Name]
**Story:** US-001
**Trigger:** [What starts this flow]

1. User is on [Screen A]
2. User clicks [Element] → System shows [Response]
3. User fills [Form/Input] → System validates [Rules]
4. User confirms [Action] → System executes [Operation]
5. System displays [Result] → User sees [Feedback]

**Happy path result:** [What happens on success]
**Error paths:**
- [Condition]: [What the user sees, how to recover]
- [Condition]: [What the user sees, how to recover]
```

### Step 4: Wireframe Descriptions

For each screen, create a text-based wireframe description:

```markdown
### Wireframe: [Screen Name]

**Layout:** [full-width | sidebar+content | centered-form | split-pane]

**Header area:**
- Page title: "[Title]" (text-2xl font-bold)
- Subtitle: "[Description]" (text-base text-base-content/70)
- Actions: [Button labels and types — primary, secondary, ghost]

**Filter/Search area:** (if applicable)
- Search input (placeholder: "[text]")
- Filter dropdowns: [list of filters]
- Active filter chips

**Main content:**
- [Component type]: [Description]
  - Columns/fields: [list]
  - Row actions: [list]
  - Empty state: "[message]"
  - Loading state: skeleton with [count] rows

**Pagination:** (if applicable)
- Items per page: 10/25/50
- Page navigation: Previous/Next + page numbers

**Footer area:** (if applicable)
- [Description]
```

### Step 5: Interaction Patterns

Document interactions for each screen:

```markdown
### Interactions: [Screen Name]

**Hover:**
- Table rows: bg-base-200 highlight
- Action buttons: tooltip with label
- Cards: subtle shadow elevation (shadow-md → shadow-lg)

**Click:**
- Table row click: navigate to detail view
- Action button: execute action or open modal
- Card click: navigate or expand

**Keyboard:**
- Tab order: [describe focus flow]
- Enter: activate focused element
- Escape: close modal/dropdown
- Arrow keys: navigate table rows or dropdown items

**Drag:** (if applicable)
- [Element]: drag to reorder, visual indicator for drop zone

**Transitions:**
- Page entry: fade-in (150ms ease-in)
- Modal open: scale from 95% + fade (200ms ease-out)
- List item add: slide-down + fade-in (200ms)
- List item remove: fade-out + collapse height (150ms)
- Toast notification: slide in from top-right (300ms)
```

### Step 6: Data Requirements Per Screen

For each screen, specify the data needed:

```markdown
### Data: [Screen Name]

**API Endpoints:**
- `GET /api/v1/[resource]` — List with pagination, filters
  - Query params: page, limit, sort, search, [filters]
  - Response: `{ items: T[], total: number, page: number, limit: number }`
- `GET /api/v1/[resource]/:id` — Single item detail
- `POST /api/v1/[resource]` — Create new item
- `PUT /api/v1/[resource]/:id` — Update existing item
- `DELETE /api/v1/[resource]/:id` — Delete item

**Display fields:**
| Field | Type | List | Detail | Create | Edit |
|-------|------|------|--------|--------|------|
| name  | string | ✅ | ✅ | ✅ | ✅ |
| status | enum | ✅ | ✅ | ❌ | ✅ |
| created_at | datetime | ✅ | ✅ | ❌ | ❌ |

**Validation rules:**
- [field]: [rule] (e.g., name: required, min 3 chars, max 100 chars)
- [field]: [rule]

**Real-time updates:** (if applicable)
- [What updates live]: WebSocket channel or polling interval
```

### Step 7: Output

Save the section design to `devflow/designs/$ARGUMENTS.md` with all sections from Steps 1-6.

```
✅ Section shaped: $ARGUMENTS
  - Screens: [count] screens identified
  - Flows: [count] user flows mapped
  - Data: [count] API endpoints defined
  - Interactions: hover, click, keyboard, transitions documented
Next: /design:sample-data $ARGUMENTS to create mock data
```

## Error Recovery

- If spec file is partially complete, work with available stories and flag gaps: "Stories US-005, US-007 lack acceptance criteria — flows are approximate"
- If section name does not match any spec section, ask user to clarify which area of the app they mean
- If design directory cannot be created, output the full spec to chat
