# Atlas package format

This page defines the Atlas package: the file Atlas Manager downloads, checks and installs.
It's for contributors who build packages or change how Atlas Manager or the installer reads them.

## The package file

An Atlas package is a ZIP archive with the extension `.atlaspkg`.
Releases publish it as `Atlas-v<version>.atlaspkg`, and [`tools/build/Build-Package.ps1`](../tools/build/Build-Package.ps1) builds it from the [`package/`](../package/) folder.

Every entry is encrypted with AES-256 under the password `atlasos`.
The password is public on purpose.
The encryption protects nothing: it stops antivirus engines from scanning, and possibly quarantining, Atlas's scripts before Atlas Manager stages them, because some of those scripts remove Microsoft Defender.
Anyone can open the archive with the password to read what it contains.

The archive holds every file under `package/` except build output:

| Path | Contents |
| --- | --- |
| `atlas.json` | The manifest, described below. |
| `Executables/AtlasModules/` | The Windows PowerShell scripts, modules, data and binaries that Atlas installs to `%windir%\AtlasModules`. |
| `Executables/AtlasDesktop/` | The AtlasDesktop folder that Atlas installs to `%windir%\AtlasDesktop`. |
| `Executables/Themes/` | The Atlas themes that Atlas installs to `%windir%\Resources\Themes`. |
| `Images/` | Artwork for options, such as browser logos. |

Atlas Manager checks a downloaded package against the SHA-256 digest GitHub publishes for the release file.
It unpacks a package into a folder named after its version and digest, which it never writes to again, and runs [the front door](front-door.md) from there.

## The manifest

`atlas.json` describes the package to Atlas Manager and the installer.
It's UTF-8 JSON without a byte order mark.

| Field | Type | Meaning |
| --- | --- | --- |
| `schemaVersion` | number | The manifest's format. This page describes version `1`. |
| `version` | string | The Atlas version, as `major.minor.patch` with an optional `-suffix` of letters, digits, dots and dashes. |
| `supportedBuilds` | array | The Windows 11 releases the package installs on, each `{ "build": <number>, "release": "<name>" }`. Only `build` is checked; `release` names it for readers. |
| `updatableFrom` | array of strings | The Atlas versions this package can update in place. |
| `requirements` | array of strings | The checks the front door runs before it installs, from the table below. |
| `estimatedMinutes` | number | How long an install usually takes, which Atlas Manager shows. |
| `choices` | array | The questions an install asks, in the order Atlas Manager asks them. |

### Requirements

| Id | Blocks the install when |
| --- | --- |
| `windows-security-off` | A Windows Security protection switch is on, or can't be read and the install wasn't told the user checked it. |
| `no-third-party-antivirus` | Another antivirus app is registered with Windows Security. |
| `plugged-in` | The PC is running on battery. |

The front door always checks the Windows build, edition, account and pending restarts, whatever the manifest lists.
A requirement id it doesn't recognise stops the install.

### Choices

| Field | Required | Meaning |
| --- | --- | --- |
| `id` | Yes | A stable name for the question, such as `defender`. |
| `kind` | Yes | `single` takes exactly one option; `multiple` takes any number, including none. |
| `default` | For `single` | The option chosen until the user picks another. |
| `dependsOn` | No | An option id. The choice is asked, and its options accepted, only when that option is chosen. |
| `description` | No | English text that explains the question. |
| `learnMore` | No | An `https://` link to documentation about the question. |
| `options` | Yes | Each option as `{ "id": "<option>", "label": "<English text>" }`, with an optional `"image": "<stem>"`. |

An option's `image` names a PNG in `Images/` without its extension, using letters, digits, `-` and `_` only.

Atlas Manager shows its own translated label and description for every option and choice it knows by id.
It falls back to the manifest's English text only for ids it doesn't know, such as options a newer package adds.

Option ids are recorded in Atlas's install records, its toggle records and Atlas Manager's saved choices, so an id keeps its meaning forever.
If an option comes to mean something different, give it a new id.

The front door accepts a set of options only when:

- every option is declared in the manifest;
- every `single` choice that's asked has exactly one option chosen;
- no option belongs to a choice that isn't asked, because its `dependsOn` option isn't chosen.

## The version recorded in Windows

During an install, Atlas writes `Atlas v<version>` to Windows' registered organisation and to the OEM model name, which `winver` and Settings show.
Releases before Atlas 0.6 wrote `Atlas Playbook v<version>` instead, so code that reads the installed version accepts both forms.
The [machine state document](install-state.md#the-machine-state-document) remains the main record of what's installed.

## Compatibility

Atlas Manager installs Atlas 0.6.0 and later.
Earlier releases came as AME Wizard packages, which Atlas Manager doesn't open; it updates those installs with the current package instead, as [Updating Atlas](upgrading.md) describes.
