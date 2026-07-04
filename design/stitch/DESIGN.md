---
name: Elite Tactical Grid
colors:
  surface: '#121416'
  surface-dim: '#121416'
  surface-bright: '#37393b'
  surface-container-lowest: '#0c0e10'
  surface-container-low: '#1a1c1e'
  surface-container: '#1e2022'
  surface-container-high: '#282a2c'
  surface-container-highest: '#333537'
  on-surface: '#e2e2e5'
  on-surface-variant: '#c2c9bb'
  inverse-surface: '#e2e2e5'
  inverse-on-surface: '#2f3133'
  outline: '#8c9387'
  outline-variant: '#42493e'
  surface-tint: '#a1d494'
  primary: '#a1d494'
  on-primary: '#0a3909'
  primary-container: '#2d5a27'
  on-primary-container: '#9dd090'
  inverse-primary: '#3b6934'
  secondary: '#ffffff'
  on-secondary: '#283500'
  secondary-container: '#c3f400'
  on-secondary-container: '#556d00'
  tertiary: '#e9c349'
  on-tertiary: '#3c2f00'
  tertiary-container: '#cca730'
  on-tertiary-container: '#4f3d00'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#bcf0ae'
  primary-fixed-dim: '#a1d494'
  on-primary-fixed: '#002201'
  on-primary-fixed-variant: '#23501e'
  secondary-fixed: '#c3f400'
  secondary-fixed-dim: '#abd600'
  on-secondary-fixed: '#161e00'
  on-secondary-fixed-variant: '#3c4d00'
  tertiary-fixed: '#ffe088'
  tertiary-fixed-dim: '#e9c349'
  on-tertiary-fixed: '#241a00'
  on-tertiary-fixed-variant: '#574500'
  background: '#121416'
  on-background: '#e2e2e5'
  surface-variant: '#333537'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '800'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
  title-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  container-margin: 20px
  gutter: 16px
---

## Brand & Style

The design system is engineered for a premium strategic sports experience, blending the precision of high-end productivity tools with the high-energy atmosphere of modern football broadcasting. The brand personality is **Smart**, **Premium**, and **Competitive**, targeting users who appreciate deep mechanics presented through a clean, modern lens.

The aesthetic direction is a hybrid of **Corporate Modern** (structured, reliable) and **Glassmorphism** (depth through transparency). It draws inspiration from the utility of the Human Interface Guidelines, the systematic approach of Material 3, and the bold, immersive presentation of elite sports gaming interfaces. The goal is to evoke a "Tactical War Room" feeling—sophisticated, focused, and data-driven, yet undeniably athletic.

## Colors

This design system utilizes a high-contrast palette designed for legibility and atmospheric immersion.

### Dark Theme (Primary)
The foundation is a **Deep Pitch Green** (#0A1A0A), providing a cinematic backdrop that feels more organic than pure black. Surfaces use **Dark Graphite** (#1A1C1E) to create structural separation. The **Electric Lime** (#CCFF00) is reserved for high-priority actions, notifications, and critical game-state indicators, cutting through the dark tones with maximum vibrance.

### Light Theme
The light mode transitions to a **Soft Mint** (#F0F7F0) environment, maintaining the football DNA while ensuring comfort during daytime play. Surfaces shift to warm neutral whites to preserve the premium feel.

### Specialized Tones
- **Rare/Legendary:** A duo of Gold and Purple is used exclusively for high-tier achievements, rare player cards, or premium unlocks.
- **Semantic Colors:** Standard success/error states should lean into the Primary Green for "Go/Success" and a sharp Ruby for "Stop/Error."

## Typography

The typography system relies on **Inter** for its exceptional legibility and systematic, neutral appearance. 

- **Display & Headlines:** Use heavy weights (Bold/ExtraBold) with slight negative letter-spacing to mimic sports headlines and broadcast graphics.
- **Caps Labels:** Use uppercase with increased tracking for secondary metadata, such as player positions or tactical categories, to give them a "pro-tool" aesthetic.
- **Hierarchy:** Maintain a clear distinction between interactive labels and informative body text through weight variance rather than just size.

## Layout & Spacing

The layout utilizes a **Fluid Grid** model based on a 4px baseline shift. 

- **Mobile:** A 4-column grid with 20px side margins.
- **Desktop/Tablet:** A 12-column centered grid with a maximum content width of 1200px.
- **Rhythm:** Spacing follows a geometric progression (4, 8, 16, 24, 32). Use 16px (md) for most internal component padding and 24px (lg) for vertical section spacing to maintain the "Minimal" brand promise and allow the UI to breathe.

## Elevation & Depth

Depth is communicated through **Tonal Layering** and **Glassmorphism**, avoiding traditional heavy shadows in favor of modern translucency.

- **Level 0 (Background):** The deep green pitch color.
- **Level 1 (Surfaces):** Dark Graphite with a subtle 1px inner stroke (10% white) to define edges.
- **Level 2 (Modals/Overlays):** Semi-transparent graphite with a 20px backdrop blur (Glassmorphism). This keeps the game field visible even when navigating menus.
- **Shadows:** When used, shadows should be "Ambient"—very large blur radius (32px+), low opacity (15-20%), and slightly tinted with the primary green to feel integrated into the environment.

## Shapes

The shape language is defined by **large, friendly radii** that soften the competitive edge of the game, making it feel premium and accessible.

- **Standard Elements:** Buttons and small cards use a 16px (rounded-lg) radius.
- **Main Containers:** Large game boards and feature cards use a 24px+ (rounded-xl) radius to align with the "smooth" aesthetic requested.
- **Interactive States:** On hover or press, shapes do not change their radius, but may receive a subtle scale-down effect (98%) to simulate tactile feedback.

## Components

### Buttons
- **Primary:** Electric Lime background with Black text. Bold weight. 16px corner radius.
- **Secondary:** Dark Graphite with a 1px border of Primary Green.
- **Tactical:** Ghost buttons (no fill) with uppercase labels for minor actions.

### Cards (The "Grid" Elements)
- **Standard Card:** Dark Graphite fill, 24px corner radius, subtle 4% white inner glow at the top edge.
- **Legendary Card:** Gradient border (Gold to Purple) with a very subtle animated shimmer effect.

### Inputs & Selection
- **Fields:** Subtle dark background with a 2px bottom-border highlight in Electric Lime when focused.
- **Chips:** Pill-shaped (rounded-full) elements used for filtering player attributes or league types.

### Lists
- Use "Inset" style lists with rounded corners for the entire group rather than individual rows. Dividers should be low-contrast (5% white).

### Progress Indicators
- Linear bars using a gradient of Primary Green to Electric Lime to indicate "energy" or "completion."