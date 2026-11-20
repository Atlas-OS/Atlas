# Security policy

If you find a security vulnerability in Atlas, report it privately so the Atlas team can fix it before the details are public.
This page explains how to report it, what to include and what Atlas covers.

## Report a vulnerability

Report a vulnerability through [GitHub private vulnerability reporting](https://github.com/Atlas-OS/Atlas/security/advisories/new).
If you don't have a GitHub account, email [contact@atlasos.net](mailto:contact@atlasos.net).

> [!IMPORTANT]
> Don't open a public issue or discussion for a vulnerability that someone could exploit.
> Atlas makes system changes as TrustedInstaller, so public disclosure puts users at risk before a fix is out.

## What to include

- The affected component, such as Atlas Manager or a script in the Atlas package, and its version.
- The steps to reproduce the problem, with any proof of concept.
- The impact: what an attacker could do, and what access they need first.

## What happens next

The Atlas team reviews your report privately, and may ask you for more detail through the same report or email thread.
If the team confirms the vulnerability, it works on a fix and publishes a security advisory when the fix is released.
Keep the details private until then.

## Scope

Atlas covers everything it releases and builds from this repository:

- Atlas Manager, the desktop app under [`app/`](../app/)
- The reports service and its MCP server under [`services/`](../services/)
- The `Atlas.*` PowerShell framework and Atlas's other files under [`playbook/Executables/`](../playbook/Executables/) (the [architecture](../docs/architecture.md) explains the layout)
- The binaries in the Atlas package, listed in the [binary inventory](../playbook/Executables/AtlasModules/README.md)
- The build tooling under [`tools/`](../tools/)

Atlas runs on Windows, so some issues are Microsoft's to fix.
If a vulnerability also affects the latest unmodified Windows, report it to Microsoft through the [Microsoft Security Response Center](https://www.microsoft.com/en-us/msrc/faqs-report-an-issue).

## Hardening ideas

For hardening ideas, and security weaknesses that nobody could exploit, open a regular issue or pull request.
Suggestions should keep the balance between security, performance and usability.

## Supported versions

Only the latest Atlas release receives security fixes.
Update to the latest release, and check that the problem is still there, before you report it.
