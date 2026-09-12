# EBOS Design System — Components

Reusable EBOS components. Every component consumes
[`tokens/liquid-glass.css`](tokens/liquid-glass.css) tokens only.
Naming is framework-neutral (the current Windows implementation maps
these to registry-driven shell surfaces; web implementations map to
HTML/CSS or XAML equivalents).

| Component | Material | Notes |
|---|---|---|
| `EBOSGlassSurface` | any | base primitive; applies material tokens, fallback chain |
| `EBOSGlassPanel` | Tinted | grouped content container (Quick Settings groups) |
| `EBOSGlassCard` | Dense | information card (dashboard tiles) |
| `EBOSGlassButton` | Interactive | hover brightness +0.06, pressed scale 0.97, focus ring = accent |
| `EBOSGlassToggle` | Interactive | state change via tint + accent thumb, 120 ms |
| `EBOSGlassMenu` | Elevated | menus, context menus |
| `EBOSGlassPopover` | Elevated | anchored, arrow-less, radius-lg |
| `EBOSGlassToolbar` | Floating | floating toolbars |
| `EBOSGlassSidebar` | Dense | navigation sidebar |
| `EBOSGlassDialog` | Dense | modal dialogs, scrim = 40% black |
| `EBOSGlassTooltip` | Floating | 80 ms fast motion, no interaction states |
| `EBOSGlassTaskbar` | Regular/Clear | see docs/TASKBAR.md |
| `EBOSGlassStartMenu` | Dense | floating surface, subtle depth |
| `EBOSGlassQuickSettings` | Tinted | grouped surfaces — not a grid of glass rectangles |
| `EBOSGlassControlCenter` | Tinted | primary/secondary/tertiary hierarchy |

## Interaction states

```
Normal    baseline tokens
Hover     brightness +0.06, tint +0.03, shadow-1
Pressed   brightness -0.04, scale 0.97, 80 ms
Focused   accent focus ring (2px, offset 2px) — never removed
Selected  accent tint 0.12 + check indicator
Disabled  opacity 0.38, no pointer events, keep focus for a11y
Active    persistent selected state + accent rim
```

All motion uses the `--ebos-motion-*` tokens; under reduced motion,
transform/scale/morph animations collapse to opacity cross-fades.

## Accessibility contract

- Keyboard navigation + visible focus indicators on every interactive component
- Screen-reader semantics preserved (glass is visual only)
- High contrast / increased contrast / reduced transparency / reduced motion
  collapse glass per the fallback chain — **transparency is never forced**
- DPI-aware sizing: components scale with 100–200% scaling; taskbar sizes
  (small/default/large) are DPI-relative

## Iconography

Consistent optical size, spacing, alignment and stroke weight. Glass
effects are **not** applied to icons themselves.
