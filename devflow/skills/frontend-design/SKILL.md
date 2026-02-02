---
name: frontend-design
description: Visual design system for web applications — tokens, app shell, screen components, and design export
tools: Read, Write, LS, Glob, Bash
model: inherit
color: cyan
---

# Frontend Design Skill

This skill provides a complete visual design workflow for web applications, from design tokens through production-ready screen components.

## What This Skill Does

Translates product specs and user stories into a concrete, implementable design system and component library. Covers:

1. **Visual Identity** — Color palettes, typography, spacing, and theming via design tokens
2. **Application Shell** — Navigation, layout structure, responsive behavior, and skeleton states
3. **Section Shaping** — Per-section UI specifications derived from user stories and acceptance criteria
4. **Sample Data** — TypeScript interfaces, realistic mock data, and factory functions
5. **Screen Components** — Production-ready, accessible, responsive components
6. **Design Export** — Complete handoff documentation with implementation prompts and test plans

## Prerequisites

Before using this skill, ensure:

- **Spec with user stories:** A product spec or PRD exists (in `devflow/specs/`, `.claude/specs/`, or `devflow/prds/`) containing user stories with Given/When/Then acceptance criteria
- **Plan with stack choice:** A technical plan or architecture decision has been made specifying the frontend framework. Default: Angular + DaisyUI + Tailwind CSS
- **Node.js project initialized:** `package.json` exists with the chosen framework and Tailwind CSS installed

## Capabilities

### Design Tokens (`/design:design-tokens`)
- Generates Tailwind CSS color palette with brand colors and semantic colors
- Creates DaisyUI theme configuration (light + dark themes)
- Defines typography system with Google Fonts selection
- Produces spacing scale, border-radius values, box-shadow values
- Outputs CSS custom properties and `tailwind.config.js` additions

### App Shell (`/design:design-shell`)
- Designs navigation pattern (sidebar, topbar, or hybrid)
- Creates user menu with avatar and dropdown
- Implements responsive behavior (mobile hamburger, tablet collapse, desktop full)
- Defines layout grid structure
- Generates skeleton loading states for all shell regions
- Builds breadcrumb pattern with route integration

### Section Shaping (`/design:shape-section <section>`)
- Reads spec user stories for the section
- Creates screen list with descriptions and routes
- Maps user flows from Given/When/Then criteria
- Writes wireframe descriptions (text-based)
- Documents interaction patterns (hover, click, keyboard, drag)
- Specifies data requirements per screen (API endpoints, fields, validation)

### Sample Data (`/design:sample-data <section>`)
- Generates TypeScript interfaces matching backend Pydantic models
- Creates 10-20 realistic mock records per entity
- Builds factory functions for dynamic test data generation
- Produces JSON fixtures for development and E2E testing
- Includes paginated response wrappers and error response fixtures

### Screen Components (`/design:design-screen <section>`)
- Builds page components (smart, stateful) and presentational components (dumb, reusable)
- Uses DaisyUI classes for consistent styling with design tokens
- Includes loading, error, and empty states for every data-driven screen
- Generates test files with meaningful test cases
- Follows WCAG 2.1 AA accessibility standards

### Design Export (`/design:export`)
- Produces component inventory with file paths and test counts
- Documents the design system (colors, typography, spacing, components)
- Generates standalone implementation prompts per component
- Creates test instructions per section
- Outputs Storybook stories if Storybook is installed

## Frameworks Supported

### Primary: Angular + DaisyUI + Tailwind CSS
- Angular 17+ with standalone components or NgModule
- DaisyUI 4.x component classes
- Tailwind CSS 3.x utility classes
- SCSS for component-specific styles
- RxJS for async data handling
- Angular Router for navigation

### Secondary: React + Tailwind CSS
- React 18+ with functional components and hooks
- Tailwind CSS 3.x utility classes
- React Router for navigation
- TypeScript interfaces for props
- Optional: Headless UI, Radix for accessible primitives

## Design Workflow

The recommended order for using this skill:

```
1. /design:design-tokens          → Visual identity and theming
2. /design:design-shell           → App layout and navigation
3. /design:shape-section <name>   → Per-section UI specification
4. /design:sample-data <name>     → Mock data for development
5. /design:design-screen <name>   → Build screen components
6. /design:export                 → Handoff documentation
```

Repeat steps 3-5 for each section of the application.

## Rules Reference

All design commands follow `devflow/rules/design-standards.md` which defines:
- Token naming conventions
- Component API conventions (Angular inputs/outputs, React props)
- Accessibility requirements (WCAG 2.1 AA)
- Responsive breakpoints
- Color contrast ratios
- Focus indicator standards
- Motion and animation guidelines

## Output Locations

| Artifact | Path |
|----------|------|
| Tailwind config | `tailwind.config.js` |
| CSS tokens | `src/styles/tokens.css` |
| Section designs | `devflow/designs/<section>.md` |
| Models | `src/app/models/<section>.models.ts` |
| Mock data | `src/app/mocks/<section>.mock.ts` |
| Factories | `src/app/mocks/<section>.factory.ts` |
| Fixtures | `src/app/mocks/fixtures/<section>-*.json` |
| Feature modules | `src/app/features/<section>/` |
| Export package | `devflow/designs/export/` |
