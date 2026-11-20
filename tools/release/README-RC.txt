Atlas @RC_ID@ test build (source commit @COMMIT@)

Thank you for testing. Please read this before installing.

What this is
- AtlasManager.exe is a release candidate of Atlas Manager with the
  Atlas @RC_ID@ package built in. It installs only that package. It doesn't
  check GitHub for Atlas releases or open other Atlas packages. Installing
  still downloads Windows and Microsoft Store updates and selected software
  from their sources.
- When your Windows update revision isn't in the list built into the app,
  Atlas Manager checks Microsoft's Windows release page, as the normal build
  does. Release Preview and Insider builds are refused.
- The .apbx beside it is the same Atlas package as a separate file, byte for
  byte. You don't need it to install.
@TOOLBOX_NOTE@

Before you start
- Atlas installs on Windows 11 builds @SUPPORTED_BUILDS@. To see your build,
  run winver.
- This candidate can update Atlas @UPGRADABLE_FROM@. If Windows needs a newer
  release first, Atlas Manager moves it through Windows Update, then installs
  this candidate. Windows Update can take from a minute to a couple of hours
  to offer the release; Atlas Manager shows how long it has been waiting.
- Use a disposable Windows 11 installation (a VM or a spare PC). Don't test
  on a PC you rely on. To test an update, use a spare PC or a copy of your
  installation.
- Windows Update still needs an internet connection. This isn't an offline
  installer.
- Updating one candidate to another isn't supported. Reinstall Windows
  before you try the next candidate or the final release.

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
- You can also choose Export diagnostics (Settings > Help and feedback) and
  share the ZIP in the bug report channel, or use the report website if
  sending from the app doesn't work.
- If the window won't open, run: AtlasManager.exe --export-diagnostics
  The ZIP is saved under %LOCALAPPDATA%\AtlasOS\App\Diagnostics and a message
  box shows the exact path.
- If the app crashed before it could export anything, its logs are in
  %LOCALAPPDATA%\AtlasOS\App\Logs (app-*.log; %TEMP%\AtlasDiagnostics when
  that folder couldn't be created). Attach the newest one to your report.
- Say which candidate you used (@RC_ID@ appears under the title bar and in
  Settings > About), what you did, and what you expected.

Checksums for this ZIP, AtlasManager.exe and the .apbx are posted with it as
SHA256SUMS.txt.
