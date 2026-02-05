---
allowed-tools: Read, Write, LS, Bash
---

# Design Shell

Design the application shell — navigation, layout, and responsive structure.

## Usage
```
/design:design-shell
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/design-standards.md` — Responsive breakpoints, a11y requirements
- Design tokens should already exist (run `/design:design-tokens` first)

## Preflight Checklist

1. **Check for design tokens:**
   - Look for `tailwind.config.js` with DaisyUI theme configuration
   - Look for `src/styles/tokens.css`
   - If not found, warn: "Design tokens not found. Run `/design:design-tokens` first for consistent theming."

2. **Detect frontend framework:**
   - Check `package.json` for `@angular/core` or `react`
   - Default: Angular + DaisyUI + Tailwind

3. **Check for existing shell:**
   - Look for `app.component.ts` / `app.component.html` or equivalent
   - If shell already exists, ask: "App shell components detected. Replace or extend?"

## Instructions

You are a frontend architect designing the application shell — the persistent frame around page content.

### Step 1: Thorough Discovery — MANDATORY PROBING QUESTIONS

**⛔ BLOCKING REQUIREMENT: You MUST ask ALL 18 questions below before ANY design work.**

**ENFORCEMENT RULES:**
1. Do NOT skip any question — each question affects shell architecture
2. Do NOT proceed to Step 2 until ALL questions are answered
3. Do NOT make assumptions — always ask, even if it seems obvious
4. If user tries to skip, respond: "These questions are mandatory. The app shell is the foundation of the entire UI — getting it wrong means rebuilding later. Which question would you like to answer first?"
5. Each round MUST be completed before moving to the next round
6. After all questions, you MUST present the summary and get explicit "proceed" confirmation

---

#### Round 1: Application Context (use AskUserQuestion)

1. **Application Type**
   - Question: "What type of application is this?"
   - Options:
     - Admin/Dashboard (data management, analytics, internal tools)
     - SaaS Product (customer-facing, feature-rich)
     - Content/Marketing Site (pages, blog, landing pages)
     - E-commerce (products, cart, checkout)
     - Communication Tool (messaging, notifications-heavy)
   - This determines optimal navigation patterns.

2. **User Session Behavior**
   - Question: "How long do users typically spend in a session?"
   - Options:
     - Quick tasks (< 5 minutes) — optimize for speed
     - Medium sessions (5-30 minutes) — balance speed + depth
     - Long sessions (30+ minutes) — optimize for comfort + efficiency
     - Always open (background tab) — optimize for notifications + quick actions
   - Follow-up: "What's the most common user action?"

3. **Navigation Depth**
   - Question: "How many levels of navigation does the app have?"
   - Options:
     - Flat (5-8 top-level sections, no sub-navigation)
     - Shallow (top-level + 1 level of sub-sections)
     - Deep (3+ levels of hierarchy)
     - Variable (some sections flat, some deep)
   - Follow-up: "List the main sections/modules of the app"

---

#### Round 2: Navigation Requirements (use AskUserQuestion)

4. **Primary Navigation Items**
   - Question: "List ALL primary navigation items (main menu entries)"
   - Follow-up: "Which items need sub-navigation?"
   - Follow-up: "Which items are the MOST frequently accessed?"
   - Follow-up: "Any items that should be hidden based on user role?"

5. **Global Actions**
   - Question: "What global actions should be accessible from anywhere?"
   - Options (multi-select):
     - Search (global search across all content)
     - Notifications (in-app alerts, messages)
     - Quick Create (+ button to create new items)
     - Help/Support (documentation, chat)
     - Settings (user preferences)
     - Theme Toggle (light/dark mode)
   - For each selected: "How prominent should it be?"

6. **Navigation Pattern Preference**
   - Question: "What navigation pattern fits your app best?"
   - Options:
     - Sidebar Navigation (Recommended for dashboards/admin) — Fixed left sidebar, top bar for global actions
     - Top Navigation (Recommended for content sites) — Horizontal nav bar, full-width content
     - Hybrid (Recommended for complex apps) — Collapsible sidebar + top bar + breadcrumbs
     - Bottom Navigation (For mobile-first apps) — Tab bar at bottom (mobile), converts to sidebar (desktop)
   - Follow-up: "Should the sidebar be collapsible? Resizable?"

---

#### Round 3: User Menu & Authentication (use AskUserQuestion)

7. **User Menu Contents**
   - Question: "What should appear in the user menu dropdown?"
   - Options (multi-select):
     - Profile (view/edit user profile)
     - Account Settings (email, password, etc.)
     - Preferences (display, notifications, language)
     - Billing/Subscription (for SaaS)
     - Organization/Team switching (for multi-tenant)
     - Admin Panel link (for admins)
     - Theme Toggle (light/dark)
     - Keyboard Shortcuts help
     - Logout
   - Follow-up: "Any other items?"

8. **Multi-Tenant/Organization Switching**
   - Question: "Does the app support multiple organizations/workspaces?"
   - Options:
     - No (single user, single context)
     - Yes, separate accounts (user logs into different orgs separately)
     - Yes, switchable (user can switch orgs without logging out)
   - If switchable: "Where should the org switcher appear? (sidebar, user menu, top bar)"

9. **User Identification Display**
   - Question: "How should users be identified in the UI?"
   - Options:
     - Avatar only (image or initials)
     - Avatar + Name
     - Avatar + Name + Role/Title
     - Full profile card on hover
   - Follow-up: "Should online/offline status be shown?"

---

#### Round 4: Notifications & Real-Time (use AskUserQuestion)

10. **Notification Types**
    - Question: "What types of notifications does the app have?"
    - Options (multi-select):
      - In-app alerts (toasts/banners)
      - Notification center (bell icon with list)
      - Real-time updates (live counters, badges)
      - Email notifications (configured in settings)
      - Push notifications (browser/mobile)
    - For each: "What events trigger these notifications?"

11. **Notification Urgency**
    - Question: "How urgent are notifications typically?"
    - Options:
      - Critical (must see immediately) — persistent, blocking
      - Important (should see soon) — prominent but dismissible
      - Informational (nice to know) — subtle, auto-dismiss
      - Mixed (different urgency levels)
    - Follow-up for Mixed: "Give examples of each urgency level"

12. **Real-Time Requirements**
    - Question: "Does the shell need real-time updates?"
    - Options:
      - No real-time needed
      - Notification counts only
      - Multiple real-time indicators (counts, status, etc.)
      - Live presence (who's online, typing indicators)
    - Follow-up: "What WebSocket or polling approach is preferred?"

---

#### Round 5: Responsive & Device Support (use AskUserQuestion)

13. **Primary Device**
    - Question: "What is the PRIMARY device for this app?"
    - Options:
      - Desktop (optimize for large screens)
      - Tablet (optimize for touch + medium screens)
      - Mobile (mobile-first design)
      - Equal (all devices equally important)
    - This determines design priority.

14. **Mobile Navigation Behavior**
    - Question: "How should navigation work on mobile?"
    - Options:
      - Hamburger menu (sidebar slides in)
      - Bottom tab bar (persistent footer navigation)
      - Full-screen menu (takes over entire screen)
      - Simplified (fewer items on mobile)
    - Follow-up: "Any gestures? (swipe to open sidebar, etc.)"

15. **Tablet Navigation Behavior**
    - Question: "How should navigation work on tablet?"
    - Options:
      - Same as desktop (full sidebar)
      - Collapsed sidebar (icons only, expand on hover/tap)
      - Auto-hide sidebar (appears on gesture/button)
      - Split view (sidebar + partial content)

---

#### Round 6: Branding & Visual Identity (use AskUserQuestion)

16. **Logo Placement**
    - Question: "Where should the logo appear?"
    - Options:
      - Top of sidebar (standard for sidebar nav)
      - Left side of top bar (standard for top nav)
      - Center of top bar (marketing sites)
      - Both sidebar header and top bar
    - Follow-up: "Do you have both full logo and icon-only versions?"

17. **Brand Color Integration**
    - Question: "How should brand color be used in the shell?"
    - Options:
      - Sidebar background (colored sidebar, light content)
      - Accent highlights only (minimal color, mostly neutral)
      - Active states and borders (subtle branding)
      - Full theme (pervasive color throughout)
    - Follow-up: "Should the shell look different in dark mode beyond inversion?"

18. **Footer Requirement**
    - Question: "Does the app need a footer?"
    - Options:
      - No footer (content extends to bottom)
      - Minimal footer (copyright, version)
      - Full footer (links, contact, legal)
      - Sticky footer (always visible at bottom)

---

#### Summary Before Proceeding

After all questions, present a summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 APP SHELL REQUIREMENTS CONFIRMED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Application Type: [type]
Session Length: [quick/medium/long/always-open]
Navigation Depth: [flat/shallow/deep]

Navigation Pattern: [sidebar/top/hybrid/bottom]
Primary Items: [list]
Global Actions: [search, notifications, quick-create, ...]

User Menu: [list of items]
Multi-Tenant: [no/separate/switchable]
User Display: [avatar/avatar+name/...]

Notifications: [types list]
Real-Time: [none/counts/multiple/presence]

Device Priority: [desktop/tablet/mobile/equal]
Mobile Nav: [hamburger/bottom-tab/full-screen]
Tablet Nav: [full/collapsed/auto-hide]

Branding:
  Logo: [placement]
  Color: [approach]
  Footer: [none/minimal/full/sticky]

Proceed to generate shell design?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### 🚦 GATE: Question Completion Check

**Before proceeding to Step 2, verify ALL questions answered:**

| Round | Questions | Answered? |
|-------|-----------|-----------|
| Round 1 | 1. Application Type | [ ] |
| | 2. User Session Behavior | [ ] |
| | 3. Navigation Depth | [ ] |
| Round 2 | 4. Primary Navigation Items | [ ] |
| | 5. Global Actions | [ ] |
| | 6. Navigation Pattern Preference | [ ] |
| Round 3 | 7. User Menu Contents | [ ] |
| | 8. Multi-Tenant/Org Switching | [ ] |
| | 9. User Identification Display | [ ] |
| Round 4 | 10. Notification Types | [ ] |
| | 11. Notification Urgency | [ ] |
| | 12. Real-Time Requirements | [ ] |
| Round 5 | 13. Primary Device | [ ] |
| | 14. Mobile Navigation Behavior | [ ] |
| | 15. Tablet Navigation Behavior | [ ] |
| Round 6 | 16. Logo Placement | [ ] |
| | 17. Brand Color Integration | [ ] |
| | 18. Footer Requirement | [ ] |

**Gate Rule:** If ANY checkbox is unchecked, you MUST go back and ask that question. Do NOT proceed.

**Only proceed to Step 2 when:**
1. All 18 questions are answered ✓
2. Summary has been presented to user ✓
3. User has explicitly said "proceed" or "yes" or "confirmed" ✓

**If user tries to skip:** "The app shell is the foundation of your entire UI. Every component sits within this shell. I cannot design it properly without understanding your needs. Let's continue with question [N]."

---

### Step 2: Navigation Pattern Finalization

Based on the confirmed requirements, finalize the navigation pattern:

**Option A: Sidebar Navigation (for dashboards/admin)**
- Fixed left sidebar (240px desktop, collapsible to 64px icons-only)
- Top bar with search, notifications, user menu
- Content area fills remaining width

**Option B: Top Navigation (for marketing/content sites)**
- Horizontal nav bar with logo, links, user menu
- Optional secondary nav below
- Full-width content area

**Option C: Hybrid (for complex apps)**
- Collapsible sidebar for primary navigation
- Top bar for global actions (search, notifications, user)
- Breadcrumbs below top bar

**Option D: Bottom Navigation (for mobile-first apps)**
- Tab bar at bottom with 4-5 key items
- Converts to sidebar on tablet/desktop
- Top bar for branding and global actions

Use the pattern that matches the confirmed requirements.

### Step 2: Layout Grid Structure

Define the grid system based on chosen pattern:

```
┌──────────────────────────────────────────────────────┐
│ Top Bar: Logo | Search | Notifications | User Menu   │
├────────────┬─────────────────────────────────────────┤
│            │ Breadcrumbs: Home > Section > Page       │
│  Sidebar   ├─────────────────────────────────────────┤
│            │                                          │
│  - Nav 1   │  Page Content Area                       │
│  - Nav 2   │                                          │
│  - Nav 3   │  ┌─────────┐ ┌─────────┐               │
│  - Nav 4   │  │  Card   │ │  Card   │               │
│            │  └─────────┘ └─────────┘               │
│            │                                          │
│  ──────    │                                          │
│  - Settings│                                          │
│  - Help    │                                          │
├────────────┴─────────────────────────────────────────┤
│ (Optional Footer)                                     │
└──────────────────────────────────────────────────────┘
```

### Step 3: Component Architecture

Generate these shell components:

#### 3a: App Layout Component
```
app-layout/
├── app-layout.component.ts
├── app-layout.component.html
├── app-layout.component.scss
└── app-layout.component.spec.ts
```
- Manages sidebar open/closed state
- Provides layout context to child components
- Handles responsive breakpoint changes

#### 3b: Sidebar Component
```
sidebar/
├── sidebar.component.ts
├── sidebar.component.html
├── sidebar.component.scss
└── sidebar.component.spec.ts
```
- Navigation items as input (array of NavItem objects)
- Collapsible with icon-only mode
- Active route highlighting
- Grouped sections with dividers
- Bottom-pinned items (settings, help, logout)

NavItem interface:
```typescript
interface NavItem {
  label: string;
  icon: string;
  route: string;
  badge?: string | number;
  children?: NavItem[];
  permission?: string;
}
```

#### 3c: Top Bar Component
```
top-bar/
├── top-bar.component.ts
├── top-bar.component.html
├── top-bar.component.scss
└── top-bar.component.spec.ts
```
- Logo/brand area (left)
- Search input with keyboard shortcut hint (Ctrl+K)
- Notification bell with unread count badge
- User menu trigger (avatar + name)

#### 3d: User Menu Component
```
user-menu/
├── user-menu.component.ts
├── user-menu.component.html
├── user-menu.component.scss
└── user-menu.component.spec.ts
```
- DaisyUI dropdown (click to toggle)
- Avatar with fallback initials
- User name and role display
- Menu items: Profile, Settings, Theme toggle (light/dark), Logout
- Keyboard accessible (Escape to close, arrow keys to navigate)

#### 3e: Breadcrumb Component
```
breadcrumb/
├── breadcrumb.component.ts
├── breadcrumb.component.html
├── breadcrumb.component.scss
└── breadcrumb.component.spec.ts
```
- Auto-generated from route data
- Truncation for deep paths (show first, ellipsis, last 2)
- Each segment is a link except the last

### Step 4: Responsive Behavior

Define behavior at each breakpoint:

**Mobile (< 640px: sm)**
- Sidebar: Hidden, hamburger menu in top bar, slides in as overlay from left
- Top bar: Logo + hamburger + user avatar only, search behind icon
- Content: Full width, single column, padding reduced
- Breadcrumbs: Hidden or single "Back" button

**Tablet (640px - 1023px: md)**
- Sidebar: Collapsed to icons only (64px), expand on hover
- Top bar: Full, search visible
- Content: Full width minus sidebar, responsive grid
- Breadcrumbs: Visible, truncated if needed

**Desktop (1024px+: lg/xl)**
- Sidebar: Fully expanded (240px), user can toggle collapse
- Top bar: Full with all elements
- Content: Full width minus sidebar, max-width container optional
- Breadcrumbs: Full path visible

Implementation approach:
```typescript
// Responsive service
@Injectable({ providedIn: 'root' })
export class LayoutService {
  private breakpoint$ = new BehaviorSubject<'mobile' | 'tablet' | 'desktop'>('desktop');
  private sidebarOpen$ = new BehaviorSubject<boolean>(true);
  private sidebarCollapsed$ = new BehaviorSubject<boolean>(false);

  // MediaQueryList listeners for breakpoint changes
  // Sidebar auto-collapses on tablet, auto-hides on mobile
}
```

### Step 5: Skeleton Loading States

Define skeleton placeholders for each shell region:

**Sidebar skeleton:**
- 6 rectangle placeholders (height: 40px, width: 80%) with rounded corners
- Pulsing animation using DaisyUI `animate-pulse`

**Top bar skeleton:**
- Logo placeholder (square), search bar placeholder (wide rectangle), 2 circle placeholders (notification + avatar)

**Content area skeleton:**
- Page title placeholder (wide rectangle, height: 32px)
- 3 card placeholders in a grid (rectangles with rounded corners)
- Each card has: header line, 3 body lines, footer line

**Breadcrumb skeleton:**
- 3 small rectangle placeholders separated by `/` characters

Skeleton component:
```typescript
@Component({
  selector: 'app-skeleton',
  template: `
    <div class="animate-pulse" [ngClass]="variant">
      <div class="bg-base-300 rounded" [style.height]="height" [style.width]="width"></div>
    </div>
  `
})
export class SkeletonComponent {
  @Input() variant: 'text' | 'circle' | 'rect' = 'rect';
  @Input() width = '100%';
  @Input() height = '1rem';
}
```

### Step 6: Breadcrumb Pattern

Breadcrumb logic:
1. Read Angular route configuration `data` property for each route
2. Build breadcrumb trail from root to current route
3. Each route should define `data: { breadcrumb: 'Label' }` or use a resolver for dynamic labels
4. Home is always the first item (with home icon)
5. Current page is displayed as plain text (not a link)
6. Separator: `/` or `>` character (use Tailwind `text-base-content/50` for separator color)

```typescript
interface Breadcrumb {
  label: string;
  url: string;
  icon?: string;
  isLast: boolean;
}
```

### Step 7: Theme Switching

Implement light/dark theme toggle:
- Store preference in `localStorage` key `theme`
- Default to system preference via `prefers-color-scheme` media query
- Toggle sets `data-theme` attribute on `<html>` element
- DaisyUI reads `data-theme` automatically
- Provide a toggle button in the user menu (sun/moon icons)

### Step 8: Generate Files

Create all component files listed in Step 3 using the detected frontend framework (Angular primary). Each file should:
- Import and use design tokens
- Follow `devflow/rules/design-standards.md` conventions
- Include ARIA attributes for accessibility
- Use DaisyUI component classes where applicable (drawer, navbar, dropdown, menu, avatar, badge)

### Step 9: Output Summary

```
✅ App shell designed
  - Layout: [chosen pattern]
  - Components: app-layout, sidebar, top-bar, user-menu, breadcrumb, skeleton
  - Responsive: mobile overlay + tablet collapse + desktop full
  - Theme: light/dark with system preference detection
  - Skeleton states: sidebar, top-bar, content, breadcrumb
Next: /design:shape-section <section> to design individual sections
```

## Error Recovery

- If framework detection fails, default to Angular and inform user
- If design tokens are missing, generate with sensible defaults and warn
- If route configuration is not yet defined, generate breadcrumb component with manual input mode
