Atlas @RC_ID@ test build (source commit @COMMIT@)

Thank you for testing. Please read this before installing.

What this is
- AtlasManager.exe is a release candidate of Atlas Manager with the
  Atlas @RC_ID@ playbook built in. It installs only that playbook. It does
  not check GitHub for releases, download anything, or open other playbooks.
- The .apbx beside it is the same playbook, byte for byte, for people who
  install with AME Wizard instead.

Before you start
- Use a disposable Windows 11 installation (a VM or a spare PC). Do not test
  on a machine you rely on.
- Windows Update still needs an internet connection. This is not an offline
  installer.
- An installed candidate cannot be upgraded. Reinstall Windows before trying
  the next candidate or the final release.

Reporting problems
- In Atlas Manager, open Settings and choose Export diagnostics, then share
  the ZIP it shows you. It is redacted, and nothing is uploaded automatically.
- If the window will not open, run: AtlasManager.exe --export-diagnostics
- Say which candidate you used (@RC_ID@ appears under the title bar and in
  Settings > About), what you did, and what you expected.

Checksums for the files in this ZIP are posted with it as SHA256SUMS.txt.
