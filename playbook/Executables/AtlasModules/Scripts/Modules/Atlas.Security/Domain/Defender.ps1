# Atlas.Security domain: Windows Defender package state and its core service.
#
# Defender is removed and restored through the NoDefender CBS package. The package
# transaction itself stays in the interactive package installer entry script, run in a
# child Windows PowerShell process so its CBS retry handling and console flow are the
# same whether Atlas or a user launches it.

$script:AtlasDefenderPackagePattern = '*Z-Atlas-NoDefender-Package*'
$script:AtlasDefenderDocumentationUrl = 'https://docs.atlasos.net/docs/atlas-configuration/security/#defender'
$script:AtlasDefenderCoreServicePath = 'HKLM:\SYSTEM\CurrentControlSet\Services\MDCoreSvc'
$script:AtlasDefenderCoreTaskName = 'AtlasDisableMDCoreSvc'

function Get-AtlasDefenderPackageNames {
    return @(Get-WindowsPackage -Online -ErrorAction Stop |
        Where-Object { $_.PackageName -like '*NoDefender*' } |
        ForEach-Object { [string]$_.PackageName })
}

function Get-AtlasDefenderState {
    <#
    .SYNOPSIS
        Reports whether Windows Defender is currently Enabled or Disabled, judged by the
        presence of the installed NoDefender package.
    #>
    [CmdletBinding()]
    param()

    $packages = @(Get-AtlasDefenderPackageNames)
    if ($packages.Count -eq 0) {
        return 'Enabled'
    }
    return 'Disabled'
}

function Set-AtlasDefenderCoreService {
    <#
    .SYNOPSIS
        Keeps Microsoft Defender Core Service (MDCoreSvc) in step with Defender. Removed
        turns the service off at the next startup; Restored, run before the NoDefender
        package comes off, puts back the automatic start Windows gives it.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Removed', 'Restored')]
        [string]$State,

        # Tests point this at a scratch key.
        [ValidateNotNullOrEmpty()]
        [string]$ServicePath = $script:AtlasDefenderCoreServicePath
    )

    if ($State -ceq 'Removed') {
        # MDCoreSvc survives the NoDefender package but its binary is removed with
        # Defender, so SCM fails it 0x80070002 (event 7023) on every boot. The Start
        # value can't be changed now: Defender Tamper Protection is still enforced at the
        # kernel level until the restart and denies the write even as TrustedInstaller.
        # A one-shot startup task writes it after the restart, once Defender is gone.
        $mdCoreArgs = "/c reg add `"HKLM\SYSTEM\CurrentControlSet\Services\MDCoreSvc`" " `
            + "/v Start /t REG_DWORD /d 4 /f > nul && " `
            + "schtasks /delete /tn `"$script:AtlasDefenderCoreTaskName`" /f > nul"
        $mdCoreTask = @{
            'TaskName'  = $script:AtlasDefenderCoreTaskName
            'Settings'  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
            'Trigger'   = New-ScheduledTaskTrigger -AtStartup
            'Principal' = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
            'Force'     = $true
            'Action'    = New-ScheduledTaskAction -Execute 'cmd' -Argument $mdCoreArgs
        }
        Register-ScheduledTask @mdCoreTask | Out-Null
        Write-AtlasLog -Message 'Microsoft Defender Core Service is turned off at the next startup.'
        return
    }

    # A removal that hasn't restarted yet would otherwise turn the service off after
    # Defender is back.
    Remove-AtlasScheduledTask -Path "\$script:AtlasDefenderCoreTaskName" -IgnoreMissing
    # Written while Defender is still removed, so Tamper Protection can't refuse it.
    $service = Get-Item -LiteralPath $ServicePath -ErrorAction SilentlyContinue
    if ($null -eq $service -or @($service.GetValueNames()) -notcontains 'Start') {
        return
    }
    if ($service.GetValueKind('Start') -eq [Microsoft.Win32.RegistryValueKind]::DWord -and
        [int]$service.GetValue('Start') -eq 4) {
        Set-AtlasRegistryValue -Path $ServicePath -Name 'Start' -Type DWord -Data 2
        Write-AtlasLog -Message 'Microsoft Defender Core Service starts automatically again.'
    }
}

function Test-AtlasDefenderCoreServiceRemoved {
    <#
    .SYNOPSIS
        Whether Set-AtlasDefenderCoreService -State Removed has nothing left to do: the
        service's Start reads 4, Atlas's task turns it off at the next startup, or this
        Windows has no such service. Reads only.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        # Tests point this at a scratch key.
        [ValidateNotNullOrEmpty()]
        [string]$ServicePath = $script:AtlasDefenderCoreServicePath
    )

    $service = Get-Item -LiteralPath $ServicePath -ErrorAction SilentlyContinue
    if ($null -eq $service) {
        return $true
    }
    if (@($service.GetValueNames()) -contains 'Start' -and
        $service.GetValueKind('Start') -eq [Microsoft.Win32.RegistryValueKind]::DWord -and
        [int]$service.GetValue('Start') -eq 4) {
        return $true
    }
    # A disabled task never runs, so only an enabled one is on its way.
    return (Get-AtlasScheduledTaskState -Path "\$script:AtlasDefenderCoreTaskName") -ceq 'Enabled'
}

function Get-AtlasDefenderPackageInstaller {
    <#
    .SYNOPSIS
        Resolves the package installer entry script and the Windows PowerShell host that
        runs it, refusing a missing file or a reparse point.
    #>
    $installScript = Join-Path -Path (Get-AtlasContext).AtlasModulesPath `
        -ChildPath 'Scripts\Entry\Install-AtlasPackage.ps1'
    $powerShellPath = Join-Path -Path ([Environment]::GetFolderPath('System')) `
        -ChildPath 'WindowsPowerShell\v1.0\powershell.exe'
    foreach ($path in @($installScript, $powerShellPath)) {
        if (-not [IO.File]::Exists($path) -or
            (([IO.File]::GetAttributes($path) -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
            throw "Required Defender package installer file '$path' is missing or a reparse point."
        }
    }

    return [pscustomobject]@{
        ScriptPath     = $installScript
        PowerShellPath = $powerShellPath
    }
}

function Invoke-AtlasDefenderPackageInstaller {
    <#
    .SYNOPSIS
        Runs the package installer for the NoDefender package and returns its exit code.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Install', 'Uninstall')]
        [string]$Operation,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]$Installer,

        [switch]$NoInteraction
    )

    $arguments = @(
        '-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $Installer.ScriptPath,
        "-${Operation}Packages", $script:AtlasDefenderPackagePattern
    )
    if (-not $NoInteraction) {
        # Interactively the installer asks its own questions. Redirecting its output
        # would hold each prompt back until it was answered, so it shares this console.
        $process = Start-Process -FilePath $Installer.PowerShellPath `
            -ArgumentList (ConvertTo-AtlasWindowsArgumentString -ArgumentList $arguments) `
            -NoNewWindow -Wait -PassThru -ErrorAction Stop
        return $process.ExitCode
    }

    # Captured so the installer's console lines never join the returned exit code. A
    # silent run has no window to show them in, so they go to the log. Redirected stderr
    # becomes error records, which Stop would throw before the exit code is read.
    $arguments += '-NoInteraction'
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& $Installer.PowerShellPath @arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    foreach ($line in $output) {
        $text = ([string]$line).Trim()
        if ($text.Length -gt 0) {
            Write-AtlasLog -Message "Package installer: $text"
        }
    }
    return $exitCode
}

function Read-AtlasDefenderMenuChoice {
    <#
    .SYNOPSIS
        Shows the Defender menu until the user picks the state that is not current, and
        returns that state. The documentation option opens the docs and asks again.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Enabled', 'Disabled')]
        [string]$CurrentState
    )

    $currentIndex = if ($CurrentState -ceq 'Disabled') { 1 } else { 2 }
    Write-AtlasNote -Text 'Only disable Windows Defender after reading the Atlas documentation.'
    Write-AtlasBlankLine
    while ($true) {
        $choice = Read-AtlasChoice -Question 'What would you like to do?' `
            -Option @('Disable Windows Defender', 'Enable Windows Defender', 'Open the documentation') `
            -CurrentIndex $currentIndex
        switch ($choice) {
            1 { return 'Disable' }
            2 { return 'Enable' }
            3 { Start-Process $script:AtlasDefenderDocumentationUrl }
        }
    }
}

function Confirm-AtlasDefenderStateChange {
    <#
    .SYNOPSIS
        Shows the consequences of the requested change and waits for the user to
        continue.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Enable', 'Disable')]
        [string]$State
    )

    Write-AtlasBlankLine
    if ($State -ceq 'Disable') {
        Write-AtlasWarning -Text @(
            'Disabling Windows Defender leaves this PC without real-time antivirus protection.'
            'Malware and unwanted software will no longer be blocked automatically.'
        )
    }
    else {
        Write-AtlasNote -Text @(
            'After Windows Defender is enabled and Windows restarts, review the settings in'
            'Windows Security and turn on the protections you want.'
        )
    }
    Wait-AtlasContinue
}

function Read-AtlasDefenderStateChoice {
    <#
    .SYNOPSIS
        The interactive half of Toggle Defender: reads the current state, shows the menu
        and the consequences, and returns the confirmed state name for the silent
        TrustedInstaller step.
    #>
    [CmdletBinding()]
    param()

    $state = Read-AtlasDefenderMenuChoice -CurrentState (Get-AtlasDefenderState)
    Confirm-AtlasDefenderStateChange -State $state
    return $state
}

function Set-AtlasDefenderState {
    <#
    .SYNOPSIS
        Disables Windows Defender by installing the NoDefender package, or enables it by
        removing that package. Read-AtlasDefenderStateChoice is the interactive menu.
        Without -Silent the package installer prompts for its own restart.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Enable', 'Disable')]
        [string]$State,

        [switch]$Silent
    )

    $installer = Get-AtlasDefenderPackageInstaller
    $current = Get-AtlasDefenderState

    if ("${State}d" -ceq $current) {
        Write-AtlasLog -Message "Windows Defender is already $($current.ToLowerInvariant()); no package change is needed."
        return
    }

    if (-not $Silent) {
        Confirm-AtlasDefenderStateChange -State $State
    }

    if ($State -ceq 'Disable') {
        $operation = 'Install'
        $failure = 'Package installation'
        $step = 'Disabling Windows Defender. This can take a few minutes...'
    }
    else {
        $operation = 'Uninstall'
        $failure = 'Package removal'
        $step = 'Enabling Windows Defender. This can take a few minutes...'
    }
    if (-not $Silent) {
        Write-AtlasStep -Text $step
    }

    if ($State -ceq 'Enable') {
        Set-AtlasDefenderCoreService -State Restored
    }
    $exitCode = Invoke-AtlasDefenderPackageInstaller -Operation $operation -Installer $installer `
        -NoInteraction:$Silent
    if ($null -eq $exitCode -or [int]$exitCode -ne 0) {
        throw "$failure failed with exit code $exitCode."
    }
    if ($State -ceq 'Disable') {
        Set-AtlasDefenderCoreService -State Removed
    }
    Write-AtlasLog -Message "Windows Defender ${State} requested through the NoDefender package ($operation)."
}
