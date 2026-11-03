Set-StrictMode -Version 3.0

function Get-AtlasInstallPlan {
    <#
    .SYNOPSIS
        Returns the ordered Atlas install steps for one execution context.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Fresh', 'Upgrade', 'Reapply', 'Rebase')]
        [string]$Mode,

        [bool]$IsOobe = $false,

        # The update chooses again (the install state's choices), so a step also runs
        # in the modes its ChooseAgainModes list.
        [bool]$ChooseAgain = $false
    )

    # Rebase: the Upgrade plan plus the fresh-install work a Windows that rebuilt
    # itself undid. Fresh-only steps that would overwrite the user's own layout,
    # theme, file associations, settings pages or power plan stay out.
    $allModes = @('Fresh', 'Upgrade', 'Reapply', 'Rebase')
    $steps = @(
        [pscustomobject][ordered]@{
            Key = 'Checkpoint/DefaultHiveLoad'; Modes = $allModes; Oobe = 'Any'
            Replay = 'Always'
        }
        [pscustomobject][ordered]@{
            Key = 'Checkpoint/PayloadReplacement'; Modes = $allModes; Oobe = 'Any'
            # Always sync the extracted files before resuming completed steps. RC
            # rebuilds can keep the same package version while fixing a failed run.
            Replay = 'Always'
        }
        [pscustomobject][ordered]@{
            Key = 'Checkpoint/NotificationDisable'; Modes = $allModes; Oobe = 'Any'
            Replay = 'Always'
        }
        [pscustomobject][ordered]@{
            # Before the choices are read: brings back the service backups and the
            # recorded choices a rebuilt Windows lost.
            Key = 'Checkpoint/RebaseRecovery'; Modes = @('Rebase'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Checkpoint/LegacyChoices'; Modes = @('Upgrade', 'Rebase'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'PreInstall'; Modes = $allModes; Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'ShellRefresh'; Modes = $allModes; Oobe = 'NonOobe'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Environment'; Modes = $allModes; Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweak/qol/set-hidden-settings-pages'; Modes = @('Fresh'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Checkpoint/InitializePath'; Modes = $allModes; Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Features'; Modes = $allModes; Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Software'; Modes = $allModes; Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Services'; Modes = @('Fresh', 'Rebase'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Components'; Modes = @('Fresh', 'Rebase'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'AppxSupport'; Modes = @('Fresh', 'Rebase'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            # Choosing again only: applies each choice that differs from the PC. After
            # LegacyChoices and Software, so the old choices are read and a newly
            # chosen browser is installed first. Before Defaults and the tweak
            # categories, so the replay and the tweaks that keep a recorded choice
            # apply the records it writes, never one the user just turned down.
            Key = 'Choices'; Modes = @(); ChooseAgainModes = @('Upgrade', 'Reapply'); Oobe = 'NonOobe'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Defaults'; Modes = $allModes; Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweak/qol/appearance/atlas-theme-upgrade'; Modes = @('Upgrade', 'Rebase'); Oobe = 'Any'
            Replay = 'Once'
        }
        # A reinstall of the same version runs the tweak categories too, so the fixes
        # a new build brings arrive; recorded choices still win over their defaults.
        [pscustomobject][ordered]@{
            Key = 'Tweaks/networking'; Modes = $allModes; Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/performance'; Modes = $allModes; Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/privacy'; Modes = $allModes; Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/qol'; Modes = $allModes; Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/security'; Modes = $allModes; Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/debloat'; Modes = $allModes; Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/scripts'; Modes = $allModes; Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/misc'; Modes = $allModes; Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweak/scripts/set-power-settings'; Modes = @('Fresh'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            # After Defaults has replayed the user's choices and Tweaks/qol has
            # written the pin, so only what nothing else owns is put back.
            Key = 'Checkpoint/WindowsTransition'; Modes = $allModes; Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            # On a reinstall too, so the installing user's own settings follow the tweaks.
            Key = 'Checkpoint/InstallingUserSetup'; Modes = $allModes; Oobe = 'NonOobe'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Checkpoint/NotificationRestore'; Modes = $allModes; Oobe = 'Any'
            Replay = 'Always'
        }
        [pscustomobject][ordered]@{
            Key = 'Checkpoint/DefaultHiveUnload'; Modes = $allModes; Oobe = 'Any'
            Replay = 'Always'
        }
    )

    foreach ($step in $steps) {
        if ($null -eq $step.PSObject.Properties['ChooseAgainModes']) {
            $step | Add-Member -NotePropertyName ChooseAgainModes -NotePropertyValue @()
        }
    }

    $plan = foreach ($step in $steps) {
        if ($step.Modes -cnotcontains $Mode -and
            -not ($ChooseAgain -and $step.ChooseAgainModes -ccontains $Mode)) {
            continue
        }
        if ($IsOobe -and $step.Oobe -ceq 'NonOobe') {
            continue
        }
        $step
    }

    return @($plan)
}
