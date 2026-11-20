# Contributing to Atlas

This guide is for anyone who wants to improve Atlas.
It covers the ways to help, the tools you need, where things live and what a pull request needs.
For an overview of taking part, see [Contributing](https://atlasos.net/docs/contributing/) in the Atlas documentation.

## Ways to contribute

- **Bug reports:** use the [bug report form](https://github.com/Atlas-OS/Atlas/issues/new?template=bug_report.yml), and attach a diagnostics ZIP from Atlas Manager.
- **Feature requests:** use the [feature request form](https://github.com/Atlas-OS/Atlas/issues/new?template=feature_request.yml).
- **Documentation:** the user documentation at [atlasos.net/docs](https://atlasos.net/docs/) lives in the [website repository](https://github.com/Atlas-OS/website), so open documentation issues and pull requests there.
  Developer documentation lives in this repository, under [`docs/`](../docs/README.md).
- **Translations:** Atlas Manager's catalogs live in [`app/i18n`](../app/i18n), and the [translation guidance](../app/docs/translating.md) explains the conventions.
- **Code:** open a pull request against `main`.
  For a larger change, open an issue or a discussion first so you can agree the approach before you build it.

To report a security vulnerability, follow the [security policy](SECURITY.md) instead of opening an issue.

## Prerequisites

| Tool | Needed for |
| --- | --- |
| PowerShell 7 (`pwsh`) | The build tools, the build tests and linting |
| 7-Zip or NanaZip on `PATH` | Creating the `.apbx` archive |
| Windows PowerShell 5.1, built into Windows | The Windows PowerShell tests |
| Pester and PSScriptAnalyzer, at the versions in the [testing guide](../docs/testing.md) | Tests and linting (the Pester 3 built into Windows is too old) |
| rustup and the Visual Studio build tools | Atlas Manager, as the [Atlas Manager guide](../app/README.md) describes |

## Build and test quick start

Build a test Atlas package and verify it from the repository root:

```powershell
./build.cmd                                                       # build playbook/Atlas Test.apbx
pwsh tools/build/Test-Apbx.ps1 -Path "playbook/Atlas Test.apbx"   # verify it
```

On Linux or macOS, run `./build.sh` instead of `./build.cmd`.
The [build guide](../docs/building.md) covers the build options.

Run the Windows PowerShell tests and the build tests in their separate hosts, as [Pester unit tests](../docs/testing.md#pester-unit-tests) describes.
Use unelevated test shells.
Install and configuration checks belong in a disposable VM, never on your own PC.

Lint in PowerShell 7 with the two profiles CI runs, listed under [PSScriptAnalyzer](../docs/testing.md#psscriptanalyzer).

Test Atlas Manager from its folder:

```powershell
cd app
cargo test --locked
```

## Where things live

| Path | What it holds |
| --- | --- |
| `app/` | Atlas Manager, the Rust desktop app ([Atlas Manager guide](../app/README.md)) |
| `playbook/playbook.conf` | Atlas package metadata, including `SupportedBuilds` and `UpgradableFrom` |
| `playbook/Executables/AtlasDesktop/` | The AtlasDesktop folder's launchers, mostly generated |
| `playbook/Executables/AtlasModules/Scripts/` | The Windows PowerShell that runs on users' PCs |
| `playbook/Executables/AtlasModules/Toggles/` | Data-only AtlasDesktop toggle definitions and their companions |
| `services/` | The Atlas reports service and its MCP server |
| `tools/` | Build, development, lab and release tooling, in PowerShell 7 |
| `tests/` | Pester suites |
| `docs/` | Developer documentation ([documentation index](../docs/README.md)) |

The scripts are organised by who invokes them:

- `Entry`: processes started from outside, such as Atlas Manager, launchers and the TrustedInstaller broker.
- `Install`: the install-only plan, phases and tasks.
- `Operations`: scripts that run in their own process and are invoked by path.
- `Modules`: shared libraries.
- `Tweaks`: data-only install tweaks and their companion scripts.
- `Preparation`: the Windows and Microsoft Store update worker, which Atlas Manager also embeds.

The [architecture](../docs/architecture.md) explains how an install runs.
[The front door](../docs/front-door.md) describes `Install-Atlas.ps1`, the script Atlas Manager runs, and how to run it when testing.
[Compatibility](../docs/compatibility.md) lists every file kept for an external consumer, with its removal condition.

## Common tasks

- **Add or change a tweak:** edit the relevant `.psd1` under `playbook/Executables/AtlasModules/Scripts/Tweaks` (schema in that folder's `README.md`) and its entry in `tweaks.manifest.psd1`.
  To turn a tweak off, remove it from `Categories` or `Standalone`, and add its full slug and a reason to `Disabled`.
  Every definition in the Atlas package must be classified exactly once.
- **Add or change an AtlasDesktop toggle:** edit the data-only definition `playbook/Executables/AtlasModules/Toggles/<Group>/<Name>.psd1` (schema in that folder's `README.md`).
  Imperative work goes in the function-only companion `<Name>.ps1` beside it.
  Validate with `Test-AtlasToggleDefinition -Path playbook/Executables/AtlasModules/Toggles` from the `Atlas.Toggles` module, and regenerate the launchers with `pwsh tools/dev/New-ToggleLaunchers.ps1`.
- **Regenerate the catalog after definition changes:** run `pwsh tools/dev/Export-AtlasCatalog.ps1` for the JSON and Markdown references.
  Both generators support `-Validate`, which checks for drift without writing files.
- **Share one implementation between the install and a toggle:** give the install tweak a `Toggle = @(@{ Name; State })` entry instead of duplicating the toggle's machine work.
- **Work on Atlas Manager:** see the [Atlas Manager guide](../app/README.md) for Rust builds, isolated tests and review tools.
- **Bump the version:** run `pwsh tools/build/Set-AtlasVersion.ps1 -Version <version>`.

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): summary`.
The scope is optional and names the area you changed, such as `app`, `toggles` or `preparation`.

| Type | Use it for |
| --- | --- |
| `feat` | A new feature or a change in behaviour |
| `fix` | A bug fix |
| `refactor` | A code change that keeps the behaviour |
| `docs` | Documentation only |
| `test` | Tests only |
| `build` | The build, packaging or dependencies |
| `ci` | GitHub Actions workflows |
| `chore` | Maintenance that fits no other type |
| `revert` | Reverting an earlier commit |

Write the summary in the imperative, in lower case, without a full stop, for example `fix(toggles): check the active power plan in Atlas health`.

## Pull requests

Describe what changed and why, link the issue it resolves, and say how you tested it.
The [pull request template](pull_request_template.md) asks for each of these.

Before you ask for a review, check that:

- CI passes.
- Changes to what Atlas does to a PC have been installed on a disposable VM, as the [testing guide](../docs/testing.md) describes.
- The documentation that describes the behaviour you changed is up to date.
- After changing tweak or toggle definitions, you've run both generators, and then run them again with `-Validate`.
- Scripts under `playbook/` and `app/resources/` use Windows PowerShell 5.1 syntax, because they run on users' PCs.
  The CI parse gate rejects PowerShell 7-only syntax there.

## Style

Follow the [writing style guide](../docs/style.md) for documentation, code comments and commit messages.
Atlas Manager's interface copy follows the [app writing guide](../app/docs/writing.md).

## Licence of contributions

Atlas is licensed under the [GNU General Public License v3.0](../LICENSE).
By contributing, you agree that your contributions are licensed under the same licence.
If you include third-party code, keep its licence and notices, and list any binary in the [binary inventory](../playbook/Executables/AtlasModules/README.md).

## Code of Conduct

Everyone who takes part in Atlas follows the [Atlas Code of Conduct](https://github.com/Atlas-OS/.github/blob/main/CODE_OF_CONDUCT.md).
