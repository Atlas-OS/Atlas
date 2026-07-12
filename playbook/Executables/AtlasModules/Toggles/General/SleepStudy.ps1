# Toggle: Sleep Study diagnostic event logs and the Power Efficiency Diagnostics task.
$sleepStudyAction = {
    param($Toggle)

    $enable = switch -CaseSensitive ([string]$Toggle.State) {
        'Enable' { $true }
        'Disable' { $false }
        default { throw "SleepStudy: unsupported state '$($Toggle.State)'." }
    }

    $eventLogSwitch = if ($enable) { '/e:true' } else { '/e:false' }
    $taskPath = '\Microsoft\Windows\Power Efficiency Diagnostics\'
    $taskName = 'AnalyzeSystem'
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

    $task = @(Get-ScheduledTask -ErrorAction Stop |
        Where-Object {
            $_.TaskPath -ceq $taskPath -and $_.TaskName -ceq $taskName
        } |
        Select-Object -First 1)
    if ($task.Count -eq 0) {
        Write-Verbose "SleepStudy: optional scheduled task '$taskPath$taskName' is not present."
    }
    elseif ($enable) {
        Enable-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction Stop | Out-Null
    }
    else {
        Disable-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction Stop | Out-Null
    }

    if (-not $Toggle.Silent) {
        $status = if ($enable) { 'enabled' } else { 'disabled' }
        Write-Host ''
        Write-Host "Sleep Study has been $status."
    }
}

@{
    Name      = 'SleepStudy'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue  = 0
            ReplayScope = 'Machine'
            Launcher    = '3. General Configuration\Sleep Study\Disable Sleep Study (default).cmd'
            Reboot      = 'None'
            Action      = $sleepStudyAction
        }
        Enable  = @{
            StateValue  = 1
            ReplayScope = 'Machine'
            Launcher    = '3. General Configuration\Sleep Study\Enable Sleep Study.cmd'
            Reboot      = 'None'
            Action      = $sleepStudyAction
        }
    }
}
