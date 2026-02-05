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

### Step 1: Extract User Stories & Deep Discovery

**FIRST: Attempt to read from spec/PRD**

Read the project spec/PRD and extract all user stories related to `$ARGUMENTS`.

For each user story found, capture:
- **Story ID** (e.g., US-001)
- **As a** [role]
- **I want** [action]
- **So that** [benefit]
- **Acceptance criteria** (Given/When/Then format)

**THEN: MANDATORY PROBING QUESTIONS — NO EXCEPTIONS**

**⛔ BLOCKING REQUIREMENT: You MUST ask ALL questions below, even if spec exists.**

**ENFORCEMENT RULES:**
1. Do NOT skip any question — every question reveals critical UI requirements
2. Do NOT proceed to Step 2 until ALL 17 questions are answered
3. Do NOT assume answers from the spec — always confirm with the user
4. If user tries to skip, respond: "These questions are mandatory to ensure the UI meets your needs. Skipping leads to rework. Which question would you like to answer first?"
5. Each round MUST be completed before moving to the next round
6. After all questions, you MUST present the summary and get explicit confirmation

---

#### Round 1: Core Purpose & Users (use AskUserQuestion)

1. **Section Purpose**
   - Question: "In one sentence, what problem does the '$ARGUMENTS' section solve for users?"
   - Follow-up: "What would users do WITHOUT this section? What's the manual workaround?"
   - This reveals the core value proposition.

2. **User Roles**
   - Question: "Who interacts with this section?"
   - Options:
     - Single user type (all users see same UI)
     - Multiple roles with same view (admin, user see same but different permissions)
     - Multiple roles with different views (admin dashboard vs user dashboard)
   - Follow-up for multiple roles: "List each role and what they can do differently"

3. **Access Patterns**
   - Question: "How often do users access this section?"
   - Options:
     - Frequently (daily, multiple times per day) — optimize for speed
     - Regularly (weekly) — optimize for clarity
     - Occasionally (monthly) — optimize for discoverability
     - Rarely (yearly) — optimize for guidance/help
   - This affects information density and onboarding needs.

---

#### Round 2: Data & Content (use AskUserQuestion)

4. **Data Volume**
   - Question: "How many items will a typical user see in this section?"
   - Options:
     - Small (1-10 items) — no pagination needed
     - Medium (10-50 items) — simple pagination
     - Large (50-500 items) — search + filter critical
     - Massive (500+ items) — virtual scroll, server-side pagination required
   - Follow-up for Large/Massive: "What are the most common filters users will need?"

5. **Data Freshness**
   - Question: "How fresh does the data need to be?"
   - Options:
     - Real-time (updates instantly) — requires WebSocket/polling
     - Near real-time (updates within seconds) — polling acceptable
     - Periodic refresh (user clicks refresh) — simpler implementation
     - Static (rarely changes) — cache aggressively
   - Follow-up for real-time: "What specific data changes in real-time?"

6. **Data Relationships**
   - Question: "Does this section's data relate to other parts of the app?"
   - Options:
     - Standalone (no cross-references)
     - Parent-child (e.g., projects → tasks)
     - Many-to-many (e.g., users ↔ teams)
     - Cross-references (links to other sections)
   - Follow-up: "Describe the key relationships"

---

#### Round 3: User Actions (use AskUserQuestion)

7. **CRUD Operations**
   - Question: "What actions can users perform on items?"
   - Options (multi-select):
     - View/Read details
     - Create new items
     - Edit existing items
     - Delete items
     - Duplicate/Clone items
     - Archive/Soft-delete items
     - Export data
     - Import data
     - Bulk actions (multi-select)
   - For each selected, follow-up: "Any special conditions or permissions?"

8. **Critical Actions**
   - Question: "Which actions are destructive or require confirmation?"
   - Follow-up: "What should the confirmation dialog say?"
   - Follow-up: "Is there an undo option, or is it permanent?"

9. **Workflow States**
   - Question: "Do items in this section have states/statuses?"
   - Options:
     - No states (items are static)
     - Simple states (active/inactive, enabled/disabled)
     - Workflow states (draft → pending → approved → published)
     - Custom states (user-defined)
   - Follow-up: "Who can change states? Are there state transition rules?"

---

#### Round 4: Edge Cases & Error Handling (use AskUserQuestion)

10. **Empty State**
    - Question: "What should users see when there's no data?"
    - Options:
      - Simple message ("No items yet")
      - Onboarding guide (steps to create first item)
      - Sample/Demo data (pre-populated examples)
      - Call-to-action (prominent "Create First" button)
    - Follow-up: "What's the exact empty state message?"

11. **Error Scenarios**
    - Question: "What errors can occur in this section?"
    - Options (multi-select):
      - Network failure (API unavailable)
      - Permission denied (unauthorized access)
      - Validation errors (invalid input)
      - Conflict errors (concurrent edits)
      - Not found (item deleted by another user)
      - Rate limiting (too many requests)
    - For each: "What should the user see? How do they recover?"

12. **Loading States**
    - Question: "What takes time to load in this section?"
    - Options:
      - Initial page load (show skeleton)
      - Individual item load (show placeholder)
      - Search/filter results (show spinner)
      - Action processing (show button loading state)
    - Follow-up: "What's the expected load time? (affects skeleton design)"

---

#### Round 5: Layout & Navigation (use AskUserQuestion)

13. **Primary Layout**
    - Question: "What's the primary view for this section?"
    - Options:
      - Table/List (data grid with columns)
      - Card grid (visual cards)
      - Kanban board (drag-and-drop columns)
      - Calendar view (time-based)
      - Tree view (hierarchical)
      - Map view (geographic)
      - Dashboard (metrics + widgets)
    - Follow-up: "Should users be able to switch between views?"

14. **Detail View**
    - Question: "How do users see item details?"
    - Options:
      - Inline expansion (expand row in table)
      - Side panel (slide-out drawer)
      - Modal/Dialog (overlay)
      - Full page (separate route)
      - Hover preview (quick peek)
    - Follow-up: "Can users edit from the detail view, or only from a separate edit mode?"

15. **Navigation Within Section**
    - Question: "How do users navigate within this section?"
    - Options:
      - Tabs (sub-sections as tabs)
      - Breadcrumbs (hierarchical navigation)
      - Sidebar (persistent sub-navigation)
      - Search/Jump (command palette style)
    - Follow-up: "What sub-sections or tabs are needed?"

---

#### Round 6: Accessibility & Device Support (use AskUserQuestion)

16. **Mobile Usage**
    - Question: "Will users access this section on mobile devices?"
    - Options:
      - No (desktop-only, can simplify)
      - Yes, occasionally (responsive but not mobile-first)
      - Yes, frequently (mobile-first design)
      - Mobile-primary (most users on mobile)
    - Follow-up: "Any mobile-specific features (swipe actions, pull-to-refresh)?"

17. **Accessibility Priority**
    - Question: "Are there specific accessibility requirements?"
    - Options:
      - Standard (WCAG 2.1 AA)
      - Enhanced (WCAG 2.1 AAA)
      - Screen reader users are primary audience
      - Keyboard-only users are primary audience
    - Follow-up: "Any known user needs (color blindness, motor impairments)?"

---

#### Summary Before Proceeding

After all questions, present a summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 SECTION REQUIREMENTS: $ARGUMENTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Purpose: [one-sentence summary]
User Roles: [list]
Access Frequency: [daily/weekly/monthly]

Data:
  Volume: [small/medium/large/massive]
  Freshness: [real-time/near-real-time/periodic/static]
  Relationships: [standalone/parent-child/many-to-many]

Actions:
  CRUD: [view/create/edit/delete/...]
  Destructive: [list with confirmation requirements]
  States: [list workflow states]

Edge Cases:
  Empty State: [approach + message]
  Errors: [list with recovery actions]
  Loading: [skeleton/spinner approach]

Layout:
  Primary View: [table/cards/kanban/...]
  Detail View: [panel/modal/page]
  Navigation: [tabs/breadcrumbs/sidebar]

Devices: [desktop-only/responsive/mobile-first]
Accessibility: [standard/enhanced]

User Stories Covered:
  - US-001: [title]
  - US-002: [title]
  - ...

Ready to proceed with screen design?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### 🚦 GATE: Question Completion Check

**Before proceeding to Step 2, verify ALL questions answered:**

| Round | Questions | Answered? |
|-------|-----------|-----------|
| Round 1 | 1. Section Purpose | [ ] |
| | 2. User Roles | [ ] |
| | 3. Access Patterns | [ ] |
| Round 2 | 4. Data Volume | [ ] |
| | 5. Data Freshness | [ ] |
| | 6. Data Relationships | [ ] |
| Round 3 | 7. CRUD Operations | [ ] |
| | 8. Critical Actions | [ ] |
| | 9. Workflow States | [ ] |
| Round 4 | 10. Empty State | [ ] |
| | 11. Error Scenarios | [ ] |
| | 12. Loading States | [ ] |
| Round 5 | 13. Primary Layout | [ ] |
| | 14. Detail View | [ ] |
| | 15. Navigation Within Section | [ ] |
| Round 6 | 16. Mobile Usage | [ ] |
| | 17. Accessibility Priority | [ ] |

**Gate Rule:** If ANY checkbox is unchecked, you MUST go back and ask that question. Do NOT proceed.

**Only proceed to Step 2 when:**
1. All 17 questions are answered ✓
2. Summary has been presented to user ✓
3. User has explicitly said "proceed" or "yes" or "confirmed" ✓

**If user tries to skip:** "I cannot proceed without understanding your requirements. Skipping questions leads to UI that doesn't match your needs and requires costly rework. Let's continue with question [N]."

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

**FIRST: Create directory if it doesn't exist:**
```bash
mkdir -p devflow/designs
```

**THEN: Save the section design to `devflow/designs/$ARGUMENTS.md`** with all sections from Steps 1-6.

**VERIFY file was created:**
```bash
ls -la devflow/designs/$ARGUMENTS.md
```

If file is missing, stop and investigate before proceeding.

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
