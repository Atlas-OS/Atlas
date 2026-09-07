# Shared destination-only shell handoff. Callers validate the protected setup root.
function Get-AtlasDesktopTaskName([string]$Sid) {
    $validated = New-Object Security.Principal.SecurityIdentifier($Sid)
    return 'AtlasOS ISO desktop cleanup ' + $validated.Value
}

function Register-AtlasDesktopCleanup([string]$Sid, [string]$Root) {
    $service = New-Object -ComObject 'Schedule.Service'
    $service.Connect()
    $task = $service.NewTask(0)
    $task.RegistrationInfo.Description = 'Removes the Atlas ISO setup shell for its setup account.'
    $task.Principal.UserId = 'S-1-5-18'
    $task.Principal.LogonType = 5 # TASK_LOGON_SERVICE_ACCOUNT
    $task.Settings.AllowDemandStart = $true
    $task.Settings.DisallowStartIfOnBatteries = $false
    $task.Settings.StopIfGoingOnBatteries = $false
    $task.Settings.ExecutionTimeLimit = 'PT1M'
    $action = $task.Actions.Create(0)
    $action.Path = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $action.Arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + (Join-Path $Root 'Setup.ps1') + '" -RestoreDesktopPolicy'
    # The user can request only this fixed action, never change or delete it.
    # TASK_CREATE refuses to replace an existing task with the same name.
    $name = Get-AtlasDesktopTaskName $Sid
    # First logon runs as an elevated administrator, which cannot assign SYSTEM
    # ownership. Administrators already have full control of this task.
    $sddl = 'O:BAG:SYD:P(A;;FA;;;SY)(A;;FA;;;BA)(A;;GRGX;;;' + $Sid + ')'
    [void]$service.GetFolder('\').RegisterTaskDefinition($name, $task, 2, 'S-1-5-18', $null, 5, $sddl)
}

function Remove-AtlasOwnedShell([Microsoft.Win32.RegistryKey]$Key, [string]$Shell) {
    # Never restore an old DACL or overwrite a shell installed by another tool.
    if ($Key -and [string]::Equals([string]$Key.GetValue('Shell'), $Shell, [StringComparison]::Ordinal)) {
        $Key.DeleteValue('Shell', $false)
    }
}

function Request-AtlasDesktopCleanup([string]$Sid) {
    $service = New-Object -ComObject 'Schedule.Service'
    $service.Connect()
    [void]$service.GetFolder('\').GetTask((Get-AtlasDesktopTaskName $Sid)).Run($null)
}

function Unregister-AtlasDesktopCleanup([string]$Sid) {
    $service = New-Object -ComObject 'Schedule.Service'
    $service.Connect()
    $service.GetFolder('\').DeleteTask((Get-AtlasDesktopTaskName $Sid), 0)
}
