# Atlas.Tweaks domain: tweak gating (Option / Arch / OnUpgrade / Oobe).

function Get-AtlasTweakSkipReason {
    <#
    .SYNOPSIS
        Returns a human-readable reason why a tweak does not apply to the current
        install context, or $null when it applies.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Tweak
    )

    $context = Get-AtlasContext

    if ($Tweak.ContainsKey('Option') -and $Tweak['Option']) {
        $option = [string]$Tweak['Option']
        if (-not (Test-AtlasOption -Name $option)) {
            return "option '$option' was not selected"
        }
    }

    if ($Tweak.ContainsKey('Arch') -and $Tweak['Arch']) {
        $arch = ([string]$Tweak['Arch']).ToUpperInvariant()
        if ($arch -eq 'ARM64' -and -not $context.IsArm64) {
            return 'requires an ARM64 machine'
        }
        if ($arch -eq 'X64' -and $context.IsArm64) {
            return 'requires an x64 machine'
        }
    }

    # Default 'Both' matches the legacy YAML semantics: actions without an explicit
    # onUpgrade gate ran on fresh installs AND upgrades.
    $onUpgrade = 'Both'
    if ($Tweak.ContainsKey('OnUpgrade') -and $Tweak['OnUpgrade']) {
        $onUpgrade = [string]$Tweak['OnUpgrade']
    }
    if ($onUpgrade -eq 'Skip' -and $context.IsUpgrade) {
        return 'skipped on upgrade installs'
    }
    if ($onUpgrade -eq 'Only' -and -not $context.IsUpgrade) {
        return 'runs only on upgrade installs'
    }

    if ($Tweak.ContainsKey('Oobe') -and $Tweak['Oobe'] -eq $false -and $context.IsOobe) {
        return 'skipped during OOBE installs'
    }

    return $null
}

function Test-AtlasTweakApplicable {
    <#
    .SYNOPSIS
        Returns whether a tweak (loaded from its .psd1) applies to the current install
        context, evaluating its Option, Arch, OnUpgrade and Oobe gates.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Tweak
    )

    return ($null -eq (Get-AtlasTweakSkipReason -Tweak $Tweak))
}
