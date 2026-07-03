# Atlas.Software domain: CBS package (CAB) install/uninstall.
#
# GPL-3.0-only license
# Ported from Executables\AtlasModules\Scripts\Install-AtlasPackage.ps1, itself modified
# from https://github.com/he3als/online-sxs
#
# Install-AtlasPackage.ps1 remains as the interactive shell (Safe Mode boot orchestration,
# prompts, the failed-component message box) around these functions; install phases
# call them directly with -NonInteractive semantics.

function Get-AtlasCbsArchitecture {
    $arm = ((Get-CimInstance -Class Win32_ComputerSystem).SystemType -match 'ARM64') -or ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
    if ($arm) { return 'arm64' } else { return 'amd64' }
}

function Initialize-AtlasCbsEnvironment {
    # DISM/servicing can misbehave under TrustedInstaller with a minimal PATH.
    $windir = [Environment]::GetFolderPath('Windows')
    $sys32 = [Environment]::GetFolderPath('System')
    $env:Path = "$windir;$sys32;$sys32\Wbem;$sys32\WindowsPowerShell\v1.0;" + $env:Path
}

function Get-AtlasCbsSafeModeListPath {
    return Join-Path -Path ([Environment]::GetFolderPath('System')) -ChildPath 'safeModePackagesToInstall.atlasmodule'
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

    $cert = (Get-AuthenticodeSignature -FilePath $CabPath).SignerCertificate
    if ($null -eq $cert) {
        throw 'No signer certificate was found.'
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

function Install-AtlasCbsCab {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CabPath
    )

    $fileName = Split-Path -Path $CabPath -Leaf
    Write-Host "`nInstalling $fileName..." -ForegroundColor Cyan
    Write-Host ('-' * 84) -ForegroundColor Magenta

    Write-Host '[INFO] Checking certificate...'
    try {
        Assert-AtlasCbsCertificate -CabPath $CabPath
    }
    catch {
        Write-Host "[ERROR] Cert error from '$CabPath': $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    Write-Host '[INFO] Adding package...'
    try {
        Add-WindowsPackage -Online -PackagePath $CabPath -NoRestart -IgnoreCheck -LogLevel 1 *>$null
    }
    catch {
        Write-Host "[ERROR] Error when adding package '$CabPath': $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    Write-Host '[INFO] Completed successfully.'
    return $true
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
        Non-interactive failure fallback: records the failed CAB paths for a Safe Mode
        retry and registers a logon task that shows the failed-component message box
        (Install-AtlasPackage.ps1 -FailMessage).
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$FailedPackages
    )

    Write-Host 'Setting error message box next boot as NoInteraction is enabled.'
    Set-Content -Path (Get-AtlasCbsSafeModeListPath) -Value $FailedPackages

    $scriptPath = Join-Path -Path (Get-AtlasContext).AtlasModulesPath -ChildPath 'Scripts\Install-AtlasPackage.ps1'
    $failedMsgTitle = 'AtlasFailedComponentMsgBox'
    $failedMsgArgs = "/c title Finalizing Installation - Atlas & echo Do not close this window. & schtasks /delete /tn `"$failedMsgTitle`" /f > nul & " `
        + "PowerShell -NoP -NonI -W Hidden -EP RemoteSigned -C `"& '$scriptPath' -FailMessage`""
    $failedMsg = @{
        'TaskName' = $failedMsgTitle
        'Settings' = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        'Trigger'  = New-ScheduledTaskTrigger -AtLogOn
        'User'     = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        'Force'    = $true
        'RunLevel' = 'Highest'
        'Action'   = New-ScheduledTaskAction -Execute 'cmd' -Argument $failedMsgArgs
    }
    Register-ScheduledTask @failedMsg | Out-Null
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
        On failure, register the Safe Mode retry fallback and throw (so the Components
        phase exits non-zero and AME Wizard halts) instead of returning the failures
        for an interactive prompt.
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
    foreach ($cabPath in $packagesToProcess) {
        if (Install-AtlasCbsCab -CabPath $cabPath) {
            $successPackages += $cabPath
        }
        else {
            $failedPackages += $cabPath
        }
    }

    if ($successPackages.Count -ne 0) {
        New-AtlasCbsRepairSource | Out-Null
    }

    if (($failedPackages.Count -gt 0) -and $NonInteractive) {
        Register-AtlasCbsFailureFallback -FailedPackages $failedPackages
        throw "These CBS packages failed to install: $($failedPackages -join ', ')"
    }

    return [pscustomobject]@{
        SuccessPackages   = $successPackages
        FailedPackages    = $failedPackages
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
