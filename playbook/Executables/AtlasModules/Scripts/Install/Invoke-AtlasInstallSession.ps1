<#
.SYNOPSIS
    TrustedInstaller half of the Atlas front door.
.DESCRIPTION
    Entry\Install-Atlas.ps1 stages the extracted playbook beneath the protected staging
    root and asks the TrustedInstaller broker to run this script from that copy, twice:

      -Phase Capture   Reads request.json beside the payload, decides Fresh, Upgrade or
                       Reapply from the machine state document, begins the install state
                       and records the validated options. The front door then publishes
                       the installing user's marker from its own session.
      -Phase Run       Binds the published user, commits the captured state and runs the
                       complete install plan through Entry\Invoke-AtlasInstall.ps1.

    request.json is a bounded document: { "options": [ "<option>", ... ] }. Every option
    must be declared by playbook.conf, every required option group must be satisfied,
    and nothing else is accepted. The broker has already verified that this script and
    its staging root are owned and writable only by trusted principals.
.NOTES
    Exit codes: 0 success, 1 failure, 2 wrong privilege.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Capture', 'Run')]
    [string]$Phase
)

$scriptsRoot = [IO.Path]::GetFullPath([IO.Path]::GetDirectoryName($PSScriptRoot))
$bootstrap = [IO.Path]::Combine($scriptsRoot, 'Initialize-AtlasPowerShell.ps1')
if (-not [IO.File]::Exists($bootstrap)) {
    throw "The PowerShell bootstrap is missing at '$bootstrap'."
}
. $bootstrap

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

function Read-AtlasInstallRequest {
    param([Parameter(Mandatory = $true)][string]$PayloadRoot, [switch]$WithMode)

    $requestPath = Join-Path -Path $PayloadRoot -ChildPath 'request.json'
    if (-not [IO.File]::Exists($requestPath)) {
        throw "The install request '$requestPath' is missing."
    }
    if ((Get-Item -LiteralPath $requestPath).Length -gt 65536) {
        throw 'The install request exceeds its bounded size.'
    }
    $request = [IO.File]::ReadAllText($requestPath) | ConvertFrom-Json -ErrorAction Stop
    foreach ($property in $request.PSObject.Properties) {
        if ($property.Name -cnotin @('options', 'windowsSetup')) {
            throw "The install request has an unknown field '$($property.Name)'."
        }
    }
    if ($null -eq $request.PSObject.Properties['options']) {
        throw "The install request declares no 'options'."
    }
    $setup = $false
    if ($null -ne $request.PSObject.Properties['windowsSetup']) {
        if ($request.windowsSetup -isnot [bool]) { throw 'windowsSetup must be a Boolean.' }
        $setup = $request.windowsSetup
        if ($setup -and (Get-ItemPropertyValue -LiteralPath 'HKLM:\SYSTEM\Setup' -Name SystemSetupInProgress -ErrorAction Stop) -ne 1) {
            throw 'Windows Setup is not running.'
        }
    }
    if ($WithMode) { return [pscustomobject]@{ options = @($request.options | ForEach-Object { [string]$_ }); windowsSetup = $setup } }
    return @($request.options | ForEach-Object { [string]$_ })
}

function Assert-AtlasInstallOptionSet {
    <#
    .SYNOPSIS
        Rejects unknown options and unsatisfied option groups; returns the option set.
    #>
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Options,
        [Parameter(Mandatory = $true)][object[]]$Groups
    )

    $known = @($Groups | ForEach-Object { $_.Options })
    foreach ($option in $Options) {
        if ($known -cnotcontains $option) {
            throw "Option '$option' is not declared by playbook.conf."
        }
    }
    if (@($Options | Sort-Object -Unique).Count -ne $Options.Count) {
        throw 'The install request repeats an option.'
    }
    foreach ($group in $Groups) {
        $chosen = @($Options | Where-Object { $group.Options -ccontains $_ })
        if (-not [string]::IsNullOrWhiteSpace([string]$group.DependsOn) -and $Options -cnotcontains [string]$group.DependsOn) {
            if ($chosen.Count -gt 0) {
                throw "Options $($chosen -join ', ') require '$($group.DependsOn)'."
            }
            continue
        }
        if ($group.ExactlyOne -and $chosen.Count -ne 1) {
            throw "Exactly one of $($group.Options -join ', ') must be selected."
        }
    }
    return $Options
}

try {
    Import-Module -Name (Join-Path -Path $scriptsRoot -ChildPath 'Modules\Atlas.Core\Atlas.Core.psd1') -Force -ErrorAction Stop
    Import-Module -Name (Join-Path -Path $scriptsRoot -ChildPath 'Modules\Atlas.InstallState\Atlas.InstallState.psd1') -Force -DisableNameChecking -ErrorAction Stop
    Assert-AtlasPrivilege -TrustedInstaller

    $payloadRoot = [IO.Path]::GetFullPath([IO.Path]::Combine($scriptsRoot, '..', '..'))
    $playbookPath = [IO.Path]::Combine($payloadRoot, '..', 'playbook.conf')

    switch ($Phase) {
        'Capture' {
            $targetVersion = Get-AtlasPlaybookVersion -PlaybookPath $playbookPath
            $installRequest = Read-AtlasInstallRequest -PayloadRoot $payloadRoot -WithMode
            $options = Assert-AtlasInstallOptionSet -Options $installRequest.options `
                -Groups @(Get-AtlasPlaybookOption -PlaybookPath $playbookPath)
            $mode = Resolve-AtlasInstallMode -TargetVersion $targetVersion

            $null = Start-AtlasInstallState -TargetVersion $targetVersion -Mode $mode -IsOobe ([bool]$installRequest.windowsSetup) `
                -CaptureNonce ([guid]::NewGuid().ToString('D'))
            Set-AtlasInstallOptions -Options $options | Out-Null
            Write-Output "Atlas install state ready for $mode of $targetVersion with options: $($options -join ', ')."
        }
        'Run' {
            $captureScript = Join-Path -Path $scriptsRoot -ChildPath 'Entry\Initialize-AtlasInstallState.ps1'
            & $captureScript -Operation Commit
            $installScript = Join-Path -Path $scriptsRoot -ChildPath 'Entry\Invoke-AtlasInstall.ps1'
            & $installScript -Run
            exit $LASTEXITCODE
        }
    }
    exit 0
}
catch {
    $exitCode = if ($_.Exception.Message -like '[[]privilege[]]*') { 2 } else { 1 }
    [Console]::Error.WriteLine($_.Exception.Message)
    exit $exitCode
}
