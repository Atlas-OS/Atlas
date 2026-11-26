# Atlas.Software domain: CBS package (CAB) install/uninstall.
#
# Adapted from online-sxs by he3als (GPL-3.0-only).
#
# Install-AtlasPackage.ps1 is the optional interactive shell around these functions;
# install phases call them directly with -NonInteractive semantics.

$cbsRetryHelper = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\Operations\CbsRetry.ps1'
if (-not [IO.File]::Exists($cbsRetryHelper) -or
    (([IO.File]::GetAttributes($cbsRetryHelper) -band
            [IO.FileAttributes]::ReparsePoint) -ne 0)) {
    throw "Required CBS retry helper '$cbsRetryHelper' is missing or a reparse point."
}
. $cbsRetryHelper -LibraryOnly

function Get-AtlasCbsArchitecture {
    <#
    .SYNOPSIS
        Returns the CBS architecture name of the PC: 'arm64' or 'amd64'.
    .DESCRIPTION
        A wrong-architecture CAB breaks servicing, so this uses the strict CIM check
        from Installers.ps1, never PROCESSOR_ARCHITECTURE.
    #>
    if (Test-AtlasSoftwareArm64) { return 'arm64' }
    return 'amd64'
}

function Initialize-AtlasCbsEnvironment {
    <#
    .SYNOPSIS
        Puts the Windows system folders at the front of PATH, because DISM and
        servicing can misbehave under TrustedInstaller with a minimal PATH.
    #>
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
    # Intact Atlas CABs can report UnknownError here. Assert-AtlasCbsHash has already
    # checked the pinned SHA-256, so reject only HashMismatch.
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

    $windowsComponentEku = '1.3.6.1.4.1.311.10.3.6' # Windows System Component Verification
    if ($ekuValues -notcontains $windowsComponentEku) {
        throw 'The CAB signer lacks the Windows component EKU.'
    }

    # Add the Atlas test cert. It isn't cleared later, as it's required for the
    # alternative repair source.
    $certRegPath = "HKLM:\$script:AtlasCbsTestRootKey"
    if (-not (Test-Path -LiteralPath $certRegPath)) {
        New-Item -Path $certRegPath -Force | Out-Null
    }
}

# The test root servicing needs to accept the Atlas CABs (see Assert-AtlasCbsCertificate).
$script:AtlasCbsTestRootKey = 'SOFTWARE\Microsoft\SystemCertificates\ROOT\Certificates\8A334AA8052DD244A647306A76B8178FA215F344'

function Get-AtlasCbsTestRootState {
    <#
    .SYNOPSIS
        Describes the test root key servicing reads to accept the Atlas CABs: whether it
        exists and which values it holds. Reads only.
    #>
    param(
        # Tests point this at a scratch key.
        [ValidateNotNull()]
        [Microsoft.Win32.RegistryKey]$BaseKey = [Microsoft.Win32.Registry]::LocalMachine
    )

    try {
        $key = $BaseKey.OpenSubKey($script:AtlasCbsTestRootKey, $false)
    }
    catch {
        return "unreadable ($($_.Exception.Message))"
    }
    if ($null -eq $key) {
        return 'missing'
    }
    try {
        $names = @($key.GetValueNames() | ForEach-Object { if ($_) { $_ } else { '(default)' } })
        if ($names.Count -eq 0) {
            return 'present, with no values'
        }
        return "present, with values $($names -join ', ')"
    }
    finally {
        $key.Dispose()
    }
}

function Get-AtlasCbsLogTail {
    <#
    .SYNOPSIS
        The lines at the end of CBS.log that say what servicing refused: its errors and
        failures, or its last lines when it named none. Read without locking out
        Windows, which keeps the file open. Returns nothing when the log can't be read.
    #>
    param(
        [string]$Path = [IO.Path]::Combine([Environment]::GetFolderPath('Windows'), 'Logs\CBS\CBS.log'),
        [int64]$Bytes = 1MB,
        [int]$MaximumLines = 60
    )

    try {
        if (-not [IO.File]::Exists($Path)) { return @() }
        $stream = [IO.FileStream]::new($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]'ReadWrite, Delete')
        try {
            [void]$stream.Seek([Math]::Max(0, $stream.Length - $Bytes), [IO.SeekOrigin]::Begin)
            $text = [IO.StreamReader]::new($stream, [Text.Encoding]::UTF8).ReadToEnd()
        }
        finally { $stream.Dispose() }
    }
    catch {
        return @()
    }
    $lines = @($text -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    # A failed package change can start an automatic store check, which fills the end
    # of the log with lines that say nothing about the failure.
    $errors = @($lines | Where-Object { $_ -match ',\s+Error\s|HRESULT|\bFailed\b' })
    $selected = if ($errors.Count -gt 0) { $errors } else { $lines }
    return @($selected | Select-Object -Last $MaximumLines)
}

function Write-AtlasCbsLogTail {
    <#
    .SYNOPSIS
        Copies the end of CBS.log into the install log after servicing refused a package,
        so the diagnostics say why.
    #>
    $lines = @(Get-AtlasCbsLogTail)
    if ($lines.Count -eq 0) {
        Write-AtlasLog -Message 'CBS.log could not be read for the servicing failure.'
        return
    }
    Write-AtlasLog -Message "The end of CBS.log after the servicing failure ($($lines.Count) line(s)):"
    foreach ($line in $lines) {
        Write-AtlasLog -Message "CBS.log: $($line.Trim())"
    }
}

function Get-AtlasCbsFailureHResult {
    <#
    .SYNOPSIS
        The servicing HRESULT of a failed DISM cmdlet, or 0. The DISM cmdlets throw a
        COMException that carries it. Their message is localised, so it's searched only
        for the 0x code it ends with.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    for ($cause = $ErrorRecord.Exception; $null -ne $cause; $cause = $cause.InnerException) {
        if ($cause -is [Runtime.InteropServices.COMException] -and $cause.HResult -ne 0) {
            return [int]$cause.HResult
        }
    }
    $code = [regex]::Match([string]$ErrorRecord.Exception.Message, '0x[0-9A-Fa-f]{8}\b')
    if ($code.Success) {
        return [Convert]::ToInt32($code.Value.Substring(2), 16)
    }
    return 0
}

function Format-AtlasCbsHResult {
    param([int]$HResult)
    return '0x{0:X8}' -f $HResult
}

# CBS_E_CANNOT_UNINSTALL: servicing refuses to remove a package it keeps permanently.
# The message that comes with it is localised, so only the code is matched.
$script:AtlasCbsCannotUninstall = -2146498523 # 0x800F0825

function Test-AtlasCbsTrustFailure {
    <#
    .SYNOPSIS
        Whether servicing refused a package's signature or the certificate chain it needs.
    .DESCRIPTION
        Windows decides these from the package's signature and this PC's certificate
        stores and trust settings, which starting in Safe Mode doesn't change, so a Safe
        Mode retry fails the same way:
        - 0x80092004 (CRYPT_E_NOT_FOUND): servicing couldn't find the certificate or
          signature it looked for.
        - 0x800B0100 to 0x800B01FF: the WinVerifyTrust certificate and signature results,
          such as TRUST_E_NOSIGNATURE, CERT_E_EXPIRED, CERT_E_UNTRUSTEDROOT and
          TRUST_E_EXPLICIT_DISTRUST.
        - 0x800B0004 (TRUST_E_SUBJECT_NOT_TRUSTED), 0x80096004 (TRUST_E_CERT_SIGNATURE)
          and 0x80096010 (TRUST_E_BAD_DIGEST): the signature or its certificate doesn't
          verify.
    #>
    param([int]$HResult)

    $code = [int64]$HResult -band 0xFFFFFFFFL
    if ($code -eq 0x80092004L -or ($code -band 0xFFFFFF00L) -eq 0x800B0100L) {
        return $true
    }
    return $code -in @(0x800B0004L, 0x80096004L, 0x80096010L)
}

function Get-AtlasCbsTrustFailureInstruction {
    <#
    .SYNOPSIS
        What to tell the user when servicing refused the signature of Atlas packages.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object[]]$Failure
    )

    $named = @($Failure | ForEach-Object {
        "$(Split-Path -Path ([string]$_.Path) -Leaf) ($(Format-AtlasCbsHResult -HResult ([int]$_.HResult)))"
    }) -join ', '
    return "Windows didn't accept the signature of $named. Starting in Safe Mode doesn't change that, so Atlas doesn't retry there. Check that the PC's date and time are right and that no security software blocks certificates, run 'DISM /Online /Cleanup-Image /RestoreHealth' as an administrator, restart Windows, then try installing Atlas again. If it fails the same way, repair-install Windows. The install log has the end of CBS.log."
}

$script:AtlasCbsExpectedHashes = $null

function Get-AtlasCbsExpectedHashes {
    <#
    .SYNOPSIS
        Loads Atlas-CbsHashes.psd1 (the SHA-256 of every included CAB) from the packages
        folder. The CAB signing cert is regenerated on every build, so its thumbprint is
        not stable and cannot be pinned; the content hash is what we verify against.
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

    $script:AtlasCbsExpectedHashes = Import-AtlasDataFile -LiteralPath $hashFile
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
    Write-AtlasLog -Message "Adding $fileName; the test root key servicing reads is $(Get-AtlasCbsTestRootState)."
    # -LogLevel 1 writes only errors to the DISM log.
    try {
        Add-WindowsPackage -Online -PackagePath $CabPath -NoRestart -IgnoreCheck -LogLevel 1 *>$null
    }
    catch {
        Write-Host "[ERROR] Error when adding package '$CabPath': $($_.Exception.Message)" -ForegroundColor Red
        $hresult = Get-AtlasCbsFailureHResult -ErrorRecord $_
        Write-AtlasLog -Level Warning -Message "Servicing refused $fileName with $(Format-AtlasCbsHResult -HResult $hresult): $($_.Exception.Message)"
        Write-AtlasCbsLogTail
        if (Test-AtlasCbsTrustFailure -HResult $hresult) {
            return [pscustomobject]@{
                Path = $CabPath; Success = $false; RetryEligible = $false; Sha256 = $expectedSha256
                FailureKind = 'Trust'; HResult = $hresult
            }
        }
        return [pscustomobject]@{
            Path = $CabPath; Success = $false; RetryEligible = $true; Sha256 = $expectedSha256
            FailureKind = 'Servicing'; HResult = $hresult
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
    # The version every Atlas package manifest carries.
    $version = '38655.38527.65535.65535'
    $srcPath = '%SystemRoot%\AtlasModules\Packages\WinSxS'
    $srcPathExpanded = [System.Environment]::ExpandEnvironmentVariables($srcPath)

    Write-Host "`nMaking repair source..." -ForegroundColor Cyan
    Write-Host ('-' * 84) -ForegroundColor Magenta

    Write-Host '[INFO] Getting manifests...'
    $manifests = @(Get-ChildItem -Path "$windir\WinSxS\Manifests" -File -Filter "*$version*")
    if ($manifests.Count -eq 0) {
        Write-Host "[WARN] No manifests found! Can't create repair source." -ForegroundColor Yellow
        return $false
    }

    if (Test-Path -LiteralPath $srcPathExpanded -PathType Container) {
        Write-Host '[INFO] Deleting old RepairSrc...'
        Remove-Item -LiteralPath $srcPathExpanded -Force -Recurse
    }
    Write-Host '[INFO] Creating RepairSrc path...'
    New-Item -Path "$srcPathExpanded\Manifests" -Force -ItemType Directory | Out-Null

    Write-Host '[INFO] Hard linking manifests...'
    foreach ($manifest in $manifests) {
        New-Item -ItemType HardLink -Path "$srcPathExpanded\Manifests\$($manifest.Name)" -Target $manifest.FullName | Out-Null
    }

    $servicingPolicyKey = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Servicing'
    if (-not (Test-Path -LiteralPath $servicingPolicyKey)) {
        New-Item -Path $servicingPolicyKey -Force | Out-Null
    }
    Set-ItemProperty -Path $servicingPolicyKey -Name 'LocalSourcePath' -Value $srcPath -Type ExpandString -Force
    return $true
}

function Get-AtlasCbsRepairSourcePolicy {
    $value = Get-ItemProperty -LiteralPath 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Servicing' -Name 'LocalSourcePath' -ErrorAction SilentlyContinue
    if ($null -eq $value) { return $null }
    return [string]$value.LocalSourcePath
}

function Remove-AtlasCbsRepairSourcePolicy {
    Remove-ItemProperty -LiteralPath 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Servicing' -Name 'LocalSourcePath' -ErrorAction Stop
}

function Update-AtlasCbsRepairSource {
    <#
    .SYNOPSIS
        Keeps the repair source the Atlas packages need. An update replaces
        %windir%\AtlasModules, and the repair source in it, without installing the
        packages again: recreate it while they are installed, and never leave
        LocalSourcePath naming a folder that is gone. Returns what it did.
    #>
    param([AllowEmptyCollection()][string[]]$AtlasPackages = @())

    if ($AtlasPackages.Count -gt 0 -and (New-AtlasCbsRepairSource)) { return 'recreated' }
    # Reading the policy expands its %SystemRoot%, so both sides are compared expanded.
    $atlasSource = [Environment]::ExpandEnvironmentVariables('%SystemRoot%\AtlasModules\Packages\WinSxS')
    $policy = Get-AtlasCbsRepairSourcePolicy
    if ($null -eq $policy -or [Environment]::ExpandEnvironmentVariables($policy) -ne $atlasSource) { return 'unchanged' }
    if (Test-Path -LiteralPath $atlasSource -PathType Container) { return 'unchanged' }
    Remove-AtlasCbsRepairSourcePolicy
    return 'removed'
}

function Get-AtlasComponentCleanupBlocker {
    <#
    .SYNOPSIS
        Why the component store cleanup must not run now, or $null. With an Atlas
        package installed, the cleanup rebuilds the inbox component the package
        replaces from its oldest version and can't rebuild all of its files, which
        leaves the store reporting damage. Fresh installs run it before the Atlas
        packages are installed; once they are, it never runs.
    #>
    param(
        [bool]$IsUpgrade,
        [AllowEmptyCollection()][string[]]$AtlasPackages = @()
    )

    if ($AtlasPackages.Count -gt 0) { return "the Atlas servicing packages are installed ($($AtlasPackages -join ', '))" }
    if ($IsUpgrade) { return 'this updates an earlier Atlas install' }
    return $null
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
}

function Install-AtlasCbsPackage {
    <#
    .SYNOPSIS
        Installs Atlas CBS packages (CABs) online. Patterns (e.g.
        '*Z-Atlas-NoDefender-Package*') are matched against the CABs in
        AtlasModules\Packages, filtered by architecture. Must run as
        SYSTEM/TrustedInstaller.
    .PARAMETER LiteralPaths
        Treat -Packages as literal CAB paths instead of patterns (used by the Safe Mode
        retry and the file-picker flow of Install-AtlasPackage.ps1).
    .PARAMETER NonInteractive
        On failure, register the Safe Mode retry fallback and throw so the ordered
        Components step fails and the orchestrator returns a single nonzero status,
        instead of returning the failures for an interactive prompt. A package whose
        signature servicing refuses (Test-AtlasCbsTrustFailure) arms no retry: the
        failure says what to do instead.
    .OUTPUTS
        PSCustomObject with SuccessPackages, FailedPackages, RetryPackages,
        TrustFailures, TrustInstruction and UnmatchedPatterns.
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
    $trustFailures = @()
    foreach ($cabPath in $packagesToProcess) {
        $cabResult = Install-AtlasCbsCab -CabPath $cabPath
        if ($cabResult.Success) {
            $successPackages += $cabPath
        }
        else {
            $failedPackages += $cabPath
            if ([string]$cabResult.FailureKind -ceq 'Trust') {
                $trustFailures += [pscustomobject]@{ Path = [string]$cabResult.Path; HResult = [int]$cabResult.HResult }
            }
            elseif ($cabResult.RetryEligible) {
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

    $trustInstruction = $null
    if ($trustFailures.Count -gt 0) {
        $trustInstruction = Get-AtlasCbsTrustFailureInstruction -Failure $trustFailures
        Write-Host "[ERROR] $trustInstruction" -ForegroundColor Red
        # The install can't finish while one package is refused this way, so a Safe Mode
        # retry of the others would only send the user through Safe Mode for nothing.
        $retryPackages = @()
    }

    if (($failedPackages.Count -gt 0) -and $NonInteractive) {
        $failure = "These CBS packages failed to install: $($failedPackages -join ', ')."
        if ($null -ne $trustInstruction) {
            $failure += " $trustInstruction"
        }
        elseif ($retryPackages.Count -gt 0) {
            Register-AtlasCbsFailureFallback -RetryPackages $retryPackages
            # This failure ends the install, so it's where the user learns of the retry.
            $failure += " $(Get-AtlasCbsRetryInstruction)"
        }
        throw $failure
    }

    return [pscustomobject]@{
        SuccessPackages   = $successPackages
        FailedPackages    = $failedPackages
        RetryPackages     = $retryPackages
        TrustFailures     = $trustFailures
        TrustInstruction  = $trustInstruction
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
        PSCustomObject with RemovedPackages, FailedPackages, PermanentPackages (failed
        because servicing keeps them permanently, CBS_E_CANNOT_UNINSTALL) and
        UnmatchedPatterns.
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
    $permanentPackages = @()
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
                # Stop: the catch sees only terminating errors, and this module doesn't
                # inherit the caller's ErrorActionPreference.
                Remove-WindowsPackage -Online -PackageName $package -NoRestart -LogLevel 1 -ErrorAction Stop *>$null
                $removedPackages += $package
            }
            catch {
                Write-Host "[ERROR] $package failed to uninstall: $($_.Exception.Message)" -ForegroundColor Red
                $hresult = Get-AtlasCbsFailureHResult -ErrorRecord $_
                Write-AtlasLog -Level Warning -Message "Servicing refused to remove $package with $(Format-AtlasCbsHResult -HResult $hresult): $($_.Exception.Message)"
                Write-AtlasCbsLogTail
                $failedPackages += $package
                if ($hresult -eq $script:AtlasCbsCannotUninstall) {
                    $permanentPackages += $package
                }
            }
        }
    }

    return [pscustomobject]@{
        RemovedPackages   = $removedPackages
        FailedPackages    = $failedPackages
        PermanentPackages = $permanentPackages
        UnmatchedPatterns = @($selection.UnmatchedPatterns)
    }
}
