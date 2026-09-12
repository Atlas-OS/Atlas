# EBOS Taskbar — Windows 11 Experience

The EBOS taskbar keeps the native Windows 11 shell (no shell
replacement, no injected DLLs, no background process) and layers the
EBOS experience on top via supported registry configuration and the
Liquid Glass material system.

> Core promise: **never destabilize Explorer.** Every change is
> reversible, captured in a change-set, and protected by an automatic
> Explorer-recovery loop.

## Layout

| Setting | Values | Where |
|---|---|---|
| Alignment | **centered** (default) / left | `EBOS-Taskbar.ps1 -Align center\|left` |
| Size | small / **default** / large | `-Size small\|default\|large` (`TaskbarSi`) |
| Multi-monitor | all monitors / primary only | `-MultiMonitor on\|off\|primary` (`MMTaskbarEnabled`) |
| Per-monitor alignment | follows global + `MMTaskbarAl` | automatic |

Sizes are DPI-relative: they scale at 100/125/150/175/200% and on
high-resolution/ultrawide monitors. Monitor hot-plug, rearrangement,
rotation and reconnect are handled by the native shell — no polling.

## Elements

Start button · Search · pinned apps · active indicators · system tray
(Wi-Fi, volume, battery, Bluetooth) · notifications · clock.

Element toggles live in the EBOS folder
(`4. Interface Tweaks → Taskbar Styling`): task view, widgets,
Copilot/chat, news & interests, meet-now, tablet mode, desktop peek.

## Materials & appearance

| Mode | Meaning |
|---|---|
| Clear Glass | maximum environment visibility |
| Tinted Glass | readability-first (default via Balanced tier) |
| Dark / Light Glass | theme-locked variants |
| Automatic Glass | follows Windows light/dark + accent |
| Opaque fallback | reduced transparency or Compatibility tier |

Windows automatic theme, the system accent color, adaptive contrast and
readable typography (see the design system) are respected.

## Interaction & accessibility

Hover/active/pressed/focused/selected/notification states use the
motion tokens (`--ebos-motion-fast` etc.). Reduced motion collapses
transform animations to opacity changes. High contrast and reduced
transparency collapse glass to opaque surfaces. Keyboard navigation and
focus indicators are provided by the native shell.

## Performance rules

No background processes, services, scheduled tasks, polling loops or
network communication are created for the taskbar. Visual effects step
down automatically (GPU class, battery saver).

## Recovery

```
Explorer failure detected
   ↓ restart Explorer safely
validate taskbar
   ↓ if failure
roll back last EBOS taskbar modification (captured change-set)
   ↓ restart Explorer
validate
```

Implemented in `EBOS-Taskbar.ps1` (`Restart-EBOSTaskbarSafe`).

## Reset

```
EBOS-Taskbar.ps1 -Reset     # restore Windows defaults
EBOS-Glass.ps1 -Quality Balanced   # restore default material
```

Resets affect only taskbar/appearance settings — unrelated
optimizations are untouched.
