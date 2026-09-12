# EBOS Liquid Glass — Material Specifications

Every EBOS surface is built from exactly one of the materials below.
Materials are defined **only** by the tokens in
[`tokens/liquid-glass.css`](tokens/liquid-glass.css) — components never
re-define material properties.

## Conceptual composition

```
Background
   ↓
Depth            (layering, elevation)
   ↓
Blur             (backdrop-filter)
   ↓
Translucency     (opacity)
   ↓
Tint             (adaptive: dark over bright wallpapers, light over dark)
   ↓
Optical Effect   (saturation / brightness lift)
   ↓
Specular Highlight (directional, subtle — communicates curvature)
   ↓
Rim              (edge lighting that separates glass from environment)
   ↓
Shadow           (elevation cue)
   ↓
Interaction      (hover / pressed / focused / selected states)
```

Not every surface is glass. Content areas stay visually calm — glass is
reserved for the shell chrome listed in [CONTEXTUAL GLASS](#contextual-glass).

## The seven EBOS materials

| Material | Purpose | Blur | Opacity | Rim | Sheen | Shadow |
|---|---|---|---|---|---|---|
| **Glass Clear** | Overlay surfaces meant to maximize environment visibility (taskbar on light wallpapers) | ●●● | 0.40 | subtle | none | 1 |
| **Glass Regular** | Default surface material — taskbar, flyouts | ●●● | 0.55 | ● | ● | 1–2 |
| **Glass Tinted** | Readability-first surfaces over busy backgrounds (Quick Settings, Control Center) | ●●● | 0.65 | ● | ● | 2 |
| **Glass Dense** | Information-dense surfaces (Start menu, dialogs) | ●● | 0.78 | ● | none | 2 |
| **Glass Elevated** | Floating panels above other glass (popovers, menus) | ●●● | 0.60 | ● | ● | 3 |
| **Glass Floating** | Detached, movable surfaces (tooltips' parents, floating toolbars) | ●●● | 0.50 | ● | ● | 3 |
| **Glass Interactive** | Buttons, toggles, list rows — reacts to pointer | ● | 0.45 | ● | on hover | 1 |

● = on, ●● / ●●● = increasing intensity, mapped through quality tiers.

## Fallback chain

```
Refraction (edge-biased distortion)
   ↓ unsupported / too expensive / Compatibility tier
Blur + Highlight
   ↓ blur disabled or Performance tier
Translucency
   ↓ reduced transparency requested (accessibility) or Compatibility tier
Opaque
```

`EBOS-Glass.ps1` enforces this chain on Windows; `tokens/liquid-glass.css`
expresses the same chain with `data-ebos-*` attributes for web surfaces.

## Contextual glass

**Glass is used on:** Taskbar · Start menu · Quick Settings · Control
Center · navigation · toolbars · menus · popovers · dialogs · floating
panels · tooltips.

**Glass is never used on:** document content · code editors · media
viewers · settings detail panes · tables · terminal output.

## Specular highlights & rims

- Highlights are **directional and subtle** (top-left light source);
  they communicate curvature and surface, never "glow".
- Rims separate glass from the environment at `--ebos-glass-rim-strength`
  (0.35 light / 0.45 dark). If a rim reads as a glowing border, it is
  wrong.

## Quality tiers

| Tier | Stack | When |
|---|---|---|
| Ultra | refraction + blur + specular + rim | discrete GPU, AC power, no accessibility limits |
| High | blur + highlight + rim | capable dGPU/iGPU |
| Balanced | blur + rim | **recommended default** |
| Performance | translucency only | low-end GPU or battery saver |
| Compatibility | opaque | reduced transparency/motion, or GPU too weak |

`EBOS-Glass.ps1 -Auto` selects the tier from the EBOS Core hardware
report; users override with `-Quality <tier>` or the dashboard.
