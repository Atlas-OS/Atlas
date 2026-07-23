# Toggle: Sleep (power-scheme sleep settings + optional hibernation follow-up).
$sleepAction = {
    param($Toggle)

    switch -CaseSensitive ([string]$Toggle.State) {
        'Disable' {
            $values = @(0, 0, 0, 0, 0)
            $unattendedSleepTimeout = 0
        }
        'Enable' {
            $values = @(1, 1, 1, 120, 1)
            $unattendedSleepTimeout = 1
        }
        default { throw "Sleep: unsupported state '$($Toggle.State)'." }
    }

    $powercfg = Join-Path -Path $Toggle.WinDir -ChildPath 'System32\powercfg.exe'
    if (-not (Test-Path -LiteralPath $powercfg -PathType Leaf)) {
        throw "Sleep: powercfg.exe is missing at '$powercfg'."
    }

    $sleepSubgroup = '238c9fa8-0aad-41ed-83f4-97be242c8f20'
    $settings = @(
        '25dfa149-5dd1-4736-b5ab-e8a37b5b8187'
        'abfc2519-3608-4c2a-94ea-171b0ed546ab'
        '94ac6d29-73ce-41a6-809f-6363ba21b47e'
        '7bc4a2f9-d8fc-4469-b07b-33eb785aaca0'
        'bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d'
    )
    for ($index = 0; $index -lt $settings.Count; $index++) {
        Invoke-AtlasToggleNativeCommand `
            -FilePath $powercfg `
            -ArgumentList ([string[]]@(
                    '/setacvalueindex'
                    'scheme_current'
                    $sleepSubgroup
                    $settings[$index]
                    [string]$values[$index]
                )) `
            -AllowedExitCodes ([int[]]@(0)) | Out-Null
    }

    Invoke-AtlasToggleNativeCommand `
        -FilePath $powercfg `
        -ArgumentList ([string[]]@(
                '/setacvalueindex'
                'scheme_current'
                '2e601130-5351-4d9d-8e04-252966bad054'
                'd502f7ee-1dc7-4efd-a55d-f04b6f5c0545'
                [string]$unattendedSleepTimeout
            )) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
    Invoke-AtlasToggleNativeCommand `
        -FilePath $powercfg `
        -ArgumentList ([string[]]@('/setactive', 'scheme_current')) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null

    if ($Toggle.Silent) { return }

    if ($Toggle.State -ceq 'Disable') {
        $answer = Read-Host 'Would you like to disable hibernation? [Y/N]'
        $hibernationState = if ($answer -match '^(y|yes)$') { 'Disable' } else { 'Enable' }
        Invoke-AtlasToggle -Name 'Hibernation' -State $hibernationState -Silent
    }

    $status = if ($Toggle.State -ceq 'Enable') { 'enabled' } else { 'disabled' }
    Write-Host "Sleep has been $status."
}

@{
    Name      = 'Sleep'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            ReplayScope = 'Machine'
            Launcher   = '3. General Configuration\Sleep\Disable Sleep.cmd'
            Reboot     = 'None'
            Action     = $sleepAction
        }
        Enable  = @{
            StateValue  = 1
            Launcher    = '3. General Configuration\Sleep\Enable Sleep (default).cmd'
            Reboot      = 'None'
            ReplayScope = 'Machine'
            Action      = $sleepAction
        }
    }
}
