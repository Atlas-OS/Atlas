### Atlas Manager: English (United States).
###
### An overlay on the en-GB source: only messages whose spelling differs
### (licence/license, colour/color, -ise/-ize, cancelled/canceled). Every
### other message falls through to en-GB, so do not copy messages here that
### read the same in both; this file is a spelling overlay, not a catalog.

## Optional choices
cost-defender-disable = Your PC has no antivirus until you install another, and Windows stops warning you before you open unrecognized apps or downloads.
update-path-choose-detail = Start from how this PC is set up now. Your apps, files and personalization stay.
change-core-isolation-on = Atlas turns virtualization-based security (VBS) back on, unless a policy on this PC controls it. This takes effect after the restart.

## Shared and settings
settings-theme-contrast-note = Atlas is using the colors from your Windows contrast theme.
settings-about-licence = License
settings-view-licences = View license notices
settings-licences-failed = Couldn't open the license notices. Try again, or find them in the source code on GitHub.

## System checks
detail-activation-no-licence = Windows didn't report a license. You can continue; Atlas won't change your activation status.

## Atlas package options
package-option-disable-core-isolation = Turn off virtualization-based security (VBS)

## Install result
restart-stopped = Automatic restart canceled. Save your work, then restart your PC to finish setting up Atlas.

## ISO creation
iso-cancelled = ISO creation canceled
iso-cancelling-short = Canceling…
iso-terms-in-setup = Windows Setup will ask you to accept the license terms.
iso-accept-terms-optional = Accept the Windows license terms, so Windows Setup doesn't ask
iso-review-skips-terms = Skips the license, Microsoft account and privacy screens
iso-customised-title = This ISO has been customized
iso-account-trailing-dot = The name can't end with a period.
iso-edition-selection = In Windows Setup, choose an edition you have a license for.

## Windows installation USB
usb-drive-cancelled-title = USB drive creation canceled

## Windows version update
windows-terms-link = Read the license terms
footer-windows-terms = Accept the license terms to continue
windows-outcome-terms-title = The license terms weren't accepted
windows-outcome-managed-title = This PC gets updates from its organization
windows-outcome-managed = Its update server doesn't offer version { $release }, so Atlas didn't change anything. Ask your organization, or reinstall Windows with an Atlas ISO.
windows-outcome-policy = { $setting } goes back after Atlas changes it, so Atlas can't update Windows. If an organization manages this PC, ask them.
detail-move-update-source-managed = This PC gets updates from its organization's server, which doesn't offer version { $release }. Ask your organization, or reinstall Windows with an Atlas ISO.
