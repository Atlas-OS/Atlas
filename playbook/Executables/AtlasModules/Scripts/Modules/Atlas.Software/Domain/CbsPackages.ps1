# Atlas.Software domain: CBS package (CAB) install/uninstall.
#
# GPL-3.0-only license
# Modified from https://github.com/he3als/online-sxs
#
# Install-AtlasPackage.ps1 is the optional interactive shell around these functions;
# install phases call them directly with -NonInteractive semantics.

$cbsRetryHelper = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\Internal\CbsRetry.ps1'
if (-not [IO.File]::Exists($cbsRetryHelper) -or
    (([IO.File]::GetAttributes($cbsRetryHelper) -band
            [IO.FileAttributes]::ReparsePoint) -ne 0)) {
    throw "Required CBS retry helper '$cbsRetryHelper' is missing or a reparse point."
}
. $cbsRetryHelper -LibraryOnly

function Get-AtlasCbsArchitecture {
    # Installers.ps1 supplies the module-wide, fail-closed native architecture
    # authority. CBS package selection must never fall back to inherited process
    # environment data or a substring match because choosing the wrong CAB is a
    # privileged servicing error, not a best-effort installer outcome.
    if (Test-AtlasSoftwareArm64) { return 'arm64' }
    return 'amd64'
}

function Initialize-AtlasCbsEnvironment {
    # DISM/servicing can misbehave under TrustedInstaller with a minimal PATH.
    $windir = [Environment]::GetFolderPath('Windows')
    $sys32 = [Environment]::GetFolderPath('System')
    $env:Path = "$windir;$sys32;$sys32\Wbem;$sys32\WindowsPowerShell\v1.0;" + $env:Path
}

function Select-AtlasCbsPackage {
    <#
    .SYNOPSIS
        Matches candidate package names/paths against wildcard patterns, keeping only
        candidates for the current architecture (pure matching helper, kept separate
        for testability).
    .PARAMETER SingleUsePatterns
        When set (CAB install matching), each pattern is consumed by its first match.
        When not set (uninstall matching), one pattern may match multiple candidates.
    #>
    param(
        [AllowEmptyCollection()]
        [string[]]$Candidates = @(),

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Patterns,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Architecture,

        [switch]$SingleUsePatterns
    )

    $matched = @()
    $remainingPatterns = @($Patterns)

    foreach ($candidate in $Candidates) {
        $patternPool = if ($SingleUsePatterns) { $remainingPatterns } else { $Patterns }
        foreach ($pattern in $patternPool) {
            if (($candidate -like $pattern) -and ($candidate -match $Architecture)) {
                $matched += $candidate
                $remainingPatterns = @($remainingPatterns -ne $pattern)
                break
            }
        }
    }

    return [pscustomobject]@{
        Matched           = $matched
        UnmatchedPatterns = $remainingPatterns
    }
}

function Assert-AtlasCbsCertificate {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CabPath
    )

    $signature = Get-AuthenticodeSignature -LiteralPath $CabPath
    $cert = $signature.SignerCertificate
    # Intact Atlas component CABs report UnknownError through this cmdlet while
    # still exposing their Microsoft Windows signer and component EKU. The pinned
    # manifest SHA-256 above is authoritative; reject explicit signature hash
    # mismatch without excluding that legitimate CAB status.
    if ($signature.Status -eq [System.Management.Automation.SignatureStatus]::HashMismatch -or $null -eq $cert) {
        throw "The CAB component signature is not intact (status '$($signature.Status)')."
    }
    $subject = [string]$cert.Subject
    if ($subject -notmatch '(?:^|,\s*)CN=Microsoft Windows(?:,|$)' -or
        $subject -notmatch '(?:^|,\s*)O=Microsoft Corporation(?:,|$)') {
        throw 'The CAB is not signed by the Microsoft Windows component publisher.'
    }

    $ekuValues = @(
        $cert.Extensions |
            Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension] } |
            ForEach-Object { $_.EnhancedKeyUsages | ForEach-Object { $_.Value } }
    )

    if ($ekuValues -notcontains '1.3.6.1.4.1.311.10.3.6') {
        throw "Cert doesn't have proper key usages, can't continue."
    }

    # Add the Atlas test cert. It isn't cleared later, as it's required for the
    # alternative repair source.
    $certRegPath = 'HKLM:\Software\Microsoft\SystemCertificates\ROOT\Certificates\8A334AA8052DD244A647306A76B8178FA215F344'
    if (-not (Test-Path -LiteralPath $certRegPath)) {
        New-Item -Path $certRegPath -Force | Out-Null
    }
}

$script:AtlasCbsExpectedHashes = $null

function Get-AtlasCbsExpectedHashes {
    <#
    .SYNOPSIS
        Loads Atlas-CbsHashes.psd1 (the SHA256 of every shipped CAB) from the packages
        folder. The CAB signing cert is regenerated on every build, so its thumbprint is
        not stable and cannot be pinned - the content hash is what we verify against.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PackagesPath
    )

    if ($null -ne $script:AtlasCbsExpectedHashes) {
        return $script:AtlasCbsExpectedHashes
    }

    $hashFile = Join-Path -Path $PackagesPath -ChildPath 'Atlas-CbsHashes.psd1'
    if (-not (Test-Path -LiteralPath $hashFile -PathType Leaf)) {
        throw "The CBS package hash manifest '$hashFile' is missing; refusing to install unverified packages."
    }

    # Parse via the AST (SafeGetValue) so loading never depends on a possibly-polluted
    # PSModulePath under TrustedInstaller (see docs/testing.md).
    $tableAst = [System.Management.Automation.Language.Parser]::ParseFile($hashFile, [ref]$null, [ref]$null).Find(
        { param($node) $node -is [System.Management.Automation.Language.HashtableAst] }, $false)
    if ($null -eq $tableAst) {
        throw "The CBS package hash manifest '$hashFile' is not a valid data file."
    }

    $script:AtlasCbsExpectedHashes = $tableAst.SafeGetValue()
    return $script:AtlasCbsExpectedHashes
}

function Assert-AtlasCbsHash {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CabPath
    )

    $fileName = Split-Path -Path $CabPath -Leaf
    $expected = Get-AtlasCbsExpectedHashes -PackagesPath (Split-Path -Path $CabPath -Parent)
    if (-not $expected.ContainsKey($fileName)) {
        throw "No expected SHA256 is recorded for '$fileName' in the CBS hash manifest; refusing to install an unlisted package."
    }

    $actual = (Get-FileHash -LiteralPath $CabPath -Algorithm SHA256).Hash
    if ($actual -ne $expected[$fileName]) {
        throw "SHA256 mismatch for '$fileName' (got '$actual'); the package may have been modified. Refusing to install it."
    }
    return ([string]$expected[$fileName]).ToUpperInvariant()
}

function Install-AtlasCbsCab {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CabPath
    )

    $fileName = Split-Path -Path $CabPath -Leaf
    Write-Host "`nInstalling $fileName..." -ForegroundColor Cyan
    Write-Host ('-' * 84) -ForegroundColor Magenta

    Write-Host '[INFO] Verifying package hash...'
    $expectedSha256 = $null
    try {
        $expectedSha256 = Assert-AtlasCbsHash -CabPath $CabPath
    }
    catch {
        Write-Host "[ERROR] Hash verification failed for '$CabPath': $($_.Exception.Message)" -ForegroundColor Red
        return [pscustomobject]@{
            Path = $CabPath; Success = $false; RetryEligible = $false; Sha256 = $null; FailureKind = 'Integrity'
        }
    }

    Write-Host '[INFO] Checking certificate...'
    try {
        Assert-AtlasCbsCertificate -CabPath $CabPath
    }
    catch {
        Write-Host "[ERROR] Cert error from '$CabPath': $($_.Exception.Message)" -ForegroundColor Red
        return [pscustomobject]@{
            Path = $CabPath; Success = $false; RetryEligible = $false; Sha256 = $expectedSha256; FailureKind = 'Signature'
        }
    }

    Write-Host '[INFO] Adding package...'
    try {
        Add-WindowsPackage -Online -PackagePath $CabPath -NoRestart -IgnoreCheck -LogLevel 1 *>$null
    }
    catch {
        Write-Host "[ERROR] Error when adding package '$CabPath': $($_.Exception.Message)" -ForegroundColor Red
        return [pscustomobject]@{
            Path = $CabPath; Success = $false; RetryEligible = $true; Sha256 = $expectedSha256; FailureKind = 'Servicing'
        }
    }

    Write-Host '[INFO] Completed successfully.'
    return [pscustomobject]@{
        Path = $CabPath; Success = $true; RetryEligible = $false; Sha256 = $expectedSha256; FailureKind = $null
    }
}

function New-AtlasCbsRepairSource {
    <#
    .SYNOPSIS
        Hardlinks the Atlas package manifests into a local repair source and registers
        it, fixing the RestoreHealth/SFC 'Sources' error.
        https://learn.microsoft.com/windows-hardware/manufacture/desktop/configure-a-windows-repair-source
        https://github.com/Atlas-OS/Atlas/issues/1103
    #>
    $windir = [Environment]::GetFolderPath('Windows')
    $version = '38655.38527.65535.65535'
    $srcPath = '%SystemRoot%\AtlasModules\Packages\WinSxS'
    $srcPathExpanded = [System.Environment]::ExpandEnvironmentVariables($srcPath)

    Write-Host "`nMaking repair source..." -ForegroundColor Cyan
    Write-Host ('-' * 84) -ForegroundColor Magenta

    # Get the list of Atlas manifests
    Write-Host '[INFO] Getting manifests...'
    $manifests = @(Get-ChildItem -Path "$windir\WinSxS\Manifests" -File -Filter "*$version*")
    if ($manifests.Count -eq 0) {
        Write-Host "[WARN] No manifests found! Can't create repair source." -ForegroundColor Yellow
        return $false
    }

    # Create a new repair source folder
    if (Test-Path -LiteralPath $srcPathExpanded -PathType Container) {
        Write-Host '[INFO] Deleting old RepairSrc...'
        Remove-Item -LiteralPath $srcPathExpanded -Force -Recurse
    }
    Write-Host '[INFO] Creating RepairSrc path...'
    New-Item -Path "$srcPathExpanded\Manifests" -Force -ItemType Directory | Out-Null

    # Hardlink all the manifests to the repair source
    Write-Host '[INFO] Hard linking manifests...'
    foreach ($manifest in $manifests) {
        New-Item -ItemType HardLink -Path "$srcPathExpanded\Manifests\$($manifest.Name)" -Target $manifest.FullName | Out-Null
    }

    # Register the repair source policy
    $servicingPolicyKey = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Servicing'
    if (-not (Test-Path -LiteralPath $servicingPolicyKey)) {
        New-Item -Path $servicingPolicyKey -Force | Out-Null
    }
    Set-ItemProperty -Path $servicingPolicyKey -Name 'LocalSourcePath' -Value $srcPath -Type ExpandString -Force
    return $true
}

function Register-AtlasCbsFailureFallback {
    <#
    .SYNOPSIS
        Arms the compact Safe Mode retry for integrity-checked CAB failures.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object[]]$RetryPackages
    )

    $packagePaths = @($RetryPackages | ForEach-Object {
        if ($null -eq $_.PSObject.Properties['Path']) {
            throw 'A CBS retry package did not provide its verified path.'
        }
        [string]$_.Path
    })
    Write-Host 'Arming the failed CBS packages for a Safe Mode retry.'
    [void](Enable-AtlasCbsRetry -Packages $packagePaths)
    Write-Host 'After Safe Mode starts, run CbsRetry.ps1 -Recover from the command prompt.'
}

function Install-AtlasCbsPackage {
    <#
    .SYNOPSIS
        Installs Atlas CBS packages (CABs) online. Patterns (e.g.
        '*Z-Atlas-NoDefender-Package*') are matched against the CABs shipped in
        AtlasModules\Packages, filtered by architecture. Must run as
        SYSTEM/TrustedInstaller.
    .PARAMETER LiteralPaths
        Treat -Packages as literal CAB paths instead of patterns (used by the Safe Mode
        retry and the file-picker flow of Install-AtlasPackage.ps1).
    .PARAMETER NonInteractive
        On failure, register the Safe Mode retry fallback and throw so the ordered
        Components step fails and the orchestrator returns a single nonzero status,
        instead of returning the failures for an interactive prompt.
    .OUTPUTS
        PSCustomObject with SuccessPackages, FailedPackages and UnmatchedPatterns.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Packages,

        [ValidateNotNullOrEmpty()]
        [string]$PackagesPath = (Join-Path -Path (Get-AtlasContext).AtlasModulesPath -ChildPath 'Packages'),

        [switch]$LiteralPaths,

        [switch]$NonInteractive
    )

    Assert-AtlasPrivilege -TrustedInstaller
    Initialize-AtlasCbsEnvironment

    $unmatchedPatterns = @()
    if ($LiteralPaths) {
        $packagesToProcess = @($Packages)
    }
    else {
        $architecture = Get-AtlasCbsArchitecture
        $candidates = @(Get-ChildItem -Path $PackagesPath -File -Filter '*.cab' -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty FullName | Sort-Object -Descending)
        $selection = Select-AtlasCbsPackage -Candidates $candidates -Patterns $Packages -Architecture $architecture -SingleUsePatterns

        if (@($selection.Matched).Count -eq 0) {
            throw "The specified CABs ($Packages) to install weren't found."
        }
        if (@($selection.UnmatchedPatterns).Count -gt 0) {
            Write-Host "[WARN] These CABs to install weren't found: $($selection.UnmatchedPatterns)" -ForegroundColor Yellow
        }

        $packagesToProcess = @($selection.Matched)
        $unmatchedPatterns = @($selection.UnmatchedPatterns)
    }

    $successPackages = @()
    $failedPackages = @()
    $retryPackages = @()
    foreach ($cabPath in $packagesToProcess) {
        $cabResult = Install-AtlasCbsCab -CabPath $cabPath
        if ($cabResult.Success) {
            $successPackages += $cabPath
        }
        else {
            $failedPackages += $cabPath
            if ($cabResult.RetryEligible) {
                $retryPackages += [pscustomobject]@{
                    Path = [IO.Path]::GetFullPath([string]$cabResult.Path)
                    Sha256 = [string]$cabResult.Sha256
                }
            }
        }
    }

    if ($successPackages.Count -ne 0) {
        New-AtlasCbsRepairSource | Out-Null
    }

    if (($failedPackages.Count -gt 0) -and $NonInteractive) {
        if ($retryPackages.Count -gt 0) {
            Register-AtlasCbsFailureFallback -RetryPackages $retryPackages
        }
        throw "These CBS packages failed to install: $($failedPackages -join ', ')"
    }

    return [pscustomobject]@{
        SuccessPackages   = $successPackages
        FailedPackages    = $failedPackages
        RetryPackages     = $retryPackages
        UnmatchedPatterns = $unmatchedPatterns
    }
}

function Uninstall-AtlasCbsPackage {
    <#
    .SYNOPSIS
        Uninstalls installed Windows packages matching the given wildcard patterns,
        filtered by architecture. Failures are logged as warnings; must run as
        SYSTEM/TrustedInstaller.
    .OUTPUTS
        PSCustomObject with RemovedPackages, FailedPackages and UnmatchedPatterns.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Packages
    )

    Assert-AtlasPrivilege -TrustedInstaller
    Initialize-AtlasCbsEnvironment

    $architecture = Get-AtlasCbsArchitecture
    $candidates = @((Get-WindowsPackage -Online).PackageName)
    $selection = Select-AtlasCbsPackage -Candidates $candidates -Patterns $Packages -Architecture $architecture

    $removedPackages = @()
    $failedPackages = @()
    if (@($selection.Matched).Count -eq 0) {
        Write-Host "[WARN] '$Packages' matched no installed packages, nothing to do." -ForegroundColor Yellow
    }
    else {
        if (@($selection.UnmatchedPatterns).Count -gt 0) {
            Write-Host "[WARN] Some packages not found to uninstall: $($selection.UnmatchedPatterns)" -ForegroundColor Yellow
        }

        foreach ($package in $selection.Matched) {
            try {
                Write-Host "[INFO] Uninstalling '$package'..."
                Remove-WindowsPackage -Online -PackageName $package -NoRestart -LogLevel 1 *>$null
                $removedPackages += $package
            }
            catch {
                Write-Host "[ERROR] $package failed to uninstall: $($_.Exception.Message)" -ForegroundColor Red
                $failedPackages += $package
            }
        }
    }

    return [pscustomobject]@{
        RemovedPackages   = $removedPackages
        FailedPackages    = $failedPackages
        UnmatchedPatterns = @($selection.UnmatchedPatterns)
    }
}
