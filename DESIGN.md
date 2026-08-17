---
name: Pohjola Architectural Nordic
colors:
  primary: "#047857"
  on-primary: "#FFFFFF"
  secondary: "#18181B"
  on-secondary: "#FFFFFF"
  tertiary: "#0F766E"
  on-tertiary: "#FFFFFF"
  neutral: "#FAFAFA"
  surface: "#FFFFFF"
  on-surface: "#09090B"
  error: "#DC2626"
  on-error: "#FFFFFF"
typography:
  headline-display:
    fontFamily: Inter, sans-serif
    fontSize: 56px
    fontWeight: 800
    lineHeight: 1.05
  headline-lg:
    fontFamily: Inter, sans-serif
    fontSize: 36px
    fontWeight: 700
    lineHeight: 1.15
  headline-md:
    fontFamily: Inter, sans-serif
    fontSize: 24px
    fontWeight: 700
    lineHeight: 1.25
  body-lg:
    fontFamily: Inter, sans-serif
    fontSize: 18px
    fontWeight: 400
    lineHeight: 1.6
  body-md:
    fontFamily: Inter, sans-serif
    fontSize: 15px
    fontWeight: 400
    lineHeight: 1.5
  body-sm:
    fontFamily: Inter, sans-serif
    fontSize: 13px
    fontWeight: 400
    lineHeight: 1.5
  label-md:
    fontFamily: JetBrains Mono, monospace
    fontSize: 12px
    fontWeight: 600
    lineHeight: 1
rounded:
  sm: 4px
  md: 6px
  lg: 10px
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
    rounded: "{rounded.sm}"
    padding: "{spacing.xs}"
  alert-error:
    backgroundColor: "{colors.error}"
    textColor: "{colors.on-error}"
    rounded: "{rounded.md}"
    padding: "{spacing.md}"
---

## Overview

Pohjola is a sharp, architectural Nordic design system engineered for high-performance server-rendered web applications. It embodies structural precision, high-contrast monochrome surfaces, deep pine-green accents, hairline grid structures, and technical monospace metadata.

## Colors

Primary (#047857): Deep Nordic Pine. Reserved strictly for the single primary call-to-action on any screen. Never used for generic backgrounds.

Secondary (#18181B): Obsidian black. Used for high-contrast inverted cards, secondary interactive triggers, and dark surface containers.

Tertiary (#0D9488): Glacial teal accent for active indicator tags, badge highlights, and subtle focus cues.

Neutral (#FAFAFA): Clean chalk-white page canvas ensuring calm, crisp contrast (Dark: #09090B).

Surface (#FFFFFF): Pure white architectural card panels with sharp 1px borders (Dark: #121215).

On-Surface (#09090B): Deep obsidian ink for text and headlines ensuring maximum WCAG AAA legibility.

Error (#DC2626): Pure accessible crimson for validation errors, destructive actions, and alerts.

## Typography

Pohjola pairs **Inter** for editorial display headlines with **JetBrains Mono** for technical metadata, tags, and code telemetry.

- Display Headlines: Heavyweight (700/800), tight tracking (`tracking-tighter` / `-0.03em`), and tight line-height (`1.05-1.15`).
- Body Copy: Balanced at 1.5 line height, high readability.
- Monospace Telemetry: `text-xs font-mono uppercase tracking-widest` for status badges, indexes, and technical indicators.

## Layout

Layout follows a strict **Architectural Grid**:
- Standard Container: `max-w-7xl` with 16px mobile / 32px desktop padding.
- Grid Separators: Crisp 1px hairline borders (`border-zinc-200 dark:border-zinc-800`).
- Section Spacing: Generous vertical rhythm (`py-16` to `py-24`).

## Elevation & Depth

No soft blurry drop-shadows. Depth is created through **hairline border rings, crisp 1px borders, and tonal layering**:
- Level 0 (Canvas): `#FAFAFA` (Dark: `#09090B`)
- Level 1 (Card): `#FFFFFF` with `border border-zinc-200 dark:border-zinc-800` (Dark: `#121215`)
- Level 2 (Dock / Terminal): `#18181B` with `border border-zinc-700`

## Shapes

Shapes are engineered and crisp:
- Buttons and inputs: 6px (`rounded-md`)
- Cards and content panels: 10px (`rounded-lg`)
- Badges and indicators: 4px (`rounded-sm`) or 9999px pill

## Components

All views MUST use typed primitives from `App.Ui`:
* `App.Ui.Button`: High-contrast, tactile buttons (`Primary`, `Secondary`, `Outline`, `Ghost`, `Inverted`).
* `App.Ui.Card`: Structured architectural cards with razor-thin borders.
* `App.Ui.Badge`: Monospace pill/tag indicators.
* `App.Ui.Stat`: Hairline metric blocks for telemetry and invariant guarantees.
* `App.Ui.Alert`: Structured ARIA status banners.
* `App.Ui.EmptyState`: Technical blueprint empty states.

## Do's and Don'ts

- DO: Keep one single primary CTA per page view.
- DO: Use monospace telemetry tags (`01 / TOTALITY`, `SYSTEM: READY`) for technical context.
- DO: Rely on razor-sharp 1px borders and tonal contrast for layout structure.
- DON'T: Use blurry gradient blobs, pastel cards, or generic dashboard pill badges.
- DON'T: Assemble raw 20-class Tailwind utility chains outside `App.Ui`.
