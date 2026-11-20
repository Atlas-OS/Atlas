# Companion for the Sleep toggle: writes the sleep settings of the active power plan with
# powercfg, for when the PC is plugged in. Set-AtlasSleepState runs as Administrator when the
# Sleep launchers run and when an update replays the recorded state; only an interactive
# Disable offers to turn off hibernation as well.

function Set-AtlasSleepState {
    param($Toggle)

    # $values follows $settings below; $deepSleep is the Idle Resiliency setting.
    switch -CaseSensitive ([string]$Toggle.State) {
        'Disable' {
            $values = @(0, 0, 0, 0, 0)
            $deepSleep = 0
        }
        'Enable' {
            $values = @(1, 1, 1, 120, 1)
            $deepSleep = 1
        }
        default { throw "Sleep: unsupported state '$($Toggle.State)'." }
    }

    $powercfg = Join-Path -Path $Toggle.WinDir -ChildPath 'System32\powercfg.exe'
    if (-not (Test-Path -LiteralPath $powercfg -PathType Leaf)) {
        throw "Sleep: powercfg.exe is missing at '$powercfg'."
    }

    # SUB_SLEEP, the Sleep subgroup.
    $sleepSubgroup = '238c9fa8-0aad-41ed-83f4-97be242c8f20'
    $settings = @(
        '25dfa149-5dd1-4736-b5ab-e8a37b5b8187' # AWAYMODE: Allow Away Mode Policy (0 No, 1 Yes)
        'abfc2519-3608-4c2a-94ea-171b0ed546ab' # ALLOWSTANDBY: Allow Standby States (0 Off, 1 On)
        '94ac6d29-73ce-41a6-809f-6363ba21b47e' # HYBRIDSLEEP: Allow hybrid sleep (0 Off, 1 On)
        '7bc4a2f9-d8fc-4469-b07b-33eb785aaca0' # UNATTENDSLEEP: System unattended sleep timeout, in seconds
        'bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d' # RTCWAKE: Allow wake timers (0 Disable, 1 Enable)
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

    # SUB_IR (Idle Resiliency) DEEPSLEEP: Deep Sleep Enabled/Disabled (0 Disabled, 1 Enabled).
    Invoke-AtlasToggleNativeCommand `
        -FilePath $powercfg `
        -ArgumentList ([string[]]@(
                '/setacvalueindex'
                'scheme_current'
                '2e601130-5351-4d9d-8e04-252966bad054'
                'd502f7ee-1dc7-4efd-a55d-f04b6f5c0545'
                [string]$deepSleep
            )) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
    Invoke-AtlasToggleNativeCommand `
        -FilePath $powercfg `
        -ArgumentList ([string[]]@('/setactive', 'scheme_current')) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null

    if ($Toggle.Silent) {
        return
    }

    if ($Toggle.State -ceq 'Disable') {
        if (Read-AtlasYesNo -Question 'Also disable hibernation?') {
            # Only an affirmative answer changes this independent recorded choice.
            Invoke-AtlasToggleMachineState -Name 'Hibernation' -State Disable -StateRoot $Toggle.StateRoot
            Write-AtlasSuccess -Text 'Hibernation is now disabled.'
        }
    }
}
