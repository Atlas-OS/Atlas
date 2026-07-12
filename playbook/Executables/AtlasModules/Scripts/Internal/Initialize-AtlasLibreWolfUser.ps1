<#
.SYNOPSIS
    Publishes LibreWolf integration for one Windows account.
.DESCRIPTION
    This helper runs as the exact install-state user, verifies that token against
    ExpectedUserSid, and creates only that user's Desktop shortcut and updater task.

    The updater task deliberately uses the user's interactive, non-elevated token.
    LibreWolf WinUpdater can move into the user's AppData when it cannot update the
    machine installation, so it must never run with highest privileges.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ExpectedUserSid
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

function ConvertTo-AtlasLibreWolfAccountSid {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Sid
    )

    $securityIdentifier = try {
        New-Object Security.Principal.SecurityIdentifier($Sid)
    }
    catch {
        throw "The expected LibreWolf user SID '$Sid' is invalid."
    }
    if (-not $securityIdentifier.IsAccountSid() -or
        -not [string]::Equals($securityIdentifier.Value, $Sid, [StringComparison]::Ordinal)) {
        throw "The expected LibreWolf user SID '$Sid' is not a canonical Windows account SID."
    }

    $securityIdentifier.Value
}

function New-AtlasLibreWolfDesktopShortcut {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This private exact-user helper always publishes its fixed LibreWolf shortcut.'
    )]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BrowserPath,

        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    $desktop = [Environment]::GetFolderPath([Environment+SpecialFolder]::DesktopDirectory)
    if ([string]::IsNullOrWhiteSpace($desktop)) {
        throw 'The exact user Desktop known folder could not be resolved.'
    }

    $shell = $shortcut = $null
    $destination = [IO.Path]::Combine($desktop, 'LibreWolf.lnk')
    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($destination)
        $shortcut.TargetPath = $BrowserPath
        $shortcut.WorkingDirectory = $WorkingDirectory
        $shortcut.Save()
    }
    finally {
        foreach ($comObject in @($shortcut, $shell)) {
            if ($null -ne $comObject -and [Runtime.InteropServices.Marshal]::IsComObject($comObject)) {
                [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($comObject)
            }
        }
    }

    if (-not [IO.File]::Exists($destination)) {
        throw "Creating the exact-user LibreWolf shortcut failed at '$destination'."
    }
}

function New-AtlasLibreWolfUpdaterTaskXml {
    <#
    .NOTES
        ScheduledTasks\New-ScheduledTaskPrincipal translates an input SID into an
        account name. Build the definition through Task Scheduler COM so the principal
        and logon trigger retain the exact canonical SID.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This private constructor creates only an unregistered in-memory COM definition.'
    )]
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserSid,

        [Parameter(Mandatory = $true)]
        [string]$UpdaterPath,

        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    $service = $definition = $trigger = $action = $null
    try {
        $service = New-Object -ComObject 'Schedule.Service'
        $service.Connect()
        $definition = $service.NewTask(0)
        $definition.RegistrationInfo.Author = 'AtlasOS'
        $definition.RegistrationInfo.Description = `
            'Checks for LibreWolf updates while this exact user is logged on.'

        # TASK_INSTANCES_IGNORE_NEW = 2.
        $definition.Settings.MultipleInstances = 2
        $definition.Settings.DisallowStartIfOnBatteries = $false
        $definition.Settings.StopIfGoingOnBatteries = $false
        $definition.Settings.AllowHardTerminate = $false
        $definition.Settings.StartWhenAvailable = $true
        $definition.Settings.RunOnlyIfNetworkAvailable = $true
        $definition.Settings.Enabled = $true

        # TASK_LOGON_INTERACTIVE_TOKEN = 3; TASK_RUNLEVEL_LUA = 0.
        $definition.Principal.UserId = $UserSid
        $definition.Principal.LogonType = 3
        $definition.Principal.RunLevel = 0

        # TASK_TRIGGER_LOGON = 9. Check after logon and every four hours thereafter.
        $trigger = $definition.Triggers.Create(9)
        $trigger.UserId = $UserSid
        $trigger.Delay = 'PT1M'
        $trigger.Repetition.Interval = 'PT4H'
        $trigger.Repetition.StopAtDurationEnd = $false

        # TASK_ACTION_EXEC = 0.
        $action = $definition.Actions.Create(0)
        $action.Path = $UpdaterPath
        $action.Arguments = '/Scheduled'
        $action.WorkingDirectory = $WorkingDirectory

        [string]$definition.XmlText
    }
    finally {
        foreach ($comObject in @($action, $trigger, $definition, $service)) {
            if ($null -ne $comObject -and [Runtime.InteropServices.Marshal]::IsComObject($comObject)) {
                [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($comObject)
            }
        }
    }
}

function Register-AtlasLibreWolfUpdaterTask {
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserSid,

        [Parameter(Mandatory = $true)]
        [string]$UpdaterPath,

        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    $taskXml = New-AtlasLibreWolfUpdaterTaskXml `
        -UserSid $UserSid -UpdaterPath $UpdaterPath -WorkingDirectory $WorkingDirectory
    $parsedTask = [xml]$taskXml
    if (-not [string]::Equals(
            [string]$parsedTask.Task.Principals.Principal.UserId,
            $UserSid,
            [StringComparison]::Ordinal
        ) -or
        -not [string]::Equals(
            [string]$parsedTask.Task.Triggers.LogonTrigger.UserId,
            $UserSid,
            [StringComparison]::Ordinal
        )) {
        throw 'Task Scheduler changed the exact LibreWolf user SID while building the task definition.'
    }

    $service = $rootFolder = $registeredTask = $null
    try {
        $service = New-Object -ComObject 'Schedule.Service'
        $service.Connect()
        $rootFolder = $service.GetFolder('\')

        # TASK_CREATE_OR_UPDATE = 6; TASK_LOGON_INTERACTIVE_TOKEN = 3.
        $registeredTask = $rootFolder.RegisterTask(
            "LibreWolf WinUpdater ($UserSid)",
            $taskXml,
            6,
            $UserSid,
            $null,
            3,
            $null
        )
    }
    finally {
        foreach ($comObject in @($registeredTask, $rootFolder, $service)) {
            if ($null -ne $comObject -and [Runtime.InteropServices.Marshal]::IsComObject($comObject)) {
                [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($comObject)
            }
        }
    }
}

$canonicalExpectedSid = ConvertTo-AtlasLibreWolfAccountSid -Sid $ExpectedUserSid
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
try {
    $currentSid = [string]$identity.User.Value
}
finally {
    $identity.Dispose()
}
if (-not [string]::Equals($currentSid, $canonicalExpectedSid, [StringComparison]::Ordinal)) {
    throw "LibreWolf user-integration token SID '$currentSid' does not match expected SID '$canonicalExpectedSid'."
}

$programFiles = [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFiles)
if ([string]::IsNullOrWhiteSpace($programFiles)) {
    throw 'The machine Program Files known folder could not be resolved.'
}

$libreWolfRoot = [IO.Path]::Combine($programFiles, 'LibreWolf')
$browserPath = [IO.Path]::Combine($libreWolfRoot, 'librewolf.exe')
if (-not [IO.File]::Exists($browserPath)) {
    return
}

New-AtlasLibreWolfDesktopShortcut `
    -BrowserPath $browserPath -WorkingDirectory $libreWolfRoot

$updaterRoot = [IO.Path]::Combine($libreWolfRoot, 'librewolf-winupdater')
$updaterPath = [IO.Path]::Combine($updaterRoot, 'LibreWolf-WinUpdater.exe')
if (-not [IO.File]::Exists($updaterPath)) {
    Write-Warning 'LibreWolf is installed, but its WinUpdater payload is absent; no updater task was registered.'
    return
}

Register-AtlasLibreWolfUpdaterTask `
    -UserSid $canonicalExpectedSid `
    -UpdaterPath $updaterPath `
    -WorkingDirectory $updaterRoot
