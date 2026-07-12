[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$downloadIntegrity = [IO.Path]::Combine($PSScriptRoot, 'Download-Integrity.ps1')
if (-not [IO.File]::Exists($downloadIntegrity)) {
    throw "The Atlas download-integrity helper is missing at '$downloadIntegrity'."
}
. $downloadIntegrity

$openShellVersion = '4.4.198'
$openShellSha256 = 'a4d2d4459de55b5e962ba2a14f7bb794170511649138173dfa72949837b48c3f'
$openShellBytes = 9924608
$openShellUri = "https://github.com/Open-Shell/Open-Shell-Menu/releases/download/v$openShellVersion/OpenShellSetup_4_4_198.exe"
$stagingDirectory = New-AtlasProtectedStagingDirectory
$cleanupStaging = $true

try {
    $installerPath = Join-Path -Path $stagingDirectory -ChildPath 'OpenShellSetup.exe'
    Invoke-AtlasPinnedDownload -Uri $openShellUri -Destination $installerPath `
        -Sha256 $openShellSha256 -ExpectedBytes $openShellBytes | Out-Null

    # The upstream installer is unsigned, so the immutable release hash is the
    # executable trust boundary. These metadata checks also catch a wrong asset
    # selected during a reviewed version bump.
    $installer = Get-Item -LiteralPath $installerPath -Force -ErrorAction Stop
    if ($installer.VersionInfo.FileVersion -ne $openShellVersion -or
        $installer.VersionInfo.CompanyName -ne 'Open-Shell' -or
        $installer.VersionInfo.ProductName -ne 'Open-Shell') {
        throw 'The pinned Open-Shell installer failed its version metadata checks.'
    }

    $nativeArchitecture = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToUpperInvariant()
    switch ($nativeArchitecture) {
        'X64' {
            $extractMode = 'extract64'
            $msiName = 'OpenShellSetup64_4_4_198.msi'
            $msiBytes = 5749469
            $msiSha256 = 'e3f7f41fe718d01a80f2af7f8d6f6c50aded56e1ea80f85d83eab03ac0cdd493'
        }
        'ARM64' {
            $extractMode = 'extractARM64'
            $msiName = 'OpenShellSetupARM64_4_4_198.msi'
            $msiBytes = 6072899
            $msiSha256 = '65b80580c2d130af88c17c2482235984bb96994595f2da2da3b77f62b6ffbbe6'
        }
        default {
            throw "Open-Shell is not supported on native architecture '$nativeArchitecture'."
        }
    }

    # The upstream wrapper's normal path expands inherited ALLUSERSPROFILE and
    # later launches a bare msiexec.exe. Use its extraction-only mode in the
    # protected directory, then invoke the protected Windows Installer directly.
    $msiPath = [IO.Path]::Combine($stagingDirectory, $msiName)
    if ([IO.File]::Exists($msiPath)) {
        throw "The Open-Shell MSI extraction target already exists at '$msiPath'."
    }
    $extractorResult = Invoke-AtlasContainedProcess `
        -FilePath $installerPath `
        -WorkingDirectory $stagingDirectory `
        -ArgumentList ([string[]]@($extractMode, '/qn')) `
        -Description 'The Open-Shell MSI extractor' `
        -Hidden `
        -NoWindow
    $extractorExitCode = [uint32]$extractorResult.ExitCodeUInt32
    if ($extractorExitCode -ne 0) {
        throw "Open-Shell MSI extraction failed with exit code $extractorExitCode."
    }

    if (-not [IO.File]::Exists($msiPath)) {
        throw "Open-Shell did not produce the expected '$msiName' package."
    }
    $msi = Get-Item -LiteralPath $msiPath -Force -ErrorAction Stop
    if (($msi.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
        $msi.Length -ne $msiBytes -or
        -not $msi.DirectoryName.Equals($stagingDirectory, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The extracted Open-Shell MSI failed its protected-file or exact byte-length checks.'
    }
    $actualMsiSha256 = (Get-FileHash -LiteralPath $msiPath -Algorithm SHA256).Hash
    if (-not $actualMsiSha256.Equals($msiSha256, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The extracted Open-Shell MSI does not match the reviewed architecture-specific SHA-256.'
    }

    $msiexecPath = [IO.Path]::Combine(
        [Environment]::GetFolderPath('System'),
        'msiexec.exe'
    )
    if (-not [IO.File]::Exists($msiexecPath)) {
        throw "The protected Windows Installer executable is missing at '$msiexecPath'."
    }
    $msiexec = Get-Item -LiteralPath $msiexecPath -Force -ErrorAction Stop
    if (($msiexec.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "The Windows Installer executable '$msiexecPath' is a reparse point."
    }

    $processResult = Invoke-AtlasContainedProcess `
        -FilePath $msiexec.FullName `
        -WorkingDirectory $stagingDirectory `
        -ArgumentList ([string[]]@(
            '/i'
            $msiPath
            '/qn'
            'ADDLOCAL=StartMenu'
            'NOSTART=1'
            '/norestart'
        )) `
        -Description 'The Open-Shell Windows Installer transaction' `
        -Hidden `
        -NoWindow
    $processExitCode = [uint32]$processResult.ExitCodeUInt32
    if ($processExitCode -notin @(0, 3010)) {
        throw "Open-Shell installation failed with exit code $processExitCode."
    }

    $installDirectory = [IO.Path]::Combine(
        [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFiles),
        'Open-Shell'
    )
    $startMenuPath = [IO.Path]::Combine($installDirectory, 'StartMenu.exe')
    $resolvedInstallDirectory = Resolve-AtlasProtectedExecutionPath `
        -Path $installDirectory `
        -PathType Container `
        -Description 'The installed Open-Shell directory'
    $resolvedStartMenu = Resolve-AtlasProtectedExecutionPath `
        -Path $startMenuPath `
        -PathType Leaf `
        -Description 'The installed Open-Shell Start Menu executable'
    $startMenu = Get-Item -LiteralPath $resolvedStartMenu -Force -ErrorAction Stop
    $installedVersion = $null
    try {
        $installedVersion = [version]$startMenu.VersionInfo.FileVersion
    }
    catch {
        throw 'The installed Open-Shell Start Menu executable has invalid version metadata.'
    }
    if (-not $resolvedStartMenu.StartsWith(
            $resolvedInstallDirectory.TrimEnd('\') + '\',
            [StringComparison]::OrdinalIgnoreCase
        ) -or
        $installedVersion.ToString(3) -ne $openShellVersion) {
        throw 'The Open-Shell installer exited successfully but its protected installed-file/version postcondition failed.'
    }

    return [pscustomobject]@{
        Version        = $openShellVersion
        RebootRequired = $processExitCode -eq 3010
    }
}
catch {
    if (Test-AtlasContainedProcessContainmentUnconfirmed -Exception $_.Exception) {
        $cleanupStaging = $false
        Write-Warning "Open-Shell process-tree containment could not be confirmed; protected staging is retained at '$stagingDirectory'."
    }
    throw
}
finally {
    if ($cleanupStaging -and (Test-Path -LiteralPath $stagingDirectory -PathType Container)) {
        Remove-Item -LiteralPath $stagingDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }
}
