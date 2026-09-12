# Attribution & Third-Party Licenses

EBOS is an open-source project licensed under
[CC BY-SA 4.0](../LICENSE).

## Integrated projects

This repository **unifies two legacy projects** into one platform:

1. **ReviOS / Revision playbook** ([meetrevision/playbook](https://github.com/meetrevision/playbook)),
   licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
   Its task set (registry configurations, service lists, package
   removal, wallpaper/theme tooling) was restructured into the EBOS
   domain architecture and, where it depended on the closed
   `revitool.exe` companion, replaced with native implementations.
   Credit for those components goes to the
   [Revision team](https://github.com/meetrevision). In accordance with
   the ShareAlike license, this repository is licensed CC BY-SA 4.0.

2. **Atlas OS playbook** ([Atlas-OS/Atlas](https://github.com/Atlas-OS/Atlas)),
   licensed under CC BY-SA 4.0. Its playbook structure, debloat task
   set, signed component-removal packages (sxsc), EBOS folder concept
   and utilities form the base of the EBOS Windows domain.
   Credit goes to the [Atlas team](https://github.com/Atlas-OS).

Upstream issue links remain in the source as factual technical
references.

## Bundled third-party components

Verified binary components and their licenses are listed in
`src/playbook/Executables/EBOSModules/README.md` (SHA-256 hashes,
sources, verification dates). License texts are preserved in
`src/playbook/Executables/Licenses/` and the `Acknowledgements` folder,
including:

- Brave Browser (MPL) — `brave-browser-mpl.txt`
- Fluent GTK theme (GPL-3.0) — `fluent-gtk-theme-gnu-gpl-v3.0.txt`
- ViVeTool (GPL-3.0, thebookisclosed) — see EBOSModules README
- SetTimerResolution / MeasureSleep (GPL-3.0, deaglebullet)
- multichoice (GPL-3.0)

## Design system

The Liquid Glass design language is an original EBOS specification
inspired by modern translucent-material design systems. No
platform-specific third-party code is used; the tokens in
`docs/design-system/` are the canonical definition.
