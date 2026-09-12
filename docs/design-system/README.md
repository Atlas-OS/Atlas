# EBOS Design System

```
EBOS Design System
├── Materials      (7 glass materials + fallback chain)   MATERIALS.md
├── Tokens         (single source of truth)               tokens/liquid-glass.css
├── Components     (reusable glass components)            COMPONENTS.md
├── Motion         (fast/standard/slow/spring/reduced)    tokens + COMPONENTS.md
├── Accessibility  (contrast, transparency, motion)       MATERIALS.md + COMPONENTS.md
└── Quality tiers  (Ultra → Compatibility)                MATERIALS.md
```

Guiding principles:

1. **Centralized** — materials are defined once, in tokens. No duplication.
2. **Adaptive** — light/dark, wallpaper brightness, GPU, battery, DPI, HDR.
3. **Accessible** — Windows accessibility settings always win.
4. **Calm** — glass belongs to shell chrome, not content.
5. **Lightweight** — visual effects must never make the OS feel slower.

The Windows implementation of this system is applied by the playbook
(`src/playbook/Configuration/ui/liquid-glass/`) and managed at runtime by
`EBOS-Glass.ps1` + `EBOS-Taskbar.ps1` (see `docs/TASKBAR.md` and
`docs/LIQUID-GLASS.md`).
