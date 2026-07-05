## Security Policy

At Atlas, our primary objective is to provide an optimal equilibrium between security, performance, and usability.

### Reporting a vulnerability

If you discover a severe or exploitable security flaw in Atlas, please report it privately through [GitHub private vulnerability reporting](https://github.com/Atlas-OS/Atlas/security/advisories/new). **Do not open a public GitHub issue for exploitable problems** — Atlas performs deep, TrustedInstaller-level system modification, so public-by-default disclosure puts users at risk before a fix can ship.

If you do not have a GitHub account, contact the team privately on our [Discord server](https://discord.atlasos.net) instead.

### Scope

Atlas is responsible for everything this repository ships and builds:

- The Playbook YAML shim under [`playbook/Configuration/`](../playbook/Configuration/)
- The `Atlas.*` PowerShell framework and payload under [`playbook/Executables/`](../playbook/Executables/) (see [`docs/architecture.md`](../docs/architecture.md) for the layout)
- The shipped binaries listed in [`playbook/Executables/AtlasModules/README.md`](../playbook/Executables/AtlasModules/README.md)
- The build tooling under [`tools/`](../tools/)

For flaws in [AME Wizard](https://amelabs.net) itself, please contact AME Labs via their [website](https://amelabs.net).

As Atlas is built on Windows, a proprietary operating system developed by Microsoft, some issues may not be rectifiable by us. If you come across a vulnerability in Atlas that is also present in the latest version of stock/vanilla Windows, please report it to Microsoft. For more information on reporting security vulnerabilities and pentesting, please visit the [Microsoft](https://www.microsoft.com/en-us/msrc/faqs-report-an-issue) website. We wish you the best of luck in your reporting endeavor.

### Non-security hardening ideas

We are committed to addressing any security concerns caused by Atlas and welcome any enhancements made to the base Windows. For hardening suggestions and other non-exploitable security improvements, we encourage the submission of regular GitHub issues and pull requests, as long as the solutions match our objective of having an equilibrium between security, performance, and usability.

### Supported versions

Only the latest Atlas release is supported. Older versions do not receive security fixes; please upgrade to the current release before reporting.
