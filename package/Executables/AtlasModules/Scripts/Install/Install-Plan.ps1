Set-StrictMode -Version 3.0

function Get-AtlasInstallPlan {
    <#
    .SYNOPSIS
        Returns the ordered Atlas install steps for one install mode.
    .DESCRIPTION
        Each step has these fields:

          Key               The step's name in the install state's completedSteps, and
                            what Entry\Invoke-AtlasInstall.ps1 runs for it:
                            Checkpoint/<name> runs a task script under Install\Tasks;
                            Tweaks/<category> applies one tweak category; Tweak/<slug>
                            applies one Standalone tweak from the manifest; any other
                            key runs Install\Phases\Invoke-<Key>Phase.ps1.
          Modes             The install modes the step runs in.
          ChooseAgainModes  The modes it also runs in when the update chooses again.
                            Empty unless the step sets it.
          Replay            Once: a resumed install skips the step once it completed.
                            Always: it runs on every attempt, resumes included.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Fresh', 'Upgrade', 'Reapply', 'Rebase')]
        [string]$Mode,

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
            Key = 'Checkpoint/DefaultHiveLoad'; Modes = $allModes
            Replay = 'Always'
        }
        [pscustomobject][ordered]@{
            Key = 'Checkpoint/PayloadReplacement'; Modes = $allModes
            # Syncs the extracted files before a resume skips the completed steps: a
            # rebuilt package can keep its version while it fixes a failed run.
            Replay = 'Always'
        }
        [pscustomobject][ordered]@{
            Key = 'Checkpoint/NotificationDisable'; Modes = $allModes
            Replay = 'Always'
        }
        [pscustomobject][ordered]@{
            # Before the choices are read: brings back the service backups and the
            # recorded choices a rebuilt Windows lost.
            Key = 'Checkpoint/RebaseRecovery'; Modes = @('Rebase')
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Checkpoint/LegacyChoices'; Modes = @('Upgrade', 'Rebase')
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'PreInstall'; Modes = $allModes
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'ShellRefresh'; Modes = $allModes
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Environment'; Modes = $allModes
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweak/qol/set-hidden-settings-pages'; Modes = @('Fresh')
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Checkpoint/InitializePath'; Modes = $allModes
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Features'; Modes = $allModes
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Software'; Modes = $allModes
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Services'; Modes = @('Fresh', 'Rebase')
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Components'; Modes = @('Fresh', 'Rebase')
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'AppxSupport'; Modes = @('Fresh', 'Rebase')
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            # Choosing again only: applies each choice that differs from the PC. After
            # LegacyChoices and Software, so the old choices are read and a newly
            # chosen browser is installed first. Before Defaults and the tweak
            # categories, so the replay and the tweaks that keep a recorded choice
            # apply the records it writes, never one the user just turned down.
            Key = 'Choices'; Modes = @(); ChooseAgainModes = @('Upgrade', 'Reapply')
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Defaults'; Modes = $allModes
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweak/qol/appearance/atlas-theme-upgrade'; Modes = @('Upgrade', 'Rebase')
            Replay = 'Once'
        }
        # A reinstall of the same version runs the tweak categories too, so the fixes
        # a new build brings arrive; recorded choices still win over their defaults.
        [pscustomobject][ordered]@{
            Key = 'Tweaks/networking'; Modes = $allModes
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/performance'; Modes = $allModes
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/privacy'; Modes = $allModes
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/qol'; Modes = $allModes
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/security'; Modes = $allModes
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/debloat'; Modes = $allModes
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/scripts'; Modes = $allModes
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/misc'; Modes = $allModes
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweak/scripts/set-power-settings'; Modes = @('Fresh')
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            # After Defaults has replayed the user's choices and Tweaks/qol has
            # written the pin, so only what nothing else owns is put back.
            Key = 'Checkpoint/WindowsTransition'; Modes = $allModes
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            # On a reinstall too, so the installing user's own settings follow the tweaks.
            Key = 'Checkpoint/InstallingUserSetup'; Modes = $allModes
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Checkpoint/NotificationRestore'; Modes = $allModes
            Replay = 'Always'
        }
        [pscustomobject][ordered]@{
            Key = 'Checkpoint/DefaultHiveUnload'; Modes = $allModes
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
        $step
    }

    return @($plan)
}
