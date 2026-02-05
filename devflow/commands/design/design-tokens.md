---
allowed-tools: Read, Write, LS, Bash
---

# Design Tokens

Generate a complete visual identity system as design tokens for the project.

## Usage
```
/design:design-tokens
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `devflow/rules/design-standards.md` — Token naming conventions, a11y requirements, breakpoints

## Preflight Checklist

1. **Check for existing tokens:**
   - Look for `tailwind.config.js` or `tailwind.config.ts` in project root
   - Look for existing CSS variables in `src/styles/` or `src/assets/styles/`
   - If tokens already exist, ask user: "Design tokens already exist. Overwrite or extend?"

2. **Detect frontend stack:**
   - Check `package.json` for `@angular/core` (Angular) or `react` (React)
   - Check for `tailwindcss` and `daisyui` dependencies
   - If not found, warn: "Tailwind CSS and/or DaisyUI not detected. Tokens will be generated but you must install dependencies."

## Instructions

You are a design systems engineer creating a comprehensive token system for a web application.

### Step 1: Gather Brand Context — MANDATORY PROBING QUESTIONS

**⛔ BLOCKING REQUIREMENT: You MUST ask ALL questions below using AskUserQuestion.**

**ENFORCEMENT RULES:**
1. Do NOT skip any question
2. Do NOT proceed to Step 2 until ALL questions are answered
3. Do NOT use defaults unless user EXPLICITLY says "use defaults" or "skip questions"
4. If user tries to skip, remind them: "These questions are mandatory to ensure the design system matches your needs. Which question would you like to answer first?"
5. Each round MUST be completed before moving to the next round

#### Round 1: Brand Identity (use AskUserQuestion)

Ask these questions in sequence, waiting for answers:

1. **Brand Personality**
   - Question: "How would you describe the brand personality?"
   - Options:
     - Professional & Corporate (banks, enterprise software)
     - Friendly & Approachable (consumer apps, social platforms)
     - Minimal & Clean (productivity tools, portfolios)
     - Bold & Energetic (gaming, entertainment, startups)
   - Follow-up if "Professional": "Is it traditional/conservative or modern/innovative?"
   - Follow-up if "Bold": "Playful-bold or serious-bold?"

2. **Target Audience**
   - Question: "Who is the primary user of this application?"
   - Options:
     - Technical users (developers, engineers, IT)
     - Business professionals (executives, managers)
     - General consumers (everyday users)
     - Creative professionals (designers, artists)
   - Follow-up: "What age range? What tech savviness level?"

3. **Emotional Response**
   - Question: "What emotion should users feel when using this app?"
   - Options:
     - Trust & Security (healthcare, finance)
     - Excitement & Energy (entertainment, social)
     - Calm & Focus (productivity, meditation)
     - Confidence & Empowerment (business tools)

#### Round 2: Color Preferences (use AskUserQuestion)

4. **Primary Color**
   - Question: "Do you have a primary brand color in mind?"
   - Options:
     - Yes, I have a specific hex code
     - I prefer a general color family (blue, green, purple, etc.)
     - No preference, suggest based on industry
     - Let me see options first
   - If hex provided: Verify it works in both light/dark themes
   - If color family: "Cool tones (blue, purple, cyan) or warm tones (red, orange, amber)?"

5. **Color Associations**
   - Question: "Are there colors you want to AVOID?"
   - Context: "Some industries have negative associations (e.g., red in finance = loss)"
   - Free text response accepted

6. **Competitive Differentiation**
   - Question: "Who are your main competitors, and do you want to stand out or blend in?"
   - Options:
     - Stand out (different color palette from competitors)
     - Blend in (industry-standard colors for familiarity)
     - Not sure
   - If "stand out": "What colors do competitors use?"

#### Round 3: Typography & Style (use AskUserQuestion)

7. **Typography Preference**
   - Question: "What font style fits your brand?"
   - Options:
     - Sans-serif, modern (Inter, Poppins, Outfit)
     - Sans-serif, geometric (Roboto, Source Sans, Nunito)
     - Serif, traditional (Merriweather, Lora, Playfair)
     - Monospace, technical (JetBrains Mono, Fira Code)
   - Follow-up: "Any specific Google Fonts you've seen and liked?"

8. **Visual Density**
   - Question: "How dense should the interface be?"
   - Options:
     - Spacious (lots of whitespace, breathing room)
     - Balanced (standard spacing)
     - Compact (data-dense, information-heavy)
   - Context: "This affects spacing tokens globally"

9. **Corner Style**
   - Question: "What corner radius style do you prefer?"
   - Options:
     - Sharp (0-2px) — technical, precise
     - Subtle (4-6px) — balanced, professional
     - Rounded (8-12px) — friendly, approachable
     - Pill-shaped (full) — playful, modern

#### Round 4: Existing Assets (use AskUserQuestion)

10. **Existing Brand Guidelines**
    - Question: "Do you have existing brand guidelines or a style guide?"
    - Options:
      - Yes, I'll share the colors/fonts
      - We have a logo but no full guidelines
      - No, starting fresh
    - If yes: "Please provide: Primary color hex, secondary color hex, font names"

11. **Dark Mode Priority**
    - Question: "How important is dark mode?"
    - Options:
      - Primary (users will mostly use dark mode)
      - Equal priority (both themes equally important)
      - Secondary (light mode is primary, dark mode is nice-to-have)
      - Not needed (light mode only)

#### Summary Before Proceeding

After all questions, present a summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 DESIGN TOKEN INPUTS CONFIRMED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Brand: [personality] for [audience]
Emotion: [desired emotional response]
Colors:
  Primary: [hex or family]
  Avoid: [colors to avoid]
  Differentiation: [stand out / blend in]
Typography: [font style preference]
Density: [spacious / balanced / compact]
Corners: [radius style]
Dark Mode: [priority level]
Existing Assets: [yes/no, details]

Proceed to generate tokens?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### 🚦 GATE: Question Completion Check

**Before proceeding to Step 2, verify:**

| Question | Answered? |
|----------|-----------|
| 1. Brand Personality | [ ] |
| 2. Target Audience | [ ] |
| 3. Emotional Response | [ ] |
| 4. Primary Color | [ ] |
| 5. Color Associations | [ ] |
| 6. Competitive Differentiation | [ ] |
| 7. Typography Preference | [ ] |
| 8. Visual Density | [ ] |
| 9. Corner Style | [ ] |
| 10. Existing Brand Guidelines | [ ] |
| 11. Dark Mode Priority | [ ] |

**Gate Rule:** If ANY checkbox is unchecked, you MUST go back and ask that question. Do NOT proceed.

**Only proceed to Step 2 when:**
1. All 11 questions are answered ✓
2. Summary has been presented to user ✓
3. User has explicitly confirmed "Proceed" ✓

---

**EXCEPTION: Defaults** — Only if user explicitly says "use defaults" or "skip all questions", use:
- Primary: `#6366f1` (indigo)
- Secondary: `#8b5cf6` (violet)
- Accent: `#06b6d4` (cyan)
- Neutral: slate palette

But even then, ask: "Are you sure? Custom tokens lead to a better design system. It only takes 2-3 minutes."

### Step 2: Generate Tailwind Color Palette

Create a full color palette with semantic naming:

```javascript
// tailwind.config.js additions
module.exports = {
  theme: {
    extend: {
      colors: {
        // Brand colors — each with 50-950 shades
        primary: {
          50: '#eef2ff',
          100: '#e0e7ff',
          200: '#c7d2fe',
          300: '#a5b4fc',
          400: '#818cf8',
          500: '#6366f1',  // base
          600: '#4f46e5',
          700: '#4338ca',
          800: '#3730a3',
          900: '#312e81',
          950: '#1e1b4b',
        },
        secondary: { /* ... generated shades ... */ },
        accent: { /* ... generated shades ... */ },

        // Semantic colors
        success: {
          50: '#f0fdf4', 100: '#dcfce7', 500: '#22c55e', 700: '#15803d',
        },
        warning: {
          50: '#fffbeb', 100: '#fef3c7', 500: '#f59e0b', 700: '#b45309',
        },
        error: {
          50: '#fef2f2', 100: '#fee2e2', 500: '#ef4444', 700: '#b91c1c',
        },
        info: {
          50: '#eff6ff', 100: '#dbeafe', 500: '#3b82f6', 700: '#1d4ed8',
        },

        // Surface colors
        surface: {
          DEFAULT: '#ffffff',
          secondary: '#f8fafc',
          tertiary: '#f1f5f9',
        },
      },
    },
  },
};
```

### Step 3: Generate DaisyUI Theme Configuration

Create light and dark themes:

```javascript
// daisyui theme in tailwind.config.js
daisyui: {
  themes: [
    {
      light: {
        'primary': '#6366f1',
        'primary-content': '#ffffff',
        'secondary': '#8b5cf6',
        'secondary-content': '#ffffff',
        'accent': '#06b6d4',
        'accent-content': '#ffffff',
        'neutral': '#1e293b',
        'neutral-content': '#f8fafc',
        'base-100': '#ffffff',
        'base-200': '#f8fafc',
        'base-300': '#f1f5f9',
        'base-content': '#0f172a',
        'info': '#3b82f6',
        'info-content': '#ffffff',
        'success': '#22c55e',
        'success-content': '#ffffff',
        'warning': '#f59e0b',
        'warning-content': '#ffffff',
        'error': '#ef4444',
        'error-content': '#ffffff',
        '--rounded-box': '0.75rem',
        '--rounded-btn': '0.5rem',
        '--rounded-badge': '1.5rem',
        '--animation-btn': '0.25s',
        '--animation-input': '0.2s',
        '--btn-focus-scale': '0.98',
        '--tab-radius': '0.5rem',
      },
      dark: {
        'primary': '#818cf8',
        'primary-content': '#0f172a',
        'secondary': '#a78bfa',
        'secondary-content': '#0f172a',
        'accent': '#22d3ee',
        'accent-content': '#0f172a',
        'neutral': '#e2e8f0',
        'neutral-content': '#0f172a',
        'base-100': '#0f172a',
        'base-200': '#1e293b',
        'base-300': '#334155',
        'base-content': '#f8fafc',
        'info': '#60a5fa',
        'info-content': '#0f172a',
        'success': '#4ade80',
        'success-content': '#0f172a',
        'warning': '#fbbf24',
        'warning-content': '#0f172a',
        'error': '#f87171',
        'error-content': '#0f172a',
        '--rounded-box': '0.75rem',
        '--rounded-btn': '0.5rem',
        '--rounded-badge': '1.5rem',
        '--animation-btn': '0.25s',
        '--animation-input': '0.2s',
        '--btn-focus-scale': '0.98',
        '--tab-radius': '0.5rem',
      },
    },
  ],
},
```

### Step 4: Typography System

Select Google Fonts and define the type scale:

```css
/* src/styles/tokens.css */

/* Google Fonts import */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500;600&display=swap');

:root {
  /* Font families */
  --font-sans: 'Inter', ui-sans-serif, system-ui, sans-serif;
  --font-mono: 'JetBrains Mono', ui-monospace, monospace;

  /* Font sizes — modular scale 1.25 */
  --text-xs: 0.75rem;       /* 12px */
  --text-sm: 0.875rem;      /* 14px */
  --text-base: 1rem;        /* 16px */
  --text-lg: 1.125rem;      /* 18px */
  --text-xl: 1.25rem;       /* 20px */
  --text-2xl: 1.5rem;       /* 24px */
  --text-3xl: 1.875rem;     /* 30px */
  --text-4xl: 2.25rem;      /* 36px */
  --text-5xl: 3rem;         /* 48px */

  /* Line heights */
  --leading-none: 1;
  --leading-tight: 1.25;
  --leading-snug: 1.375;
  --leading-normal: 1.5;
  --leading-relaxed: 1.625;
  --leading-loose: 2;

  /* Font weights */
  --font-light: 300;
  --font-regular: 400;
  --font-medium: 500;
  --font-semibold: 600;
  --font-bold: 700;

  /* Letter spacing */
  --tracking-tight: -0.025em;
  --tracking-normal: 0em;
  --tracking-wide: 0.025em;
}
```

Also add to `tailwind.config.js`:

```javascript
theme: {
  extend: {
    fontFamily: {
      sans: ['Inter', 'ui-sans-serif', 'system-ui', 'sans-serif'],
      mono: ['JetBrains Mono', 'ui-monospace', 'monospace'],
    },
  },
},
```

### Step 5: Spacing Scale

```css
:root {
  /* Spacing — based on 4px grid */
  --space-0: 0;
  --space-px: 1px;
  --space-0-5: 0.125rem;   /* 2px */
  --space-1: 0.25rem;      /* 4px */
  --space-1-5: 0.375rem;   /* 6px */
  --space-2: 0.5rem;       /* 8px */
  --space-3: 0.75rem;      /* 12px */
  --space-4: 1rem;         /* 16px */
  --space-5: 1.25rem;      /* 20px */
  --space-6: 1.5rem;       /* 24px */
  --space-8: 2rem;         /* 32px */
  --space-10: 2.5rem;      /* 40px */
  --space-12: 3rem;        /* 48px */
  --space-16: 4rem;        /* 64px */
  --space-20: 5rem;        /* 80px */
  --space-24: 6rem;        /* 96px */

  /* Component-specific spacing */
  --space-card-padding: var(--space-6);
  --space-section-gap: var(--space-8);
  --space-page-margin: var(--space-6);
  --space-input-padding-x: var(--space-4);
  --space-input-padding-y: var(--space-2);
}
```

### Step 6: Border Radius Values

```css
:root {
  --radius-none: 0;
  --radius-sm: 0.25rem;    /* 4px — small elements, tags */
  --radius-md: 0.375rem;   /* 6px — buttons, inputs */
  --radius-lg: 0.5rem;     /* 8px — cards, modals */
  --radius-xl: 0.75rem;    /* 12px — large containers */
  --radius-2xl: 1rem;      /* 16px — hero sections */
  --radius-full: 9999px;   /* pill shapes, avatars */
}
```

### Step 7: Box Shadow Values

```css
:root {
  --shadow-xs: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  --shadow-sm: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px -1px rgba(0, 0, 0, 0.1);
  --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -2px rgba(0, 0, 0, 0.1);
  --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -4px rgba(0, 0, 0, 0.1);
  --shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1);
  --shadow-2xl: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  --shadow-inner: inset 0 2px 4px 0 rgba(0, 0, 0, 0.06);

  /* Colored shadows for elevated interactive elements */
  --shadow-primary: 0 4px 14px 0 rgba(99, 102, 241, 0.3);
  --shadow-error: 0 4px 14px 0 rgba(239, 68, 68, 0.3);
}
```

### Step 8: CSS Custom Properties Summary

Combine all tokens into a single `src/styles/tokens.css` file that includes:
- All CSS custom properties from Steps 4-7
- Dark mode overrides using `[data-theme="dark"]` selector
- Utility classes for common token applications

### Step 9: Output Files

Create the following files:

1. **`tailwind.config.js`** (or update existing) — Merged color palette, DaisyUI themes, font families
2. **`src/styles/tokens.css`** — All CSS custom properties
3. **`src/styles/tokens.ts`** (optional) — TypeScript constants mirroring the tokens for programmatic access

### Step 10: Verification

After generating:
- Verify all color contrast ratios meet WCAG 2.1 AA (4.5:1 for normal text, 3:1 for large text)
- Confirm dark theme has sufficient contrast
- Check that DaisyUI theme keys match the expected DaisyUI API

## Output

```
✅ Design tokens generated
  - tailwind.config.js — color palette + DaisyUI themes + fonts
  - src/styles/tokens.css — CSS custom properties (spacing, radius, shadows, typography)
  - Light theme: [primary color] based
  - Dark theme: [primary color] adjusted for dark surfaces
Next: /design:design-shell to create the app shell layout
```

## Error Recovery

- If `tailwind.config.js` cannot be written, output the full configuration to the chat for manual copy
- If color contrast fails WCAG, suggest adjusted values automatically
- If Google Fonts cannot be resolved, fall back to system font stack
