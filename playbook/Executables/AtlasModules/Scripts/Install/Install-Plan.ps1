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

        [bool]$IsOobe = $false
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
            Key = 'Defaults'; Modes = $allModes; Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweak/qol/appearance/atlas-theme-upgrade'; Modes = @('Upgrade', 'Rebase'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/networking'; Modes = @('Fresh', 'Upgrade', 'Rebase'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/performance'; Modes = @('Fresh', 'Upgrade', 'Rebase'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/privacy'; Modes = @('Fresh', 'Upgrade', 'Rebase'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/qol'; Modes = @('Fresh', 'Upgrade', 'Rebase'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/security'; Modes = @('Fresh', 'Upgrade', 'Rebase'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/debloat'; Modes = @('Fresh', 'Upgrade', 'Rebase'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/scripts'; Modes = @('Fresh', 'Upgrade', 'Rebase'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/misc'; Modes = @('Fresh', 'Upgrade', 'Rebase'); Oobe = 'Any'
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
            Key = 'Checkpoint/InstallingUserSetup'; Modes = @('Fresh', 'Upgrade', 'Rebase'); Oobe = 'NonOobe'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Checkpoint/OemBranding'; Modes = @('Upgrade', 'Rebase'); Oobe = 'Any'
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

    $plan = foreach ($step in $steps) {
        if ($step.Modes -cnotcontains $Mode) {
            continue
        }
        if ($IsOobe -and $step.Oobe -ceq 'NonOobe') {
            continue
        }
        $step
    }

    return @($plan)
}
