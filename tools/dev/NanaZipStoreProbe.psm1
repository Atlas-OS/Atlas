# Developer-only experiment. Not imported by the playbook.
Set-StrictMode -Version 3.0

function Get-NanaZipStoreDecision {
    param([bool]$InstallStarted, [string]$Status, [bool]$Provisioned)
    if (-not $InstallStarted) { return 'DownloadFallbackAllowed' }
    if ($Status -eq 'Ok' -and $Provisioned) { return 'Installed' }
    # Even a failed/cancelled COM call can have changed package state.
    return 'InspectBeforeRetry'
}

function Get-NanaZipProvisioned {
    @(Get-AppxProvisionedPackage -Online -ErrorAction Stop | Where-Object {
        $_.DisplayName -ceq '40174MouriNaruto.NanaZip'
    } | Select-Object DisplayName, PackageName, Version)
}

function Get-NanaZipProbeContext {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    @{ IsSystem = $identity.IsSystem; Elevated = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }
}

function Save-ProbeReport {
    param($Report, [string]$Path)
    $Report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath "$Path.tmp" -Encoding UTF8
    Move-Item -LiteralPath "$Path.tmp" -Destination $Path -Force
}

function Invoke-NanaZipStoreProbe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ClientManifest,
        [Parameter(Mandatory)][string]$ReportPath,
        [switch]$Install
    )
    $ErrorActionPreference = 'Stop'
    $context = Get-NanaZipProbeContext
    $report = [ordered]@{
        StartedUtc = [DateTime]::UtcNow.ToString('o')
        WindowsVersion = [Environment]::OSVersion.Version.ToString()
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        IsSystem = $context.IsSystem
        Elevated = $context.Elevated
        ProductId = '9N8G7TSCL18R'
        Scope = 'System'
        Phase = 'Preflight'
        InstallStarted = $false
        Decision = 'DownloadFallbackAllowed'
        Package = $null
        Before = @()
        After = @()
        Result = $null
        Error = $null
    }
    # A durable checkpoint precedes the mutating COM call. A killed worker must
    # never leave a report claiming that it is safe to start a fallback install.
    Save-ProbeReport -Report $report -Path $ReportPath
    try {
        if ($Install -and -not $report.Elevated) { throw 'Machine-scope installation requires elevation.' }
        $manifest = Test-ModuleManifest -Path $ClientManifest
        if ($manifest.Name -ne 'Microsoft.WinGet.Client' -or $manifest.Version -ne [version]'1.29.280') {
            throw 'Use the pinned Microsoft.WinGet.Client 1.29.280 module for this experiment.'
        }
        Import-Module $ClientManifest -ErrorAction Stop
        if ($report.Elevated) { $report.Before = @(Get-NanaZipProvisioned) }
        $report.Phase = 'StoreLookup'
        Save-ProbeReport -Report $report -Path $ReportPath
        $packages = @(Find-WinGetPackage -Id $report.ProductId -Source msstore -MatchOption Equals -ErrorAction Stop)
        if ($packages.Count -ne 1 -or $packages[0].Id -cne $report.ProductId -or $packages[0].Source -ne 'msstore') {
            throw 'The Store did not return exactly the requested NanaZip product.'
        }
        $report.Package = $packages[0] | Select-Object Id, Name, Source, Version
        if (-not $Install) {
            $report.Phase = 'LookupSucceeded'
            $report.Decision = 'ProbeOnly'
        }
        elseif ($report.Before.Count -gt 0) {
            $report.Phase = 'AlreadyProvisioned'
            $report.Decision = 'AlreadyProvisioned'
        }
        else {
            $report.Phase = 'Installing'
            $report.InstallStarted = $true
            $report.Decision = 'InspectBeforeRetry'
            Save-ProbeReport -Report $report -Path $ReportPath
            $result = Install-WinGetPackage -PSCatalogPackage $packages[0] -Scope System -Mode Silent -ErrorAction Stop
            $report.Result = $result | Select-Object Status, InstallerErrorCode, RebootRequired, CorrelationData,
                @{ Name = 'ExtendedHResult'; Expression = { if ($_.ExtendedErrorCode) { $_.ExtendedErrorCode.HResult } } }
            $report.Phase = 'VerifyingProvisioning'
            Save-ProbeReport -Report $report -Path $ReportPath
            $report.After = @(Get-NanaZipProvisioned)
            $report.Decision = Get-NanaZipStoreDecision -InstallStarted $true -Status $result.Status -Provisioned ($report.After.Count -gt 0)
            if ($report.Decision -ne 'Installed') { throw 'Store installation did not establish successful machine provisioning. Inspect the result before retrying.' }
            $report.Phase = 'Complete'
        }
    }
    catch {
        $report.Error = [ordered]@{ Message = $_.Exception.Message; HResult = $_.Exception.HResult; ErrorId = $_.FullyQualifiedErrorId }
        $report.Decision = Get-NanaZipStoreDecision -InstallStarted $report.InstallStarted -Status 'Failed' -Provisioned $false
    }
    finally { Save-ProbeReport -Report $report -Path $ReportPath }
    [pscustomobject]$report
}

Export-ModuleMember -Function Invoke-NanaZipStoreProbe, Get-NanaZipStoreDecision
