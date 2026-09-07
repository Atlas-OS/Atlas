# Atlas.Security domain: Windows Defender package state.
#
# Defender is removed and restored through the NoDefender CBS package. The package
# transaction itself stays in the interactive package installer entry script, run in a
# child Windows PowerShell process so its CBS retry handling and console flow are the
# same whether Atlas or a user launches it.

$script:AtlasDefenderPackagePattern = '*Z-Atlas-NoDefender-Package*'
$script:AtlasDefenderDocumentationUrl = 'https://docs.atlasos.net/docs/atlas-configuration/security/#defender'

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
    if ($NoInteraction) {
        $arguments += '-NoInteraction'
    }

    & $Installer.PowerShellPath @arguments
    return $LASTEXITCODE
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
        removing that package. Without -State the interactive menu picks the change;
        a silent call must name the state. The package installer prompts for its own
        restart.
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('Enable', 'Disable')]
        [string]$State,

        [switch]$Silent
    )

    $installer = Get-AtlasDefenderPackageInstaller
    $current = Get-AtlasDefenderState

    if (-not $State) {
        if ($Silent) {
            throw 'A silent Defender change requires -State Enable or Disable.'
        }
        $State = Read-AtlasDefenderMenuChoice -CurrentState $current
    }
    elseif ("${State}d" -ceq $current) {
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

    $exitCode = Invoke-AtlasDefenderPackageInstaller -Operation $operation -Installer $installer `
        -NoInteraction:$Silent
    if ($null -eq $exitCode -or [int]$exitCode -ne 0) {
        throw "$failure failed with exit code $exitCode."
    }
    Write-AtlasLog -Message "Windows Defender ${State} requested through the NoDefender package ($operation)."
}
