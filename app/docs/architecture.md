# Atlas Manager architecture

This page explains how Atlas Manager's source is organised, how its model runs background work, how it handles Atlas packages, and how its tests reach the model.
It's for contributors who change the app's code.

## Framework

Atlas Manager is written in Rust on [GPUI](https://github.com/zed-industries/zed/tree/main/crates/gpui), Zed's GPU-accelerated UI framework.
It's pinned to the `gpui-pre` crates.io snapshot and uses no component library.
`src/ui` draws Windows 11 Fluent controls (Mica, Segoe UI Variable, Segoe Fluent Icons and WinUI colour tokens), so the window looks native and has Windows' accessible roles, names and keyboard behaviour ([accessibility](accessibility.md)).

The text box adapts Zed's GPUI input example, under the Apache License 2.0 (`licenses/GPUI-input-APACHE-2.0.txt`).
The vendored GPUI crates and AccessKit's Windows adapter carry Atlas changes, each described in its `ATLAS-PATCH.md`:

- [`gpui-pre`](../vendor/gpui-pre/ATLAS-PATCH.md): line breaking, accessibility states and the completion background tag.
- [`gpui-pre-windows`](../vendor/gpui-pre-windows/ATLAS-PATCH.md): the completion page shader and precompiled shaders for Linux builds.
- [`accesskit_windows`](../vendor/accesskit_windows/ATLAS-PATCH.md): heading levels.

## Layout

```text
src/
  main.rs         window options (Mica, custom title bar, icon), key bindings
  cli.rs          command-line flags
  platform.rs     builds the GPUI application on the Windows backend
  shell.rs        title bar with the settings gear, one content layer, theme, focus traversal, close guard
  model.rs        AppModel: all state and the background tasks it owns; model/ holds it by concern,
                  and model/tests/ drives it headless on model/test_harness.rs
  environment.rs  what the model needs from the process: paths, machine adapters, restart timing
  flow.rs         the install flow's state machine: steps, run state, allowed transitions
  theme.rs        Fluent tokens for light, dark and contrast themes, Atlas blue accent
  assets.rs       SVGs and the window icon compiled into the binary
  i18n/           language choice, message lookup (t!), words for semantic state,
                  regional formatting, catalog checks
  ui/             Fluent controls: Button, card, InfoBar, RadioGroup, CheckBox,
                  ComboBox, ToggleSwitch, TextInput, ProgressBar, ProgressRing,
                  StatusLight, tooltips, ContentDialog (the window's prompts),
                  TitleBar, Scrollbar, release-note Markdown
  pages/          Home (status, what's new, the install button), Install (install/,
                  4 steps), Installing, Installed, ISO, USB, Send a report, Settings,
                  and the shared stepper and footer
  services/       Windows-facing code with no UI dependency: system, atlas_state,
                  security, requirements, windows_release, windows_installation,
                  releases, playbook, embedded, preparation, recovery_app,
                  installer, session, settings, registry, locale, iso, usb, desktop_setup,
                  diagnostics (and its redaction), reports, licenses
resources/        icon and version resource; iso/ (ISO, USB and destination
                  setup scripts) and prepare/ (protected staging helper)
i18n/<tag>/atlas.ftl   one Fluent message catalog per available language (en-GB is the source)
examples/         i18n_spike, the GPUI rendering probe for right-to-left, CJK and mixed scripts
licenses/         third-party notices and the dependency inventory
vendor/           the patched GPUI crates and AccessKit's Windows adapter
tools/            release build, notices, measurement and review scripts
```

## The model and background tasks

`AppModel` in `src/model.rs` holds all of the app's state and owns its background tasks.
Pages are thin views over it, and it notifies them when it changes.

- Slow work (HTTP, Windows Update, WMI, extraction and the installer launch) runs on GPUI's background executor and reports back through the model.
- Each model-owned task carries a generation.
  Cancelling or repeating an operation drops the old task, and a late result from it never lands in newer state.
- `src/flow.rs` holds the install flow's state machine.
  Every route in the UI goes through its transitions, which refuse what a running install forbids, so no button can edit, leave or restart a running install.
- `AppModel::locked` covers the flow and the other work that holds an install: an ISO or USB job, Windows preparation, and putting Windows Update settings back.
  Actions that change anything feeding an install refuse while it's true.
- The model stores values and causes, never interface text.
  `src/i18n/describe.rs` words them at render time, so a language switch re-words everything on screen ([languages](i18n.md)).
- The Windows Update, Security Center and licensing queries behind the checks time out instead of hanging, with at most one worker each (`Bounded` in `src/services/requirements/`).

`src/environment.rs` holds what the model takes from its process: the app data paths, whether it checks GitHub, timings and the machine adapters.
Each adapter is a plain function, such as reading Windows Security or scheduling a restart, so a test can substitute one without a trait for each service.

## Releases and packages

- The app reads `%windir%\AtlasOS\state.json` (the installed version, mode, options and history) but never writes it; the Atlas package's PowerShell modules own it.
- The GitHub releases API supplies the latest release.
  Versions compare as Atlas tags them, so `0.5.0-hotfix` is newer than `0.5.0`.
- Downloads go to `%LOCALAPPDATA%\AtlasOS\App\Downloads`, and the app trusts one only once it matches the asset's size and published digest.
- Packages unpack through a private staging directory into an immutable `...\App\Playbooks\<version>_<digest>` folder (`src/services/playbook.rs`).
  A bad package never replaces a good one, and two packages that both claim the same version never share a folder.
- Atlas Manager installs only packages that include the front door, `Entry\Install-Atlas.ps1`: Atlas 0.6.0 and later.
  It refuses older packages and says which versions it installs.

The front door is the script in the Atlas package that Atlas Manager runs to install Atlas ([the front door](../../docs/front-door.md)).
[The install flow](install-flow.md) covers how the app runs it.

## Tests

- Unit tests sit beside the code they cover, in services, pages, the language catalogs and the flow.
- The model tests in `src/model/tests/` run the real model in headless GPUI with controlled adapters for elevation, Windows Security, the checks and restart commands, and a real Windows PowerShell child running a stub front door.
  They cover the final security decision, recovering installs that finished while the app was closed, retrying a recovered failure and the restart countdown's timer ownership.
- The catalog gate in `src/i18n/checks.rs` checks every catalog and every `t!` call ([languages](i18n.md)).
- With `--features embedded-playbook`, the tests also unpack a bundled LocalTest Atlas package into a temporary folder ([development](development.md#ci)).

[Development](development.md) covers how to run them.
