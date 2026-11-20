# Writing style

This page sets the house style for Atlas documentation, READMEs, code comments and commit messages.
Interface copy in Atlas Manager follows the [app writing guide](../app/docs/writing.md), which shares the terms below.

## Language

Write in British English.

- Use `-ise` and `-isation`: organise, recognise, customise, optimise, virtualisation.
- Use `-our`, `-re` and doubled `l`: behaviour, colour, centre, cancelled, labelled, modelling.
- "Licence" is the noun and "license" the verb.
  Proper names keep their spelling: GNU General Public License, MIT License, the `LICENSE` file.
- Keep code, identifiers, file names, registry values, command output and quoted text exactly as they are, such as `DeliveryOptimization` or `-NoColor`.
- "Catalog", "program", "disk", "dialog" and "artifact" are technical terms here; they name things in code and in GitHub.

Use contractions (don't, can't, isn't, it's) in all documentation.

## Write timeless copy

Documentation should stay true from one release to the next.

- Describe how Atlas behaves, not when it changed.
  Avoid "new", "now", "currently", "recently", "no longer", "soon" and "will" for product behaviour.
- Name a version only when the version is the fact, such as a compatibility limit ("Atlas Manager installs Atlas 0.6.0 and later") or records left by older releases.
- Don't copy lists of supported Windows builds or Atlas versions into prose.
  Link to the source of truth: the [supported releases](windows-release-policy.md#supported-releases) table, or `SupportedBuilds` and `UpgradableFrom` in `playbook/playbook.conf`.
- Keep test results, release status and dates out of documentation.
  They belong in release notes, pull requests and the record each release keeps against the [release verification matrix](release-verification-matrix.md).
- Use placeholders in examples that would otherwise go stale: `<version>`, `<n>`, `<yyyy-MM-dd>`.

## How Atlas is installed

Atlas Manager is the only way to install Atlas.
User documentation says that Atlas Manager checks the PC, downloads Atlas and installs it, and doesn't explain the package.

Contributor documentation may describe `Install-Atlas.ps1`, the script Atlas Manager runs (called the front door), and how to run it directly when testing.
Don't present it to users as an installer.

Mention AME Wizard only where older Atlas releases, which it installed, left records that Atlas still reads.

## Words

| Use | Avoid |
| --- | --- |
| Atlas package | playbook (except fixed names), payload |
| Atlas Manager, then "the app" | the Atlas app, the desktop app, the standalone executable |
| update (one Atlas release to a newer one) | upgrade, except in fixed names such as `UpgradableFrom` and the Upgrade mode |
| move Windows to a newer release; feature update | "the move" as an undefined noun |
| restart | reboot |
| sign in (verb), sign-in (noun) | log on, logon, login |
| the protection switches (on first mention: the four Windows Security protection switches) | Defender switches, security switches |
| internet | Internet |
| check box | checkbox |
| `%windir%` | `C:\Windows`, `%WINDIR%`, `%SystemRoot%` |
| KiB, MiB, GiB for binary sizes | MB or GB for binary sizes |
| SHA-256 | SHA256, except in file and identifier names |

Never use "ships", "shipped" or "shipping", or "payload", in prose.
Avoid "surface" as a verb, and "bounded", "authoritative" and "durable".
Use "boundary" only for a real security boundary.
Avoid intensifiers and filler: very, really, just, actually, basically, simply.

Name each Atlas Manager page the way the app does, in bold: the **Get ready** page, the **Your choices** page.

## Sentences and paragraphs

- Put one idea in each sentence. Aim for under 25 words, and treat anything over 35 as a sentence to split.
- If a sentence needs more than one semicolon, or a colon followed by a series of clauses, make it a list or a table.
- Keep paragraphs to two to five sentences on one topic.
- Write instructions in the second person ("you"), the present tense and the active voice.
- Define a term before you use it, or link to where it's defined.
- Say what does happen. Avoid stacked negatives such as "no X, no Y, no Z" and reveals such as "It's not X, it's Y".

## Page structure

- Open every page with one or two sentences that say what it covers and who it's for.
- Use one H1, and don't skip heading levels.
- Write headings in sentence case, without emoji.
- Give each page one job: a tutorial, a how-to guide, a reference or an explanation.
  Link between them instead of mixing them.
- Put each fact in one place and link to it from elsewhere.

## Markdown

- Start each sentence on a new line, and don't break lines within a sentence.
  This keeps diffs readable and makes long sentences easy to spot.
- Use backtick fences with a language: `powershell`, `sh`, `text`, `json`, `toml`, `yaml`, `xml` or `rust`.
- Use tables for reference data, with at most one short sentence in a cell.
- Use GitHub alerts (`> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`, `> [!WARNING]`, `> [!CAUTION]`) for the few points a reader mustn't miss.
- Write link text that says where the link goes. Never use "here" or a bare file name, unless the file name is the point.
- Link to files in this repository with relative links.
  Link to Microsoft Learn without a locale segment: `https://learn.microsoft.com/windows/...`.
- Write repository paths with `/` and installed Windows paths with `\`.
- Show interface labels in bold, exactly as they appear.

## Code comments

- Explain why: the constraint, the invariant or the Windows behaviour the code relies on.
- Describe the lasting condition and how Atlas handles it, for example "PCs tweaked beyond Atlas can be missing EnableLUA; Windows then uses its default, so the token check decides".
  Never describe the report, PC or test run that prompted a change, and never narrate history ("previously", "used to", "the new …"). Git keeps the history.
- Don't describe one developer's machine, and don't include machine paths.
- Credit only code that Atlas reuses, with its licence.
  Don't mention projects that were only compared or consulted.
- Don't commit commented-out code. If a setting is left out on purpose, say why in one line.
- In PowerShell, give scripts that people or Atlas Manager start comment-based help with `.SYNOPSIS`, `.DESCRIPTION`, parameters and exit codes.
  Give exported functions at least `.SYNOPSIS`.
  Give dot-sourced phases, tasks and toggle companions one header comment that says what the file does, which identity runs it and when.
- In Rust, give every module a `//!` summary and public items a `///` summary, written as sentences.
- Keep comment lines under 120 columns, and use a semicolon or colon where a spaced hyphen would stand in for a dash.

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): summary`.
The types are `feat`, `fix`, `refactor`, `docs`, `test`, `build`, `ci`, `chore` and `revert`.
Write the summary in the imperative, in lower case, without a full stop, for example `fix(toggles): check the active power plan in Atlas health`.
