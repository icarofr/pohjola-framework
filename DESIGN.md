---
name: Pohjola Nordic
colors:
  primary: "#047857"
  on-primary: "#FFFFFF"
  secondary: "#4B5563"
  on-secondary: "#FFFFFF"
  tertiary: "#0F766E"
  on-tertiary: "#FFFFFF"
  neutral: "#F9FAFB"
  surface: "#FFFFFF"
  on-surface: "#111827"
  error: "#DC2626"
  on-error: "#FFFFFF"
typography:
  headline-display:
    fontFamily: Inter, sans-serif
    fontSize: 48px
    fontWeight: 700
    lineHeight: 1.1
  headline-lg:
    fontFamily: Inter, sans-serif
    fontSize: 32px
    fontWeight: 600
    lineHeight: 1.2
  headline-md:
    fontFamily: Inter, sans-serif
    fontSize: 24px
    fontWeight: 600
    lineHeight: 1.3
  body-lg:
    fontFamily: Inter, sans-serif
    fontSize: 18px
    fontWeight: 400
    lineHeight: 1.6
  body-md:
    fontFamily: Inter, sans-serif
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.5
  body-sm:
    fontFamily: Inter, sans-serif
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.5
  label-md:
    fontFamily: Inter, sans-serif
    fontSize: 14px
    fontWeight: 500
    lineHeight: 1
rounded:
  sm: 4px
  md: 8px
  lg: 16px
  full: 9999px
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  2xl: 48px
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.md}"
    padding: "{spacing.sm}"
  button-secondary:
    backgroundColor: "{colors.secondary}"
    textColor: "{colors.on-secondary}"
    rounded: "{rounded.md}"
    padding: "{spacing.sm}"
  card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.lg}"
    padding: "{spacing.lg}"
  canvas:
    backgroundColor: "{colors.neutral}"
    textColor: "{colors.on-surface}"
  badge:
    backgroundColor: "{colors.tertiary}"
    textColor: "{colors.on-tertiary}"
    rounded: "{rounded.full}"
    padding: "{spacing.xs}"
  alert-error:
    backgroundColor: "{colors.error}"
    textColor: "{colors.on-error}"
    rounded: "{rounded.md}"
    padding: "{spacing.md}"
---

## Overview

Pohjola is an opinionated, minimalist Nordic design system built for high-performance server-rendered web applications. It emphasizes natural clarity, functional hierarchy, high contrast legibility, and zero visual clutter.

## Colors

Primary (#047857): Deep Nordic pine green used strictly for the single primary call-to-action on any screen. Never use for generic background decoration.

Secondary (#4B5563): Slate gray used for secondary actions, borders, and supportive metadata.

Tertiary (#0F766E): Nordic deep teal reserved for active badges, highlights, and subtle focus cues.

Neutral (#F9FAFB): Crisp off-white canvas background ensuring calm contrast without blinding brightness.

Surface (#FFFFFF): Pure white surface cards for elevated containers and content panels.

On-Surface (#111827): Near-black ink for headlines, body copy, and primary readable text.

Error (#DC2626): Pure accessible red reserved for validation errors, destructive confirmations, and critical alerts.

## Typography

The typography is built entirely on **Inter** to ensure geometric rhythm and high legibility at all screen sizes.

Headlines use tight negative tracking (`-0.02em`) with strong weight (600/700) to establish instant focal points. Body text is balanced at 1.5 line height for effortless scanning.

## Layout

The layout uses a fluid container with a maximum width of 1280px (`max-w-7xl`). All layout rhythm conforms to a strict **8px grid** (with a 4px micro-scale).

Container spacing rules:
- Page container padding: 16px mobile (`sm`), 32px desktop (`xl`).
- Grid gaps: 24px (`lg`) between primary cards, 16px (`md`) between form elements.

## Elevation & Depth

Visual hierarchy is communicated through **tonal layering and subtle 1px border rings** rather than heavy drop shadows.

- Layer 0 (Canvas): `#F9FAFB` (Dark: `#0B0F17`)
- Layer 1 (Card / Surface): `#FFFFFF` with `ring-1 ring-gray-200` (Dark: `#111827` with `ring-white/10`)
- Layer 2 (Modal / Popover): Elevated with `shadow-lg ring-1 ring-gray-300`

## Shapes

Shapes are strictly geometric with purposeful rounding:
- Inputs and buttons: 8px (`rounded-md`)
- Cards and content panels: 16px (`rounded-lg`)
- Badges and pills: 9999px (`rounded-full`)

Never mix arbitrary rounding values (e.g. `rounded-[22px]`).

## Components

All UI generation MUST use pre-composed component primitives from `App.Ui`:

* **Buttons (`App.Ui.Button`)**: `Primary` (Emerald CTA), `Secondary` (Slate border), `Outline`, `Ghost`.
* **Cards (`App.Ui.Card`)**: Surface container with standardized padding, 16px radius, and subtle border ring.
* **Badges (`App.Ui.Badge`)**: Pill-shaped status indicators with semantic color mappings.
* **Alerts (`App.Ui.Alert`)**: Structured error and notification boxes with role="alert" or role="status".
* **Modals (`App.Ui.Modal`)**: Accessible dialogs with focus traps, escape-key dismiss, and backdrop blur.
* **Accordions & Tabs (`App.Ui.Accordion`, `App.Ui.Tabs`)**: Accessible ARIA-compliant expandable views.

## Do's and Don'ts

- DO: Limit each view to ONE primary button variant (`Primary`).
- DO: Use semantic component constructors from `App.Ui` instead of writing raw Tailwind strings.
- DO: Maintain WCAG AA contrast (minimum 4.5:1 for body text, 3:1 for large text).
- DON'T: Create decorative gradients, pulse pills, or icon-stuffed bento boxes without user purpose.
- DON'T: Use arbitrary custom CSS classes or inline pixel values.
