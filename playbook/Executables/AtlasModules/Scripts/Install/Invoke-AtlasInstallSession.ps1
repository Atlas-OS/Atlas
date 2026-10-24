<#
.SYNOPSIS
    TrustedInstaller half of the Atlas front door.
.DESCRIPTION
    Entry\Install-Atlas.ps1 stages the extracted package beneath the protected staging
    root and asks the TrustedInstaller broker to run this script from that copy, twice:

      -Phase Capture   Reads request.json beside the staged files, decides Fresh, Upgrade,
                       Reapply or Rebase from the machine state document, begins the
                       install state and records the validated options. The front door
                       then publishes the installing user's marker from its own session.
      -Phase Run       Binds the published user, commits the captured state and runs the
                       complete install plan through Entry\Invoke-AtlasInstall.ps1.

    request.json is a size-limited document: { "options": [ "<option>", ... ] }. Every option
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
$sessionLog = [IO.Path]::Combine([IO.Path]::GetDirectoryName($scriptsRoot), 'Logs', "install-$($Phase.ToLowerInvariant()).log")

function Write-AtlasSessionLog {
    param([string]$Message)
    [IO.File]::AppendAllText($sessionLog, "[$([DateTime]::UtcNow.ToString('o'))] $Message`r`n", [Text.UTF8Encoding]::new($false))
}

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

function Read-AtlasInstallRequest {
    param([Parameter(Mandatory = $true)][string]$PayloadRoot)

    $requestPath = Join-Path -Path $PayloadRoot -ChildPath 'request.json'
    if (-not [IO.File]::Exists($requestPath)) {
        throw "The install request '$requestPath' is missing."
    }
    if ((Get-Item -LiteralPath $requestPath).Length -gt 65536) {
        throw 'The install request exceeds its size limit.'
    }
    $request = [IO.File]::ReadAllText($requestPath) | ConvertFrom-Json -ErrorAction Stop
    foreach ($property in $request.PSObject.Properties) {
        if ($property.Name -cne 'options') {
            throw "The install request has an unknown field '$($property.Name)'."
        }
    }
    if ($null -eq $request.PSObject.Properties['options']) {
        throw "The install request declares no 'options'."
    }
    return @($request.options | ForEach-Object { [string]$_ })
}

function Assert-AtlasInstallOptionSet {
    <#
    .SYNOPSIS
        Rejects unknown options and unsatisfied option groups; returns the option set.
    .PARAMETER ResumedOptions
        The options of the unfinished install this request resumes. A resume must
        keep them, so a required group added to the package after they were
        recorded may stay unchosen when they chose nothing in it; its steps then
        change nothing.
    #>
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Options,
        [Parameter(Mandatory = $true)][object[]]$Groups,
        [AllowEmptyCollection()][string[]]$ResumedOptions
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
        $addedSinceResumed = $chosen.Count -eq 0 -and $PSBoundParameters.ContainsKey('ResumedOptions') -and
            -not @($ResumedOptions | Where-Object { $group.Options -ccontains $_ })
        if ($group.ExactlyOne -and $chosen.Count -ne 1 -and -not $addedSinceResumed) {
            throw "Exactly one of $($group.Options -join ', ') must be selected."
        }
    }
    return $Options
}

try {
    # The native TrustedInstaller child has no inherited console or standard handles.
    # Persist failures before bootstrap/module loading, then let the broker relay them.
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($sessionLog))
    [IO.File]::WriteAllText($sessionLog, '', [Text.UTF8Encoding]::new($false))
    Write-AtlasSessionLog "Starting install phase $Phase."
    if (-not [IO.File]::Exists($bootstrap)) {
        throw "The PowerShell bootstrap is missing at '$bootstrap'."
    }
    . $bootstrap
    Import-Module -Name (Join-Path -Path $scriptsRoot -ChildPath 'Modules\Atlas.Core\Atlas.Core.psd1') -Force -ErrorAction Stop
    Import-Module -Name (Join-Path -Path $scriptsRoot -ChildPath 'Modules\Atlas.InstallState\Atlas.InstallState.psd1') -Force -DisableNameChecking -ErrorAction Stop
    Assert-AtlasPrivilege -TrustedInstaller

    $payloadRoot = [IO.Path]::GetFullPath([IO.Path]::Combine($scriptsRoot, '..', '..'))
    $playbookPath = [IO.Path]::Combine($payloadRoot, '..', 'playbook.conf')

    switch ($Phase) {
        'Capture' {
            $targetVersion = Get-AtlasPlaybookVersion -PlaybookPath $playbookPath
            $requestedOptions = @(Read-AtlasInstallRequest -PayloadRoot $payloadRoot)
            $optionCheck = @{ Options = $requestedOptions; Groups = @(Get-AtlasPlaybookOption -PlaybookPath $playbookPath) }
            # The same test Set-AtlasInstallOptions uses to hold a resume to its options.
            $active = Get-AtlasInstallState
            if ($null -ne $active -and $active.targetVersion -ceq $targetVersion -and
                ($active.status -ceq 'Running' -or @($active.completedSteps).Count -gt 0)) {
                $optionCheck.ResumedOptions = @($active.options | ForEach-Object { [string]$_ })
            }
            $options = Assert-AtlasInstallOptionSet @optionCheck
            $mode = Resolve-AtlasInstallMode -TargetVersion $targetVersion

            $null = Start-AtlasInstallState -TargetVersion $targetVersion -Mode $mode `
                -CaptureNonce ([guid]::NewGuid().ToString('D'))
            Set-AtlasInstallOptions -Options $options | Out-Null
            $message = "Atlas install state ready for $mode of $targetVersion with options: $($options -join ', ')."
            Write-AtlasSessionLog $message
            Write-Output $message
        }
        'Run' {
            $captureScript = Join-Path -Path $scriptsRoot -ChildPath 'Entry\Initialize-AtlasInstallState.ps1'
            & $captureScript -Operation Commit
            $installScript = Join-Path -Path $scriptsRoot -ChildPath 'Entry\Invoke-AtlasInstall.ps1'
            & $installScript -Run *>&1 | ForEach-Object {
                Write-AtlasSessionLog ([string]$_)
                Write-Output $_
            }
            Write-AtlasSessionLog "Install plan exited with code $LASTEXITCODE."
            exit $LASTEXITCODE
        }
    }
    exit 0
}
catch {
    $failure = $_
    $exitCode = if ($failure.Exception.Message -like '[[]privilege[]]*') { 2 } else { 1 }
    try {
        Write-AtlasSessionLog "ERROR: $($failure.Exception.ToString())`r`n$($failure.InvocationInfo.PositionMessage)`r`n$($failure.ScriptStackTrace)"
    }
    catch { [Console]::Error.WriteLine("Could not persist install failure: $($_.Exception.Message)") }
    [Console]::Error.WriteLine($failure.Exception.Message)
    exit $exitCode
}
