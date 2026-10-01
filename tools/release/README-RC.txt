Atlas @RC_ID@ test build (source commit @COMMIT@)

Thank you for testing. Please read this before installing.

What this is
- AtlasManager.exe is a release candidate of Atlas Manager with the
  Atlas @RC_ID@ package built in. It installs only that package. It does
  not check GitHub for Atlas releases or open other Atlas packages. Setup
  still downloads Windows/Store updates and selected software from their
  sources.
- The normal build may consult Microsoft's Windows release page when your
  Windows update revision is newer than the list built into the app. This
  build never contacts that page: a public revision of build 26200 or 26300 that the
  list does not know is accepted. Insider builds are still refused.
- The .apbx beside it is the same Atlas package, byte for byte, for people
  who use the alternative installer, AME Wizard, which calls it a playbook.

Before you start
- Windows 11 25H2 (build 26200) and 26H2 (build 26300) are accepted.
  26H2 is enabled for further testing after a successful x64 VM install and
  post-restart check; physical hardware, ARM64 and upgrades still need testing.
- Use a disposable Windows 11 installation (a VM or a spare PC). Do not test
  on a machine you rely on.
- Windows Update still needs an internet connection. This is not an offline
  installer.
- An installed candidate cannot be upgraded. Reinstall Windows before trying
  the next candidate or the final release.

Reporting problems
- In Atlas Manager, open Settings and choose Send a report under Help and
  feedback, or choose Report a problem on Home. Describe the issue, agree to
  send it, then choose Send report.
- Diagnostics are included for an issue and collected while you write; there
  is no separate step. Atlas removes your user name, PC name, email addresses
  and known passwords or keys, and keeps error details, hardware models and
  app names. Choose Review ZIP to check the ZIP before sending it. Nothing is
  uploaded automatically.
- Reports go privately to the Atlas team at https://reports.atlasos.net and are
  deleted after 90 days. Contact details are optional and sent as written. The
  team may use AI services from other companies to help investigate; these get
  your message and diagnostics, but not your contact details.
- You can still choose Export diagnostics (Settings > Help and feedback) and
  share the ZIP in the bug report channel, or use the report website if
  sending from the app does not work.
- If the window will not open, run: AtlasManager.exe --export-diagnostics
  The ZIP is saved under %LOCALAPPDATA%\AtlasOS\App\Diagnostics and a message
  box shows the exact path.
- If the app crashed before it could export anything, its logs are in
  %LOCALAPPDATA%\AtlasOS\App\Logs (app-*.log; %TEMP%\AtlasDiagnostics when
  that folder could not be created). Attach the newest one to your report.
- Say which candidate you used (@RC_ID@ appears under the title bar and in
  Settings > About), what you did, and what you expected.

Checksums for the files in this ZIP are posted with it as SHA256SUMS.txt.
