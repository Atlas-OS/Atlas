# Helpers shared by Setup.ps1 and Desktop.ps1 on the installed PC. Callers
# validate the setup root.
function Get-AtlasPowerShellPath {
    return Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
}

# The shell command Setup.ps1 registers. Cleanup compares the registry value
# with it exactly, so both scripts must build it here.
function Get-AtlasDesktopShell([string]$Root) {
    return '"' + (Get-AtlasPowerShellPath) + '" -NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + (Join-Path $Root 'Desktop.ps1') + '"'
}

function Get-AtlasDesktopTaskName([string]$Sid) {
    $validated = New-Object Security.Principal.SecurityIdentifier($Sid)
    return 'AtlasOS ISO desktop cleanup ' + $validated.Value
}

function Get-AtlasTaskService {
    $service = New-Object -ComObject 'Schedule.Service'
    $service.Connect()
    return $service
}

function Register-AtlasDesktopCleanup([string]$Sid, [string]$Root) {
    $taskCreate = 2 # TASK_CREATE: never replaces an existing task
    $serviceAccount = 5 # TASK_LOGON_SERVICE_ACCOUNT
    $service = Get-AtlasTaskService
    $task = $service.NewTask(0)
    $task.RegistrationInfo.Description = 'Removes the Atlas ISO setup shell for its setup account.'
    $task.Principal.UserId = 'S-1-5-18'
    $task.Principal.LogonType = $serviceAccount
    $task.Settings.AllowDemandStart = $true
    $task.Settings.DisallowStartIfOnBatteries = $false
    $task.Settings.StopIfGoingOnBatteries = $false
    $task.Settings.ExecutionTimeLimit = 'PT1M'
    $action = $task.Actions.Create(0)
    $action.Path = Get-AtlasPowerShellPath
    $action.Arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + (Join-Path $Root 'Setup.ps1') + '" -RestoreDesktopPolicy'
    $name = Get-AtlasDesktopTaskName $Sid
    # The setup account may only read and run (GRGX) this fixed action. First
    # logon runs as an elevated administrator, which cannot assign SYSTEM
    # ownership; Administrators already have full control of the task.
    $sddl = 'O:BAG:SYD:P(A;;FA;;;SY)(A;;FA;;;BA)(A;;GRGX;;;' + $Sid + ')'
    [void]$service.GetFolder('\').RegisterTaskDefinition($name, $task, $taskCreate, 'S-1-5-18', $null, $serviceAccount, $sddl)
}

function Test-AtlasOwnedShell([Microsoft.Win32.RegistryKey]$Key, [string]$Shell) {
    return ($null -ne $Key -and [string]::Equals([string]$Key.GetValue('Shell'), $Shell, [StringComparison]::Ordinal))
}

function Remove-AtlasOwnedShell([Microsoft.Win32.RegistryKey]$Key, [string]$Shell) {
    # Never restore an old DACL or overwrite a shell installed by another tool.
    if (Test-AtlasOwnedShell $Key $Shell) { $Key.DeleteValue('Shell', $false) }
}

function Request-AtlasDesktopCleanup([string]$Sid) {
    [void](Get-AtlasTaskService).GetFolder('\').GetTask((Get-AtlasDesktopTaskName $Sid)).Run($null)
}

function Unregister-AtlasDesktopCleanup([string]$Sid) {
    (Get-AtlasTaskService).GetFolder('\').DeleteTask((Get-AtlasDesktopTaskName $Sid), 0)
}

# Appends, so a failed recovery does not overwrite the error that caused it.
function Write-AtlasDesktopRecoveryLog($ErrorRecord) {
    [IO.File]::AppendAllText((Join-Path $env:LOCALAPPDATA 'Atlas-desktop-recovery.log'), ($ErrorRecord | Out-String))
}
