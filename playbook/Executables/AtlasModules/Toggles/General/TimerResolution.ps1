function Import-AtlasTimerResolutionTaskModule {
    param($Toggle)

    $scheduledTasksModule = Join-Path -Path $Toggle.WinDir `
        -ChildPath 'System32\WindowsPowerShell\v1.0\Modules\ScheduledTasks\ScheduledTasks.psd1'
    if (-not (Test-Path -LiteralPath $scheduledTasksModule -PathType Leaf)) {
        throw "TimerResolution: the inbox ScheduledTasks module is missing at '$scheduledTasksModule'."
    }
    Import-Module -Name $scheduledTasksModule -ErrorAction Stop
}

function Unregister-AtlasTimerResolutionTask {
    param($Toggle)

    Import-AtlasTimerResolutionTaskModule -Toggle $Toggle

    $taskName = 'Force Timer Resolution'
    $taskPath = '\'
    $task = Get-ScheduledTask -ErrorAction Stop |
        Where-Object { $_.TaskPath -ceq $taskPath -and $_.TaskName -ceq $taskName } |
        Select-Object -First 1
    if ($null -ne $task) {
        if ([string]$task.State -ceq 'Running') {
            Stop-ScheduledTask -InputObject $task -ErrorAction Stop
        }
        Unregister-ScheduledTask -InputObject $task -Confirm:$false -ErrorAction Stop
    }
}

function Register-AtlasTimerResolutionTask {
    param($Toggle)

    Import-AtlasTimerResolutionTaskModule -Toggle $Toggle

    $taskName = 'Force Timer Resolution'
    $taskPath = '\'
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
