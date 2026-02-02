# Frontend Patterns

Frontend patterns for Angular+DaisyUI+Tailwind (primary) and React+Tailwind (secondary).

## Component Architecture

### Smart vs Dumb Components

**Smart (Container) Components:**
- Connect to state management (NgRx store / Zustand / Context)
- Handle data fetching and side effects
- Pass data down to dumb components via inputs/props
- Located in `features/` directories

**Dumb (Presentational) Components:**
- Receive data via `@Input()` / props
- Emit events via `@Output()` / callback props
- No direct service or store access
- Highly reusable
- Located in `shared/components/` or within feature `components/` subdirectory

### Angular Container Pattern

```typescript
// Smart component — connects to store
@Component({
  selector: 'app-project-list-page',
  template: `
    <app-project-list
      [projects]="projects$ | async"
      [loading]="loading$ | async"
      (projectSelected)="onProjectSelected($event)"
      (deleteRequested)="onDelete($event)"
    />
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ProjectListPageComponent {
  projects$ = this.store.select(selectProjects);
  loading$ = this.store.select(selectProjectsLoading);

  constructor(private store: Store) {
    this.store.dispatch(ProjectActions.loadProjects());
  }

  onProjectSelected(project: Project): void {
    this.router.navigate(['/projects', project.id]);
  }

  onDelete(projectId: string): void {
    this.store.dispatch(ProjectActions.deleteProject({ id: projectId }));
  }
}
```

```typescript
// Dumb component — pure presentation
@Component({
  selector: 'app-project-list',
  template: `
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      @for (project of projects; track project.id) {
        <app-project-card
          [project]="project"
          (click)="projectSelected.emit(project)"
          (delete)="deleteRequested.emit(project.id)"
        />
      }
    </div>
    @if (loading) {
      <div class="flex justify-center p-8">
        <span class="loading loading-spinner loading-lg"></span>
      </div>
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ProjectListComponent {
  @Input({ required: true }) projects: Project[] = [];
  @Input() loading = false;
  @Output() projectSelected = new EventEmitter<Project>();
  @Output() deleteRequested = new EventEmitter<string>();
}
```

### React Container Pattern

```tsx
// Smart component
function ProjectListPage() {
  const { projects, loading } = useProjectStore();
  const navigate = useNavigate();

  useEffect(() => {
    useProjectStore.getState().fetchProjects();
  }, []);

  return (
    <ProjectList
      projects={projects}
      loading={loading}
      onProjectSelected={(project) => navigate(`/projects/${project.id}`)}
      onDelete={(id) => useProjectStore.getState().deleteProject(id)}
    />
  );
}

// Dumb component
interface ProjectListProps {
  projects: Project[];
  loading: boolean;
  onProjectSelected: (project: Project) => void;
  onDelete: (id: string) => void;
}

const ProjectList = React.memo(function ProjectList({
  projects,
  loading,
  onProjectSelected,
  onDelete,
}: ProjectListProps) {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {projects.map((project) => (
        <ProjectCard
          key={project.id}
          project={project}
          onClick={() => onProjectSelected(project)}
          onDelete={() => onDelete(project.id)}
        />
      ))}
      {loading && (
        <div className="flex justify-center p-8">
          <span className="loading loading-spinner loading-lg" />
        </div>
      )}
    </div>
  );
});
```

## State Management

### Angular: NgRx

Structure per feature:
```
features/projects/
  store/
    project.actions.ts
    project.reducer.ts
    project.effects.ts
    project.selectors.ts
    project.state.ts
```

```typescript
// project.state.ts
export interface ProjectState {
  projects: Project[];
  selectedProject: Project | null;
  loading: boolean;
  error: string | null;
}

export const initialProjectState: ProjectState = {
  projects: [],
  selectedProject: null,
  loading: false,
  error: null,
};
```

```typescript
// project.actions.ts
import { createActionGroup, props, emptyProps } from '@ngrx/store';

export const ProjectActions = createActionGroup({
  source: 'Projects',
  events: {
    'Load Projects': emptyProps(),
    'Load Projects Success': props<{ projects: Project[] }>(),
    'Load Projects Failure': props<{ error: string }>(),
    'Delete Project': props<{ id: string }>(),
    'Delete Project Success': props<{ id: string }>(),
  },
});
```

### React: Zustand

```typescript
import { create } from 'zustand';

interface ProjectStore {
  projects: Project[];
  loading: boolean;
  error: string | null;
  fetchProjects: () => Promise<void>;
  deleteProject: (id: string) => Promise<void>;
}

export const useProjectStore = create<ProjectStore>((set) => ({
  projects: [],
  loading: false,
  error: null,

  fetchProjects: async () => {
    set({ loading: true, error: null });
    try {
      const response = await api.get('/api/v1/projects');
      set({ projects: response.data.data, loading: false });
    } catch (err) {
      set({ error: 'Failed to load projects', loading: false });
    }
  },

  deleteProject: async (id: string) => {
    try {
      await api.delete(`/api/v1/projects/${id}`);
      set((state) => ({
        projects: state.projects.filter((p) => p.id !== id),
      }));
    } catch (err) {
      set({ error: 'Failed to delete project' });
    }
  },
}));
```

## Routing Patterns

### Angular: Lazy Loading

```typescript
// app.routes.ts
export const routes: Routes = [
  {
    path: '',
    redirectTo: 'dashboard',
    pathMatch: 'full',
  },
  {
    path: 'dashboard',
    loadComponent: () =>
      import('./features/dashboard/dashboard.component').then(
        (m) => m.DashboardComponent
      ),
  },
  {
    path: 'projects',
    loadChildren: () =>
      import('./features/projects/projects.routes').then(
        (m) => m.PROJECT_ROUTES
      ),
    canActivate: [authGuard],
  },
];
```

### Route Guards

```typescript
// auth.guard.ts
export const authGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (authService.isAuthenticated()) {
    return true;
  }
  return router.createUrlTree(['/login'], {
    queryParams: { returnUrl: state.url },
  });
};
```

### React: Lazy Loading

```tsx
const Dashboard = lazy(() => import('./features/dashboard/DashboardPage'));
const Projects = lazy(() => import('./features/projects/ProjectsPage'));

function AppRoutes() {
  return (
    <Suspense fallback={<LoadingSpinner />}>
      <Routes>
        <Route path="/" element={<Navigate to="/dashboard" />} />
        <Route path="/dashboard" element={<Dashboard />} />
        <Route
          path="/projects/*"
          element={
            <RequireAuth>
              <Projects />
            </RequireAuth>
          }
        />
      </Routes>
    </Suspense>
  );
}
```

## Form Handling

### Angular: Reactive Forms

```typescript
@Component({
  selector: 'app-project-form',
  template: `
    <form [formGroup]="form" (ngSubmit)="onSubmit()" class="space-y-4">
      <div class="form-control w-full">
        <label class="label">
          <span class="label-text">Project Name</span>
        </label>
        <input
          type="text"
          formControlName="name"
          class="input input-bordered w-full"
          [class.input-error]="form.get('name')?.invalid && form.get('name')?.touched"
        />
        @if (form.get('name')?.hasError('required') && form.get('name')?.touched) {
          <label class="label">
            <span class="label-text-alt text-error">Name is required</span>
          </label>
        }
      </div>

      <div class="form-control w-full">
        <label class="label">
          <span class="label-text">Description</span>
        </label>
        <textarea
          formControlName="description"
          class="textarea textarea-bordered w-full"
          rows="3"
        ></textarea>
      </div>

      <button
        type="submit"
        class="btn btn-primary"
        [disabled]="form.invalid || submitting"
      >
        @if (submitting) {
          <span class="loading loading-spinner loading-sm"></span>
        }
        Save Project
      </button>
    </form>
  `,
})
export class ProjectFormComponent {
  @Output() formSubmitted = new EventEmitter<ProjectFormData>();

  submitting = false;

  form = new FormGroup({
    name: new FormControl('', [Validators.required, Validators.maxLength(255)]),
    description: new FormControl('', [Validators.maxLength(2000)]),
  });

  onSubmit(): void {
    if (this.form.valid) {
      this.formSubmitted.emit(this.form.getRawValue() as ProjectFormData);
    }
  }
}
```

### React: react-hook-form

```tsx
import { useForm } from 'react-hook-form';

interface ProjectFormData {
  name: string;
  description?: string;
}

function ProjectForm({ onSubmit, submitting }: ProjectFormProps) {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<ProjectFormData>();

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <div className="form-control w-full">
        <label className="label">
          <span className="label-text">Project Name</span>
        </label>
        <input
          type="text"
          {...register('name', { required: 'Name is required', maxLength: 255 })}
          className={`input input-bordered w-full ${errors.name ? 'input-error' : ''}`}
        />
        {errors.name && (
          <label className="label">
            <span className="label-text-alt text-error">{errors.name.message}</span>
          </label>
        )}
      </div>

      <div className="form-control w-full">
        <label className="label">
          <span className="label-text">Description</span>
        </label>
        <textarea
          {...register('description', { maxLength: 2000 })}
          className="textarea textarea-bordered w-full"
          rows={3}
        />
      </div>

      <button type="submit" className="btn btn-primary" disabled={submitting}>
        {submitting && <span className="loading loading-spinner loading-sm" />}
        Save Project
      </button>
    </form>
  );
}
```

## Accessibility Requirements

### ARIA Labels
- Every interactive element must have an accessible name
- Use `aria-label` when visible text is insufficient
- Use `aria-labelledby` to reference visible headings
- Use `aria-describedby` for additional context (error messages, hints)

```html
<!-- Angular / React -->
<button aria-label="Delete project: {{ project.name }}">
  <svg><!-- trash icon --></svg>
</button>

<input
  aria-label="Search projects"
  aria-describedby="search-hint"
/>
<p id="search-hint" class="text-sm text-base-content/60">
  Search by name or description
</p>
```

### Keyboard Navigation
- All interactive elements reachable via Tab
- Custom components must implement keyboard handlers (Enter, Space, Escape, Arrow keys)
- Focus traps for modals and dialogs
- Skip-to-content link as first focusable element

```typescript
// Angular: Focus management for modals
@Component({
  selector: 'app-modal',
  template: `
    <dialog
      #dialog
      class="modal"
      (keydown.escape)="close()"
      role="dialog"
      aria-modal="true"
      [attr.aria-labelledby]="titleId"
    >
      <div class="modal-box" cdkTrapFocus>
        <h3 [id]="titleId" class="font-bold text-lg">{{ title }}</h3>
        <ng-content />
        <div class="modal-action">
          <button class="btn" (click)="close()">Close</button>
        </div>
      </div>
      <form method="dialog" class="modal-backdrop">
        <button>close</button>
      </form>
    </dialog>
  `,
})
export class ModalComponent {
  @Input({ required: true }) title = '';
  titleId = `modal-title-${crypto.randomUUID()}`;
}
```

### Focus Management
- Return focus to trigger element when closing modals/dropdowns
- Move focus to first error field on form validation failure
- Announce dynamic content changes with `aria-live` regions

```html
<div aria-live="polite" class="sr-only">
  {{ statusMessage }}
</div>
```

## Responsive Design

### Mobile-First with Tailwind Breakpoints

Always start with mobile styles, then add larger breakpoints:

```html
<!-- Mobile: single column, Tablet: 2 columns, Desktop: 3 columns -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 p-4 md:p-6 lg:p-8">
  ...
</div>
```

### Breakpoint Reference
| Prefix | Min Width | Target |
|--------|-----------|--------|
| (none) | 0px | Mobile (default) |
| `sm` | 640px | Large phones |
| `md` | 768px | Tablets |
| `lg` | 1024px | Small laptops |
| `xl` | 1280px | Desktops |
| `2xl` | 1536px | Large screens |

### Responsive Patterns
- Navigation: Hamburger menu on mobile, sidebar on desktop
- Tables: Horizontal scroll on mobile, full table on desktop
- Forms: Full width on mobile, constrained width on desktop
- Modals: Full screen on mobile, centered overlay on desktop

```html
<!-- Responsive navigation -->
<div class="drawer lg:drawer-open">
  <input id="sidebar" type="checkbox" class="drawer-toggle" />
  <div class="drawer-content">
    <!-- Mobile hamburger -->
    <label for="sidebar" class="btn btn-ghost lg:hidden">
      <svg><!-- menu icon --></svg>
    </label>
    <!-- Page content -->
    <main class="p-4 lg:p-8">
      <ng-content />
    </main>
  </div>
  <div class="drawer-side">
    <label for="sidebar" class="drawer-overlay"></label>
    <nav class="menu bg-base-200 w-64 min-h-full p-4">
      <!-- Navigation items -->
    </nav>
  </div>
</div>
```

## Theming with DaisyUI

### Theme Switching

```html
<!-- In index.html or root component -->
<html data-theme="light">
```

```typescript
// Theme service (Angular)
@Injectable({ providedIn: 'root' })
export class ThemeService {
  private readonly STORAGE_KEY = 'preferred-theme';
  private currentTheme = signal<string>(this.getStoredTheme());

  readonly theme = this.currentTheme.asReadonly();

  setTheme(theme: string): void {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem(this.STORAGE_KEY, theme);
    this.currentTheme.set(theme);
  }

  private getStoredTheme(): string {
    return localStorage.getItem(this.STORAGE_KEY) ?? 'light';
  }
}
```

### Theme Switcher Component

```html
<div class="dropdown dropdown-end">
  <div tabindex="0" role="button" class="btn btn-ghost" aria-label="Change theme">
    Theme
  </div>
  <ul tabindex="0" class="dropdown-content menu bg-base-200 rounded-box w-52 p-2 shadow-lg">
    @for (theme of themes; track theme) {
      <li>
        <button
          (click)="setTheme(theme)"
          [class.active]="currentTheme() === theme"
        >
          {{ theme }}
        </button>
      </li>
    }
  </ul>
</div>
```

### Custom Theme Definition

```javascript
// tailwind.config.js
module.exports = {
  plugins: [require('daisyui')],
  daisyui: {
    themes: [
      'light',
      'dark',
      {
        brand: {
          'primary': '#4f46e5',
          'primary-content': '#ffffff',
          'secondary': '#7c3aed',
          'accent': '#06b6d4',
          'neutral': '#1f2937',
          'base-100': '#ffffff',
          'base-200': '#f9fafb',
          'base-300': '#f3f4f6',
          'info': '#3b82f6',
          'success': '#22c55e',
          'warning': '#f59e0b',
          'error': '#ef4444',
        },
      },
    ],
  },
};
```

## API Integration Patterns

### Angular: HTTP Interceptors

```typescript
// auth.interceptor.ts
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const token = authService.getToken();

  if (token) {
    req = req.clone({
      setHeaders: { Authorization: `Bearer ${token}` },
    });
  }
  return next(req);
};

// error.interceptor.ts
export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  const router = inject(Router);

  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      if (error.status === 401) {
        router.navigate(['/login']);
      }
      return throwError(() => error);
    }),
  );
};

// Register in app.config.ts
export const appConfig: ApplicationConfig = {
  providers: [
    provideHttpClient(withInterceptors([authInterceptor, errorInterceptor])),
  ],
};
```

### Angular: API Service Pattern

```typescript
@Injectable({ providedIn: 'root' })
export class ProjectApiService {
  private readonly baseUrl = '/api/v1/projects';

  constructor(private http: HttpClient) {}

  list(params?: { limit?: number; after?: string }): Observable<ProjectListResponse> {
    return this.http.get<ProjectListResponse>(this.baseUrl, { params: params as any });
  }

  get(id: string): Observable<ProjectResponse> {
    return this.http.get<ProjectResponse>(`${this.baseUrl}/${id}`);
  }

  create(data: ProjectCreate): Observable<ProjectResponse> {
    return this.http.post<ProjectResponse>(this.baseUrl, data);
  }

  update(id: string, data: ProjectUpdate): Observable<ProjectResponse> {
    return this.http.patch<ProjectResponse>(`${this.baseUrl}/${id}`, data);
  }

  delete(id: string): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }
}
```

### React: Axios Instance with Interceptors

```typescript
import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '',
  headers: { 'Content-Type': 'application/json' },
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      window.location.href = '/login';
    }
    return Promise.reject(error);
  },
);

export default api;
```

## Performance Patterns

### Angular: OnPush Change Detection

Always use `OnPush` for all components:

```typescript
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  // ...
})
```

OnPush rules:
- Component re-renders only when `@Input()` references change or an event fires within the component
- Use `async` pipe for observables (triggers change detection automatically)
- Use `signal()` for reactive state (Angular 17+)
- Avoid mutating objects/arrays — always create new references

### React: React.memo and useMemo

```tsx
// Memoize expensive components
const ProjectCard = React.memo(function ProjectCard({ project, onClick }: Props) {
  return (
    <div className="card bg-base-100 shadow-md" onClick={onClick}>
      <div className="card-body">
        <h2 className="card-title">{project.name}</h2>
        <p>{project.description}</p>
      </div>
    </div>
  );
});

// Memoize expensive computations
function ProjectStats({ projects }: { projects: Project[] }) {
  const stats = useMemo(
    () => ({
      total: projects.length,
      active: projects.filter((p) => p.status === 'active').length,
      completed: projects.filter((p) => p.status === 'completed').length,
    }),
    [projects],
  );

  return <StatsDisplay stats={stats} />;
}
```

### Virtual Scrolling

For lists with hundreds or thousands of items:

```typescript
// Angular: @angular/cdk virtual scrolling
import { CdkVirtualScrollViewport, CdkVirtualForOf } from '@angular/cdk/scrolling';

@Component({
  template: `
    <cdk-virtual-scroll-viewport itemSize="72" class="h-[600px]">
      <div *cdkVirtualFor="let item of items" class="h-[72px] border-b">
        <app-item-row [item]="item" />
      </div>
    </cdk-virtual-scroll-viewport>
  `,
  imports: [CdkVirtualScrollViewport, CdkVirtualForOf],
})
export class ItemListComponent {
  @Input() items: Item[] = [];
}
```

```tsx
// React: @tanstack/react-virtual
import { useVirtualizer } from '@tanstack/react-virtual';

function VirtualList({ items }: { items: Item[] }) {
  const parentRef = useRef<HTMLDivElement>(null);

  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 72,
  });

  return (
    <div ref={parentRef} className="h-[600px] overflow-auto">
      <div style={{ height: `${virtualizer.getTotalSize()}px`, position: 'relative' }}>
        {virtualizer.getVirtualItems().map((virtualItem) => (
          <div
            key={virtualItem.key}
            style={{
              position: 'absolute',
              top: 0,
              transform: `translateY(${virtualItem.start}px)`,
              height: `${virtualItem.size}px`,
              width: '100%',
            }}
          >
            <ItemRow item={items[virtualItem.index]} />
          </div>
        ))}
      </div>
    </div>
  );
}
```

## Rules Summary

1. Use smart/dumb component separation — smart components connect to state, dumb components are pure presentation
2. Angular uses NgRx for state; React uses Zustand or Context
3. Lazy load all feature routes
4. Use reactive forms (Angular) or react-hook-form (React) for all forms
5. Every interactive element must be keyboard accessible and have an accessible name
6. Mobile-first responsive design with Tailwind breakpoints
7. Use DaisyUI theme system with `data-theme` attribute
8. HTTP interceptors for auth tokens and error handling
9. Always use OnPush change detection (Angular) or React.memo for list items
10. Use virtual scrolling for lists with more than 100 items
