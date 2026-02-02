# Design Standards

Standards and conventions for the design system. All design commands reference this file.

## Token Naming Conventions

Use semantic, consistent naming across all design tokens:

### Colors
```
color-primary          → Main brand color
color-primary-{shade}  → 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950
color-secondary        → Supporting brand color
color-accent           → Highlight/CTA color
color-success          → Positive outcomes (green family)
color-warning          → Caution states (amber family)
color-error            → Errors, destructive actions (red family)
color-info             → Informational (blue family)
color-surface          → Background surfaces
color-surface-secondary → Elevated/card backgrounds
```

### Spacing
```
space-0      → 0
space-1      → 0.25rem (4px)
space-2      → 0.5rem (8px)
space-3      → 0.75rem (12px)
space-4      → 1rem (16px)
space-6      → 1.5rem (24px)
space-8      → 2rem (32px)
space-12     → 3rem (48px)
space-16     → 4rem (64px)
```

### Typography
```
text-xs      → 0.75rem (12px)
text-sm      → 0.875rem (14px)
text-base    → 1rem (16px)
text-lg      → 1.125rem (18px)
text-xl      → 1.25rem (20px)
text-2xl     → 1.5rem (24px)
text-3xl     → 1.875rem (30px)
text-4xl     → 2.25rem (36px)
```

### Radius
```
radius-sm    → 0.25rem (4px) — tags, small elements
radius-md    → 0.375rem (6px) — buttons, inputs
radius-lg    → 0.5rem (8px) — cards, panels
radius-xl    → 0.75rem (12px) — modals, large containers
radius-full  → 9999px — pills, avatars
```

### Shadows
```
shadow-xs    → Subtle depth for borders
shadow-sm    → Cards at rest
shadow-md    → Cards on hover, dropdowns
shadow-lg    → Modals, popovers
shadow-xl    → Elevated overlays
```

## Component API Conventions

### Angular Components

**Inputs (Properties):**
- Use `@Input()` decorator with explicit types
- Prefix boolean inputs with `is` or `has` when the meaning is ambiguous (e.g., `isLoading`, `hasError`)
- Simple booleans like `loading`, `disabled`, `readonly` do not need prefix
- Provide default values for optional inputs
- Document each input with a JSDoc comment

```typescript
@Component({ selector: 'app-data-table' })
export class DataTableComponent<T> {
  /** Items to display in the table */
  @Input() items: T[] = [];

  /** Column definitions */
  @Input() columns: ColumnDef<T>[] = [];

  /** Whether the table is in a loading state */
  @Input() loading = false;

  /** Number of skeleton rows to show while loading */
  @Input() skeletonRows = 5;

  /** Currently active sort configuration */
  @Input() sort: SortConfig | null = null;

  /** Enable row selection checkboxes */
  @Input() selectable = false;
}
```

**Outputs (Events):**
- Use `@Output()` with `EventEmitter<T>`
- Name outputs as past-tense verbs: `selected`, `changed`, `deleted`
- Or as noun phrases: `pageChange`, `sortChange`
- Always type the emitted value

```typescript
@Output() rowSelected = new EventEmitter<T>();
@Output() pageChange = new EventEmitter<number>();
@Output() sortChange = new EventEmitter<SortConfig>();
@Output() deleteRequested = new EventEmitter<T>();
```

### React Components (Secondary)

**Props:**
- Define props as a TypeScript interface named `ComponentNameProps`
- Use destructuring in function signature
- Provide default values via default parameters
- Use `React.FC<Props>` or plain function with return type

```typescript
interface DataTableProps<T> {
  /** Items to display in the table */
  items: T[];
  /** Column definitions */
  columns: ColumnDef<T>[];
  /** Loading state */
  loading?: boolean;
  /** Callback when a row is selected */
  onRowSelect?: (item: T) => void;
  /** Callback when page changes */
  onPageChange?: (page: number) => void;
}

function DataTable<T>({ items, columns, loading = false, onRowSelect, onPageChange }: DataTableProps<T>) {
  // ...
}
```

## Accessibility Requirements (WCAG 2.1 AA)

### Color Contrast
- **Normal text** (< 18px or < 14px bold): minimum **4.5:1** contrast ratio against background
- **Large text** (>= 18px or >= 14px bold): minimum **3:1** contrast ratio
- **UI components and graphical objects**: minimum **3:1** against adjacent colors
- **Focus indicators**: minimum **3:1** against the background they appear on

### Keyboard Navigation
- All interactive elements must be reachable via Tab key
- Tab order must follow visual reading order (left-to-right, top-to-bottom)
- Custom widgets must implement appropriate keyboard patterns:
  - Dropdown/menu: Arrow keys to navigate, Enter to select, Escape to close
  - Modal: Tab trapped inside, Escape to close, focus returns to trigger on close
  - Table: Arrow keys for cell navigation (if interactive cells)
  - Tabs: Arrow keys to switch tabs, Tab to enter content area
- Visible focus indicators on all focusable elements (never `outline: none` without replacement)

### ARIA Attributes
- Use semantic HTML first (`<button>`, `<nav>`, `<main>`, `<table>`)
- Add ARIA only when semantic HTML is insufficient
- Required ARIA patterns:
  - `role="alert"` for error messages and dynamic notifications
  - `aria-live="polite"` for content that updates asynchronously (loading states, search results count)
  - `aria-label` for icon-only buttons
  - `aria-expanded` for collapsible sections and dropdowns
  - `aria-current="page"` for active navigation items
  - `aria-sort` for sortable table columns
  - `aria-describedby` linking form inputs to error messages

### Forms
- Every input has a visible label (or `aria-label` for search inputs with placeholder)
- Error messages are associated with inputs via `aria-describedby`
- Required fields marked with `aria-required="true"` and visual indicator
- Group related inputs with `<fieldset>` and `<legend>`
- Submission errors summarized at top of form with links to each field

### Images and Icons
- Meaningful images: `alt` text describing the content
- Decorative images/icons: `aria-hidden="true"` and `alt=""`
- SVG icons used as buttons: `role="img"` with `aria-label`, or wrap in `<button>` with label

### Motion and Animation
- Respect `prefers-reduced-motion` media query
- Provide CSS that disables or reduces animations:
  ```css
  @media (prefers-reduced-motion: reduce) {
    *, *::before, *::after {
      animation-duration: 0.01ms !important;
      animation-iteration-count: 1 !important;
      transition-duration: 0.01ms !important;
    }
  }
  ```
- No content that flashes more than 3 times per second

## Responsive Breakpoints

Follow Tailwind CSS default breakpoints:

| Name | Min Width | Typical Devices | Layout Behavior |
|------|-----------|-----------------|-----------------|
| `sm` | 640px | Large phones (landscape) | Single column, larger touch targets |
| `md` | 768px | Tablets | Two-column, sidebar collapses |
| `lg` | 1024px | Small laptops | Full layout, sidebar visible |
| `xl` | 1280px | Desktops | Max-width containers, comfortable spacing |
| `2xl` | 1536px | Large monitors | Optional: wider content area |

### Mobile-First Approach
- Write base styles for mobile (< 640px)
- Add complexity via `sm:`, `md:`, `lg:`, `xl:` prefixes
- Never hide critical content on mobile — reflow, stack, or collapse instead

### Responsive Patterns
- **Navigation:** Overlay on mobile, collapsed icons on tablet, full sidebar on desktop
- **Tables:** Horizontal scroll on mobile, or reflow to card layout
- **Forms:** Single column on mobile, two-column on desktop
- **Grids:** 1 column → 2 columns → 3-4 columns as width increases
- **Modals:** Full-screen on mobile, centered overlay on desktop

## Focus Indicators

Default DaisyUI focus ring is acceptable. Custom focus styles must meet:
- Minimum 2px outline width
- 3:1 contrast against background
- Visible on both light and dark themes

```css
/* Custom focus style if overriding DaisyUI */
:focus-visible {
  outline: 2px solid hsl(var(--p));
  outline-offset: 2px;
}
```

Do not use `:focus` without `:focus-visible` — this avoids showing focus rings on mouse click while keeping them for keyboard navigation.

## Motion and Animation Guidelines

### Timing
- **Micro-interactions** (button press, toggle): 100-150ms
- **Small transitions** (hover, fade): 150-200ms
- **Medium transitions** (slide, expand): 200-300ms
- **Large transitions** (page, modal): 300-500ms

### Easing
- **Enter:** `ease-out` (fast start, slow end) — elements appearing
- **Exit:** `ease-in` (slow start, fast end) — elements leaving
- **Move:** `ease-in-out` — elements moving position

### Standard Animations
```css
/* Fade in */
@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

/* Slide up */
@keyframes slideUp {
  from { transform: translateY(8px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}

/* Scale in (for modals) */
@keyframes scaleIn {
  from { transform: scale(0.95); opacity: 0; }
  to { transform: scale(1); opacity: 1; }
}
```

### Rules
- Never animate `width`, `height`, or `top`/`left` — use `transform` and `opacity` only for 60fps
- Always provide `will-change` hint for animated properties on complex elements
- Disable animations for `prefers-reduced-motion` users (see Accessibility section)
- Loading spinners and skeleton pulse are exempt from reduced-motion (they indicate system status)
