# EBOS Liquid Glass

Liquid Glass is the EBOS material system: layered, translucent surfaces
with depth, subtle optics and strict readability guarantees — **not**
generic glassmorphism.

- Canonical tokens: [`design-system/tokens/liquid-glass.css`](design-system/tokens/liquid-glass.css)
- Material specs: [`design-system/MATERIALS.md`](design-system/MATERIALS.md)
- Component specs: [`design-system/COMPONENTS.md`](design-system/COMPONENTS.md)

## Composition

```
Background → Depth → Blur → Translucency → Tint → Optical Effect
→ Specular Highlight → Rim → Shadow → Interaction
```

Not every surface is transparent: glass is reserved for shell chrome
(taskbar, Start, Quick Settings, Control Center, menus, popovers,
dialogs, floating panels). Content areas stay calm.

## On Windows

The playbook ships two tasks (`ui\liquid-glass\`):

1. **enable-glass-materials.yml** — enables the Windows transparency
   pipeline (`EnableTransparency`) the glass surfaces build upon
2. **glass-quality-auto.yml** — `EBOS-Glass.ps1 -Auto` selects the
   quality tier from the EBOS Core hardware report

Runtime control:

```powershell
& $env:WINDIR\EBOSModules\Core\EBOS-Glass.ps1 -Status
& $env:WINDIR\EBOSModules\Core\EBOS-Glass.ps1 -Auto      # recommended
& $env:WINDIR\EBOSModules\Core\EBOS-Glass.ps1 -Quality High
```

or from `EBOS → 0. EBOS Core → Liquid Glass Quality.cmd`.

## Quality tiers

| Tier | Stack | Chosen when |
|---|---|---|
| Ultra | refraction + blur + specular + rim | high-end GPU, AC power |
| High | blur + highlight + rim | discrete GPU |
| Balanced | blur + rim | default (integrated GPU) |
| Performance | translucency only | battery saver |
| Compatibility | opaque | reduced transparency/motion, weak GPU |

## Adaptive behavior

- **Light/dark**: dark wallpaper → brighter rim, readable text; bright
  wallpaper → stronger tint
- **GPU**: too expensive → reduce refraction → blur → animation → simpler
  material
- **Battery**: battery saver → step down one level; restored afterwards
- **DPI / HDR**: tokens scale; HDR-capable surfaces use wider gamuts
  where supported

## Accessibility contract

Windows is the source of truth. If reduced transparency is requested,
Liquid Glass collapses to the simplified (opaque) material — never
forced. High contrast removes glass entirely. Reduced motion collapses
movement while preserving opacity-based feedback. Typography never drops
below the contrast thresholds defined in the tokens.

## Fallback chain

```
Refraction → Blur + Highlight → Translucency → Opaque
```
