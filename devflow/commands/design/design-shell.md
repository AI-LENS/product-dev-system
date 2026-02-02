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

### Step 1: Navigation Pattern Selection

Ask the user their preferred navigation pattern:

**Option A: Sidebar Navigation (recommended for dashboards/admin)**
- Fixed left sidebar (240px desktop, collapsible to 64px icons-only)
- Top bar with search, notifications, user menu
- Content area fills remaining width

**Option B: Top Navigation (recommended for marketing/content sites)**
- Horizontal nav bar with logo, links, user menu
- Optional secondary nav below
- Full-width content area

**Option C: Hybrid (recommended for complex apps)**
- Collapsible sidebar for primary navigation
- Top bar for global actions (search, notifications, user)
- Breadcrumbs below top bar

If the user has no preference, default to **Option C: Hybrid**.

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
