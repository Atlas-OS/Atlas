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
### - "Atlas", "AtlasOS", "Windows", "Defender", "Windows Security", "GitHub"
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
# Accessible description of a disabled control.
common-not-available = Not available right now
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
common-open-log-file = Open log file
# Accessible name of the Copy button beside the install log.
common-copy-install-log = Copy installation log
common-install-log = Installation log
# Row labels in summary cards.
common-windows = Windows
common-options = Options
common-package = Installation files
common-installed-as = Installation type
common-installed = Installed
common-checking = Checking
# Joins two items in a list: "Brave, Firefox". The braces keep the space.
list-separator = { ", " }
# Joins two alternatives: "26100 or 26200".
list-or = { $a } or { $b }

## Window

# Dialog shown when the window is closed while an install runs.
window-close-title = Close while Atlas is installing?
window-close-message = Installation will continue in the background. Open Atlas again to check progress and see the result. Keep your PC on until it finishes.
window-close-keep = Keep open
window-close-close = Close window
# Title of the file picker for a playbook (.apbx) file.
file-dialog-open-playbook = Open an Atlas playbook (.apbx)
# Message Windows shows in its restart notification.
shutdown-comment = Atlas is installed. Restarting Windows to finish setup.

## System

# "Windows 11 Pro 25H2 (build 26200.1234)". All three values are text.
system-description = { $product } { $version } (build { $build })

## Home page

home-not-installed = Welcome to Atlas
# The headline when Atlas is installed. $version is text.
home-version = Atlas { $version }
# $date is a formatted date.
home-installed-on = Installed { $date }
home-status-checking = Checking for updates
home-status-offline = Couldn't check for updates
home-status-not-checked = Updates not checked yet
home-status-update = Atlas { $version } is available
home-status-up-to-date = Up to date
home-status-newest = Latest version: Atlas { $version }
home-check-again = Check again
# Primary button while an install is running or waiting.
home-show-install = View progress
home-continue-installing = Continue setup
home-update-to = Update to Atlas { $version }
home-reinstall = Reinstall Atlas
home-install = Install Atlas
home-start-over = Start over
home-security-reminder-title = Turn your protection back on
home-security-reminder-message = No installation is running. Open Windows Security and turn on Tamper Protection, real-time protection, cloud-delivered protection and automatic sample submission.
home-elevation-title = Atlas needs permission to install
home-state-error-title = Couldn't read your Atlas installation details
home-whats-new = What's new in Atlas { $version }
home-view-release = View release notes on GitHub
home-released = Released { $date }
home-show-less = Show less
home-show-full-notes = Show all release notes
home-your-install = Your Atlas setup
# Row label: how Atlas was set up.
home-set-up = Setup method
home-set-up-during-oobe = During Windows setup
home-history = Installation history
# One history row. $version is text, $mode one of the history-mode-* messages, $date a formatted date and time.
home-history-entry = Atlas { $version } · { $mode } · { $date }
home-how-it-works = Let's get your PC ready for Atlas
home-step-1-title = Check your PC
home-step-1-detail = Atlas checks Windows and downloads the installation files. Your Windows settings stay as they are.
home-step-2-title = Make it yours
home-step-2-detail = Choose how Windows handles protection and updates, then pick any extra apps or settings.
home-step-3-title = Pause antivirus protection
home-step-3-detail = Atlas guides you through four Windows Security switches so they won't block installation.
home-step-4-title = Install and restart
home-step-4-detail =
    { $minutes ->
        [one] About a minute.
       *[other] About { $minutes } minutes.
    }
# Accessible name of a numbered step.
home-step-a11y = Step { $number }: { $title }
home-github = View Atlas on GitHub
home-discord = Join the Atlas community
home-report-problem = Report a problem

## How an install was done (from the state document)

mode-fresh = First installation
mode-upgrade = Update from an earlier version
mode-reapply = Reinstall of the same version
mode-unknown = Installation
# Lower-case forms used inside a history row.
history-mode-fresh = first installation
history-mode-upgrade = update
history-mode-reapply = reinstall
history-mode-unknown = installation

## Notices on the Home page

notice-settings-reset-title = Atlas is using default app settings
# $error is a raw error message (text).
notice-settings-unreadable = Atlas couldn't read your saved app settings. Your Windows settings haven't changed. Details: { $error }
# $file is a file name (text).
notice-settings-damaged-kept = Your app settings file was damaged and has been reset. A copy of the old file is saved as { $file }. Details: { $error }
notice-settings-damaged = Your app settings file was damaged. Atlas is using defaults for now. Details: { $error }
notice-settings-not-saved-title = Couldn't save app settings
notice-session-unreadable-title = Couldn't check the previous installation
# $path is a file path (text).
notice-session-unreadable-message = Atlas can't read { $path } and needs to know whether an installation is still running. If you aren't sure, get help from the Atlas community before removing this file. Only delete it and try again if you've confirmed no installation is running. Details: { $error }

## Administrator elevation

elevation-declined = Permission wasn't granted. Try again and choose Yes when Windows asks to let Atlas make changes.
elevation-declined-continue = Permission wasn't granted. Try again and choose Yes when Windows asks to let Atlas make changes. Your setup choices are saved.
elevation-draft-not-saved = Atlas couldn't save your setup choices, so it hasn't relaunched. Try again. Details: { $error }

## The install flow

step-ready = Get ready
step-options = Your choices
step-security = Windows Security
step-install = Install
install-title = Set up Atlas
# Accessible name of the row of steps.
stepper-label = Atlas setup steps
# Accessible name of one step. $status is one of the stepper-status-* messages.
stepper-step-a11y = Step { $number } of { $total }, { $title }, { $status }
stepper-status-completed = completed
stepper-status-current = current step
stepper-status-upcoming = upcoming step
# Heading above each step's content.
step-heading = Step { $number } of { $total }: { $title }

## Step 1: Get ready

ready-banner-busy-title = Getting your PC ready
ready-banner-busy-message = Atlas is checking your PC and preparing the installation files.
ready-banner-blocked-title = Your PC needs a little preparation
ready-banner-blocked-message = Follow the instructions below, then choose Check again.
ready-banner-no-package-title = Download Atlas to continue
ready-banner-no-package-message = Download the latest version below, or open a saved Atlas playbook (.apbx).

ready-banner-warnings-title = A few things to review
ready-banner-warnings-message = Read the notes below and take any recommended steps before continuing.
ready-banner-ok-title = You're ready to choose your settings
ready-banner-ok-message = The checks passed and your installation files are ready.

# Card title and accessible name of the list of checks.
ready-this-pc = PC checks
ready-check-again = Check again

package-title = Installation files
# $received and $total are formatted numbers of megabytes (text).
package-downloading = Downloading Atlas { $version } · { $received } of { $total } MB
package-unpacking-progress =
    { $total ->
        [one] Unpacking · { $done } of { $total } file
       *[other] Unpacking · { $done } of { $total } files
    }
package-unpacking = Unpacking
package-looking = Checking for the latest Atlas version.
package-none = No installation files yet. A playbook (.apbx) contains the instructions and files Atlas needs.
# Short status words beside the card title.
package-status-downloading = Downloading
package-status-unpacking = Unpacking
package-status-failed = Couldn't prepare files
package-status-ready = Ready
package-status-checking = Checking
package-status-missing = Not downloaded
# Accessible name of the progress bar.
package-progress = Installation file progress
package-download-again = Download again
package-download-version = Download Atlas { $version }
package-download-newest = Download latest version
package-open-file = Open playbook file
# Where the package came from. $file is a file name, $path a folder path (text).
package-from-release = Atlas { $version } downloaded from GitHub and ready to install.
package-from-file = Atlas { $version } loaded from { $file } and ready to install.
package-unpacked = Atlas { $version } is ready to install.
package-at = Installation files: { $path }
package-none-yet = No installation files selected
acquire-no-asset = Atlas { $version } has no playbook file available to download. Open a saved Atlas playbook (.apbx) to continue.
acquire-unsupported = This app can install Atlas 0.6.0 and later. To install Atlas { $version }, use AME Wizard instead.
acquire-failed = Couldn't prepare the installation files. Try downloading again or open another Atlas playbook (.apbx). Details: { $error }

## System checks

check-administrator = Permission to install
check-supported-build = Windows compatibility
check-pending-updates = Windows updates
check-pending-reboot = Pending restart
check-third-party-antivirus = Other antivirus software
check-internet = Internet connection
check-power = Power supply
check-activation = Windows activation
# Accessible name of a check row. $state is one of the check-state-* messages.
check-a11y = { $title }: { $state }
check-state-checking = checking
check-state-passed = passed
check-state-warning = needs attention
check-state-failed-blocking = action needed before installing
check-state-failed = needs attention
check-state-unknown = could not be checked
check-fix-windows-update = Open Windows Update
check-fix-network = Open network settings
check-fix-power = Open power settings
check-fix-activation = Open activation settings
# Check boxes the user ticks when a check could not run.
check-ack-updates = I checked Windows Update: no updates are waiting to install
check-ack-reboot = I've restarted Windows and no further restart is needed
check-ack-internet = This PC is connected to the internet
check-ack-generic = I've checked this requirement myself

detail-admin-ok = Atlas has permission to make the changes needed for installation.
detail-admin-missing = Relaunch Atlas as administrator, then choose Yes when Windows asks for permission.
# $builds is a list of build numbers such as "26100 or 26200"; $build is this PC's (text).
detail-build-unsupported = This Atlas version requires Windows build { $builds }. Your PC has build { $build }. Install a supported Windows version before continuing.
detail-updates-none = No Windows updates are waiting to install.
# $titles lists up to two update names (text); $count is the total.
detail-updates-pending =
    { $count ->
        [1] Install this update first: { $titles }.
        [2] Install these updates first: { $titles }.
       *[other] Install { $count } updates first, including { $titles }.
    }
detail-updates-unknown = Couldn't check for Windows updates. Open Windows Update, then confirm below if no updates are waiting. ({ $error })
detail-reboot-none = Windows doesn't need a restart right now.
detail-reboot-pending = Restart your PC to finish earlier changes, then reopen Atlas and check again.
detail-reboot-unknown = Couldn't check whether Windows needs a restart. Restart your PC, then reopen Atlas and check again. ({ $error })
detail-antivirus-none = No other antivirus software was detected.
# $products is a list of product names (text).
detail-antivirus-found = Antivirus software may block installation: { $products }. Uninstall this software before continuing.
detail-antivirus-unknown = Couldn't check for other antivirus software. Check your installed apps before continuing. ({ $error })
detail-internet-ok = You're connected. Keep this connection available while Atlas downloads and installs software.
detail-internet-missing = Connect to the internet, then check again.
detail-power-mains = Your PC is plugged in. Keep it connected until installation finishes.
detail-power-battery = Plug your PC into a power supply so it stays on throughout installation.
detail-power-unknown = Couldn't check the power supply. If you're using a laptop, plug it in before continuing.
detail-activation-ok = Windows is activated. Atlas won't change this.
detail-activation-missing = Windows isn't activated. You can continue, but Atlas won't activate Windows for you.
detail-activation-no-licence = Windows didn't report a licence. You can continue; Atlas won't change your activation status.
detail-activation-unknown = Couldn't check Windows activation. You can continue; Atlas won't change your activation status. ({ $error })

## Step 2: Options

options-progress = Choice { $number } of { $total }
options-progress-extras = Choice { $number } of { $total }: optional extras
# Short names for each decision (summary rows) and the question each screen asks.
screen-defender-title = Microsoft Defender
screen-defender-question = Keep antivirus protection on?
screen-mitigations-title = Processor security
screen-mitigations-question = Keep Windows' processor protections?
screen-updates-title = Windows Update
screen-updates-question = How should Windows install updates?
screen-browser-title = Browser
screen-power-title = Power and security
screen-apps-title = Apps
screen-optional-apps-title = Optional apps
screen-choose-one-title = Choose an option
screen-extras-title = Optional extras
screen-extras-question = Choose any extras you'd like
# Question for a required choice this app has no specific wording for.
screen-generic-question = Choose an option for { $title }
learn-more-defender = Learn more about Microsoft Defender
learn-more-mitigations = Read about processor security
learn-more-updates = Learn more about Windows Update
learn-more-browser = Learn more about browsers
learn-more-power = Learn more about power and security
learn-more-apps = Learn more about apps
learn-more-eclean = How eclean works with AtlasOS
learn-more-generic = Read the setup guide
# One line under the chosen answer: what it means for the PC.
consequence-defender-enable = Keeps Windows' built-in antivirus to help protect your PC from viruses and other threats.
consequence-defender-disable = Removes Microsoft Defender. Your PC won't have antivirus protection until you install another antivirus app.
consequence-mitigations-default = Keeps Windows' default protections against attacks that exploit how your processor works.
consequence-mitigations-disable = Turns off these protections and reduces security. Performance depends on your processor and may get worse.
consequence-auto-updates-disable = You'll need to open Windows Update and install updates yourself. Update notifications stay on.
consequence-auto-updates-default = Windows will install updates automatically, including security fixes.

## Playbook text
## The playbook package carries its own English text for each option. These
## UI labels and explanations are used only when the package text matches
## i18n/playbook-source.ftl. A future package with different wording keeps
## its own text instead of receiving a potentially outdated description.

playbook-option-defender-enable = Keep Microsoft Defender (recommended)
playbook-option-defender-disable = Remove Microsoft Defender
playbook-option-mitigations-default = Keep default protections (recommended)
playbook-option-mitigations-disable = Turn off processor protections
playbook-option-auto-updates-disable = Let me install updates
playbook-option-auto-updates-default = Install updates automatically
playbook-option-disable-hibernation = Turn off hibernation
playbook-option-disable-power-saving = Turn off power saving
playbook-option-disable-core-isolation = Turn off virtualisation-based security (VBS)
playbook-option-remove-snipping-tool = Remove Snipping Tool
playbook-option-uninstall-edge = Remove Microsoft Edge
playbook-option-install-another-browser = Install a browser
playbook-option-install-toolbox = Install Atlas Toolbox
playbook-option-browser-brave = Brave
playbook-option-browser-librewolf = LibreWolf
playbook-option-browser-firefox = Firefox
playbook-option-browser-chrome = Chrome
playbook-page-defender-enable-description = Microsoft Defender is Windows' built-in antivirus. Keeping it is recommended. Only remove it if you understand the risks and plan to use another antivirus app.
playbook-page-mitigations-default-description = These protections, also called security mitigations, help defend against processor vulnerabilities. Keeping the Windows defaults is recommended.
playbook-page-auto-updates-disable-description = Windows updates include security fixes. You can have Windows install them automatically or install them yourself.
consequence-install-toolbox = Add Atlas Toolbox to help manage your Atlas settings. Toolbox is in beta, so some features may be unfinished.
playbook-page-browser-brave-description = Choose a browser to install. Atlas won't change your browser settings.

## Step 3: Windows Security

security-banner-reading-title = Checking Windows Security
security-banner-reading-message = Atlas is checking the four protection switches below.
security-banner-off-title = The four protection switches are off
security-banner-off-message = You can now review your choices before installing.

security-banner-readable-off-title = The switches Atlas could check are off

security-banner-readable-off-message = Check the remaining switches in Windows Security.
security-banner-on-title = Temporarily disable antivirus protection
security-banner-on-message = These protections can block the changes Atlas needs to make.
# The page name in Windows Security.
security-list-title = Virus & threat protection settings
security-switch-off = Off
security-switch-on = On
security-switch-unreadable = Couldn't check
security-switch-reading = Checking
security-all-off = All off
# Accessible name of a switch row. $state is one of the security-switch-* messages.
security-a11y = { $title }: { $state }
# Parts of the summary "2 still on, 1 can't be read".
security-count-still-on = { $count } still on
security-count-unreadable = { $count } can't be read
security-count-join = { $a }, { $b }
security-unknown-title = Confirm the switches Atlas couldn't read
security-unknown-message = After checking in Windows Security that all four switches are off, confirm below.
security-acknowledge = I've checked Windows Security and all four switches are off
security-unknown-unelevated-title = Atlas needs permission to check protection
security-unknown-unelevated-message = Relaunch Atlas as administrator so it can check Microsoft Defender's settings.
# The four switches, named as Windows Security names them.
protection-tamper = Tamper Protection
protection-tamper-why = Turn this off first so Defender allows changes to its protection settings.
protection-realtime = Real-time protection
protection-realtime-why = Pause file scanning so Defender won't block Atlas installation files.
protection-cloud = Cloud-delivered protection
protection-cloud-why = Pause online threat checks that may block Atlas installation files.
protection-samples = Automatic sample submission
protection-samples-why = Stop Defender from automatically sending Atlas files to Microsoft for analysis.

## Step 4: Install

install-preparing-title = One last check before installation
install-preparing-message = Atlas is checking your PC and protection settings again before making changes.
install-installing = Installing
install-running = Running
# Accessible name of the progress bar.
install-progress = Installation progress
phase-preflight = Checking your PC and preparing files
phase-staging = Preparing the installation files
phase-applying = Setting up Windows. Keep your PC on.
phase-done = Finishing setup
outcome-succeeded-title = Atlas is installed
outcome-lost-title = Couldn't confirm the installation result
outcome-failed-title = Installation didn't finish
outcome-succeeded = Restart your PC to finish setting up Atlas.
outcome-requirements = Your PC didn't meet the installation requirements. No installation changes were made. Return to Get ready and run the checks again.
outcome-not-elevated = No installation changes were made. Relaunch Atlas as administrator and try again.
outcome-failed-preflight = Installation stopped before changing anything. Open the log file to see what happened, then try again.
outcome-failed-staging = Installation stopped while preparing files, before changing Windows. Open the log file to see what happened, then try again.
outcome-failed-applying = Some changes may already have been made. If you stop here, turn the protections you turned off back on in Windows Security, if they're still available.
outcome-not-started = The installer didn't start in time. No installation changes were made. Choose Try again.
outcome-lost = The installer stopped without reporting a result, and some changes may already have been made. Open the log file to see what happened, then choose Try again to resume.
restart-now-message = Windows is restarting to finish setting up Atlas.
restart-countdown =
    { $seconds ->
        [one] Windows restarts in { $seconds } second so Atlas can finish setting up.
       *[other] Windows restarts in { $seconds } seconds so Atlas can finish setting up.
    }
restart-stopped = Automatic restart cancelled. Save your work, then restart your PC to finish setting up Atlas.
restart-needed = Save your work, then restart Windows to finish setting up Atlas.
restart-dont-now = Restart later
restart-now = Restart now
# Accessible name of the countdown bar.
restart-progress = Time until restart
restart-start-failed = Couldn't restart Windows. Save your work, then restart from the Start menu. Details: { $error }
preflight-title = Installation hasn't started
preflight-invalid-options = Atlas couldn't use these setup choices. Return to Your choices and review them, then try again. Details: { $error }
# $problems is a sentence or two built from preflight-problem and preflight-security.
preflight-changed = Your PC's status changed after the earlier checks. Resolve the following before trying again. { $problems }
preflight-problem = { $title }: { $detail }
# $summary is the Windows Security summary such as "2 still on".
preflight-security = Windows Security: { $summary }.
preflight-busy = Another Atlas window is starting an installation. Wait a moment, then try again.
preflight-record-unreadable = Atlas couldn't check whether the previous installation is still running, so it hasn't started another one. Close and reopen Atlas for recovery instructions. Details: { $error }

preflight-refused = Couldn't start the installer. No installation changes were made. Details: { $error }
go-to-ready = Return to Get ready
# Button on the preflight banner when the setup choices could not be used; leads to step 2.
go-to-options = Return to Your choices
output-problem-title = Couldn't read installation progress
output-problem-message = Atlas couldn't read the log. This doesn't mean installation has stopped. Keep your PC on and try opening the log file. Details: { $error }
install-elevate-title = Atlas needs permission to install
install-no-package-title = Choose your installation files first
install-no-package-message = Return to Get ready to download Atlas or open a saved playbook (.apbx).
install-security-title = Check antivirus protection before installing
install-security-reading = Checking the four protection switches again.
install-security-message = { $summary }. Open Windows Security and make sure all four switches are off before continuing.
summary-this-install = Installation summary
summary-try-again = Review before trying again
summary-ready = Review your Atlas setup
summary-activation = Activation
summary-activation-ok = Activated. Atlas won't change this.
summary-activation-missing = Not activated. You can continue, but Atlas won't activate Windows.
summary-activation-unknown = Atlas won't change your Windows activation status.
summary-duration = Estimated time
summary-duration-value =
    { $minutes ->
        [one] { $minutes } minute, then a restart
       *[other] { $minutes } minutes, then a restart
    }
summary-restart-checkbox = Restart my PC automatically after installation
summary-show-command = Show installation command
summary-hide-command = Hide installation command
summary-command-unavailable = Couldn't prepare the installation command. Details: { $error }
summary-not-chosen = No choice made yet
# Accessible name of a Change link. $title is a screen-*-title message.
summary-change-a11y = Change { $title }
footer-still-checking = Preparing for installation

footer-fix-items = Complete the checks above to continue
footer-need-package = Download Atlas or open a playbook to continue
footer-reading-security = Checking the protection switches
button-checking = Checking
button-installing = Installing
button-install = Install Atlas
log-earlier-lines =
    { $count ->
        [one] { $count } earlier line is in the log file.
       *[other] { $count } earlier lines are in the log file.
    }
# Appended when the log is copied. $path is a file path (text).
log-full-log-note = (full log: { $path })

## The installing view

installing-checking-title = One last check
installing-checking-line = Atlas is checking your PC before making changes. This may take a moment.
installing-title = Installing Atlas
installing-phase-preflight = Checking your PC and preparing the installation files.
installing-phase-staging = Getting the installation files ready. Keep your PC on.
installing-phase-applying = Setting up Windows with your choices. Keep your PC on and plugged in.
installing-phase-done = Finishing the installation. Keep your PC on.
installing-installed-title = Atlas is installed
# $time is a formatted clock time.
installing-started-just-now = Started at { $time }, less than a minute ago
installing-started-minutes =
    { $minutes ->
        [one] Started at { $time }, a minute ago
       *[other] Started at { $time }, { $minutes } minutes ago
    }

## The "Atlas is installed" window after the restart

installed-title-version = Atlas { $version } is installed
installed-title = Atlas is installed
installed-ready = You're all set. Your PC is ready to use with Atlas.
installed-open-atlas = View your Atlas setup

## Settings

settings-title = Settings
settings-theme = App theme
settings-theme-system = Match Windows
settings-theme-light = Light
settings-theme-dark = Dark
settings-theme-contrast-note = Atlas is using the colours from your Windows contrast theme.
settings-theme-mica-note = To show the translucent background, choose the same light or dark theme as Windows.
settings-language = Language
settings-language-system = Match Windows
# Under "Match Windows": which language that gives. $language is a language's own name.
settings-language-system-detail = With Match Windows: { $language }

# Under a language that is translated but not yet reviewed by a native speaker.
settings-language-preview = Preview · awaiting language review
# One-line strip under the title bar while a preview translation is in use, until the
# user dismisses it (common-dismiss names the close button). $language is the
# language's own name; the two links follow the sentence on the same line.
preview-notice = { $language } is a preview translation.
preview-notice-switch = Switch to English
preview-notice-language = Change language
# $tag is a language tag (text).
settings-language-unavailable = { $tag } isn't available in this version of Atlas. English is shown for now, and your language choice is saved.
# $languages is the Windows display-language list (text).
settings-language-windows-unmatched = Atlas doesn't yet support your Windows display languages ({ $languages }). English is shown for now.
settings-language-windows-unavailable = Couldn't check your Windows display language. Atlas is using English for now. Details: { $error }
# $locale is the regional format's own name, for example "English (United Kingdom)".
settings-language-formats = Numbers, dates and times follow your Windows regional format ({ $locale }).
settings-language-contribute = Help translate Atlas
settings-installing = Installation
settings-restart-label = Restart my PC automatically after installation
settings-restart-locked = You can change this after installation finishes.
settings-restart-description = A restart is needed to finish setup. Save your work before installing if automatic restart is on.
settings-about = About
settings-about-app = Atlas Manager
settings-about-data = App files
settings-about-licence = Licence
settings-about-licence-value = GPL-3.0, free and open source
settings-view-source = View source code
settings-open-data-folder = Open app folder

## Optional choices: explanations shown before selection.

consequence-disable-hibernation = Frees the disk space used to save your session during hibernation. Hibernate and Fast Startup will be unavailable.
consequence-disable-power-saving = Disables power-saving features. Your PC may use more power, run hotter and have shorter battery life.
consequence-disable-core-isolation = Turns off an extra layer of Windows security, including memory integrity. This reduces protection and may affect apps or games that require it.
consequence-remove-snipping-tool = Removes the Windows app for taking screenshots and screen recordings.
consequence-uninstall-edge = Removes the Microsoft Edge browser. Make sure you have another browser, or choose one below.
consequence-install-another-browser = Choose a browser below and Atlas will install it for you.

# Introduction on the home page before Atlas is installed.
home-intro = Atlas adjusts Windows to reduce background activity and distractions. We'll guide you through the checks and choices before making changes.

detail-build-missing = This playbook does not declare any supported Windows builds. Choose a full playbook build instead of a LocalTest package.
## ISO creation (Beta)
iso-home-title = Windows installation media
iso-home-description = Create a Windows ISO with Atlas for a fresh installation on this PC or another one.
iso-open = Create an Atlas ISO
iso-title = Create an Atlas ISO
iso-beta = Beta
iso-beta-description = Try the ISO in a virtual machine before using it on a PC. Back up your files before installing Windows.
iso-admin-description = Administrator access is needed to read Windows images and create installation media.
iso-files-description = Choose an unmodified Windows 11 x64 ISO, an Atlas playbook (.apbx), and a new filename for the result.
iso-source = Windows ISO
iso-package = Atlas playbook (0.6+)
iso-output = Save the new ISO to
iso-no-file = No file selected
iso-browse = Browse
iso-save-as = Save as
iso-inspect = Check files
iso-mode-title = Windows and Atlas preferences
iso-mode-interactive = Choose Atlas settings after sign-in
iso-mode-interactive-description = After signing in, the Atlas Manager helps you update Windows and Store apps, choose your settings and apply Atlas.
iso-mode-before = Choose Atlas settings now
iso-mode-before-description = Save your Atlas settings in the ISO. After signing in, update Windows and Store apps, then apply Atlas with these settings.
iso-package-unsupported-title = Choose a newer playbook
iso-package-unsupported = ISO setup requires Atlas 0.6 or newer with ISO support. Choose a compatible playbook.
iso-atlas-options = Atlas settings
iso-review = Review ISO
iso-review-title = Ready to create your ISO
iso-editions = Included editions: { $editions }
iso-source-size = Source ISO: { $size } MB
iso-review-description = Atlas will create a separate ISO. Your original ISO is kept. Boot from the new ISO to install Windows; creating it does not install Atlas on this PC.
iso-create = Create ISO
iso-stage-inspect = Checking the Windows image
iso-stage-copy = Copying Windows files
iso-stage-inject = Adding Atlas
iso-stage-master = Creating the ISO
iso-stage-verify = Verifying the output
iso-stage-cleanup = Finishing up
iso-progress-description = Keep the app open. Large images can take a while to process.
iso-cancel = Cancel creation
iso-cancelling = Waiting for a safe point to cancel
iso-cancelled = ISO creation cancelled
iso-cancelled-description = Your original ISO is kept. The diagnostic log records any temporary files that still need cleaning up.
iso-complete = Your ISO is ready
iso-complete-description = Test it in a virtual machine, then use it to create Windows installation media.
iso-open-folder = Show in folder
iso-failed = Could not finish creating the ISO
iso-failed-description = Open the diagnostics to see what failed. Correct the problem, then try again with a new output filename.
iso-diagnostics = Open diagnostics
iso-close-title = ISO creation is still running
iso-close-message = Keep this window open until creation or cancellation finishes. Cancelling waits for the current operation to reach a safe stopping point.
iso-keep-open = Keep open
prepare-title = Update Windows and Store apps
prepare-description = Install Windows updates, update Microsoft Store and all installed Store apps before applying Atlas. Store apps may close during updates.
prepare-complete = Windows and Store apps are up to date.
prepare-reboot = Windows needs to restart. Your Atlas choices will be saved; check for updates again after signing in.
prepare-failed = Some updates could not finish. Check the diagnostic log, resolve any Windows or Store errors, then try again.
prepare-cancelled = Preparation stopped. Check for updates again before continuing.
prepare-windows-search = Checking Windows Update…
prepare-windows-download = Downloading Windows updates…
prepare-windows-install = Installing Windows updates…
prepare-store-search = Checking Microsoft Store…
prepare-store-install = Updating Microsoft Store and its apps…
prepare-stop-description = Stopping waits for the current update operation to finish. Keep Atlas open until it stops.
prepare-stop = Stop after current operation
prepare-restart = Restart and continue
prepare-start = Check and install updates
iso-username = Local account name
iso-account-description = Windows will ask you to set a password after reinstalling.
iso-username-placeholder = Your name
iso-account-invalid = Use 1–20 characters, without leading or trailing spaces or Windows account-name symbols.
iso-privacy-defaults = Windows setup turns off optional data sharing and personalised offers automatically.
prepare-drivers = How should drivers be installed?
prepare-drivers-auto = Get drivers through Windows Update
prepare-drivers-auto-detail = Windows finds drivers for your hardware. Recommended for most PCs.
prepare-drivers-manual = Install drivers myself
prepare-drivers-manual-detail = Block driver downloads from Windows Update. You will need to get drivers yourself; existing drivers stay installed.
prepare-network-needed = Connect using unmetered Wi-Fi or Ethernet, then try again. If Wi-Fi is missing, install your network driver first.
prepare-network-settings = Open network settings
iso-target-title = Which PC will you reinstall Windows on?
iso-target-this = This PC
iso-target-other = A different PC
iso-copy-network = Include this PC’s network drivers
iso-network-detail = Reuse this PC’s Wi-Fi and Ethernet drivers during Windows setup. You’ll reconnect to Wi-Fi after reinstalling.
iso-network-source = Network driver source
iso-network-installed = Use installed drivers
iso-network-updated = Check Windows Update first
iso-network-updated-detail = Download matching drivers offered by Windows Update and keep installed drivers as a fallback. Requires an unmetered connection.
iso-stage-network-drivers = Preparing network drivers…
iso-network-failed = Network drivers couldn’t be prepared. Check the diagnostics, or go back and change the network driver option.
iso-mode-desktop = Finish setup before the desktop
iso-mode-desktop-description = Choose Atlas settings now. After signing in, finish updates and Atlas setup before opening the Windows desktop.
desktop-setup-description = Finish setting up your PC. Your Atlas choices are saved; you can return to Windows if you need to.
desktop-setup-exit = Continue in Windows

# Windows installation USB (Beta)
usb-title = Create installation USB
usb-existing = Create a USB from an existing ISO
usb-description = Create a bootable USB for Windows 11 25H2. Use it to install Windows and Atlas on your PC.
usb-choose-iso = Choose ISO
usb-drive = USB drive
usb-empty = Connect a USB drive, then refresh the list. Only writable USB drives that do not contain the running Windows installation are shown.
usb-refresh = Refresh
usb-drive-detail = { $size } GB · { $volumes } · Serial: { $serial }
usb-review = Review USB
usb-erase-title = Erase this USB drive?
usb-erase-description = All files and partitions on { $drive } ({ $size } GB) will be permanently erased. Your ISO will be kept.
usb-layout = Windows setup uses up to 32 GB. Any remaining space will be unallocated. This USB is for PCs that boot using UEFI.
usb-ack = I understand that everything on this USB drive will be erased.
usb-write = Erase and create USB
usb-stage-prepare = Preparing installation files…
usb-stage-format = Formatting USB…
usb-stage-copy = Copying installation files…
usb-stage-verify = Verifying USB…
usb-working = Keep Atlas open and the USB connected. Cancelling waits for the current operation to stop safely; an unfinished USB cannot be used to install Windows.
usb-failed = Could not finish creating the USB. Check that it is connected and open diagnostics for details. Select the drive again to retry.
usb-cancelled = USB creation stopped. The drive may contain unfinished installation files. Create it again before using it to install Windows.
usb-complete = Your USB is ready and all files have been verified. Eject it, connect it to the PC you want to reinstall, then choose the USB in that PC’s UEFI boot menu.
usb-eject = Eject USB
usb-ejected = You can safely unplug the USB. To install Windows, choose it in your PC’s UEFI boot menu.
usb-eject-failed = Windows could not eject the USB. Close any files or windows using it, then try again.
ready-fresh-title = Start with a fresh Windows installation
ready-fresh-description = Atlas requires a fresh Windows installation, except for supported Atlas upgrades. A fresh Atlas 0.6 installation requires Windows 11 25H2. Back up your files before reinstalling Windows.
detail-edition-unsupported = Use Windows 11 Pro, Pro for Workstations or Enterprise. Home, LTSC and Server editions are not supported. If Windows could not identify your edition, resolve that before continuing.
install-source-title = Installation unavailable
install-source-unsupported = Atlas { $source } cannot be updated to { $target } directly. Reinstall Windows to use this version.
install-source-unknown = Atlas couldn't verify the installation state. Resolve any unfinished installation and check the diagnostics before trying again.
iso-edition-selection = Only supported editions are included. During Windows setup, choose an edition you have a Windows licence for.
detail-windows-preview = Insider builds aren’t supported. Use a public release of Windows 11.
detail-windows-release-unknown = Atlas couldn’t verify this Windows build as a public release. Connect to the internet and check again.
iso-release-unknown = This ISO couldn’t be verified as a public Windows 11 25H2 release. Connect to the internet and try again, or choose official release media.
prepare-previous-worker = An earlier update operation is still running. Atlas will wait for it to finish before you can try again.

ready-used-windows-title = Reinstall Windows before continuing
ready-used-windows-description = This Windows setup shows signs of prior use. Installing Atlas here is unsupported and strongly discouraged. Continue only if you understand the risks.
ready-used-windows-dismiss = I understand the risks
playbook-option-install-eclean = Install eclean
consequence-install-eclean = A maintenance tool from the team behind AtlasOS, for keeping your PC tidy after setup. Review junk files and startup apps. Requires an account and an internet connection.
