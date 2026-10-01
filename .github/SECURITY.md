## Security Policy

Atlas aims to balance security, performance and usability.

### Reporting a vulnerability

If you discover a severe or exploitable security flaw in Atlas, please report it privately through [GitHub private vulnerability reporting](https://github.com/Atlas-OS/Atlas/security/advisories/new). **Do not open a public GitHub issue for exploitable problems** — Atlas performs deep, TrustedInstaller-level system modification, so public-by-default disclosure puts users at risk before a fix can be released.

If you do not have a GitHub account, contact the team privately on our [Discord server](https://discord.atlasos.net) instead.

### Scope

Atlas is responsible for everything it releases and builds from this repository:

- Atlas Manager, the desktop app under [`app/`](../app/)
- The reports service and its MCP server under [`services/`](../services/)
- The AME Wizard configuration (YAML) under [`playbook/Configuration/`](../playbook/Configuration/)
- The `Atlas.*` PowerShell framework and Atlas's other files under [`playbook/Executables/`](../playbook/Executables/) (see [`docs/architecture.md`](../docs/architecture.md) for the layout)
- The binaries included in the Atlas package, listed in [`playbook/Executables/AtlasModules/README.md`](../playbook/Executables/AtlasModules/README.md)
- The build tooling under [`tools/`](../tools/)

For flaws in [AME Wizard](https://amelabs.net) itself, please contact AME Labs via their [website](https://amelabs.net).

Atlas runs on Windows, so some issues are Microsoft's to fix. If a vulnerability also affects the latest unmodified Windows, report it to Microsoft through the [Microsoft Security Response Center](https://www.microsoft.com/en-us/msrc/faqs-report-an-issue).

### Non-security hardening ideas

For hardening ideas and other security improvements that aren't exploitable, open a regular GitHub issue or pull request. Suggestions should keep the balance between security, performance and usability.

### Supported versions

Only the latest Atlas release is supported. Older versions do not receive security fixes; please upgrade to the current release before reporting.
