# Toggle: Global timer resolution (scheduled task that forces a high timer resolution).
$timerResolutionAction = {
    param($Toggle)

    Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath `
            -ChildPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') `
        -ErrorAction Stop

    $scheduledTasksModule = Join-Path -Path $Toggle.WinDir `
        -ChildPath 'System32\WindowsPowerShell\v1.0\Modules\ScheduledTasks\ScheduledTasks.psd1'
    if (-not (Test-Path -LiteralPath $scheduledTasksModule -PathType Leaf)) {
        throw "TimerResolution: the inbox ScheduledTasks module is missing at '$scheduledTasksModule'."
    }
    Import-Module -Name $scheduledTasksModule -ErrorAction Stop

    $kernelKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
    $taskName = 'Force Timer Resolution'
    $taskPath = '\'

    switch -CaseSensitive ([string]$Toggle.State) {
        'Disable' {
            Remove-AtlasRegistryValue -Path $kernelKey -Name 'GlobalTimerResolutionRequests'

            $task = Get-ScheduledTask -ErrorAction Stop |
                Where-Object { $_.TaskPath -ceq $taskPath -and $_.TaskName -ceq $taskName } |
                Select-Object -First 1
            if ($null -ne $task) {
                if ([string]$task.State -ceq 'Running') {
                    Stop-ScheduledTask -InputObject $task -ErrorAction Stop
                }
                Unregister-ScheduledTask -InputObject $task -Confirm:$false -ErrorAction Stop
            }

            if (-not $Toggle.Silent) {
                Write-Host 'Finished, changes have been applied.'
            }
        }
        'Enable' {
            Set-AtlasRegistryValue -Path $kernelKey `
                -Name 'GlobalTimerResolutionRequests' -Type DWord -Data 1

            $taskXml = Join-Path -Path $Toggle.AtlasModulesPath `
                -ChildPath 'Other\Force Timer Resolution.xml'
            if (-not (Test-Path -LiteralPath $taskXml -PathType Leaf)) {
                throw "TimerResolution: the scheduled-task XML is missing at '$taskXml'."
            }
            $taskXmlContent = Get-Content -LiteralPath $taskXml -Raw -ErrorAction Stop
            if ([string]::IsNullOrWhiteSpace($taskXmlContent)) {
                throw "TimerResolution: the scheduled-task XML at '$taskXml' is empty."
            }

            Register-ScheduledTask -TaskName $taskName -TaskPath $taskPath `
                -Xml $taskXmlContent -Force -ErrorAction Stop | Out-Null
            Start-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction Stop
        }
        default { throw "TimerResolution: unsupported state '$($Toggle.State)'." }
    }
}

@{
    Name          = 'TimerResolution'
    Elevation     = 'Admin'
    NoStateRecord = $true
    Warning       = 'WARNING: This script will modify system services. Modifying services can lead to potential breakage of features and bugs. Proceed with caution, and refer to Atlas docs for more information!'
    States        = [ordered]@{
        Disable = @{
            Launcher = '3. General Configuration\Timer Resolution\Disable timer resolution (default).cmd'
            Reboot   = 'None'
            Action   = $timerResolutionAction
        }
        Enable  = @{
            Launcher = '3. General Configuration\Timer Resolution\Enable timer resolution.cmd'
            Reboot   = 'Recommend'
            Action   = $timerResolutionAction
        }
    }
}
