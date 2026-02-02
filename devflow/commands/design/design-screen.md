---
allowed-tools: Read, Write, LS, Glob, Bash
---

# Design Screen

Build screen-level components for a section using Angular + DaisyUI (primary) or React + Tailwind (secondary).

## Usage
```
/design:design-screen <section>
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/design-standards.md` — Component API conventions, a11y requirements, responsive breakpoints

## Preflight Checklist

1. **Validate section name:**
   - `$ARGUMENTS` must be a non-empty string
   - If empty: "Usage: `/design:design-screen <section>` — e.g., `/design:design-screen user-management`"

2. **Check prerequisites:**
   - Design tokens exist: look for `tailwind.config.js` with DaisyUI config, `src/styles/tokens.css`
   - Section design exists: look for `devflow/designs/$ARGUMENTS.md` (from `/design:shape-section`)
   - Sample data exists: look for `src/app/models/$ARGUMENTS.models.ts` and `src/app/mocks/$ARGUMENTS.mock.ts`
   - If any missing, warn which prerequisite is missing but proceed (use sensible defaults)

3. **Detect frontend framework:**
   - Check `package.json` for `@angular/core` → Angular + DaisyUI (primary)
   - Check `package.json` for `react` → React + Tailwind (secondary)
   - If neither found, ask user. Default: Angular.

## Instructions

You are a frontend engineer building production-ready screen components for the **$ARGUMENTS** section.

### Step 1: Read Section Design

Read `devflow/designs/$ARGUMENTS.md` to get:
- Screen list and their purposes
- User flows
- Wireframe descriptions
- Interaction patterns
- Data requirements

If the design file does not exist, ask the user to describe the screens needed.

### Step 2: Component Structure

For each screen identified, create a component following this structure:

#### Angular (Primary)

```
src/app/features/<section>/
├── <section>.module.ts              # Feature module with declarations and routes
├── <section>-routing.module.ts      # Route definitions
├── pages/
│   ├── <screen>-page/
│   │   ├── <screen>-page.component.ts
│   │   ├── <screen>-page.component.html
│   │   ├── <screen>-page.component.scss
│   │   └── <screen>-page.component.spec.ts
│   └── ...
├── components/
│   ├── <component>/
│   │   ├── <component>.component.ts
│   │   ├── <component>.component.html
│   │   ├── <component>.component.scss
│   │   └── <component>.component.spec.ts
│   └── ...
└── services/
    └── <section>.service.ts         # HTTP service for API calls
```

#### React (Secondary, if plan specifies React)

```
src/features/<section>/
├── index.ts                         # Public exports
├── routes.tsx                       # Route definitions
├── pages/
│   ├── <ScreenPage>.tsx
│   └── ...
├── components/
│   ├── <Component>.tsx
│   └── ...
├── hooks/
│   └── use<Section>.ts              # Custom hooks
└── services/
    └── <section>.service.ts         # API service
```

### Step 3: Page Components

For each page (screen), generate the component file. Pages are smart components that:
- Manage state (data fetching, loading, error)
- Orchestrate child components
- Handle routing parameters
- Connect to services

**Angular page component pattern:**

```typescript
import { Component, OnInit, inject } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { SectionService } from '../../services/<section>.service';

@Component({
  selector: 'app-<screen>-page',
  templateUrl: './<screen>-page.component.html',
  styleUrls: ['./<screen>-page.component.scss'],
})
export class ScreenPageComponent implements OnInit {
  private service = inject(SectionService);
  private route = inject(ActivatedRoute);
  private router = inject(Router);

  // State
  items: EntityName[] = [];
  loading = true;
  error: string | null = null;
  totalCount = 0;
  currentPage = 1;
  pageSize = 10;

  ngOnInit(): void {
    this.loadData();
  }

  loadData(): void {
    this.loading = true;
    this.error = null;
    this.service.list({ page: this.currentPage, limit: this.pageSize }).subscribe({
      next: (response) => {
        this.items = response.items;
        this.totalCount = response.total;
        this.loading = false;
      },
      error: (err) => {
        this.error = 'Failed to load data. Please try again.';
        this.loading = false;
      },
    });
  }
}
```

### Step 4: Template with DaisyUI

Each template uses DaisyUI classes for consistent styling:

**List page template example:**
```html
<div class="p-6">
  <!-- Page Header -->
  <div class="flex items-center justify-between mb-6">
    <div>
      <h1 class="text-2xl font-bold text-base-content">Page Title</h1>
      <p class="text-sm text-base-content/70 mt-1">Brief description</p>
    </div>
    <button class="btn btn-primary" (click)="onCreate()">
      <svg><!-- plus icon --></svg>
      Create New
    </button>
  </div>

  <!-- Search and Filters -->
  <div class="flex flex-wrap gap-3 mb-4">
    <div class="form-control flex-1 min-w-[200px]">
      <input
        type="text"
        placeholder="Search..."
        class="input input-bordered w-full"
        [(ngModel)]="searchQuery"
        (input)="onSearch()"
        aria-label="Search items"
      />
    </div>
    <select class="select select-bordered" [(ngModel)]="statusFilter" (change)="onFilter()" aria-label="Filter by status">
      <option value="">All Statuses</option>
      <option value="active">Active</option>
      <option value="inactive">Inactive</option>
    </select>
  </div>

  <!-- Loading State -->
  <div *ngIf="loading" class="space-y-3">
    <div *ngFor="let i of [1,2,3,4,5]" class="animate-pulse flex items-center gap-4 p-4 bg-base-200 rounded-lg">
      <div class="h-10 w-10 bg-base-300 rounded-full"></div>
      <div class="flex-1 space-y-2">
        <div class="h-4 bg-base-300 rounded w-3/4"></div>
        <div class="h-3 bg-base-300 rounded w-1/2"></div>
      </div>
    </div>
  </div>

  <!-- Error State -->
  <div *ngIf="error && !loading" class="alert alert-error" role="alert">
    <svg><!-- error icon --></svg>
    <span>{{ error }}</span>
    <button class="btn btn-sm btn-ghost" (click)="loadData()">Retry</button>
  </div>

  <!-- Empty State -->
  <div *ngIf="!loading && !error && items.length === 0" class="text-center py-16">
    <svg><!-- empty icon --></svg>
    <h3 class="text-lg font-medium text-base-content mt-4">No items found</h3>
    <p class="text-base-content/60 mt-1">Get started by creating your first item.</p>
    <button class="btn btn-primary mt-4" (click)="onCreate()">Create New</button>
  </div>

  <!-- Data Table -->
  <div *ngIf="!loading && !error && items.length > 0" class="overflow-x-auto">
    <table class="table table-zebra w-full">
      <thead>
        <tr>
          <th class="cursor-pointer" (click)="onSort('name')" (keydown.enter)="onSort('name')" tabindex="0" role="columnheader" aria-sort="none">
            Name
            <svg *ngIf="sortBy === 'name'"><!-- sort indicator --></svg>
          </th>
          <th>Status</th>
          <th>Created</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <tr *ngFor="let item of items" class="hover cursor-pointer" (click)="onView(item)" (keydown.enter)="onView(item)" tabindex="0">
          <td class="font-medium">{{ item.name }}</td>
          <td>
            <span class="badge" [ngClass]="{
              'badge-success': item.status === 'active',
              'badge-warning': item.status === 'pending',
              'badge-ghost': item.status === 'inactive',
              'badge-error': item.status === 'archived'
            }">{{ item.status }}</span>
          </td>
          <td class="text-base-content/70">{{ item.created_at | date:'mediumDate' }}</td>
          <td>
            <div class="dropdown dropdown-end" (click)="$event.stopPropagation()">
              <label tabindex="0" class="btn btn-ghost btn-sm btn-circle" aria-label="Actions for {{ item.name }}">
                <svg><!-- dots icon --></svg>
              </label>
              <ul tabindex="0" class="dropdown-content menu p-2 shadow bg-base-100 rounded-box w-40 z-10">
                <li><a (click)="onEdit(item)">Edit</a></li>
                <li><a (click)="onDelete(item)" class="text-error">Delete</a></li>
              </ul>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
  </div>

  <!-- Pagination -->
  <div *ngIf="totalCount > pageSize" class="flex justify-center mt-6">
    <div class="join">
      <button class="join-item btn btn-sm" [disabled]="currentPage === 1" (click)="onPageChange(currentPage - 1)">Previous</button>
      <button class="join-item btn btn-sm btn-active">{{ currentPage }}</button>
      <button class="join-item btn btn-sm" [disabled]="currentPage * pageSize >= totalCount" (click)="onPageChange(currentPage + 1)">Next</button>
    </div>
  </div>
</div>
```

### Step 5: Presentational Components

Extract reusable pieces into presentational (dumb) components that only take inputs and emit outputs:

```typescript
// Angular pattern
@Component({
  selector: 'app-status-badge',
  template: `<span class="badge" [ngClass]="badgeClass">{{ status }}</span>`,
})
export class StatusBadgeComponent {
  @Input() status!: string;

  get badgeClass(): Record<string, boolean> {
    return {
      'badge-success': this.status === 'active',
      'badge-warning': this.status === 'pending',
      'badge-ghost': this.status === 'inactive',
      'badge-error': this.status === 'archived',
    };
  }
}
```

Common presentational components to extract:
- **StatusBadge** — Renders status with color-coded badge
- **DataTable** — Reusable table with sort, select, actions
- **EmptyState** — Icon + message + action button
- **ConfirmDialog** — DaisyUI modal for delete/destructive actions
- **FormField** — Label + input + error message wrapper
- **PageHeader** — Title + subtitle + actions layout

### Step 6: Styles

Each component gets a `.scss` file for component-specific styles. General rules:
- Use Tailwind utility classes in templates for 90% of styling
- Use SCSS only for complex selectors, animations, or component-specific overrides
- Reference design tokens via CSS custom properties (`var(--space-4)`)
- Never hardcode colors — always use DaisyUI semantic classes or CSS variables

```scss
// <screen>-page.component.scss
:host {
  display: block;
  min-height: 100%;
}

// Custom scrollbar for tables
.table-container {
  &::-webkit-scrollbar {
    height: 6px;
  }
  &::-webkit-scrollbar-track {
    background: hsl(var(--b2));
  }
  &::-webkit-scrollbar-thumb {
    background: hsl(var(--bc) / 0.2);
    border-radius: var(--radius-full);
  }
}
```

### Step 7: Test Files

Each component gets a `.spec.ts` file:

```typescript
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ScreenPageComponent } from './<screen>-page.component';
import { SectionService } from '../../services/<section>.service';
import { of, throwError } from 'rxjs';
import { createPaginatedResponse, createEntities } from '../../../mocks/<section>.factory';

describe('ScreenPageComponent', () => {
  let component: ScreenPageComponent;
  let fixture: ComponentFixture<ScreenPageComponent>;
  let mockService: jasmine.SpyObj<SectionService>;

  beforeEach(async () => {
    mockService = jasmine.createSpyObj('SectionService', ['list', 'get', 'create', 'update', 'delete']);
    mockService.list.and.returnValue(of(createPaginatedResponse(createEntities(10))));

    await TestBed.configureTestingModule({
      declarations: [ScreenPageComponent],
      providers: [{ provide: SectionService, useValue: mockService }],
    }).compileComponents();

    fixture = TestBed.createComponent(ScreenPageComponent);
    component = fixture.componentInstance;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should load data on init', () => {
    fixture.detectChanges();
    expect(mockService.list).toHaveBeenCalledWith({ page: 1, limit: 10 });
    expect(component.items.length).toBe(10);
    expect(component.loading).toBeFalse();
  });

  it('should show error state on failure', () => {
    mockService.list.and.returnValue(throwError(() => new Error('Network error')));
    fixture.detectChanges();
    expect(component.error).toBeTruthy();
    expect(component.loading).toBeFalse();
  });

  it('should show empty state when no items', () => {
    mockService.list.and.returnValue(of(createPaginatedResponse([])));
    fixture.detectChanges();
    expect(component.items.length).toBe(0);
  });
});
```

### Step 8: Accessibility Checklist

Before finalizing each component, verify:
- [ ] All interactive elements are keyboard accessible (tabindex, keydown handlers)
- [ ] Form inputs have associated labels (explicit `<label for="">` or `aria-label`)
- [ ] Images/icons have alt text or `aria-hidden="true"` if decorative
- [ ] Color is not the only indicator (add text/icon alongside color-coded badges)
- [ ] Focus is visible (DaisyUI default focus rings, do not override)
- [ ] Page has a single `<h1>`, heading hierarchy is correct
- [ ] ARIA landmarks used (`role="main"`, `role="navigation"`, `role="alert"`)
- [ ] Dynamic content changes announced (`aria-live="polite"` for loading/error states)
- [ ] Modals trap focus and return focus on close
- [ ] Tables use proper `<th>` with `scope` attributes

### Step 9: Generate Files

Create all files for every screen in the section. For each screen, generate:
1. Page component (`.ts`, `.html`, `.scss`, `.spec.ts`)
2. Extracted presentational components
3. Feature module and routing module
4. Service file with typed HTTP methods

```
✅ Screen components built: $ARGUMENTS
  - Pages: [list of page names]
  - Components: [list of shared components]
  - Service: <section>.service.ts with [count] methods
  - Tests: [count] spec files
  - A11y: WCAG 2.1 AA compliant
Next: /design:export to generate the handoff package
```

## Error Recovery

- If section design is missing, generate screens based on common CRUD patterns (list, detail, create, edit)
- If mock data is missing, create inline mock data within test files
- If framework cannot be detected, ask user and default to Angular
