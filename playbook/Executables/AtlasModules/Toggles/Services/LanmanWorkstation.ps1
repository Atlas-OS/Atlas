function Get-AtlasSmbDirectFeature {
    $feature = @(Dism\Get-WindowsOptionalFeature -Online -ErrorAction Stop |
        Where-Object { $_.FeatureName -ceq 'SmbDirect' })
    if ($feature.Count -gt 1) {
        throw 'More than one SmbDirect feature was returned.'
    }
    return $feature
}

function Disable-AtlasSmbDirectFeature {
    param($Toggle)

    if (@(Get-AtlasSmbDirectFeature).Count -ne 1) {
        return
    }
    Dism\Disable-WindowsOptionalFeature -Online -FeatureName 'SmbDirect' -NoRestart -ErrorAction Stop | Out-Null
    $feature = @(Dism\Get-WindowsOptionalFeature -Online -FeatureName 'SmbDirect' -ErrorAction Stop)
    if ($feature.Count -ne 1 -or
        [string]$feature[0].State -notin @('Disabled', 'DisablePending', 'DisabledWithPayloadRemoved')) {
        throw 'SmbDirect did not reach a disabled state.'
    }
}

function Enable-AtlasSmbDirectFeature {
    param($Toggle)

    if (@(Get-AtlasSmbDirectFeature).Count -ne 1) {
        return
    }
    Dism\Enable-WindowsOptionalFeature -Online -FeatureName 'SmbDirect' -NoRestart -ErrorAction Stop | Out-Null
    $feature = @(Dism\Get-WindowsOptionalFeature -Online -FeatureName 'SmbDirect' -ErrorAction Stop)
    if ($feature.Count -ne 1 -or [string]$feature[0].State -notin @('Enabled', 'EnablePending')) {
        throw 'SmbDirect did not reach an enabled state.'
    }
}
