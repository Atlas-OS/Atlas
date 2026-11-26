### Atlas Manager: English (United Kingdom), the source catalog.
###
### Every other language falls back to this file, so it must define every
### message. Ids are stable identifiers, never shown to users. Comments
### above a message say where it appears and what its variables hold.
###
### Conventions for translators:
### - Keep the variables ({ $name }) exactly; reorder them freely.
### - Numbers arrive as numbers and are formatted for the user's region
###   automatically; use plural selectors ({ $count -> [one] ... *[other] ... })
###   with your language's CLDR categories where the count changes the wording.
### - Values marked "text" (versions, build numbers, file names, paths,
###   error details) are inserted as they are and must not be translated.
### - "Atlas", "AtlasOS", "Windows", "Defender", "Windows Security", "SmartScreen", "GitHub"
###   are product names. Windows feature names should match what Windows
###   shows in your language (for example the four Virus & threat protection
###   switches).
### - Buttons are verb-first and short. Sentences end with a full stop;
###   titles and labels do not.

## Shared

app-name = Atlas Manager
common-done = Done
common-cancel = Cancel
common-back = Back
common-next = Continue
common-dismiss = Dismiss
# Link beside a summary row that jumps back to change that choice.
common-change = Change
common-copy = Copy
# Shown where a list of options is empty.
common-none = None
# Accessible name of the back arrow on the Install and Settings pages.
common-back-to-home = Back to home
# Accessible name of the gear button in the title bar.
common-settings = Settings
common-close-settings = Close settings
common-open-windows-security = Open Windows Security
common-restart-as-administrator = Relaunch as administrator
common-try-again = Try again
common-read-the-docs = Read the Atlas guide
common-show-details = Show details
common-hide-details = Hide details
# Accessible name of a button that acts on one card, so two buttons with the same label stay
# distinct: a Show details or Hide details toggle, or PC checks' Check again. $action is the
# button's label; $section is the title of its card.
common-details-a11y = { $action }, { $section }
# Opens the folder of the install log, with the log selected.
common-open-log-folder = Open log folder
# Accessible name of the Copy button beside the install log.
common-copy-install-log = Copy installation log
common-install-log = Installation log
# Row labels in summary cards.
common-windows = Windows
common-package = Atlas package
common-checking = Checking
# Joins two items in a list: "Brave, Firefox". The braces keep the space.
list-separator = { ", " }
# Joins two alternatives: "26100 or 26200".
list-or = { $a } or { $b }
# Joins the last two items of a list: "Tamper Protection and Cloud-delivered protection".
# $a may itself be several items joined with list-separator.
list-and = { $a } and { $b }
# Accessible name of a message bar that announces itself: its title, then its message.
infobar-a11y = { $title }. { $message }

## Window

# Dialog shown when the window is closed while an install runs. Its buttons are
# window-close-keep and window-close-close.
window-close-title = Close while Atlas is installing?
window-close-installing = Installation keeps running. Reopen Atlas to see the result.
# Instead of window-close-installing when the installation restarts the PC afterwards: only an
# open Atlas window restarts it, so closing the window cancels that.
window-close-installing-no-restart = Installation keeps running, but your PC won't restart by itself. Reopen Atlas to see the result.
# The answer that keeps the window open when closing it would interrupt something, such as
# installing or Windows Update access.
window-close-keep = Keep open
window-close-close = Close window
# Dialog shown when the window is closed during the final checks, before the installer has
# started. Its buttons are window-close-keep-installing and window-close-stop-and-close.
window-close-checks-question = Stop before installing?
window-close-checks-unchanged = Installation hasn't changed anything yet. If you close, it won't start.
window-close-keep-installing = Keep installing
window-close-stop-and-close = Stop and close
# Dialog shown when the window is closed while Windows and Store apps update. Its buttons are
# stop-update-keep and prepare-stop. Atlas stays open once it has stopped.
prepare-close-question = Stop updating?
# "Stage" is a stage of updating (as in prepare-percent), not one of the four flow steps.
prepare-close-stops-after-stage = Atlas stops after the current stage. You can close it then.
# Dialog shown when the window is closed during the restart countdown after a successful
# install. Its buttons are restart-now and restart-dont-now, the default, which closes Atlas
# without restarting.
window-close-restart-question = Restart to finish setting up Atlas?
window-close-restart-closed = Atlas can't restart your PC once it's closed. Save your work first.
# Closing while Get ready counts down to the restart Windows and Store updates need. Its buttons
# are restart-now and restart-dont-now ("Restart later"), the default, which closes Atlas; Atlas
# opens again and carries on after the next restart.
window-close-update-restart-question = Restart to finish updating?
window-close-update-restart-later = Save your work first. If you restart later, Atlas carries on after the restart.
# Dialog shown when the window is closed during a setup with Windows Security switches still
# off. Its message is window-close-protection-all or window-close-protection-some; its buttons
# are common-open-windows-security and window-close-close.
window-close-protection-title = Close Atlas with protection turned off?
window-close-protection-all = The four Windows Security protection switches are off. If you're not installing Atlas now, turn them back on first.
# $switches names the switches that are off as Windows Security does, joined like a list;
# $count is how many there are.
window-close-protection-some = { $count ->
    [one] { $switches } is off in Windows Security. If you're not installing Atlas now, turn it back on first.
   *[other] { $switches } are off in Windows Security. If you're not installing Atlas now, turn them back on first.
}
# Dialogs shown when the window is closed while an ISO or a USB drive is being created.
# Their buttons are window-close-keep-creating and window-close-stop; Atlas stays open once it
# has stopped.
iso-close-question = Stop creating the ISO?
iso-close-safe-point = Atlas stops at the next safe point.
usb-close-question = Stop creating the USB drive?
usb-close-unfinished = An unfinished drive can't install Windows.
window-close-keep-creating = Keep creating
window-close-stop = Stop
# The Open button of the file picker for an Atlas package (.atlaspkg) file, on Get ready and the
# ISO page. It's a button label, so keep it short.
file-dialog-open-package = Open an Atlas package (.atlaspkg)
# Message Windows shows in its restart notification.
shutdown-comment = Atlas is installed. Restarting Windows to finish setup.
# Message Windows shows in its restart notification when "Get ready" restarts
# to finish installing Windows updates.
prepare-shutdown-comment = Atlas is restarting Windows to finish installing updates.

## System

# "Windows 11 Pro 25H2 (build 26200.1234)". All three values are text.
system-description = { $product } { $version } (build { $build })

## Home page

home-not-installed = Welcome to Atlas
# Under home-not-installed: this PC's Windows, such as "Windows 11 Pro 25H2". Both values are text.
home-windows = { $product } { $version }
# Instead of home-windows once Atlas has found its latest release: this PC's Windows and the Atlas
# version Install Atlas would install, such as "Windows 11 Pro 25H2 · Atlas 0.6.1". $product and
# $version are this PC's Windows edition and version, and $atlas is the Atlas version (all text).
home-windows-atlas = { $product } { $version } · Atlas { $atlas }
# Under home-windows or home-windows-atlas, on a PC without Atlas: what Atlas does, in one sentence.
# Keep it to what Atlas changes: don't promise a faster PC.
home-about = Atlas reduces background activity and distractions in Windows.
# The headline when Atlas Manager can't tell what is installed on this PC.
home-state-unknown = Atlas on this PC
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# Beside the update status, on the line under the version. $date is a formatted date.
home-installed-on = Installed { $date }
home-status-checking = Checking for updates…
# While startup checks whether another window's installation is running.
home-status-recovering = Checking for an installation in progress
home-status-offline = Couldn't check for updates
home-status-not-checked = Updates not checked yet
home-status-update = Atlas { $version } is available
home-status-up-to-date = Up to date
home-status-newest = Latest version: Atlas { $version }
# An earlier installation of Atlas { $version } stopped before it finished.
home-status-unfinished = Installation of Atlas { $version } isn't finished
home-check-again = Check again
# Primary button while an install is running or waiting.
home-show-install = View progress
home-continue-installing = Continue setup
home-update-to = Update to Atlas { $version }
home-reinstall = Reinstall Atlas
home-install = Install Atlas
home-finish-install = Finish installing Atlas { $version }
home-start-over = Start over
# The question Install Atlas asks where Windows on this PC has been in use: installed a week
# or more ago, or with several apps. Its buttons are common-cancel and home-used-windows-install.
home-used-windows-title = Install Atlas on this PC?
# OneDrive: use the name Windows shows in your language.
home-used-windows-message = Apps and settings you already have may stop working, and Atlas removes OneDrive, so files in it stop syncing and folders may look empty. Back up your files first.
home-used-windows-install = Install anyway
# The card that opens ISO creation; its button is iso-open.
home-iso-title = Reinstall Windows with Atlas
# Under home-iso-title, with the Recommended badge, where Windows on this PC has been in use.
home-iso-used = Windows on this PC has been in use, and Atlas works best on a fresh installation.
# A bar on Home after an installation finished, until the PC restarts. Its message is
# restart-needed and its button restart-now.
home-restart-title = Your PC needs to restart
# Instead of restart-needed when Windows refused to restart. The raw error is behind Show
# details, and the bar's button is common-try-again.
home-restart-failed = Atlas couldn't restart your PC. Restart it from the Start menu.
home-security-reminder-title = Turn your protection back on
# Instead of home-security-reminder-title when no switch reads off but some couldn't be read
# (with home-security-reminder-unreadable-message).
home-security-reminder-unreadable-title = Make sure your protection is on
# Under home-security-reminder-title, after leaving the install flow or an installation that kept
# Microsoft Defender. $switches names the switches that read off, as Windows Security names them
# (protection-*), joined with list-separator and list-and; $count is how many it names.
security-switches-still-off =
    { $count ->
        [one] This is still off in Windows Security: { $switches }.
       *[other] These are still off in Windows Security: { $switches }.
    }
# Instead of security-switches-still-off when no switch
# reads off but some couldn't be read. $switches names those, joined like a list.
home-security-reminder-unreadable-message = Atlas couldn't read every protection switch. Check that these are on in Windows Security: { $switches }.
home-elevation-title = Atlas needs permission to install
# Under home-elevation-title when the setup choices couldn't be saved; the raw error is
# behind Show details.
home-elevation-draft-not-saved = Atlas couldn't save your setup choices, so it hasn't relaunched.
home-state-error-title = Couldn't read your Atlas installation details
# Its button is common-try-again; the raw error is behind Show details.
home-state-error-problem = Your Atlas version, choices and history may not show correctly.
# A bar on Home when the Atlas package needs a newer Atlas Manager. Its message is
# acquire-manager-update-required or acquire-manager-update-required-any, and the button beside
# the version above is manager-download.
home-manager-needed-title = Atlas Manager needs an update
home-whats-new = What's new in Atlas { $version }
home-view-release = View release notes on GitHub
home-show-less = Show less
home-show-full-notes = Show all release notes
home-your-install = Your Atlas setup
# Atlas is installed, but without the record Atlas Manager keeps (older versions didn't write one).
home-install-unrecorded = This PC has no record of how Atlas was installed, so your choices and installation history can't be shown.
home-history = Installation history
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
# Accessible name of a numbered step.
home-step-a11y = Step { $number }: { $title }
# Accessible name of a numbered step with its sentence, as screen readers read each step of
# Home's lists. $step is home-step-a11y or stepper-item-a11y, and $detail is the step's sentence,
# such as home-step-ready.
home-step-detail-a11y = { $step }. { $detail }
# The card on Home that lists the four install steps (step-ready, step-options, step-security and
# step-install) on a PC without Atlas, each with its home-step-* sentence beside it.
home-steps-title = What happens
# Instead of home-steps-title while a setup is under way: each step shows whether it's done, current
# or still to come.
home-steps-under-way-title = Setting up Atlas
# Beside step-ready in that card.
home-step-ready = Atlas checks your PC and updates Windows.
# Instead of home-step-ready where Windows must move to a newer version before Atlas can install.
# $release is that version, such as "26H2" (text).
home-step-ready-move = Atlas checks your PC and moves Windows to version { $release }.
# Beside step-options in that card. Microsoft Defender is one of the choices asked there.
home-step-options = You choose what to keep, such as Microsoft Defender.
# Beside step-security in that card.
home-step-security = You turn off the four Windows Security protection switches.
# Beside step-install in that card. $minutes is how long installing usually takes, from the Atlas
# package (a number). The first is shown when the PC restarts by itself after installing, as set in
# settings-restart-automatically, and the second when the person restarts it.
home-step-install-restarts =
    { $minutes ->
        [one] Installing usually takes about { $minutes } minute, then your PC restarts.
       *[other] Installing usually takes about { $minutes } minutes, then your PC restarts.
    }
home-step-install-restart-yourself =
    { $minutes ->
        [one] Installing usually takes about { $minutes } minute, then restart your PC.
       *[other] Installing usually takes about { $minutes } minutes, then restart your PC.
    }
# At the bottom of that card, under the four steps.
home-steps-save-work = Save your work first: apps may close and your PC restarts.
home-github = View Atlas on GitHub
home-discord = Join the Atlas community
home-report-problem = Report a problem

## How an install was done (from the state document)

# Lower-case forms used inside a history row.
history-mode-fresh = first installation
history-mode-upgrade = update
history-mode-reapply = reinstall
history-mode-unknown = installation

## Notices on the Home page

# Each notice's raw error, and the file it concerns, are behind Show details.
notice-settings-reset-title = Atlas is using default app settings
notice-settings-unreadable-problem = Atlas couldn't read your saved app settings. Your Windows settings haven't changed.
notice-settings-damaged-kept-problem = Your app settings file was damaged, so Atlas reset it and kept a copy of the old file.
notice-settings-damaged-problem = Your app settings file was damaged. Atlas is using defaults for now.
notice-settings-not-saved-title = Couldn't save app settings
notice-settings-not-saved-problem = Atlas couldn't save your latest changes, so they may be lost when you close Atlas. If another Atlas window is open, close it, then make the change again.
notice-session-unreadable-title = Couldn't check the previous installation
# Its button, iso-open-folder, shows the install record in File Explorer.
notice-session-unreadable-problem = Atlas couldn't tell whether an earlier installation is still running. If you're sure none is, delete its install record, then relaunch Atlas.
# Get ready, when the install record can't be read. $path is a file path (text).
notice-session-unreadable-message = Atlas couldn't tell whether an earlier installation is still running. If you're not sure, ask the Atlas community for help. Only if you're sure none is running, delete { $path } and try again. Details: { $error }

## Administrator elevation

elevation-declined = Permission wasn't granted. Try again and choose Yes when Windows asks to let Atlas make changes.
elevation-declined-continue = Permission wasn't granted. Try again and choose Yes when Windows asks to let Atlas make changes. Your setup choices are saved.
elevation-draft-not-saved = Atlas couldn't save your setup choices, so it hasn't relaunched. Try again. Details: { $error }
# Shown with the home-start-over button.
elevation-taken-over = Another Atlas window is now using this setup, so Atlas hasn't relaunched. Continue in that window, or choose Start over to set up again here.

## The install flow

step-ready = Get ready
step-options = Your choices
step-security = Windows Security
step-install = Install
install-title = Set up Atlas
# Accessible name of the row of steps.
stepper-label = Atlas setup steps
# Accessible name of one step. $heading is step-heading; $status is one of the
# stepper-status-* messages.
stepper-item-a11y = { $heading }, { $status }
stepper-status-completed = completed
stepper-status-current = current step
stepper-status-upcoming = upcoming step
# A step already visited whose requirements aren't met yet.
stepper-status-attention = needs attention
# Names the step showing. Not shown: the stepper marks the step, and its current step reads
# this, or step-heading-*-a11y, when it takes focus.
step-heading = Step { $number } of { $total }: { $title }
# Accessible name of the current step on Your choices, read when it takes focus. $heading is
# stepper-item-a11y; $questions is what the screen asks: each question, such as
# screen-defender-question, one after another, then screen-extras-title, or, on the first
# screen of an update or reinstall, update-path-update-title or update-path-reinstall-title.
step-heading-choices-a11y = { $heading }. { $questions }

## Step 1: Get ready
## One checklist with three rows: the checks, the Atlas package, and the updates. Each row has a
## title and one status line. Get ready starts updating and moves on by itself.

# Row title. It names what the row does, as a checklist item.
ready-checks-title = Check your PC
# Status line while the checks run.
ready-checks-running = Checking your PC…
ready-check-again = Check again
# Status line once every check passed; common-show-details lists them.
ready-checks-passed =
    { $count ->
        [one] { $count } check passed
       *[other] { $count } checks passed
    }
# Status line when some checks need attention, which are listed under it. When updating takes
# care of every one of them, ready-checks-handled follows it, after usb-detail-separator.
ready-checks-passed-some =
    { $total ->
        [one] { $passed } of { $total } check passed
       *[other] { $passed } of { $total } checks passed
    }
# After ready-checks-passed-some, when the only checks that didn't pass are ones updating takes
# care of, such as updates waiting: "5 of 9 checks passed · 4 handled by updating". $count is
# how many updating takes care of.
ready-checks-handled = { $count } handled by updating
# Accessible state of a check that updating takes care of, after check-a11y's title.
check-state-updates = updating takes care of it
# Under the title of a check that updating takes care of.
check-updates-handled = Updates are waiting. Atlas installs them while it updates Windows.
check-restart-handled = Windows needs a restart to finish earlier changes. Updating takes care of it.
check-handled = Updating takes care of this.
# Row title: the Atlas version the package holds.
ready-package-title = Atlas { $version }
# Status lines of the package row.
ready-package-downloading = Downloading…
ready-package-unpacking = Unpacking…
ready-package-ready = Ready
ready-package-checking = Checking for the latest version…
# Tester build: the bundled Atlas package is being unpacked; nothing is downloaded.
ready-package-bundled = Preparing the bundled Atlas package…
ready-package-none = Not downloaded yet
ready-package-failed = Couldn't get the Atlas package
# Under ready-package-failed, with package-download-again and package-open-file. The raw error
# is behind common-show-details.
ready-package-failed-detail = Download it again, or open another Atlas package (.atlaspkg).
# Tester build: the same, with Try again (common-try-again) as the only control.
ready-package-bundled-failed-detail = The Atlas package bundled with this test build couldn't be unpacked. Try again.
ready-package-manager = Needs a newer Atlas Manager
ready-package-release-failed = Couldn't check for the latest version
# Under ready-package-release-failed, with package-download-again and package-open-file.
ready-package-release-failed-detail = Check your internet connection, then try again. If you have an Atlas package (.atlaspkg), you can open it instead.
# Row title.
ready-updates-title = Windows and Microsoft Store updates
# Status line before updating starts. Get ready starts it by itself.
ready-updates-pending = Store apps such as Notepad may close while they update. Save your work in them first.
# Status line while Windows moves to version $release, whose card says how that stands.
ready-updates-after-move = Starts after Windows moves to version { $release }.
# Status line after Atlas's own restart, until updating carries on by itself.
ready-updates-resumed = Carrying on after the restart…
ready-updates-restarting = Restarting your PC…
ready-updates-done = Windows and Store apps are up to date.
# Instead of ready-updates-done where Microsoft Store is turned off, so only Windows was updated;
# prepare-store-skipped-removed says so under it.
ready-updates-done-windows = Windows is up to date.
# The countdown before the restart updating needs, with restart-now and restart-dont-now under
# it. Read when it shows, not every second.
ready-updates-restart-countdown =
    { $seconds ->
        [one] Your PC restarts in { $seconds } second.
       *[other] Your PC restarts in { $seconds } seconds.
    }
ready-updates-restart = Your PC needs to restart to finish updating.
ready-updates-restart-finish = Windows needs one more restart to finish installing version { $release }.
ready-updates-restart-failed = Your PC didn't restart
# Under the restart's status line, before Restart now.
ready-updates-restart-save = Save your work first.
ready-updates-restart-persists = Windows still asks for a restart
# Under ready-updates-restart-persists, with Try again and check-fix-windows-update.
ready-updates-restart-persists-advice = Restarting again probably won't help. Finish anything waiting in Windows Update, then try again.
# Behind common-show-details. $reasons lists prepare-reason-* messages.
ready-updates-restart-persists-reasons = Restart reasons: { $reasons }
ready-updates-network = Updates can't use this connection
ready-updates-stopped = Updating stopped. Some updates may already be installed.
ready-updates-previous = Waiting for updates started earlier…
# Button after the user stopped updating.
ready-updates-resume = Resume updates
ready-updates-start = Start updating
# Why updating hasn't started, under the row.
ready-updates-blocked = Updates wait until Atlas can install on this PC.
ready-updates-needs-admin = Starts once Atlas has administrator permission.
ready-updates-needs-windows = Starts once the Windows compatibility check passes.
ready-updates-needs-drivers = Starts once you've decided how drivers are installed.
# The driver choice, one line under the update row. $choice is ready-drivers-automatic or
# ready-drivers-manual. common-change unfolds the two answers.
ready-drivers-row = Drivers: { $choice }
# The two values are also the Drivers row on the ISO's Create step (iso-review-drivers), where
# the answer is the one chosen on the Setup step.
ready-drivers-automatic = Through Windows Update
ready-drivers-manual = Install them myself
ready-drivers-change-a11y = Change how drivers are installed
# Under the two answers, once updating has run.
ready-drivers-again = Changing this runs the updates again.

# $received and $total are formatted numbers of megabytes (text).
package-downloading = Downloading Atlas { $version } · { $received } of { $total } MB
package-unpacking = Unpacking
package-status-ready = Ready
# Accessible name of the progress bar.
package-progress = Atlas package progress
package-download-again = Download again
package-download-version = Download Atlas { $version }
package-download-newest = Download latest version
package-cancel-download = Cancel download
package-open-file = Open package file
# Where the package came from. $file is a file name (text).
package-from-release = Atlas { $version } downloaded from GitHub and ready to install.
package-from-file = Atlas { $version } loaded from { $file } and ready to install.
package-unpacked = Atlas { $version } is ready to install.
package-none-yet = No Atlas package yet
acquire-no-asset = Atlas { $version } has no package file to download. Open a saved Atlas package (.atlaspkg) to continue.
# Shown for a package older than Atlas 0.6.0, and for a file that isn't an Atlas package, such as an
# .apbx file from an Atlas release before 0.6.
acquire-unsupported = This app can install Atlas 0.6.0 and later, from Atlas packages (.atlaspkg).
# A package new enough to include the installer script that this app drives, but without it.
acquire-incomplete = Atlas { $version } is missing files this app needs to install it. Download it again, or open another Atlas package (.atlaspkg).
acquire-failed = Couldn't prepare the Atlas package. Download it again, or open another Atlas package (.atlaspkg). Details: { $error }
# The download received nothing for a minute and was stopped.
acquire-stalled = The download stopped responding. Check your internet connection, then download again, or open a saved Atlas package (.atlaspkg).
# Tester build: the bundled Atlas package couldn't be unpacked. Try again is the only control offered.
acquire-failed-bundled = Couldn't prepare the bundled Atlas package. Choose Try again. Details: { $error }
# The Atlas package asks for a newer Atlas Manager than this one. $version is the version it asks for,
# such as 0.7.0. Download Atlas Manager (manager-download) is beside it. "It" is the Atlas Manager
# downloaded, and "this one" the Atlas Manager running now.
acquire-manager-update-needed = This Atlas package needs a newer Atlas Manager. Download Atlas Manager { $version } or later and use it instead of this one.
# The same, for a package that doesn't say which version it needs.
acquire-manager-update-needed-any = This Atlas package needs a newer Atlas Manager. Download the latest Atlas Manager and use it instead of this one.
# The Atlas package for Atlas $version asks for Atlas Manager $required or later, such as 0.7.0.
# Download Atlas Manager (manager-download) is beside it, on Get ready and on Home.
acquire-manager-update-required = To install Atlas { $version }, download Atlas Manager { $required } or later and use it instead of this one.
# The same, for a package that doesn't say which Atlas Manager it needs.
acquire-manager-update-required-any = To install Atlas { $version }, download the latest Atlas Manager and use it instead of this one.

## Newer Atlas Manager

# Opens the latest Atlas release on GitHub in the browser, where Atlas Manager is downloaded.
manager-download = Download Atlas Manager
# A note on Home and in Settings that a newer Atlas Manager has been released. $version is its
# version, such as 0.7.0. The note doesn't stop anything; manager-download is its button.
manager-update-title = Atlas Manager { $version } is available
manager-update-message = Atlas Manager can't update itself. Download the new version and use it instead of this one.

## System checks

check-administrator = Permission to install
check-supported-build = Windows compatibility
check-pending-updates = Windows updates
check-pending-reboot = Pending restart
check-third-party-antivirus = Other antivirus software
check-internet = Internet connection
check-power = Power supply
check-activation = Windows activation
# Checks shown only where Atlas moves Windows to a newer version: what the move needs.
check-move-hardware = Windows 11 hardware
check-move-space = Free space
check-move-update-source = Where updates come from
# Accessible name of a check row. $state is one of the check-state-* messages.
check-a11y = { $title }: { $state }
check-state-checking = checking
check-state-passed = passed
check-state-warning = needs attention
check-state-failed-blocking = action needed before installing
check-state-failed = needs attention
check-state-unknown = couldn't be checked
check-fix-windows-update = Open Windows Update
check-fix-network = Open network settings
check-fix-power = Open power settings
check-fix-activation = Open activation settings
# Opens Storage in Windows Settings, where space is freed up.
check-fix-storage = Open Storage settings
# Opens Installed apps in Windows Settings, from the Other antivirus software check. "Installed
# apps" is the page of that name in Windows Settings, as in fixed-installed; use the name Windows
# shows in your language.
check-fix-installed-apps = Open Installed apps
# Check box the user ticks when the Windows Update scan could not run.
check-ack-updates = I've checked Windows Update: no updates are waiting to install

detail-admin-ok = Atlas has permission to make the changes needed for installation.
detail-admin-missing = Relaunch Atlas as administrator, then choose Yes when Windows asks for permission.
# $builds is a list of build numbers such as "26100 or 26200"; $build is this PC's (text).
detail-build-unsupported = This Atlas version requires Windows build { $builds }. Your PC has build { $build }. Install a supported Windows version before continuing.
detail-build-missing = This Atlas package doesn't list any supported Windows builds. Use a full build of the package instead of a LocalTest build.
detail-updates-none = No Windows updates are waiting to install.
# Updates still waiting once updating has run. $count is how many.
detail-updates-left =
    { $count ->
        [one] { $count } update is still waiting. Install it in Windows Update, then check again.
       *[other] { $count } updates are still waiting. Install them in Windows Update, then check again.
    }
detail-updates-scan-failed = Couldn't check for Windows updates. Open Windows Update to see whether any are waiting. ({ $error })
detail-reboot-none = Windows doesn't need a restart right now.
# Once updating has run: a restart it left, or one Windows still wants.
detail-restart-pending = Windows needs to restart to finish earlier changes. Restart your PC, then check again.
# $reasons: the pending-restart markers Windows set, from the prepare-reason-* names.
detail-restart-pending-reasons = Windows needs to restart to finish earlier changes ({ $reasons }). Restart your PC, then check again.
# Warning, not a block: $files lists up to three file paths Windows will replace or remove at the next restart.
detail-reboot-file-renames = You can continue. Windows has files to replace or remove at the next restart ({ $files }). Some apps, such as Xbox Gaming Services, do this after every restart.
detail-reboot-unknown = Couldn't check whether Windows needs a restart. Restart your PC, then reopen Atlas and check again. ({ $error })
detail-antivirus-none = No other antivirus software was detected.
# $products is a list of product names (text). The row offers check-fix-installed-apps.
detail-antivirus-uninstall = Antivirus apps other than Microsoft Defender can block installation. Uninstall { $products }, then check again.
# Warning, not a block: Security Center still lists the product but its files are gone.
detail-antivirus-stale = Windows Security still lists { $products }, but its files are gone, so it isn't installed any more. Atlas can install anyway.
detail-antivirus-check-failed = Couldn't check for other antivirus software. If this keeps happening, restart your PC and check again. ({ $error })
detail-internet-ok = You're connected. Keep this connection available while Atlas downloads and installs software.
detail-internet-missing = Connect to the internet, then check again.
detail-power-mains = Your PC is plugged in. Keep it connected until installation finishes.
detail-power-battery = Plug your PC into a power supply so it stays on throughout installation.
detail-power-check-failed = Atlas couldn't tell whether your PC is plugged in. If it's a laptop, plug it in, then check again.
detail-activation-ok = Windows is activated. Atlas won't change this.
detail-activation-missing = Windows isn't activated. You can continue, but Atlas won't activate Windows for you.
detail-activation-no-licence = Windows didn't report a licence. You can continue; Atlas won't change your activation status.
detail-activation-unknown = Couldn't check Windows activation. You can continue; Atlas won't change your activation status. ({ $error })
# Under each check-move-* check, which passes, when this PC doesn't need to move Windows to a
# newer version.
detail-move-not-needed = Atlas doesn't need to move Windows to a newer version on this PC.
detail-move-hardware-ready = This PC has the TPM 2.0 and UEFI firmware that Windows 11 needs.
# What moving Windows to version $release needs. $missing lists hardware-tpm and hardware-uefi.
detail-move-hardware-missing = This PC doesn't have { $missing }, so Windows Update won't move it to version { $release }. Back up your files, then reinstall Windows with an Atlas ISO.
detail-move-hardware-unread = Atlas couldn't read all of this PC's hardware, so Windows Update checks it.
# $drive is a drive such as C:; $free and $needed are whole gigabytes.
detail-move-space-ok = { $drive } has { $free } GB free.
detail-move-space-short = Version { $release } needs { $needed } GB free on { $drive }, and it has { $free } GB. Free up space, and Atlas checks again by itself.
detail-move-space-unknown = Couldn't check the free space for the Windows update. Restart your PC, then check again. ({ $error })
detail-move-update-source-ok = This PC gets updates from Windows Update.
detail-move-update-source-managed = This PC gets updates from its organisation's server, which doesn't offer version { $release }. Ask your organisation, or reinstall Windows with an Atlas ISO.

## Step 2: Your choices
## One screen asks every question, a card each, with the optional extras folded under them.

# Once, at the top of Your choices. It names only what the Atlas folder can change back; other
# choices, such as removing Microsoft Edge, can't be undone there.
options-change-later = You can change Microsoft Defender, processor protections and update settings later from the Atlas folder on your desktop.
# The status line of the folded Optional extras card, then options-extras-show or -hide beside it.
options-extras-none = None selected
# $count is how many of the extras' check boxes are ticked.
options-extras-ticked = { $count } selected
# Links that unfold and fold the Optional extras card.
options-extras-show = Show
options-extras-hide = Hide
# Under each question's title, one sentence at most. What every Defender answer turns off
# is in the Install step's details (summary-turned-off).
question-defender-description = Microsoft Defender is the antivirus built into Windows.
question-mitigations-description = These protections, also called security mitigations, defend against processor flaws, such as Spectre and Meltdown, and attacks that exploit bugs in apps.
question-auto-updates-description = Either way, Atlas keeps Windows on its current version and turns off automatic updates for Microsoft Store apps.
question-browser-description = Atlas won't change your browser settings.
# One line under an answer other than the recommended one: what it costs.
# cost-defender-disable is also the caution under Remove Microsoft Defender on the Install step
# and Home, and the message after an installation that removed Defender.
cost-defender-disable = Your PC has no antivirus until you install another, and Windows stops warning you before you open unrecognised apps or downloads.
# "Exploit protection" is the Windows Security page of that name; use the name Windows shows in
# your language.
cost-mitigations-disable = This also turns off Exploit protection for apps, such as Control Flow Guard, which reduces security.
cost-auto-updates-disable = Open Windows Update regularly to get security fixes.
cost-auto-updates-default = Windows may restart your PC to finish installing updates.
# Under the taskbar selector answer, which turns off the keyboard shortcuts for switching.
cost-keyboard-shortcuts-off = Alt+Shift and Ctrl+Shift no longer switch languages or layouts.
# One line under an optional extra: what ticking it does.
extra-disable-hibernation = Frees disk space, but Hibernate and Fast Startup become unavailable.
extra-disable-power-saving = Your PC may use more power, run hotter and have shorter battery life.
extra-disable-core-isolation = Reduces protection, and games using anti-cheats such as Riot Vanguard or FACEIT may not start until you turn memory integrity back on.
extra-uninstall-edge = Your Edge bookmarks, history and saved passwords on this PC are deleted, except what's synced to your Microsoft account.
extra-install-toolbox = Helps you manage your Atlas settings, though some features may be unfinished while it's in beta.
extra-install-eclean = A tool from the team behind AtlasOS for reviewing junk files and startup apps, which needs an account and an internet connection.
# Short names for each decision (summary rows) and the question each screen asks.
screen-defender-title = Microsoft Defender
screen-defender-question = Keep Microsoft Defender?
screen-mitigations-title = Processor protections
screen-mitigations-question = Keep Windows' processor protections?
screen-updates-title = Windows Update
screen-updates-question = How should Windows install updates?
screen-browser-title = Browser
screen-power-title = Power and security
screen-apps-title = Apps
screen-optional-apps-title = Optional apps
screen-choose-one-title = Choose an option
screen-extras-title = Optional extras
# Each decision's short name in the middle of a sentence, as in summary-change-a11y,
# update-path-differs, preflight-choice-unanswered and installed-not-applied-choices. Write it as
# the language does mid-sentence: in English, product names keep their capitals and other names
# are lower case.
screen-update-path-name = how Atlas updates
screen-defender-name = Microsoft Defender
screen-mitigations-name = processor protections
screen-updates-name = Windows Update
screen-keyboard-name = keyboard languages
screen-browser-name = browser
screen-power-name = power and security
screen-apps-name = apps
screen-optional-apps-name = optional apps
# A question with one answer that this app has no name for, such as one a newer Atlas package
# adds. Its title is screen-choose-one-title.
screen-package-choice-name = a choice in the Atlas package
screen-extras-name = optional extras
# Question for a required choice this app has no specific wording for.
screen-generic-question = Choose an option for { $title }
learn-more-defender = Learn more about Microsoft Defender
learn-more-mitigations = Learn more about processor protections
learn-more-updates = Learn more about Windows Update
learn-more-browser = Learn more about browsers
learn-more-power = Learn more about power and security
learn-more-apps = Learn more about apps
learn-more-eclean = Learn more about eclean
learn-more-keyboard = Learn more about keyboard languages
learn-more-generic = Read the setup guide
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = Keeps Windows' built-in antivirus to help protect your PC from viruses and other threats.
consequence-mitigations-default = Keeps Windows' default protections against processor flaws and attacks that exploit bugs in apps.
# Under Turn off processor protections. "Exploit protection" is the Windows Security page
# of that name; use the name Windows shows in your language.
consequence-mitigations-disable = Also turns off Exploit protection for apps, such as Control Flow Guard. This reduces security. Any performance difference depends on your processor.
consequence-auto-updates-disable = Open Windows Update regularly to install updates. Update notifications stay on.
consequence-auto-updates-default = Windows will install updates automatically, including security fixes.

## Step 2 on an update or reinstall of the installed Atlas

# The first screen of Your choices when updating the installed Atlas. $version is the Atlas
# version being installed, such as 0.6.1.
update-path-update-title = How do you want to update to Atlas { $version }?
# The same screen when installing again the Atlas version this PC already has.
update-path-reinstall-title = How do you want to reinstall Atlas { $version }?
# The two answers on that screen, each with the detail line under it. Other messages
# name the answers too, so keep each the same everywhere.
update-path-keep = Keep my choices
update-path-keep-detail = Atlas keeps every choice as this PC has it now and changes none of them.
update-path-choose = Choose again
update-path-choose-detail = Start from how this PC is set up now. Your apps, files and personalisation stay.
# Heading of the list under the two answers: one row per choice, as this PC has it now.
update-path-now-title = Your choices on this PC now
# The value of a row in that list for a choice nothing on the PC shows. Keep my choices
# then asks it.
update-path-unknown = Atlas can't tell this from your PC, so it asks you
# Above that list. $choices lists the screen-*-name messages, such as "Microsoft Defender and
# processor protections", joined with list-and.
update-path-differs = This PC doesn't match Atlas's record for { $choices }.
# A line above the questions Keep my choices still asks, which are the ones this PC can't show.
keep-choices-asked = Atlas keeps every other choice as this PC has it now.
# A short tag, on a line of its own, under the answer this PC has now, on the screens of
# Choose again.
option-now = On this PC now
# Under an answer on a screen of Choose again, instead of what it usually means, when
# choosing it changes this PC.
change-defender-enable = Atlas brings Microsoft Defender back. After the restart, turn its protection on in Windows Security.
change-mitigations-default = Atlas turns processor protections back on, as Windows sets them. This takes effect after the restart.
# Under Keep processor protections when every protection is turned on: Atlas leaves them
# all on rather than going back to the Windows defaults.
change-mitigations-all-on = All processor protections are turned on now. Keeping protections leaves them all on.
change-auto-updates-default = Atlas lets Windows install updates automatically again.
# Under Turn off hibernation, Turn off power saving and Turn off VBS when the box is cleared
# while this PC has them off.
change-hibernation-on = Atlas turns hibernation back on.
change-power-saving-on = Atlas turns power saving back on and goes back to your earlier power plan, or to Balanced if there isn't one.
change-core-isolation-on = Atlas turns virtualisation-based security (VBS) back on, unless a policy on this PC controls it. This takes effect after the restart.
# Under Remove Snipping Tool when it's ticked while this PC still has the app.
change-remove-snipping-tool = Removes Snipping Tool for everyone on this PC. Atlas can't put it back later, but you can install it again from Microsoft Store.
# Under a box Choose again shows ticked and can't clear, saying why. Install or Remove Edge
# is a file name in the Atlas folder, in English on every PC.
fixed-uninstall-edge = Microsoft Edge is already removed, and updating Atlas can't put it back. To install it again, use Install or Remove Edge in the Atlas folder.
# The same for an app Atlas installed. $app is its name, such as Atlas Toolbox or Brave.
# "Installed apps" is the page of that name in Windows Settings.
fixed-installed = { $app } is installed. Atlas doesn't uninstall apps; to remove it, go to Installed apps in Windows Settings.
# Under the browser chosen when another browser Atlas offers is already installed.
# $installed and $browser are browser names, such as Brave and Firefox.
browser-also = { $installed } stays installed, and Atlas installs { $browser } as well.

## Atlas package text
## Labels and descriptions for the Atlas package's options and choices, by
## their ids in the package's atlas.json. The app shows these in place of the
## package's own English text; an option or choice that a newer package adds,
## which has no message here, shows the package's English.
## An option whose label recommends it has a -short form too: the same answer
## without the recommendation, for the Install step's summary, Home and the
## records, where the choice is already made.

package-option-defender-enable = Keep Microsoft Defender (recommended)
package-option-defender-enable-short = Keep Microsoft Defender
package-option-defender-disable = Remove Microsoft Defender
package-option-mitigations-default = Keep processor protections (recommended)
package-option-mitigations-default-short = Keep processor protections
package-option-mitigations-disable = Turn off processor protections
package-option-auto-updates-disable = Install updates myself
package-option-auto-updates-default = Install updates automatically
package-option-disable-hibernation = Turn off hibernation
package-option-disable-power-saving = Turn off power saving
package-option-disable-core-isolation = Turn off virtualisation-based security (VBS)
package-option-remove-snipping-tool = Remove Snipping Tool
package-option-uninstall-edge = Remove Microsoft Edge
package-option-install-another-browser = Install a browser
package-option-install-toolbox = Install Atlas Toolbox
package-option-install-eclean = Install eclean
package-option-browser-brave = Brave
package-option-browser-librewolf = LibreWolf
package-option-browser-firefox = Firefox
package-option-browser-chrome = Chrome
package-choice-defender-description = Microsoft Defender is the antivirus built into Windows. Remove it only if you understand the risks and plan to use another antivirus app. Whichever you choose, Atlas turns off Smart App Control, Enhanced Phishing Protection and Find my device.
package-choice-mitigations-description = These protections, also called security mitigations, help defend against processor flaws, such as Spectre and Meltdown, and against attacks that exploit bugs in apps. Keeping the Windows defaults is recommended.
package-choice-auto-updates-description = Windows updates include security fixes. You can have Windows install them automatically or install them yourself. Either way, Atlas keeps Windows on its current version, which gets security fixes only until Microsoft ends support for it. Atlas also turns off automatic updates for Microsoft Store apps, so update them in Microsoft Store.
package-choice-browser-description = Choose a browser to install. Atlas won't change your browser settings.

## Step 3: Windows Security

# Shown instead of the switch list when Microsoft Defender isn't on this PC and the user
# chose to remove it.
security-banner-absent-title = Microsoft Defender isn't installed on this PC
# The message under security-banner-absent-title and security-banner-removed-title.
security-nothing-to-turn-off = There are no protection switches to turn off.
# Instead of security-banner-absent-title when Atlas's own package removed Microsoft Defender
# and it stays removed. Its message is security-nothing-to-turn-off.
security-banner-removed-title = Atlas removed Microsoft Defender from this PC
# When Atlas's own package removed Microsoft Defender and this installation brings it back.
security-banner-restore-title = Atlas brings Microsoft Defender back in this installation
security-restore-nothing-to-turn-off = Defender isn't running yet, so there's nothing to turn off. After the restart, turn its protection on in Windows Security.
# A warning that doesn't stop the step: the user chose to keep Microsoft Defender, but it
# isn't on this PC and Atlas didn't remove it. Home and the "Atlas is installed" window use
# the same title.
security-banner-missing-title = Microsoft Defender is missing
security-banner-missing-message = Atlas didn't remove it, so it can't bring it back. You can continue, but your PC has no antivirus until you install another antivirus app or repair Windows.
# While a switch is on, or none can be read. Atlas has opened Windows Security at the switches,
# and Open Windows Security, its button, opens it again.
security-turn-off-title = Turn off these four switches
security-turn-off-message = Microsoft Defender can block Atlas while it installs. If you keep Defender, turn them back on after installing.
# The page name in Windows Security.
security-list-title = Virus & threat protection settings
security-switch-off = Off
security-switch-on = On
security-switch-unreadable = Couldn't read
security-switch-reading = Checking
security-all-off = All off
# Accessible name of a switch row. $state is one of the security-switch-* messages.
security-a11y = { $title }: { $state }
# Parts of the summary "2 still on, 1 couldn't be read".
security-count-still-on = { $count } still on
security-count-unreadable = { $count } couldn't be read
security-count-join = { $a }, { $b }
# Every switch Atlas could read is off, and the rest couldn't be read. $switches names those,
# as Windows Security names them, joined with list-and; $count is how many there are. English
# reads the same for one or several; agree with $count where your language needs to.
security-unread-switches-title =
    { $count ->
        [one] Atlas couldn't read { $switches }
       *[other] Atlas couldn't read { $switches }
    }
security-unread-message =
    { $count ->
        [one] Make sure it's off in Windows Security.
       *[other] Make sure they're off in Windows Security.
    }
# The check box under security-unread-message.
security-unread-confirm =
    { $count ->
        [one] I've checked that { $switches } is off
       *[other] I've checked that { $switches } are off
    }
# The check box when Atlas couldn't read any of the four switches.
security-acknowledge = I've checked Windows Security and all four switches are off
security-unknown-unelevated-title = Atlas needs permission to check protection
security-unknown-unelevated-message = Relaunch Atlas as administrator so it can check Microsoft Defender's settings.
# The four switches, named as Windows Security names them, each with why it must be off.
protection-tamper = Tamper Protection
protection-tamper-why = So Atlas can change security settings.
protection-realtime = Real-time protection
protection-realtime-reason = Scans can block Atlas's files.
protection-cloud = Cloud-delivered protection
protection-cloud-reason = Online checks can block Atlas's files.
protection-samples = Automatic sample submission
protection-samples-why = So Atlas's files aren't sent to Microsoft.

## Step 4: Install

outcome-succeeded-title = Atlas is installed
outcome-lost-title = Couldn't confirm the installation result
outcome-failed-title = Installation didn't finish
# The result bar's message after an attempt that didn't succeed: what happened, then what to do,
# in two sentences at most. The bar's button, or the footer's Try again, is the next step, so the
# message never names it. The installer's own error is behind Show details.
# Beside go-to-ready.
result-requirements = Your PC didn't meet the installation requirements, so no installation changes were made.
# The -resumed variants follow a retry of an installation an earlier attempt had already started applying.
result-requirements-resumed = Your PC didn't meet the installation requirements, so this attempt stopped. An earlier attempt already made changes.
# Beside common-restart-as-administrator.
result-not-elevated = Atlas didn't have administrator permission, so no installation changes were made.
result-not-elevated-resumed = Atlas didn't have administrator permission, so this attempt stopped. An earlier attempt already made changes.
# The installer's live check found Windows or Store updates unfinished. Beside go-to-ready, where
# updating starts again by itself.
result-preparation-stale = Atlas couldn't confirm that Windows and Store apps are up to date, so installation stopped before changing Windows.
result-preparation-stale-resumed = Atlas couldn't confirm that Windows and Store apps are up to date, so this attempt stopped. An earlier attempt already made changes.
result-failed-preflight = Installation stopped before changing anything. You can try again.
result-failed-staging = Installation stopped while preparing files, before changing Windows. You can try again.
# Beside common-open-windows-security. The "protection switches" are the four the user turned off.
result-failed-applying = Some changes may already have been made. You can try again, or turn the protection switches back on in Windows Security if you stop here.
# The -defender-removed variants once Microsoft Defender has been removed, so there are no
# protection switches to turn back on.
result-failed-applying-defender-removed = Some changes may already have been made. You can try again.
result-failed-resumed = This attempt stopped early, but an earlier attempt already made changes. You can try again, or turn the protection switches back on in Windows Security if you stop here.
result-failed-resumed-defender-removed = This attempt stopped early, but an earlier attempt already made changes. You can try again.
# The -repeated variants follow a retry of an installation already part-way through that stopped
# with the same error as the attempt before it, so they point to a report rather than another try.
# "Send a report" is report-title, in the row of links under the bar.
result-failed-repeated = This attempt stopped with the same error as the one before it, so trying again is unlikely to help. Send a report so the Atlas team can find the cause, and turn your protection switches back on if you stop here.
result-failed-repeated-defender-removed = This attempt stopped with the same error as the one before it, so trying again is unlikely to help. Send a report so the Atlas team can find the cause.
# $apps holds the package names Windows gives the apps, such as MSTeams (text), joined with list-and.
result-failed-repeated-apps = Windows still wouldn't remove { $apps }, so trying again is unlikely to help. Send a report so the Atlas team can find the cause, and turn your protection switches back on if you stop here.
result-failed-repeated-apps-defender-removed = Windows still wouldn't remove { $apps }, so trying again is unlikely to help. Send a report so the Atlas team can find the cause.
result-not-started = The installer didn't start in time, so no installation changes were made. You can try again.
result-lost = The installer stopped without reporting a result, so some changes may have been made. You can try again, or turn the protection switches back on in Windows Security if you stop here.
# Instead of result-lost once Defender is gone, as for the -defender-removed variants above.
result-lost-defender-removed = The installer stopped without reporting a result, so some changes may have been made. You can try again.
restart-now-message = Windows is restarting to finish setting up Atlas.
restart-stopped = Automatic restart cancelled. Save your work, then restart your PC to finish setting up Atlas.
restart-needed = Save your work, then restart your PC to finish setting up Atlas.
restart-dont-now = Restart later
restart-now = Restart now
# The bar when the final checks refuse to start the installer. Its message names what needs
# attention; the bar's button is the fix, and raw errors are behind Show details.
preflight-title = Installation hasn't started
# Beside go-to-options. $choice is a screen-*-name message, as it reads mid-sentence, such as
# processor protections.
preflight-choice-unanswered = Atlas needs your answer for { $choice }.
preflight-choices-unusable = Atlas couldn't use these choices.
# Beside go-to-ready. $checks lists check-* names, such as "Internet connection and Power supply",
# joined with list-and; $count is how many it names.
preflight-checks-changed =
    { $count ->
        [one] { $checks } needs attention since Atlas checked your PC.
       *[other] { $checks } need attention since Atlas checked your PC.
    }
# Beside common-open-windows-security. $summary is the Windows Security summary such as "1 still on".
preflight-security-changed = Windows Security changed since you turned the switches off: { $summary }.
preflight-busy-wait = Another Atlas window is starting an installation. Wait a moment, then try again.
# Beside home-start-over.
preflight-taken-over-start-over = Another Atlas window is now using this setup. Continue there, or start over here.
# Beside go-to-ready.
preflight-record-unreadable-check = Atlas couldn't check whether an earlier installation is still running, so it hasn't started another.
preflight-not-started = Atlas couldn't start the installer, so no installation changes were made. You can try again.
# Instead of preflight-not-started when retrying an installation an earlier attempt had already
# started applying.
preflight-not-started-resumed = Atlas couldn't start the installer, but an earlier attempt already made changes. You can try again.
go-to-ready = Go to Get ready
# Button on the Install step's bar when a question has no answer; opens Your choices there.
go-to-options = Go to Your choices
# Button on the Install step's bar when switches Atlas can't read need confirming on that step.
go-to-security = Go to Windows Security
# Replaces Continue on a choice opened from a Change link on the Install step, while Continue leads straight back there.
go-to-install = Return to Install
output-problem-title = Couldn't read installation progress
install-elevate-title = Atlas needs permission to install
# Under install-elevate-title, beside common-restart-as-administrator.
install-elevate-uac = When Atlas relaunches, Windows asks for your permission.
# A bar on the Install step, beside go-to-ready, when no Atlas package is ready.
install-package-missing = The Atlas package isn't ready
# Step 4 when step 1 is incomplete for this session (checks or Windows updates), with go-to-ready as the button.
install-not-ready-title = Finish Get ready first
install-not-ready-message = Atlas needs to finish checking your PC and updating Windows before it can install.
# A bar on the Install step when a fresh reading of the protection switches no longer passes.
# $summary is the Windows Security summary such as "1 still on".
install-switches-title = Turn off the protection switches again
install-switches-message = Windows Security: { $summary }.
# The Install step's card, when nothing stands in the way of installing, and otherwise.
summary-ready-title = Ready to install
summary-setup-title = Your Atlas setup
summary-activation = Activation
summary-activation-ok = Activated. Atlas won't change this.
summary-activation-missing = Not activated. You can continue, but Atlas won't activate Windows.
summary-activation-unknown = Atlas won't change your Windows activation status.
# How long installing usually takes, from the Atlas package. The card shows the first while the
# box below it is ticked, and the second while it isn't.
summary-time-restarts =
    { $minutes ->
        [one] Usually about { $minutes } minute, then your PC restarts
       *[other] Usually about { $minutes } minutes, then your PC restarts
    }
summary-time-restart-yourself =
    { $minutes ->
        [one] Usually about { $minutes } minute, then restart your PC
       *[other] Usually about { $minutes } minutes, then restart your PC
    }
# The check box on the card. It starts from settings-restart-automatically and applies to this install only.
summary-restart-automatically = Restart automatically when installation finishes
# A row of the card's details: what Atlas turns off whichever Microsoft Defender answer is chosen.
summary-turned-off = Also turned off
summary-turned-off-value = Smart App Control, Enhanced Phishing Protection and Find my device
summary-show-command = Show installation command
summary-hide-command = Hide installation command
# Accessible name of the Copy button under the installation command.
summary-copy-command-a11y = Copy installation command
summary-command-unavailable = Couldn't prepare the installation command. Details: { $error }
summary-not-chosen = No choice made yet
# Accessible name of a Change link on the Install step, and of the Windows download's on the ISO
# page. $title is a screen-*-name message, or iso-download-what, as it reads mid-sentence.
summary-change-a11y = Change { $title }
# The summary's first row on an update or reinstall. Its value is update-path-keep or
# update-path-choose.
summary-update-path = How Atlas updates
# Why Continue waits on Get ready: read with it as its description, and shown beside it
# where the page doesn't already say so. 8 words or fewer.
footer-still-checking = Preparing for installation
footer-checks-blocked = Fix what the checks found to continue
footer-manager-outdated = Download a newer Atlas Manager to continue
footer-need-files = Get the Atlas package to continue
# Tester build variant of footer-need-files.
footer-need-package-bundled = Prepare the bundled Atlas package to continue
footer-drivers = Decide how drivers are installed to continue
footer-windows-terms = Accept the licence terms to continue
footer-updating = Updating Windows and Store apps…
footer-restart = Restart your PC to continue
footer-reading-security = Checking the protection switches
# Why Continue waits on Windows Security, read with it as its description: while a switch is
# on, then while only switches Atlas couldn't read are left to confirm.
footer-security-pending = Turn off all four switches to continue
footer-security-confirm = To continue, confirm the switches Atlas couldn't read
# Beside Install Atlas while automatic restart is on: the PC restarts when installation finishes.
footer-install-ready = Save your work and close your apps first
button-install = Install Atlas
log-earlier-lines =
    { $count ->
        [one] { $count } earlier line is in the log file.
       *[other] { $count } earlier lines are in the log file.
    }
# Appended when the log is copied. $path is a file path (text).
log-full-log-note = (full log: { $path })

## The installing view

installing-title = Installing Atlas
# What Atlas is doing, under installing-title and as the progress bar's accessible name: a
# short verb phrase ending in an ellipsis. The final checks and the installer's own first
# checks both read installing-checking-label.
installing-checking-label = Checking your PC…
installing-staging-label = Copying Atlas's files…
installing-applying-label = Setting up Windows…
installing-finishing-label = Finishing…
# The one line under the progress bar: when the PC restarts by itself after, and when it doesn't.
installing-keep-on-restart = Keep your PC on and plugged in. It restarts by itself when installation finishes.
installing-keep-on = Keep your PC on and plugged in. Restart it when installation finishes.
# When Atlas can't follow the installer's log. Its title is output-problem-title; "Open log
# folder" is common-open-log-folder, its button.
installing-output-problem = This doesn't mean installation has stopped.
installing-installed-title = Atlas is installed
# Under installing-installed-title while the restart counts down, with installing-restart-save
# under it, then restart-now and restart-dont-now.
installing-restart-countdown =
    { $seconds ->
        [one] Your PC restarts in { $seconds } second.
       *[other] Your PC restarts in { $seconds } seconds.
    }
installing-restart-save = Save your work first.

## The "Atlas is installed" window after the restart

installed-title-version = Atlas { $version } is installed
installed-title = Atlas is installed
installed-ready = You're all set. Your PC is ready to use with Atlas.
# A line under the setup card where the user installs drivers themselves, with
# installed-drivers-guide, a link, under it.
installed-manual-drivers-detail = Get chipset, network and graphics drivers from your PC, motherboard or device manufacturer.
installed-drivers-guide = Open the drivers guide
# After an installation that removed Microsoft Defender. Its message is cost-defender-disable.
installed-defender-removed-title = Microsoft Defender was removed
# Home and the "Atlas is installed" window, after an installation that kept Microsoft Defender,
# when it is missing and no Atlas package removed it. Its title is security-banner-missing-title;
# its button is report-title.
defender-missing-message = Atlas didn't remove it. If you don't use another antivirus app, install one to protect your PC.
# Home and the "Atlas is installed" window, when Atlas's record kept Microsoft Defender but
# Atlas's own package still removes it. Its button is home-reinstall. 7. Security, Defender and
# Toggle Defender are folder and file names in the Atlas folder, in English on every PC.
installed-defender-not-restored-title = Microsoft Defender is still removed
defender-not-restored-message = An earlier Atlas update didn't bring it back, so Defender isn't protecting your PC. Reinstall Atlas and keep Defender, or run Toggle Defender from 7. Security > Defender in the Atlas folder.
# The "Atlas is installed" window, when what the installation recorded for some choices isn't
# what was chosen. The help links (Send a report, Export diagnostics, Open log folder) follow.
installed-not-applied-title = Some choices didn't apply
# $choices lists their names as they read mid-sentence (screen-*-name), such as "Microsoft
# Defender and processor protections", joined with list-and; $count is how many it names.
installed-not-applied-choices =
    { $count ->
        [one] This choice stayed as it was: { $choices }.
       *[other] These choices stayed as they were: { $choices }.
    }
# After an update whose last step turned Windows Update off, or paused it, again, as the
# user's own Atlas choices ask.
installed-update-off-title = Windows Update is off again, as you chose
installed-update-off-message = While it's off, your PC doesn't get security updates.
installed-update-paused-title = Windows updates are paused again, as you chose
installed-update-paused-message = While they're paused, your PC doesn't get security updates.

## Settings

settings-title = Settings
# Headings of the page's sections, over their cards. settings-language and settings-help
# head sections too.
settings-appearance = Appearance
settings-installation = Installation
settings-privacy = Privacy
settings-theme = App theme
settings-theme-system = Match Windows
settings-theme-light = Light
settings-theme-dark = Dark
settings-theme-contrast-note = Atlas is using the colours from your Windows contrast theme.
settings-language = Language
# The setting in the Language section, and its box's name.
settings-app-language = App language
# The first choice in the language box: following Windows, then the language that gives.
# $language is that language's own name, for example "English (United Kingdom)".
settings-language-match-windows = Match Windows – { $language }

# A short tag after each language in the list that is translated but not yet reviewed
# by a native speaker.
settings-language-preview-tag = Preview
# Under the language box while the language in use is a preview translation, once its
# notice (preview-notice) has been dismissed.
settings-language-preview-in-use = This translation hasn't been reviewed by a native speaker yet.
# A bar at the top of the content while a preview translation is in use, until the user
# dismisses it (common-dismiss names its close button). $language is the language's own
# name; preview-notice-switch and preview-notice-language are its links.
preview-notice = { $language } is a preview translation and may contain mistakes.
preview-notice-switch = Switch to English
preview-notice-language = Change language
# Under the language box when the language chosen isn't in this version, and the box
# shows English, which is in use.
settings-language-chosen-unavailable = The language you chose isn't in this version of Atlas, so Atlas shows English. Your choice is kept.
# Under the language box while Match Windows is chosen and Atlas has none of the Windows
# display languages.
settings-language-windows-unsupported = Atlas doesn't support your Windows display language yet, so it shows English.
# Under the language box while Match Windows is chosen and the Windows display languages
# couldn't be read.
settings-language-windows-unreadable = Atlas couldn't check your Windows display language, so it shows English.
# Under the language box when the regional format is of another language or region than
# the app. $locale is the regional format's own name, for example "English (United States)".
settings-language-formats = Numbers, dates and times follow your Windows regional format: { $locale }.
# Instead of settings-language-formats when the regional format writes dates or times
# right to left. $locale is the format's English name, for example "Arabic (Saudi Arabia)".
settings-language-formats-numbers-only = Numbers follow your Windows regional format: { $locale }. Dates and times use a standard format because Atlas can't show right-to-left text yet.
settings-language-contribute = Help translate Atlas
# The usage analytics switch, with its description and a link to the privacy policy.
settings-share-usage = Share usage data with Atlas
settings-share-usage-description = Pages you open, ISO builds and whether installs succeed.
settings-privacy-policy = Privacy policy
# The switch covers the restart after installing and the restart that Windows and Store
# updates need before installing.
settings-restart-automatically = Restart automatically after installing and updating
settings-restart-automatically-description = Your PC restarts within a minute of Atlas finishing, closing open apps.
settings-restart-locked = You can change this after installation finishes.
# Heading over Send a report, Export diagnostics and settings-open-data-folder.
settings-help = Help
settings-about = About
settings-about-app = Atlas Manager
settings-about-licence = Licence
settings-about-licence-value = GPL-3.0, free and open source
settings-view-source = View source code
# Link that opens the third-party licence notices.
settings-view-licences = View licence notices
# Under the links when Windows could not open the notices.
settings-licences-failed = Couldn't open the licence notices. Try again, or find them in the source code on GitHub.
settings-open-data-folder = Open app folder

## Optional choices: explanations shown before selection.

consequence-disable-hibernation = Frees the disk space used to save your session during hibernation. Hibernate and Fast Startup will be unavailable.
consequence-disable-power-saving = Disables power-saving features. Your PC may use more power, run hotter and have shorter battery life.
consequence-disable-core-isolation = Turns off an extra layer of Windows security, including memory integrity. This reduces protection, and games using anti-cheats such as Riot Vanguard or FACEIT may not start until you turn memory integrity back on.
consequence-remove-snipping-tool = Removes the Windows app for taking screenshots and screen recordings.
consequence-uninstall-edge = Removes the Microsoft Edge browser. Make sure you have another browser, or choose one below.
# Under Remove Microsoft Edge in the Install step's summary, with a caution glyph.
caution-uninstall-edge = Deletes your Edge bookmarks, history and saved passwords on this PC.
consequence-install-another-browser = Choose a browser below and Atlas will install it for you.
consequence-install-toolbox = Add Atlas Toolbox to help manage your Atlas settings. Toolbox is in beta, so some features may be unfinished.
consequence-install-eclean = A maintenance tool from the team behind AtlasOS, for keeping your PC tidy after setup. Review junk files and startup apps. Requires an account and an internet connection.

## ISO creation
iso-open = Create an Atlas ISO
iso-title = Create an Atlas ISO
iso-recommended = Recommended
# Titles of the three ISO steps in the stepper: where Windows comes from, how it's set
# up, and the review that creates the ISO.
iso-step-source = Windows
iso-step-setup = Setup
iso-step-create = Create
# The first question on the Windows step. It sets the defaults that follow: the
# architecture, language, edition and account name, and this PC's network drivers.
iso-target-title = Which PC is this ISO for?
iso-target-this = This PC
iso-target-another = Another PC
# Under the question when the ISO is for another kind of processor than this PC's, so only
# Another PC applies. $architecture is iso-architecture-x64 or iso-architecture-arm64.
iso-target-arch = This ISO is for { $architecture } PCs.
iso-source = Windows ISO
# Starts the Windows 11 download at once, in the language and architecture of the caption
# under it (iso-download-caption). Also in the Windows ISO's Change menu and on the bar of
# an ISO Atlas can't use.
iso-download-windows = Download from Microsoft
# What the download gets. $language is Microsoft's own name for the language, in English,
# such as "English International"; $architecture is iso-architecture-x64 or -arm64.
iso-download-caption = Windows 11 · { $language } · { $architecture }
# The same while Microsoft's list of languages loads.
iso-download-caption-loading = Windows 11 · { $architecture }
# Used only inside summary-change-a11y, as the accessible name of the Change link beside the
# download's language and architecture: "Change Windows download".
iso-download-what = Windows download
iso-download-language = Language
iso-download-arch = Architecture
iso-download-languages = Loading languages…
# The progress bar's label while Windows downloads, then how much has arrived. $received and
# $total are sizes such as "2.4 GB" (size-gigabytes).
iso-downloading = Downloading Windows 11…
iso-download-amount = { $received } of { $total }
# The download couldn't start because Microsoft's download service couldn't be reached
# through Atlas, or it stopped part-way. Try again (common-try-again) is beside it.
iso-download-unreachable = Atlas couldn't reach Microsoft's download service. Check your internet connection, then try again.
iso-download-incomplete = The download didn't finish. Check your internet connection and free space, then try again.
iso-download-website = Open Microsoft's download page
# Opens the file picker for a Windows ISO, and is that picker's Open button. On the ISO and
# USB pages, and on the bar of an ISO Atlas can't use.
iso-use-local = Choose an ISO file
# A status pill while the files are checked, before Continue becomes available.
iso-checking = Checking your Windows ISO…
# Accessible name of the Ready pill once the check passed. $facts is the ISO's architecture
# and size, such as "x64 · 6.6 GB".
iso-checked-a11y = Windows ISO ready, { $facts }
iso-package-latest-label = Latest
# The latest Atlas release is older than this Atlas Manager can use; Open package file
# (package-open-file) is under it.
iso-package-release-old = The latest Atlas release is older than this Atlas Manager can use.
# While Atlas finds and downloads the latest Atlas package by itself.
iso-package-fetching = Getting the latest Atlas…
# The release check failed, so the latest package couldn't be found; Try again is beside it.
iso-package-release-failed = Atlas couldn't check for the latest version. Check your internet connection, then try again.
# Accessible name of a Change button or link on the ISO and USB pages: $action is its text and
# $field the label of what it changes, as shown, such as iso-source, iso-edition or an ISO
# step's title.
iso-pick-a11y = { $action }: { $field }
# Beside the unavailable Continue on the Windows step while there's no Windows ISO yet.
iso-need-windows = Get a Windows ISO to continue
# The question on the Setup step about when the package's choices are made.
iso-mode-question = When do you want to make your Atlas choices?
iso-mode-after = After sign-in
iso-mode-after-description = Atlas guides you through setup after you sign in.
iso-mode-now = Now
iso-mode-now-description = Saved in the ISO. You install Atlas after signing in.
# A check box under Now, whose description already says the choices are saved in the ISO.
iso-mode-before-desktop = Finish before the desktop opens
iso-mode-before-desktop-description = After you sign in, Atlas runs full screen until it's installed.
# In place of the question when the Atlas package can't save choices in an ISO.
iso-mode-unavailable = This Atlas package can't save choices in the ISO, so you make them after sign-in.
iso-atlas-options = Atlas choices
# The line at the top of the Create step.
iso-create-intro = Creating the ISO doesn't change this PC or your original ISO.
iso-review-package = Atlas package
iso-review-output = New ISO
iso-review-edition = Edition
iso-review-editions = Editions
iso-edition = Windows edition
# The edition shown on the Setup step's edition card when Windows Setup asks which edition to
# install.
iso-edition-auto = Windows Setup asks
# The first item of that card's edition menu, above the ISO's own editions: the choice that lets
# Windows Setup ask which edition to install.
iso-edition-auto-menu = Windows Setup asks
# An optional check box: accepting the terms here stops Windows Setup from asking.
iso-accept-terms-optional = Accept the Windows licence terms, so Windows Setup doesn't ask
iso-architecture-x64 = x64
iso-architecture-arm64 = Arm64
# A file size; $size is a formatted number (text). Megabytes below a gigabyte.
size-megabytes = { $size } MB
size-gigabytes = { $size } GB
iso-review-account = Account name
iso-review-target = Install on
iso-review-drivers = Drivers
# A review row about the Windows Setup screens the ISO's answer file skips.
iso-review-setup-screens = Windows Setup
iso-review-skips = Skips Microsoft account and privacy screens
iso-review-skips-terms = Skips the licence, Microsoft account and privacy screens
iso-review-network = Network drivers
iso-review-network-included = This PC's Wi-Fi and Ethernet drivers
# The Atlas choices row when they're saved in the ISO and finish before the desktop opens.
iso-review-mode-before-desktop = Now, finished before the desktop opens
# Under the new ISO on the Create step. $needed and $free are sizes such as "35.0 GB"
# (size-gigabytes); $drive is a drive such as "C:".
iso-destination-space = Needs { $needed } · { $free } free on { $drive }
iso-destination-short = The ISO needs { $needed }, and { $drive } has { $free } free. Free up space, or save the ISO to another drive.
iso-destination-filesystem = { $drive } can't hold the ISO's large files. Save it to a drive formatted as NTFS, such as your Windows drive.
iso-destination-unusable = Atlas can only save the ISO to a folder on a drive in this PC.
iso-create = Create ISO
# Heading above the progress bar and the list of stages (iso-stage-*) while the ISO is
# being created.
iso-progress-title = Creating your ISO…
# The progress bar's label while an ISO or a USB drive is created: the stage under way, ending
# in an ellipsis. $stage is one of the iso-stage-* or usb-stage-* names. Those names also label
# the list of stages, each shown as completed, in progress or not started, so add here any
# in-progress form your language needs.
iso-progress-stage = { $stage }…
# The stages of creating the ISO, as a list under iso-progress-title. Each name reads as
# completed, in progress or not started (iso-stage-a11y), so write it as a noun or plain verb
# phrase, without an in-progress form; English uses the -ing noun.
iso-stage-read = Reading the Windows ISO
iso-stage-copy = Copying Windows files
iso-stage-add-atlas = Adding Atlas
iso-stage-master = Writing the ISO file
iso-stage-verify = Checking the new ISO
iso-stage-cleanup = Finishing up
# Accessible name of one stage while the ISO is created. No "Step": the screen reader adds
# "4 of 6". $status is stepper-status-completed or one of the three below.
iso-stage-a11y = { $title }, { $status }
iso-stage-status-current = in progress
# The stage where creating the ISO stopped with an error.
iso-stage-status-failed = failed
iso-stage-status-not-started = not started
iso-progress-keep-open = Keep Atlas open until it finishes.
iso-cancel = Cancel creation
iso-cancelling = Waiting for a safe point to cancel
# The heading over the progress bar of an ISO or a USB drive once cancelling is asked for.
iso-cancelling-short = Cancelling…
iso-cancelled = ISO creation cancelled
iso-cancelled-unchanged = Your original ISO wasn't changed.
iso-complete = Your ISO is ready
iso-complete-backup = Back up your files before you reinstall Windows from it.
# The finished page's main button, which opens the USB drive panel.
iso-create-usb = Create a USB drive
iso-open-folder = Show in folder
iso-failed = Couldn't finish creating the ISO
# Under iso-failed, beside Try again.
iso-failed-retry = Make sure your files are still where you chose them and the drive you're saving to is connected, then try again.
# Title while checking the files fails; the messages below say why.
iso-check-failed = Couldn't check the files
iso-check-failed-retry = Make sure the ISO and the Atlas package have finished downloading, then try again.
# Nothing ran because the folder the worker runs from couldn't be created.
iso-unstaged = Atlas couldn't prepare its working folder, so nothing changed.
# Titles and messages for an ISO or package Atlas can't use. The bar offers the fix:
# iso-download-windows and iso-use-local for the ISO, iso-fix-package for the package.
iso-edition-unsupported-title = This ISO has no edition Atlas supports
iso-edition-unsupported = Windows Home and LTSC aren't supported. Use an ISO with Pro, Education or Enterprise.
iso-customised-title = This ISO has been customised
iso-customised = It already contains setup files, such as autounattend.xml. Use an unmodified ISO from Microsoft.
iso-preview-title = This ISO is a preview build
iso-preview = Its Windows build isn't in Microsoft's list of public releases. Use an ISO from Microsoft.
iso-windows-unsupported-title = This Atlas package can't use this ISO
iso-windows-unsupported = Use an unmodified Windows 11 ISO for a version the package supports.
iso-release-unknown-title = Atlas couldn't confirm this Windows release
iso-release-unconfirmed = Atlas checks it against Microsoft's list of public releases. Check your internet connection, then try again.
# $minimum is the oldest Atlas version that can make an ISO, such as "0.6.0".
iso-package-old-title = This Atlas package can't make an ISO
iso-package-old = Use Atlas { $minimum } or newer.
iso-manager-missing-title = Atlas Manager's file is missing
iso-fix-package = Choose another package
# A package that needs a newer Atlas Manager; Download Atlas Manager (manager-download) is
# beside it, and acquire-manager-update-needed says which version.
iso-manager-outdated-title = Atlas Manager needs an update
# This PC's network drivers couldn't be exported; the button beside it builds without them.
iso-network-not-added = Atlas couldn't add this PC's network drivers to the ISO.
iso-network-skip = Create without them
# Title of the bar that asks for administrator permission. Its message is iso-admin-reason,
# or iso-elevation-declined after Windows refused the relaunch (UAC declined).
iso-elevation-title = Atlas needs permission to create an ISO
iso-admin-reason = It's needed to read your Windows ISO and create the new one.
iso-elevation-declined = Windows didn't give Atlas permission, so it can't read your Windows ISO yet.
# The free space ran out while the ISO was being created.
iso-failed-space = There isn't enough free space on the destination drive. Free up space, or save the new ISO to another drive.
# Under iso-manager-missing-title.
iso-manager-missing = Download AtlasManager.exe to a local folder such as Downloads, then open it from there.
# Home and LTSC are the editions ISO creation drops; the others are examples it keeps.
iso-failed-edition = This ISO contains no supported Windows editions. Windows Home and LTSC aren't supported. Use an ISO that includes another edition, such as Pro, Education or Enterprise.
# Opens the folder with an ISO or USB job's raw logs.
iso-diagnostics = Open log folder
# On the ISO and USB pages while Atlas updates Windows, or puts back Windows Update settings,
# from another page. Their controls are unavailable until it finishes.
iso-locked = Atlas is busy with Windows Update. You can continue here once it finishes.
# Names of the markers Windows sets when it wants a restart. They're listed, joined with
# list-separator, in detail-restart-pending-reasons ("Windows needs to restart to finish earlier changes (…)")
# and ready-updates-restart-persists-reasons ("Restart reasons: …"); keep them short and lower
# case where the language allows.
prepare-reason-servicing = Windows servicing
prepare-reason-windows-update = Windows Update
prepare-reason-file-renames = files waiting to be replaced
prepare-reason-update-agent = the Windows Update service
prepare-reason-unknown = reason not reported
# Under prepare-failed-title, with Try again (common-try-again).
prepare-failed-retry = If trying again doesn't help, finish the remaining updates in Windows Update or Microsoft Store.
# Title of the error bar on the update card; the cause is its message.
prepare-failed-title = Some updates couldn't finish
# Under prepare-unconfirmed-title: the run ended without writing any result, for example after
# Atlas was closed while it ran.
prepare-unconfirmed = Updating stopped before it reported a result.
# Title of the bar over prepare-unconfirmed: not called a failure, as none was reported.
prepare-unconfirmed-title = Couldn't confirm the update result
prepare-affected-app = the affected app
# A Store app couldn't update because it was open. $app is its name, such as NanaZip, or
# prepare-affected-app.
prepare-close-app = Close { $app }, then try again. If you can't find it, close it in Task Manager.
prepare-install-busy = Another installation or a required restart is blocking updates. Let other installations finish, restart your PC if Windows asks you to, then try again.
# Updates failed with 0x80073712 after Atlas's own repair of the component store (DISM). The
# button is prepare-restart-and-retry; updating carries on by itself after the restart.
prepare-components-damaged-title = Windows couldn't repair itself
prepare-components-damaged = Windows reports damage that stops updates installing. A restart can clear it, and Atlas carries on after you sign in.
prepare-restart-and-retry = Restart and try again
# Windows records damage to its component store that it can't repair, so Atlas stops before
# any update. The one button is iso-open.
prepare-components-unrepairable-title = Windows is too damaged to update
prepare-components-unrepairable = Back up your files, then reinstall Windows with an Atlas ISO.
# Causes the update worker names. The worker's own English message is shown below as a detail.
prepare-failed-session-owner = Atlas is running as a different account from the one signed in to Windows. Sign in to Windows with an administrator account, open Atlas from that account, then try again.
prepare-failed-store-missing = Microsoft Store isn't set up for your account. Open Microsoft Store once, or reinstall it if it's missing, then try again.
prepare-failed-store-battery = Microsoft Store paused updates to save battery. Plug in your PC, then try again.
prepare-failed-store-network = Microsoft Store paused updates until your PC has an unmetered connection. Connect to unmetered Wi-Fi or Ethernet, then try again.
prepare-failed-store-timeout = Store apps haven't finished updating. Finish the remaining downloads in Microsoft Store, then try again.
prepare-failed-store-passes = Microsoft Store kept offering new updates. Finish the remaining updates in Microsoft Store, then try again.
prepare-failed-manual-updates = Some Windows updates need to be finished in Windows Update. Open Windows Update, finish them, then try again.
prepare-failed-windows-passes = Windows Update kept offering new updates. Finish the remaining updates in Windows Update, then try again.
prepare-failed-windows-update-unreachable = Windows Update couldn't reach Microsoft's servers. Check your internet connection and any firewall, proxy or VPN, then try again.
# Atlas Manager runs from a folder that links to another place (a junction or symbolic
# link). "Linked folder" and "local folder" as in usb-iso-location. Atlas keeps using
# the folder it was opened from, so trying again in the same window can't help.
prepare-failed-source-linked = Atlas Manager is in a linked folder. Close Atlas, move Atlas Manager to a local folder on this PC, then open it from there.
prepare-error-code = Error code: { $code }
prepare-open-store = Open Microsoft Store
prepare-windows-search = Checking Windows Update…
prepare-percent = { $percent }% of this stage
prepare-count = Updates completed: { $completed } of { $total }
prepare-bytes = Downloaded { $downloaded } of approximately { $total } MB
prepare-progress-still = No progress for { $minutes } min. Large updates can take a while, so keep Atlas open.
prepare-report-late = Windows hasn't reported progress for a while. Updates may still be running, so keep Atlas open.
prepare-windows-download = Downloading Windows updates…
prepare-windows-install = Installing Windows updates…
# While DISM repairs Windows' component store, before updates or after one failed on it, with
# prepare-windows-repair-detail under the progress bar. DISM reports no progress.
prepare-windows-repairing = Repairing Windows…
prepare-windows-repair-detail = Windows reports damage that can stop updates installing. This can take half an hour or more.
prepare-store-search = Checking Microsoft Store…
prepare-store-install = Updating Microsoft Store and its apps…
prepare-stop = Stop updating
prepare-start = Check and install updates
# Under the Administrator check, while the Atlas package is still downloading or unpacking.
prepare-wait-for-package = Available when the Atlas package is ready.
iso-username = Local account name
# Under the local account name: Windows asks for the password at the first sign-in.
iso-account-help = You'll choose a password when you first sign in.
iso-username-placeholder = Your name
# Beside the unavailable Continue button while the local account name is empty.
iso-account-empty = Enter a local account name to continue
# Keep the list of symbols exactly: Windows refuses them in account names.
iso-account-invalid = Use up to 20 characters, with no space at the start or end and none of these: " / \ [ ] : ; | = , + * ? < > @
iso-account-trailing-dot = The name can't end with a full stop.
iso-account-reserved = Windows uses this name for a built-in account. Choose another name.
# The answer file on the ISO hides these Windows setup screens.
iso-terms-in-setup = Windows Setup will ask you to accept the licence terms.
prepare-drivers = How should drivers be installed?
prepare-drivers-auto = Get drivers through Windows Update
# The same answer as a radio button's label, where the choice is made.
prepare-drivers-auto-recommended = Get drivers through Windows Update (recommended)
prepare-drivers-auto-detail = Windows finds drivers for your hardware.
prepare-drivers-manual = Install drivers myself
prepare-drivers-manual-detail = Windows Update won't install drivers, so you'll need to get them from your PC or device maker. Drivers already installed are kept.
# The Setup step's drivers card: this PC's network drivers on the ISO, then the choice
# Atlas Manager applies after sign-in, asked with prepare-drivers.
iso-drivers-card = Drivers
iso-network-drivers = Include this PC's Wi-Fi and Ethernet drivers
# The third driver answer, and its value on the Create step: Get ready asks on the new PC.
iso-drivers-defer = Choose after sign-in
prepare-network-unmetered = Updates need an internet connection that isn't metered. Connect to Wi-Fi or Ethernet, then try again.
# Connected, but Windows found no internet access (a captive portal, or DNS or firewall filtering).
prepare-network-limited = Windows reports that this network has no internet access. Sign in to the network if it asks you to, or check your router and any DNS or firewall filtering, then try again.
# "Metered connection" is the switch's name in Windows network settings.
prepare-network-metered = This connection is metered or has a data limit. Connect to an unmetered network, or turn off Metered connection in network settings, then try again.
prepare-network-settings = Open network settings
iso-stage-network-drivers = Preparing network drivers
# Under iso-complete when this PC's network drivers were asked for but the adapters use
# drivers that come with Windows, so none were added.
iso-network-inbox = This PC's network adapters use drivers that come with Windows, so the ISO doesn't need to include them.
desktop-setup-description = Finish setting up your PC. Your Atlas choices are saved; you can return to Windows if you need to.
desktop-setup-exit = Continue in Windows

# Windows installation USB
usb-title = Create a USB drive
usb-existing = Create a USB drive from an existing ISO
# Title of the drive card, and the name of a drive that doesn't report one.
usb-drive = USB drive
# Title of the card with the ISO the USB drive is made from.
usb-iso-title = Windows ISO
# No ISO was given, and none whose name starts with "Atlas" is in Downloads.
usb-iso-missing = There's no Atlas ISO in your Downloads folder.
usb-iso-checking = Checking the ISO…
# What checking the ISO found. It runs before anything is erased, so none of these mentions the drive.
usb-iso-not-usable = Atlas can't make a USB drive from this ISO. Use an ISO created by Atlas, or a Windows 11 ISO from Microsoft for a version Atlas supports.
# A linked folder points to another place (a junction or symbolic link).
usb-iso-location = The ISO or Atlas Manager is on a network location or in a linked folder. Move it to a folder on this PC, such as Downloads.
# Splitting a large Windows image needs room on the drive Windows is on. Atlas checks again every 30 seconds.
usb-working-space = There isn't enough free space on the Windows drive to prepare this ISO. Free up some space, and Atlas checks again by itself.
# The ISO couldn't be read for another reason, such as a damaged file.
usb-iso-unreadable = Atlas couldn't read this ISO. Try again, or use another ISO.
# Opens the Storage page of Windows Settings, where space can be freed.
usb-open-storage = Open Storage settings
usb-looking = Looking for USB drives…
# $size is a whole number of gigabytes, as drives are sold.
usb-connect = Connect a USB drive of { $size } GB or more.
# Under a drive that can't be used, after its size and letters: why. $size is a whole number
# of gigabytes, as drives are sold, as in usb-connect.
usb-drive-too-small-needs = Too small. Needs { $size } GB or more.
usb-drive-too-small-iso = Too small for this ISO
usb-drive-has-iso = Your ISO is on this drive
usb-drive-has-app = Atlas Manager is running from this drive
# A drive's size as it's sold, which isn't the size Windows shows. $size is a whole number of
# gigabytes, or a number of terabytes (text).
usb-drive-size = { $size } GB
usb-drive-size-tb = { $size } TB
# Joins a drive's size and its letters, an ISO's architecture and size under its name, and
# ready-checks-passed-some and ready-checks-handled on Get ready.
usb-detail-separator = { " · " }
usb-create = Create USB drive
# Beside the unavailable Create USB drive (usb-create) while several drives are listed and none is picked.
usb-hint-pick = Pick a USB drive first
# The question before erasing. $drive is the name the drive reports, such as Kingston
# DataTraveler Max (text); $size is usb-drive-size or usb-drive-size-tb; $letters is its drive
# letters, such as "F:" or "F:, G:". A drive with no letter, such as one an unfinished write
# left, is asked with usb-confirm-title.
usb-confirm-title-letters = Erase { $drive } ({ $size }, { $letters })?
usb-confirm-title = Erase { $drive } ({ $size })?
# The same question for a drive that reports no name.
usb-confirm-title-unnamed-letters = Erase the USB drive ({ $size }, { $letters })?
usb-confirm-title-unnamed = Erase the USB drive ({ $size })?
usb-confirm-message = Everything on it will be deleted. Your ISO is kept.
usb-confirm-erase = Erase and create
usb-progress-title = Creating the USB drive…
# $percent is a whole number.
usb-percent = { $percent }%
# The stages of creating the USB drive, as a checklist under usb-progress-title, which
# iso-progress-stage also names while each runs. Each name reads as completed, in progress or not
# started, as the ISO's stages do, so write it as a noun or plain verb phrase.
usb-stage-prepare-files = Preparing files
usb-stage-formatting = Formatting
usb-stage-copying = Copying files
usb-stage-checking = Checking the drive
usb-stage-ejecting = Ejecting
usb-keep-open = Keep Atlas open and the drive connected.
usb-scan-failed-title = Couldn't list USB drives
usb-scan-failed-retry = Atlas couldn't read the drives connected to this PC. Try again.
# The title of the error bar for a USB drive, and the heading of the finished drive's page.
usb-failed-title = Couldn't create the USB drive
usb-complete-title = Your USB drive is ready
# F12, F11 and Esc are key names.
usb-ready = Unplug it, back up the PC you're reinstalling, then start that PC from the USB drive. Its boot menu often opens with F12, F11 or Esc.
# After erasing may have begun.
usb-failed-partial = The drive was partly written. Check it's connected, then try again.
# Before anything on the drive was changed.
usb-failed-before-erase = Atlas stopped before changing the drive. Try again.
# Before erasing, the drive no longer matched the list: it was removed, reconnected or replaced.
# Atlas reads the list again, and picks the drive again if it's back.
usb-drive-changed-title = The USB drive changed
usb-drive-changed = It was removed or reconnected before Atlas erased it, so nothing on it changed.
usb-drive-cancelled-title = USB drive creation cancelled
usb-cancelled-partial = The drive is incomplete. Create it again before using it.
usb-cancelled-unchanged = Your USB drive wasn't changed.
usb-eject-failed-title = Couldn't eject the USB drive
usb-eject-failed-ready = It's ready to use. Close any files or windows that use it, then try again.
# Title of the bar with Relaunch as administrator (common-restart-as-administrator). Its
# message is usb-admin-reason, or usb-elevation-declined after Windows refused the relaunch
# (UAC declined), as on the ISO page.
usb-elevation-title = Atlas needs permission to create a USB drive
usb-admin-reason = Atlas needs administrator permission to erase and write the drive.
usb-elevation-declined = Windows didn't give Atlas permission, so it can't write the USB drive yet.
# Home, LTSC and Server are the editions the check refuses; the others are examples of
# editions it accepts. Keep edition names as Windows shows them.
detail-edition-unsupported = Windows 11 Home, LTSC and Server editions aren't supported. Use another edition, such as Pro, Education or Enterprise. If Windows couldn't identify your edition, resolve that before continuing.
install-source-title = Installation unavailable
install-source-unsupported = Atlas { $source } can't be updated to { $target } directly. To use this version, back up your files and reinstall Windows.
# Before a package is chosen, so the version on offer isn't known yet.
install-source-unsupported-any = Atlas { $source } can't be updated directly. To use a newer version, back up your files and reinstall Windows.
# $folder is a folder path (text).
install-source-resume-package = An installation of Atlas { $target } didn't finish, and only the Atlas { $target } package can finish it. Open that Atlas package (.atlaspkg). If Atlas downloaded it, it's in { $folder }.
# Tester build: only the bundled Atlas package can be installed.
install-source-resume-bundled = An installation of Atlas { $target } didn't finish. This test build can only install its bundled Atlas package, so finish that installation with the Atlas { $target } package in a release build of Atlas Manager.
# Send a report and Export diagnostics are offered with it.
install-source-unconfirmed = Atlas couldn't confirm what's already installed on this PC, so it won't install anything for now.
# Atlas's files are on this PC without a record of a finished installation, as an earlier Atlas
# leaves them when its installation didn't finish or Windows was reinstalled over it. Create an
# Atlas ISO (iso-open) is beside it.
install-source-unrecorded = This PC has files from an earlier Atlas, but no record of a finished installation, so it can't be updated. To install Atlas, back up your files and reinstall Windows.
# Under the editions on the Create step, when Windows Setup asks which to install.
iso-edition-selection = In Windows Setup, choose an edition you have a licence for.
detail-windows-preview = Insider builds aren't supported. Use a public release of Windows 11.
detail-windows-release-unknown = Atlas couldn't verify this Windows build as a public release. Connect to the internet and check again.
# $build is this PC's Windows build and update number, such as 26300.9807 (text).
detail-windows-release-not-listed = Build { $build } isn't in Microsoft's list of public Windows 11 releases, so Atlas can't install on it yet. Release Preview and other preview builds aren't supported. Check again once Microsoft lists this build.


prepare-continue = Continue updates
prepare-saving-restart = Saving your choices and arranging to reopen Atlas after Windows restarts…
prepare-restart-save-failed = Your choices couldn't be saved. Try again before restarting.
prepare-restart-registration-failed = Your choices are saved, but Atlas couldn't arrange to open again after the restart. Try again, or restart your PC yourself and open Atlas after you sign in.
# The same cause as prepare-failed-source-linked, met while arranging the restart. Both ways
# on need the move, because Atlas keeps using the folder it was opened from.
prepare-restart-source-linked = Your choices are saved, but Atlas can't arrange to open again after the restart while Atlas Manager is in a linked folder. Close Atlas and move Atlas Manager to a local folder on this PC. Then open it from there, or restart your PC yourself and open it from there after you sign in.
prepare-restart-failed = Atlas couldn't restart your PC. Try again, or restart it from the Start menu. Your choices are saved, and Atlas opens again after you sign in.
diagnostics-export = Export diagnostics
# Beside a spinner while an export runs, and in Send a report's footer while its diagnostics
# are collected.
diagnostics-exporting = Collecting diagnostics…
# Accessible name of the row of help links: report-title, diagnostics-export and iso-diagnostics.
diagnostics-help-a11y = Get help
# Title of the result bar after an export; its button is iso-open-folder.
diagnostics-saved = Diagnostics saved
# Under diagnostics-saved, above diagnostics-saved-privacy. $file is the ZIP's name, such as
# Atlas-diagnostics-2026-11-24-0612.zip, and $folder the name of the folder it's in,
# "Diagnostics" (both text, never translated).
diagnostics-saved-in-folder = Saved as { $file } in Atlas's { $folder } folder.
# Under diagnostics-saved. Says exactly what the export removes, so keep every item.
diagnostics-saved-privacy = Atlas removed your user name, PC name, email addresses and known passwords or keys from it.
# The bar when an export failed, on its own. Its button is common-try-again, and its raw error
# is behind Show details.
diagnostics-save-failed = Couldn't save the diagnostics ZIP

## Tester builds (embedded-package feature)

# A bar at the top of the content on a release-candidate build.
rc-banner = Atlas { $release } test build. This app installs only the bundled Atlas package.
home-status-bundled = Test build { $release }
package-bundled = Atlas { $version } bundled with this test build is ready to install.
rc-about-release = Test build
rc-about-commit = Source commit
rc-about-package = Bundled Atlas package (SHA-256)
iso-package-bundled = The Atlas package bundled with this test build

check-user-account = User account
detail-user-account-ok = UAC is enabled and your account is ready for installation.
detail-user-account-not-ready = Turn on User Account Control (UAC), restart your PC, then try again. If you use the built-in Administrator account, sign in with another administrator account.
detail-user-account-work-or-school = Atlas can't be installed from a work or school (Microsoft Entra ID) account. Sign in with a local account or a Microsoft account, then try again.
detail-user-account-check-failed = Atlas couldn't check your user account. Restart your PC, then reopen Atlas and check again. Windows reported: { $error }

footer-prepare-required = Finish updating Windows and Store apps to continue
# "Stage" as in prepare-close-stops-after-stage.
footer-prepare-stopping-stage = Stopping updates after the current stage…
resume-choices-title = Continuing your previous installation
# The bar on Your choices, above the choices an unfinished installation holds, which it shows
# and can't change.
resume-choices-held = Atlas uses the choices you made last time to finish that installation, so they can't change until it's done.

## Voluntary reports
report-title = Send a report
report-received = Report received
# Under the report's reference, which has a line of its own with a Copy button.
report-reference = Keep this reference if you contact the Atlas team about this report. If you left contact details, the team may use them to reply, but a reply isn't guaranteed.
# Accessible name of the Copy button beside the report reference.
report-copy-reference = Copy report reference
report-another = Send another report
# Label of the choice between the two kinds of report.
report-kind = What would you like to send?
report-kind-issue = An issue
report-kind-suggestion = A suggestion
report-message = Your message
# What the message box shows while it's empty, for each kind of report.
report-message-placeholder-issue = What happened, and what were you doing?
report-message-placeholder-suggestion = What would you like changed?
# Under the message box, which also reads it out.
report-message-help = Don't include passwords.
# Under the message or contact box once it's near the longest the report service accepts.
# $count and $max are numbers.
report-character-count = { $count } of { $max } characters
report-contact = Contact details (optional)
report-contact-placeholder = Email or Discord username
report-attach = Include diagnostics
# Under Include diagnostics. Part of the privacy notice the user agrees to: it says
# exactly what Atlas removes and keeps, so keep every item.
report-attach-description = Logs and system details that help find the cause. Atlas removes your user name, PC name, email addresses and known passwords or keys. Error details, hardware models and app names are kept. You can review the ZIP before sending.
report-review = Review ZIP
# A bar when diagnostics couldn't be prepared. Its button is common-try-again, and its raw
# error is behind Show details.
report-prepare-failed-title = Couldn't prepare diagnostics
report-prepare-failed-advice = Try again, or send without diagnostics.
# The privacy notice the user agrees to, with report-attach-description. Changing it means a
# new PRIVACY_VERSION in the app, the report service and the website, deployed together.
report-privacy = Your report goes privately to the Atlas team at reports.atlasos.net. Your message and contact details are sent as written. The team may use AI services from other companies to help investigate. These get your message and diagnostics, but not your contact details. Reports are deleted after 90 days, and server security logs may record your IP address.
report-website = Privacy and report website
report-consent = I agree to send this report and any included diagnostics to the Atlas team
# Under "Report wasn't sent". The footer's button is common-try-again, except after
# report-not-sent-outdated, where it's report-failed-website and the bar's button is
# manager-download.
report-not-sent-retry = Check your internet connection, then try again. You can also send it from the report website.
report-not-sent-busy = The report service is busy. Wait a few minutes, then try again.
report-not-sent-outdated = This version of Atlas Manager can't send reports. Copy your message into the report website, with the ZIP if you included diagnostics.
report-not-sent-diagnostics = The diagnostics couldn't be sent. Try again, or send without diagnostics.
# The footer's button where this version can't send.
report-failed-website = Open the report website
# Beside a spinner in the footer while the report is on its way.
report-sending = Sending…
report-send = Send report

# Under the message box when Send report finds it too short or too long. $min and $max
# are numbers: the message lengths the report service accepts.
report-validation-message = Enter { $min }–{ $max } characters.

# Under the contact box. $max is a number: the longest contact details the report
# service accepts.
report-validation-contact = Keep contact details within { $max } characters.

# Under the agreement check box when Send report is chosen without it.
report-validation-consent = Confirm you agree to send this report.

report-failed-title = Report wasn't sent

## Windows version update
# Atlas moves Windows to a newer release before installing, through Windows Update.
# $release is the target release (26H2) and $current the release the PC has (24H2);
# say "Windows 11, version" before them as Microsoft does. $version is an Atlas version.

# Home, under the update button, when the update also moves Windows: a card with the
# update's two parts. home-plan-name is the accessible name of their list.
home-plan-files = Your files and apps stay.
home-plan-name = This update has two parts
home-plan-windows-title = Windows 11, version { $release }
home-plan-windows-step = Atlas installs it from Windows Update, then your PC restarts.
# The same step where moving is optional.
home-plan-windows-step-ask = Optional. Atlas asks first, then installs it from Windows Update and your PC restarts.
# Instead of the step's own line, once Windows has moved.
home-plan-step-installed = Installed.
home-plan-atlas-title = Atlas { $version }
home-plan-atlas-step = Atlas updates and keeps your choices, then your PC restarts.
# $date and $until are dates.
home-end-of-updates-title = Windows 11, version { $current } stops getting security updates on { $date }
home-end-of-updates-past-title = Windows 11, version { $current } no longer gets security updates
home-end-of-updates-message = Updating to Atlas { $version } also moves this PC to Windows 11, version { $release }, which gets security updates until { $until }.
# Instead of home-end-of-updates-message when the card with the update's two parts, which
# names the move, is under the bar.
home-end-of-support-plan = Windows 11, version { $release } gets security updates until { $until }.

# Home, when this Windows can't take the Atlas version at all. $product is Windows'
# own name for the edition, such as Windows 11 Home.
install-windows-edition-only = Atlas { $version } works with Windows 11 Pro, Enterprise and Education, so it can't install on { $product }.
# The same, on a version whose security updates end, with Open Windows Update. $date is a date.
install-windows-edition-until = Atlas { $version } works with Windows 11 Pro, Enterprise and Education, so it can't install on { $product }. Windows 11, version { $current } gets security updates until { $date }, and Windows Update can move this PC to a newer version.
# The same once that date has passed.
install-windows-edition-ended-update = Atlas { $version } works with Windows 11 Pro, Enterprise and Education, so it can't install on { $product }. Version { $current } no longer gets security updates, so update Windows even without Atlas.
# Instead of install-windows-edition-only on an LTSC edition, which Windows names with a year,
# such as "LTSC 2024", that reads like a version of Windows.
install-windows-edition-ltsc = Atlas { $version } works with Windows 11 Pro, Enterprise and Education. LTSC editions aren't supported.
# $releases lists the supported releases, such as "25H2 or 26H2".
install-windows-reinstall = Atlas { $version } needs Windows 11, version { $releases }, and Windows Update can't move this PC there. Back up your files, then reinstall Windows with an Atlas ISO.
# The same on Home, where the card that creates an Atlas ISO comes first and says how to reinstall.
home-windows-no-path = Atlas { $version } needs Windows 11, version { $releases }, and Windows Update can't move this PC there.

# Home, when Atlas changed Windows Update settings for an update and hasn't put them back.
# The bar's button is home-put-back; Continue update (home-continue-update) is beside the
# version above.
home-update-access-title = Windows Update settings are changed for the Atlas update
# Under home-update-access-title while an update that moves Windows is under way.
home-update-access-put-back-later = Atlas puts these settings back when the update finishes.
# When the last check found no offer yet.
home-update-access-waiting = Atlas turned on Windows Update to move this PC to Windows 11, version { $release }, and Windows Update hasn't offered it yet.
home-update-access-updating = Atlas turned on Windows Update to install updates and hasn't finished.
# Instead of home-update-access-title when Atlas can't read its record of the settings it changed.
home-update-access-unreadable-title = Couldn't read Atlas's Windows Update record
# With Send a report and Export diagnostics under it; the raw error is behind Show details. Also
# why putting the settings back failed, where the worker names this cause.
home-update-access-unreadable-problem = Atlas can't read its record of the Windows Update settings it changed, so it won't change or put back anything.
# Under the bar when putting the settings back failed for another reason. Put back settings
# tries again; the raw error is behind Show details.
home-put-back-failed = Atlas couldn't put the settings back.
# Why the Windows Update settings Atlas changed can't be put back yet: an unfinished Atlas
# installation or update puts them back in its last stage. On Home, where Put back settings is
# hidden meanwhile, and in the close question when putting them back failed. Also under the
# Windows release choice on Get ready, where keeping this version waits for the same reason.
# "Stage" is a stage of installing, not one of the four flow steps.
update-access-finish-install = Finish installing Atlas first. Its last stage puts back the Windows Update settings Atlas changed.
home-continue-update = Continue update
home-put-back = Put back settings
home-putting-back = Putting back settings…

# Get ready: the card of the move to a newer Windows version, first on the page. Its title is
# windows-card-title, and the line under it says how the move stands.
windows-card-title = Windows 11, version { $release }
# Under the title of a move the Atlas package needs, before the go-ahead.
windows-required = Atlas { $version } doesn't support version { $current }, so Atlas updates Windows first.
# Under the title where moving is optional.
windows-optional = Atlas works with either version.
# The choice's accessible name; the two answers say it.
windows-card-question = Which version of Windows should this PC use?
windows-choice-move-recommended = Update to Windows 11, version { $release } (recommended)
# $date is when the new version stops getting security updates.
windows-choice-move-support = Security updates until { $date }.
windows-choice-keep = Keep Windows 11, version { $current }
windows-choice-keep-later = Stays on version { $current }. You can move later from Atlas Manager.
windows-card-facts = What changes
windows-fact-files = Your files and apps stay. Atlas puts back anything the update undoes.
windows-fact-time = Usually a few minutes, up to 2 hours, then a restart.
# Behind Show details, on a PC whose version still has them.
windows-fact-removes = Removes Windows PowerShell 2.0 and WMIC.
# Opens the Atlas documentation on undoing the move, where moving is optional.
windows-undo-link = How to undo the update
# Before windows-accept: accepting the terms and starting the move are one choice.
windows-terms-line = Updating means you accept the Microsoft Software License Terms.
windows-terms-link = Read the licence terms
windows-accept = Accept and update
# Once the terms are accepted, before the move starts by itself.
windows-starting = Starting…
windows-starts-after-checks = Starts once the checks pass.
windows-starts-after-package = Starts once Atlas { $version } is ready.
# After the move, when Windows reinstalled itself instead of switching the new version on.
windows-rebuilt = Version { $release } reset some of Atlas's changes. Atlas { $version } puts them back with your earlier choices.
# Asked before keeping this version once the move has begun; the message is stop-update-before
# and the buttons are common-cancel and prepare-keep-version.
windows-keep-title = Keep Windows 11, version { $current }?


# The bar that names each Windows Update setting Atlas turns on for the update.
access-notice-title = Atlas turns Windows Update on for now
access-off = Windows Update is turned off on this PC. Atlas turns it back on while it updates Windows.
access-paused = Windows updates are paused on this PC. Atlas unpauses them while it updates Windows.
access-delayed = Monthly updates are delayed on this PC. Atlas removes the delay while it updates Windows.
# After the lines above.
access-back = When Atlas { $version } is installed, these settings go back as they were.
access-back-stop = If you stop before then, Atlas puts them back.

prepare-reason-feature-update = the new Windows version
prepare-reason-feature-commit = finishing the new Windows version
# Waiting for Windows Update to offer the new version: the progress bar's label and status
# line, the line under the bar, and how long Atlas has waited, in whole minutes, after it.
windows-waiting = Waiting for Windows Update to offer Windows 11, version { $release }…
windows-waiting-detail = Usually minutes, up to 2 hours. Atlas carries on by itself; you can keep using your PC.
windows-waited =
    { $minutes ->
        [one] Waiting for { $minutes } minute.
       *[other] Waiting for { $minutes } minutes.
    }
# After 2 hours of looking again without an offer. The buttons are common-try-again and iso-open.
windows-wait-ended-title = Windows Update didn't offer version { $release } within 2 hours
windows-wait-ended = Atlas put your settings back. Try again later, or reinstall Windows with an Atlas ISO.
# Instead of the message above when putting the settings back failed. The button is
# home-put-back; the raw error is behind common-show-details.
windows-wait-put-back-failed = Atlas couldn't put your Windows Update settings back.
# Windows couldn't get the new version ready to finish at the restart, so the PC didn't
# restart. Try again (common-try-again) makes the restart again.
windows-commit-failed-title = Windows couldn't prepare the restart
windows-commit-failed = Your PC didn't restart. Try again.

# Outcomes of moving Windows, each a title and what to do next. A cause that only the Atlas
# team can look into has report-title as its button; one an ISO fixes, iso-open.
windows-outcome-not-offered-title = Windows Update hasn't offered version { $release } yet
windows-outcome-not-offered = It can take up to 2 hours. Your PC still has version { $current }.
windows-outcome-hardware-title = This PC doesn't meet the Windows 11 requirements
# $missing lists the hardware this PC lacks, from the two messages below.
windows-outcome-hardware = It doesn't have { $missing }, so Windows Update won't offer version { $release }. Back up your files, then reinstall Windows with an Atlas ISO.
hardware-tpm = TPM 2.0
hardware-uefi = UEFI firmware
windows-outcome-hidden-title = Version { $release } is hidden in Windows Update
windows-outcome-hidden = Show it again with the tool you used to hide it, then try again.
windows-outcome-disk-space-title = Not enough free space
# $needed and $free are whole gigabytes; $drive is a drive such as C:. The button is
# check-fix-storage; Atlas reads the free space again by itself.
windows-outcome-disk-space = Windows needs { $needed } GB free on { $drive } and has { $free } GB. Atlas carries on by itself once there's enough.
windows-outcome-managed-title = This PC gets updates from its organisation
windows-outcome-managed = Its update server doesn't offer version { $release }, so Atlas didn't change anything. Ask your organisation, or reinstall Windows with an Atlas ISO.
windows-outcome-policy-title = Something keeps changing Windows Update back
# $setting is the technical name of a Windows Update policy value, such as NoAutoUpdate,
# shown as it is.
windows-outcome-policy = { $setting } goes back after Atlas changes it, so Atlas can't update Windows. If an organisation manages this PC, ask them.
# $service is a service-* name, after a fixed phrase so that the name needs no agreement. The
# buttons are common-try-again and prepare-open-services.
windows-outcome-service-off-title = Service turned off: { $service }
windows-outcome-blocked-service = Windows Update needs it. Set it to Manual in Services, then try again.
windows-outcome-blocked-title = Something keeps Windows Update off
windows-outcome-blocked = A setting Atlas didn't change, { $setting }, stops it running. Change it, then try again.
windows-outcome-rollback-title = Windows couldn't finish installing version { $release }
windows-outcome-rolled-back = It went back to version { $current }. Your files and apps are fine.
windows-outcome-components-lost-title = Some of Atlas's changes are gone
windows-outcome-components-lost = Atlas can't tell why, so it stopped before installing Atlas { $version }.
windows-outcome-build-title = Windows changed version during the update
windows-outcome-build = Put back the settings Atlas changed, then start again from Home.
windows-outcome-journal-title = Atlas can't read its record of this update
windows-outcome-journal = It won't change or put back anything until the Atlas team has looked at it.
windows-outcome-pin-title = A Windows Update policy can't be recorded
# $setting is the name of a Windows Update policy value, such as TargetReleaseVersionInfo.
windows-outcome-pin = { $setting } has a value Atlas can't put back later, so Atlas didn't change anything.
windows-outcome-terms-title = The licence terms weren't accepted
windows-outcome-terms = Windows Update needs them before it installs version { $release }.
windows-outcome-failed-title = Windows couldn't install version { $release }
windows-outcome-failed = Your PC still has version { $current }.
# Windows services a move needs, as Services lists them.
service-bits = Background Intelligent Transfer Service (BITS)
service-cryptsvc = Cryptographic Services
service-trusted-installer = Windows Modules Installer
prepare-open-services = Open Services
# Confirms keeping this version in the windows-keep-title question.
prepare-keep-version = Keep version { $current }

# Asked before leaving the update with Windows Update settings changed.
stop-update-title = Stop updating to Atlas { $version }?
# stop-update-title for a first install or a reinstall, which so far has only updated Windows.
stop-update-title-windows = Stop updating Windows?
stop-update-before = Atlas puts back the Windows Update settings it changed. Updates Windows already installed stay installed, and your PC keeps Windows 11, version { $current }.
stop-update-after = Your PC keeps Windows 11, version { $release }. Atlas puts back the Windows Update settings it changed.
stop-update-access = Atlas puts back the Windows Update settings it changed. Updates Windows already installed stay installed.
stop-update-keep = Keep updating
# Dialog shown when the window is closed while Windows Update is turned on for an update; its
# buttons are window-close-keep and window-close-put-back.
window-close-update-access-title = Close Atlas?
window-close-update-access-message = Atlas puts back the Windows Update settings it changed before closing. You can start the update again from Home.
window-close-put-back = Put back and close
# When putting the settings back before closing failed. The reason comes first, then this
# message; the buttons are window-close-keep and window-close-close.
window-close-put-back-failed-title = Close without putting the settings back?
window-close-put-back-failed-message = If you close Atlas now, the Windows Update settings stay as Atlas changed them. When you open Atlas again, Home offers to put them back.

# PC checks: Windows compatibility on a version Atlas moves from. The move's card says how
# the move goes.
detail-build-needs-release = This version of Atlas needs Windows 11, version { $release }, and this PC has version { $current }.

# The first lines of a report about a Windows update that didn't finish; technical
# details follow in English.
report-transition-intro = Updating Windows for Atlas didn't finish. Details for the Atlas team:

# When Windows reinstalled itself while it moved to a newer version, instead of
# switching the new version on in place. Atlas then puts all of its changes back.
history-mode-rebase = reinstall after a Windows update
# Your choices after Windows reinstalled itself during a move, which put the choices of the
# Atlas it had back.
rebase-choices-title = Your choices from Atlas { $previous }
rebase-choices-kept = Atlas puts back the choices you made for Atlas { $previous }, and you can change them later by reinstalling Atlas.
# Above the questions the record of the move had no answer for, which are all Your choices asks.
rebase-choices-asked = Atlas puts back every other choice you made for Atlas { $previous }.
# Asked before any restart Atlas makes while other people are signed in to the PC. Its
# buttons are restart-others-keep, the default, and restart-others-restart.
restart-other-question = Restart while someone else is signed in?
restart-others-question = Restart while other people are signed in?
# $names lists their account names, such as "Alex and Sam"; $count is how many there are.
restart-others-signed-in =
    { $count ->
        [one] { $names } is signed in too. Restarting closes their apps, and they lose unsaved work.
       *[other] { $names } are signed in too. Restarting closes their apps, and they lose unsaved work.
    }
restart-others-keep = Don't restart
restart-others-restart = Restart anyway
# Microsoft Store itself, before the Store apps: Get ready's status line while it updates or is
# repaired, with prepare-store-repair-detail under the progress bar while it's repaired.
prepare-store-updating = Updating Microsoft Store…
prepare-store-repairing = Repairing Microsoft Store…
prepare-store-repair-detail = This can take a few minutes.
# Under ready-updates-done-windows once Get ready has finished, where Microsoft Store is turned off.
# What updating did to Microsoft Store itself otherwise is only in the log.
prepare-store-skipped-removed = Microsoft Store is turned off on this PC, so Store apps weren't updated.
# None of Atlas's repairs made Microsoft Store work. The button is prepare-repair-store-again;
# prepare-store-broken-iso and Create an Atlas ISO (iso-open) are behind common-show-details.
prepare-store-broken-title = Microsoft Store isn't working
prepare-store-broken = Atlas couldn't repair it, and installing Atlas now could break Store apps.
prepare-store-broken-iso = If the repair keeps failing, back up your files and reinstall Windows with an Atlas ISO.
prepare-repair-store-again = Try repair again
# Windows couldn't install updates for some of its own apps, such as Calculator or Photos, and
# Atlas's Store repairs didn't help. $apps lists the apps by their package names (WindowsCalculator,
# ZuneMusic), joined with list-and. The buttons are iso-open and common-try-again.
prepare-store-staging-title = Windows can't update its built-in apps
prepare-store-staging = Windows couldn't install updates for these built-in apps, and Atlas's repairs didn't help: { $apps }. { prepare-components-unrepairable }

screen-keyboard-title = Keyboard languages
screen-keyboard-question = Do you use multiple keyboard languages?
package-option-keyboard-shortcuts = Yes, with keyboard shortcuts
package-option-keyboard-selector = Yes, with the taskbar selector
package-option-keyboard-single = No, I use one keyboard layout
consequence-keyboard-shortcuts = Alt+Shift switches languages; Ctrl+Shift switches layouts.
consequence-keyboard-selector = Turn off Alt+Shift and Ctrl+Shift to avoid accidental switches while gaming.
package-choice-keyboard-description = Choose how you switch keyboard languages.
consequence-keyboard-single = { consequence-keyboard-selector }
