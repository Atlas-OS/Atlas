function Set-AtlasSleepStudyEventLogState {
    param($Toggle)

    $enable = switch -CaseSensitive ([string]$Toggle.State) {
        'Enable' { $true }
        'Disable' { $false }
        default { throw "SleepStudy: unsupported state '$($Toggle.State)'." }
    }

    $eventLogSwitch = if ($enable) { '/e:true' } else { '/e:false' }
    $wevtutil = Join-Path -Path $Toggle.WinDir -ChildPath 'System32\wevtutil.exe'

    $availableLogs = @(Invoke-AtlasToggleNativeCommand `
            -FilePath $wevtutil `
            -ArgumentList ([string[]]@('el')) `
            -AllowedExitCodes ([int[]]@(0)) |
        ForEach-Object { [string]$_ })
    foreach ($log in @(
            'Microsoft-Windows-SleepStudy/Diagnostic'
            'Microsoft-Windows-Kernel-Processor-Power/Diagnostic'
            'Microsoft-Windows-UserModePowerService/Diagnostic'
        )) {
        if ($availableLogs -cnotcontains $log) {
            Write-Verbose "SleepStudy: optional event channel '$log' is not present."
            continue
        }

        Invoke-AtlasToggleNativeCommand `
            -FilePath $wevtutil `
            -ArgumentList ([string[]]@('sl', $log, $eventLogSwitch)) `
            -AllowedExitCodes ([int[]]@(0)) | Out-Null
    }
}
