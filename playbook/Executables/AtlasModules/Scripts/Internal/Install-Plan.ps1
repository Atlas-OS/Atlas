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
        [ValidateSet('Fresh', 'Upgrade', 'Reapply')]
        [string]$Mode,

        [bool]$IsOobe = $false
    )

    $allModes = @('Fresh', 'Upgrade', 'Reapply')
    $steps = @(
        [pscustomobject][ordered]@{
            Key = 'Checkpoint/DefaultHiveLoad'; Modes = $allModes; Oobe = 'Any'
            Replay = 'Always'
        }
        [pscustomobject][ordered]@{
            Key = 'Checkpoint/PayloadReplacement'; Modes = $allModes; Oobe = 'Any'
            # Always sync the extracted payload before resuming completed steps. RC
            # rebuilds can keep the same playbook version while fixing a failed run.
            Replay = 'Always'
        }
        [pscustomobject][ordered]@{
            Key = 'Checkpoint/NotificationDisable'; Modes = $allModes; Oobe = 'Any'
            Replay = 'Always'
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
            Key = 'Checkpoint/HiddenSettingsPages'; Modes = @('Fresh'); Oobe = 'Any'
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
            Key = 'Services'; Modes = @('Fresh'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Components'; Modes = @('Fresh'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'AppxSupport'; Modes = @('Fresh'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Defaults'; Modes = $allModes; Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Checkpoint/DefaultRegistrySeed'; Modes = @('Fresh'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Revert'; Modes = @('Upgrade'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/networking'; Modes = @('Fresh'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/performance'; Modes = @('Fresh'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/privacy'; Modes = @('Fresh'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/qol'; Modes = @('Fresh'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/security'; Modes = @('Fresh'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/debloat'; Modes = @('Fresh'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/scripts'; Modes = @('Fresh'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Tweaks/misc'; Modes = @('Fresh'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Checkpoint/PowerSettings'; Modes = @('Fresh'); Oobe = 'Any'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Checkpoint/InstallingUserSetup'; Modes = @('Fresh'); Oobe = 'NonOobe'
            Replay = 'Once'
        }
        [pscustomobject][ordered]@{
            Key = 'Checkpoint/OemBranding'; Modes = @('Upgrade'); Oobe = 'Any'
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
