#Requires -Version 5.0

<#
	.SYNOPSIS
	Uninstalls or reinstalls Microsoft Edge and its related components. Made by @he3als.

	.Description
	Uninstalls or reinstalls Microsoft Edge and its related components in a non-forceful manner, based upon switches or user choices in a TUI.

	.PARAMETER UninstallEdge
	Uninstalls Edge, leaving the Edge user data.

	.PARAMETER InstallEdge
	Installs Edge, leaving the previous Edge user data.

	.PARAMETER InstallWebView
	Installs Edge WebView2 using the Evergreen installer.

	.PARAMETER RemoveEdgeData
	Removes all Edge user data. Compatible with -InstallEdge.

	.PARAMETER KeepAppX
	Doesn't check for and remove the AppX, in case you want to use alternative AppX removal methods. Doesn't work with UninstallEdge.

	.PARAMETER NonInteractive
	When combined with other parameters, this does not prompt the user for anything.

	.PARAMETER Embedded
	The Atlas toggle engine hosts this script in its own window: it has printed the
	heading and owns the exit pause, so neither is printed here.

	.LINK
	https://github.com/he3als/EdgeRemover
#>

param (
    [switch]$UninstallEdge,
    [switch]$InstallEdge,
    [switch]$InstallWebView,
    [switch]$RemoveEdgeData,
    [switch]$KeepAppX,
    [switch]$NonInteractive,
    [switch]$MachineContext,
    [switch]$Embedded
)

Set-StrictMode -Version 3.0

$modulesRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'Modules'
foreach ($moduleManifest in @(
        (Join-Path $modulesRoot 'Atlas.Core\Atlas.Core.psd1')
        (Join-Path $modulesRoot 'Atlas.Download\Atlas.Download.psd1')
    )) {
    if (-not [IO.File]::Exists($moduleManifest)) {
        throw "The module manifest is missing at '$moduleManifest'."
    }
    Import-Module -Name $moduleManifest -ErrorAction Stop
}

$version = '1.9.5'

$ProgressPreference = 'SilentlyContinue'
$sys32 = [Environment]::GetFolderPath('System')
$msedgeExePaths = @(
    "$([Environment]::GetFolderPath('ProgramFilesx86'))\Microsoft\Edge\Application\msedge.exe",
    "$([Environment]::GetFolderPath('ProgramFiles'))\Microsoft\Edge\Application\msedge.exe"
)
# Exact HTTPS download locations in Microsoft's published Edge endpoint allowlist.
$microsoftEdgeDownloadHosts = @(
    'msedge.sf.tlu.dl.delivery.mp.microsoft.com'
    'msedge.sf.dl.delivery.mp.microsoft.com'
    'msedge.sb.tlu.dl.delivery.mp.microsoft.com'
    'msedge.sb.dl.delivery.mp.microsoft.com'
)

if ($NonInteractive -and (!$UninstallEdge -and !$InstallEdge -and !$InstallWebView)) {
    $NonInteractive = $false
}
if ($InstallEdge -and $UninstallEdge) {
    throw "You can't use both -InstallEdge and -UninstallEdge as arguments."
}
if ($MachineContext -and (-not $UninstallEdge -or -not $KeepAppX -or
        -not $NonInteractive -or $InstallEdge -or $InstallWebView -or $RemoveEdgeData)) {
    throw 'MachineContext supports only the fixed noninteractive Edge-browser removal contract with KeepAppX and without user-data mutation.'
}

function Pause {
    # Only a standalone interactive run owns its exit pause.
    if (!$NonInteractive -and !$Embedded) { Wait-AtlasExit }
}

function Write-Status {
    <#
    .SYNOPSIS
        Prints one line through the shared vocabulary. -Exit ends the script with the
        given code after the failure block.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Text,
        [ValidateSet('Success', 'Info', 'Warning', 'Error', 'Critical')]
        [string]$Level = 'Info',
        [switch]$Exit,
        [int]$ExitCode = 1
    )

    if ($Exit) {
        Write-AtlasNotApplied -Title 'Install or Remove Edge' -Reason $Text -DetailsPath (Get-AtlasInstallLogPath)
        Write-AtlasLog -Level Error -Message "Edge helper failed: $Text" -NoConsole
        Pause
        exit $ExitCode
    }

    switch ($Level) {
        'Success' { Write-AtlasSuccess -Text $Text }
        'Warning' { Write-AtlasWarning -Text $Text }
        'Error' { Write-AtlasFailure -Text $Text }
        'Critical' { Write-AtlasFailure -Text $Text }
        default { Write-AtlasNote -Text $Text }
    }
}

function InternetCheck {
    try {
        Microsoft.PowerShell.Utility\Invoke-WebRequest `
            -Uri 'https://www.microsoft.com/robots.txt' `
            -Method GET `
            -UseBasicParsing `
            -TimeoutSec 10 `
            -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Status "Microsoft.com could not be reached. An Internet connection is needed to install Edge or its components. $($_.Exception.Message)" -Level Critical -Exit -ExitCode 404
    }
}

function Assert-MicrosoftSignedInstaller {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$StagingDirectory,

        [Parameter(Mandatory = $true)]
        [string]$Description,

        [ValidatePattern('^[0-9a-fA-F]{64}$')]
        [string]$ExpectedSha256,

        [ValidateRange(1, 1073741824)]
        [long]$ExpectedBytes
    )

    if (-not [IO.File]::Exists($Path)) {
        throw "$Description is missing at '$Path'."
    }

    $file = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    $expectedParent = [IO.Path]::GetFullPath($StagingDirectory).TrimEnd('\')
    $actualParent = [IO.Path]::GetFullPath($file.DirectoryName).TrimEnd('\')
    if (($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
        -not $actualParent.Equals($expectedParent, [StringComparison]::OrdinalIgnoreCase)) {
        throw "$Description is not a regular file directly inside protected staging."
    }

    if ($PSBoundParameters.ContainsKey('ExpectedBytes') -and $file.Length -ne $ExpectedBytes) {
        throw "$Description no longer matches its expected byte length."
    }
    if ($PSBoundParameters.ContainsKey('ExpectedSha256') -and
        (Microsoft.PowerShell.Utility\Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash -ne $ExpectedSha256) {
        throw "$Description no longer matches its expected SHA-256."
    }

    $signature = Microsoft.PowerShell.Security\Get-AuthenticodeSignature -LiteralPath $file.FullName
    if ($signature.Status -ne [System.Management.Automation.SignatureStatus]::Valid -or
        $null -eq $signature.SignerCertificate -or
        $signature.SignerCertificate.Subject -notmatch '(^|,\s*)CN=Microsoft Corporation(,|$)') {
        throw "$Description is not validly signed by Microsoft Corporation."
    }

    return $file.FullName
}

function Invoke-MicrosoftWebViewDownload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [uri]$Uri,

        [Parameter(Mandatory = $true)]
        [string]$Destination,

        [Parameter(Mandatory = $true)]
        [string]$StagingDirectory
    )

    $expectedUri = 'https://go.microsoft.com/fwlink/p/?LinkId=2124703'
    $expectedFileName = 'MicrosoftEdgeWebview2Setup.exe'
    $maximumBytes = 33554432

    if ($Uri.AbsoluteUri -cne $expectedUri) {
        throw "The WebView bootstrap URI '$Uri' is not the reviewed Microsoft forwarding URL."
    }
    if (Test-Path -LiteralPath $Destination) {
        throw "The WebView download destination '$Destination' already exists."
    }

    $protectedParent = [IO.Path]::GetFullPath($StagingDirectory).TrimEnd('\')
    $destinationParent = [IO.Path]::GetFullPath((Split-Path -Parent $Destination)).TrimEnd('\')
    if (-not $destinationParent.Equals($protectedParent, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The WebView download destination is outside protected staging.'
    }
    $parentItem = Get-Item -LiteralPath $protectedParent -Force -ErrorAction Stop
    if (($parentItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
        -not (Test-AtlasProtectedStagingAcl -Acl (Get-Acl -LiteralPath $protectedParent -ErrorAction Stop))) {
        throw 'The WebView download destination is not an Atlas protected staging directory.'
    }

    $curlPath = [IO.Path]::Combine([Environment]::GetFolderPath('System'), 'curl.exe')
    if (-not [IO.File]::Exists($curlPath)) {
        throw "The protected Windows cURL executable is missing at '$curlPath'."
    }

    $curlArguments = @(
        # This must remain argument zero so a caller-writable .curlrc is ignored.
        '--disable'
        '--fail'
        '--location'
        '--silent'
        '--show-error'
        '--proto', '=https'
        '--proto-redir', '=https'
        '--tlsv1.2'
        '--connect-timeout', '10'
        '--max-time', '300'
        '--max-redirs', '5'
        '--max-filesize', [string]$maximumBytes
        '--write-out', '%{url_effective}'
        $Uri.AbsoluteUri
        '--output', $Destination
    )

    try {
        $effectiveUrlOutput = & $curlPath @curlArguments
        $curlExitCode = $LASTEXITCODE
        if ($curlExitCode -ne 0 -or -not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
            throw "Downloading '$Uri' failed with cURL exit code $curlExitCode."
        }

        $effectiveUri = $null
        $effectiveUrl = ([string]($effectiveUrlOutput -join '')).Trim()
        if (-not [uri]::TryCreate($effectiveUrl, [UriKind]::Absolute, [ref]$effectiveUri) -or
            $effectiveUri.Scheme -ne 'https' -or
            -not [string]::IsNullOrEmpty($effectiveUri.UserInfo) -or
            -not $effectiveUri.IsDefaultPort -or
            $effectiveUri.Host -notin $microsoftEdgeDownloadHosts -or
            -not [string]::IsNullOrEmpty($effectiveUri.Query) -or
            -not [IO.Path]::GetFileName($effectiveUri.AbsolutePath).Equals($expectedFileName, [StringComparison]::OrdinalIgnoreCase)) {
            throw "The WebView forwarding URL resolved to the unreviewed location '$effectiveUrl'."
        }

        $download = Get-Item -LiteralPath $Destination -Force -ErrorAction Stop
        if (($download.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
            $download.Length -lt 1 -or $download.Length -gt $maximumBytes -or
            -not [IO.Path]::GetFullPath($download.DirectoryName).TrimEnd('\').Equals(
                $protectedParent,
                [StringComparison]::OrdinalIgnoreCase
            )) {
            throw 'The WebView bootstrapper failed its protected-file and size checks.'
        }

        Assert-MicrosoftSignedInstaller `
            -Path $download.FullName `
            -StagingDirectory $StagingDirectory `
            -Description 'The Edge WebView2 bootstrapper' | Out-Null

        return [pscustomobject]@{
            Path     = $download.FullName
            FinalUri = $effectiveUri
        }
    }
    catch {
        Remove-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
        throw
    }
}

function DeleteIfExist($Path) {
    if (Test-Path $Path) {
        Remove-Item -Path $Path -Force -Recurse -Confirm:$false
    }
}

function Remove-EdgePath {
    # Take ownership, grant Administrators full control, then delete - with a cmd 'rd'
    # retry for trees the provider can't remove.
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    & "$sys32\takeown.exe" /F "$Path" /R /D Y *> $null
    & "$sys32\icacls.exe" "$Path" /grant '*S-1-5-32-544:(F)' /T /C *> $null
    Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $Path) {
        & "$sys32\cmd.exe" /c rd /s /q "$Path" *> $null
    }
}

function EdgeInstalled {
    foreach ($msedgeExe in $msedgeExePaths) {
        if (Test-Path $msedgeExe) {
            return $true
        }
    }

    return $false
}

function KillEdgeProcesses {
    $ErrorActionPreference = 'SilentlyContinue'
    foreach ($service in (Get-Service -Name 'MicrosoftEdgeElevationService').Name) {
        Stop-Service -Name $service -Force
    }

    # Match only the Edge browser; a bare '\Microsoft\*' would
    # also kill classic Teams, x86 Office and OneDrive. Trailing '\' stops the 'Edge' glob
    # from also matching '\Microsoft\EdgeWebView'.
    $edgePathPatterns = @()
    foreach ($programFiles in @([Environment]::GetFolderPath('ProgramFilesX86'), [Environment]::GetFolderPath('ProgramFiles'))) {
        foreach ($edgeComponent in @('Edge')) {
            $edgePathPatterns += "$programFiles\Microsoft\$edgeComponent\*"
        }
    }

    foreach (
        $process in
        (Get-Process | Where-Object {
            $processPath = $_.Path
            # Never the WebView2 Runtime (by name or install path): the shell hosts it on
            # 24H2/25H2 and we don't uninstall it, so killing it drops the live session.
            $isWebView = ($_.Name -eq 'msedgewebview2') -or ($processPath -like '*\Microsoft\EdgeWebView\*')
            (-not $isWebView) -and (
                (@($edgePathPatterns | Where-Object { $processPath -like $_ }).Count -gt 0) -or
                ($_.Name -match '^(msedge|MicrosoftEdge|MicrosoftEdgeCP|MicrosoftEdgeSH)$')
            )
        }).Id
    ) {
        Stop-Process -Id $process -Force
    }
    $ErrorActionPreference = 'Continue'
}

function Wait-EdgeUninstallerProcesses {
    <#
        Give Edge's detached uninstallers a short opportunity to complete, then
        stop and verify any that remain. Waiting for the uninstallers without a
        bound can reach RestartManager and sign out the live user on 24H2/25H2.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Process,

        [ValidateRange(0, 30)]
        [int]$LaunchWindowSeconds = 3,

        [ValidateRange(0, 30)]
        [int]$TerminationSeconds = 5
    )

    $trackedIds = @(
        $Process |
            Where-Object { $null -ne $_ -and $null -ne $_.Id } |
            ForEach-Object { [int]$_.Id } |
            Sort-Object -Unique
    )
    if ($trackedIds.Count -eq 0) {
        return
    }

    $launchDeadline = [DateTime]::UtcNow.AddSeconds($LaunchWindowSeconds)
    do {
        $runningIds = @(
            foreach ($processId in $trackedIds) {
                if ($null -ne (Get-Process -Id $processId -ErrorAction SilentlyContinue)) {
                    $processId
                }
            }
        )
        if ($runningIds.Count -eq 0) {
            Write-AtlasLog -Message 'Edge uninstallers completed inside the bounded launch window.'
            return
        }
        if ([DateTime]::UtcNow -ge $launchDeadline) {
            break
        }
        Start-Sleep -Milliseconds 100
    } while ($true)

    Write-AtlasLog -Level Warning -Message "Stopping $($runningIds.Count) Edge uninstaller process(es) before direct removal." -NoConsole
    foreach ($processId in $runningIds) {
        Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
    }

    $terminationDeadline = [DateTime]::UtcNow.AddSeconds($TerminationSeconds)
    do {
        $remainingIds = @(
            foreach ($processId in $runningIds) {
                if ($null -ne (Get-Process -Id $processId -ErrorAction SilentlyContinue)) {
                    $processId
                }
            }
        )
        if ($remainingIds.Count -eq 0) {
            Write-AtlasLog -Message 'Confirmed that the detached Edge uninstallers stopped.'
            return
        }
        if ([DateTime]::UtcNow -ge $terminationDeadline) {
            break
        }
        Start-Sleep -Milliseconds 100
    } while ($true)

    throw "Could not confirm termination of detached Edge uninstaller process(es): $($remainingIds -join ', ')."
}

function DisableEdgeBrowserServices {
    $serviceNames = @(
        'MicrosoftEdgeElevationService'
    )

    try {
        $serviceNames += Get-CimInstance Win32_Service -ErrorAction Stop |
        Where-Object {
            ($_.PathName -like '*\Microsoft\Edge\Application\*')
        } |
        Select-Object -ExpandProperty Name
    }
    catch {
        Write-Status "Edge services could not be listed: $($_.Exception.Message)" -Level Warning
    }

    foreach ($serviceName in @($serviceNames | Where-Object { $_ } | Sort-Object -Unique)) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($null -eq $service) {
            continue
        }

        try {
            if ($service.Status -ne 'Stopped') {
                Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
            }
            Set-Service -Name $serviceName -StartupType Disabled -ErrorAction Stop
        }
        catch {
            Write-Status "The Edge service '$serviceName' could not be disabled: $($_.Exception.Message)" -Level Warning
        }
    }

    # EdgeUpdate services and tasks also service WebView2; keep them operational.
}

function Remove-EdgeRegistryKey {
    param(
        [Parameter(Mandatory = $true)][string]$KeyPath,
        [Parameter(Mandatory = $true)][ValidateSet('32', '64')][string]$RegistryView
    )
    & "$sys32\reg.exe" delete $KeyPath /f "/reg:$RegistryView" *> $null
}

function Remove-EdgeRegistration {
    # Edge leaves shell registration behind after its binaries are gone: dead protocol
    # handlers (microsoft-edge:), App Paths\msedge.exe, a binary-less Apps-list Uninstall
    # row, StartMenuInternet and the Edge Stable client registration. The updater is
    # shared with WebView2: never remove its parent tree or COM registration.
    $edgeKeys = @(
        'HKLM\SOFTWARE\Microsoft\Edge'
        'HKLM\SOFTWARE\Microsoft\EdgeUpdate\Clients\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}'
        'HKLM\SOFTWARE\Microsoft\EdgeUpdate\ClientState\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}'
        'HKLM\SOFTWARE\Microsoft\EdgeUpdate\ClientStateMedium\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}'
        'HKLM\SOFTWARE\Microsoft\MicrosoftEdge'
        'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{9459C573-B17A-45AE-9F64-1857B5D58CEE}'
        'HKLM\SOFTWARE\Microsoft\Internet Explorer\EdgeIntegration'
        'HKLM\SOFTWARE\Microsoft\Internet Explorer\EdgeDebugActivation'
        'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe'
        'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge'
        'HKLM\SOFTWARE\Clients\StartMenuInternet\Microsoft Edge'
        'HKLM\SOFTWARE\Classes\microsoft-edge'
        'HKLM\SOFTWARE\Classes\microsoft-edge-holographic'
        'HKLM\SOFTWARE\Classes\MSEdgeHTM'
        'HKLM\SOFTWARE\Classes\MSEdgeMHT'
    )
    if (-not $MachineContext) {
        $edgeKeys += @(
            'HKCU\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\microsoft-edge'
            'HKCU\SOFTWARE\Classes\microsoft-edge'
            'HKCU\SOFTWARE\Classes\MSEdgeHTM'
        )
    }
    foreach ($edgeKey in $edgeKeys) {
        foreach ($view in @('64', '32')) {
            Remove-EdgeRegistryKey -KeyPath $edgeKey -RegistryView $view
        }
    }
}

function InstallEdgeChromium {
    InternetCheck

    $link = 'Undefined'

    if ([Environment]::Is64BitOperatingSystem) {
        $arm = ((Get-CimInstance -Class Win32_ComputerSystem).SystemType -match 'ARM64') -or ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
        $archString = ('x64', 'arm64')[$arm]
    }
    else {
        $archString = 'x86'
    }

    Write-AtlasStep -Text 'Looking up the latest Microsoft Edge release...'
    try {
        try {
            $edgeUpdateApi = (Microsoft.PowerShell.Utility\Invoke-WebRequest `
                    -Uri 'https://edgeupdates.microsoft.com/api/products' `
                    -UseBasicParsing `
                    -TimeoutSec 30 `
                    -ErrorAction Stop).Content | Microsoft.PowerShell.Utility\ConvertFrom-Json
        }
        catch {
            Write-Status "The Microsoft Edge release list could not be downloaded: $_" -Level Critical -Exit -ExitCode 4
        }

        $edgeItem = ($edgeUpdateApi | Where-Object { $_.Product -eq 'Stable' }).Releases |
            Where-Object { $_.Platform -eq 'Windows' -and $_.Architecture -eq $archString } |
            Where-Object { $_.Artifacts.Count -ne 0 } | Select-Object -First 1

        if ($null -eq $edgeItem) {
            Write-Status 'The Microsoft Edge release list has no download for this PC.' -Level Critical -Exit
        }

        $artifacts = @($edgeItem.Artifacts | Where-Object { $_.ArtifactName -eq 'msi' })
        if ($artifacts.Count -ne 1) {
            throw "Expected one Edge MSI artifact, but the API returned $($artifacts.Count)."
        }
        $artifact = $artifacts[0]

        $downloadUri = $null
        $link = [string]$artifact.Location
        if (-not [uri]::TryCreate($link, [UriKind]::Absolute, [ref]$downloadUri) -or
            $downloadUri.Scheme -ne 'https' -or
            -not [string]::IsNullOrEmpty($downloadUri.UserInfo) -or
            -not $downloadUri.IsDefaultPort -or
            -not [string]::IsNullOrEmpty($downloadUri.Query) -or
            $downloadUri.Host -notin $microsoftEdgeDownloadHosts) {
            throw "The Edge API returned the unreviewed download location '$link'."
        }

        $architectureName = @{
            x64   = 'X64'
            arm64 = 'ARM64'
            x86   = 'X86'
        }[$archString]
        $expectedMsiName = "MicrosoftEdgeEnterprise$architectureName.msi"
        if (-not [IO.Path]::GetFileName($downloadUri.AbsolutePath).Equals($expectedMsiName, [StringComparison]::OrdinalIgnoreCase)) {
            throw "The Edge API returned an unexpected MSI name for '$archString'."
        }

        $hash = [string]$artifact.Hash
        $hashAlgorithm = [string]$artifact.HashAlgorithm
        if (-not $hashAlgorithm.Equals('SHA256', [StringComparison]::OrdinalIgnoreCase) -or
            $hash -notmatch '^[0-9a-fA-F]{64}$') {
            throw 'The Edge API did not provide the required SHA-256 digest.'
        }

        $expectedBytes = [long]$artifact.SizeInBytes
        if ($expectedBytes -lt 1 -or $expectedBytes -gt 1073741824) {
            throw 'The Edge API did not provide a valid bounded MSI byte length.'
        }

        $version = [string]$edgeItem.ProductVersion
        if ([string]::IsNullOrWhiteSpace($version)) {
            throw 'The Edge API did not provide a product version.'
        }
        if ([string]::IsNullOrWhiteSpace([string]$edgeItem.PublishedTime)) {
            throw 'The Edge API did not provide a publication timestamp.'
        }
        $released = Get-Date $edgeItem.PublishedTime -ErrorAction Stop
        $sizeInMb = [math]::Round($expectedBytes / 1Mb)
        $link = $downloadUri.AbsoluteUri
    }
    catch {
        Write-Status "The Microsoft Edge release information from `"$link`" could not be used: $_" -Level Critical -Exit -ExitCode 5
    }

    Write-AtlasStep -Text ("Downloading Microsoft Edge {0} (Stable, released {1:yyyy-MM-dd}, {2} MB)..." -f $version, $released, $sizeInMb)

    $stagingDirectory = $null
    $retainStaging = $false
    try {
        $stagingDirectory = New-AtlasProtectedStagingDirectory
        $msi = Join-Path -Path $stagingDirectory -ChildPath $expectedMsiName
        $msiLog = Join-Path -Path $stagingDirectory -ChildPath 'edgeMsi.log'

        try {
            Invoke-AtlasPinnedDownload `
                -Uri $downloadUri `
                -Destination $msi `
                -Sha256 $hash `
                -ExpectedBytes $expectedBytes | Out-Null
        }
        catch {
            if (Test-AtlasContainedProcessContainmentUnconfirmed -Exception $_.Exception) {
                $retainStaging = $true
            }
            Write-Status "Microsoft Edge could not be downloaded and verified from `"$link`": $_" -Level Critical -Exit -ExitCode 6
        }
        Write-AtlasNote -Text 'The installer matches the published hash and size.'

        $msiexecPath = [IO.Path]::Combine([Environment]::GetFolderPath('System'), 'msiexec.exe')
        if (-not [IO.File]::Exists($msiexecPath)) {
            Write-Status "The protected Windows Installer executable is missing at '$msiexecPath'." -Level Critical -Exit -ExitCode 7
        }
        $msiexec = Get-Item -LiteralPath $msiexecPath -Force -ErrorAction Stop
        if (($msiexec.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            Write-Status "The Windows Installer executable '$msiexecPath' is a reparse point." -Level Critical -Exit -ExitCode 7
        }

        $originalTemp = [Environment]::GetEnvironmentVariable('TEMP', 'Process')
        $originalTmp = [Environment]::GetEnvironmentVariable('TMP', 'Process')
        try {
            [Environment]::SetEnvironmentVariable('TEMP', $stagingDirectory, 'Process')
            [Environment]::SetEnvironmentVariable('TMP', $stagingDirectory, 'Process')

            foreach ($transaction in @(
                    @{ Status = 'Installing Microsoft Edge. This can take a few minutes...'; Mode = '/i'; Description = 'The Microsoft Edge installation' }
                    @{ Status = 'Repairing the Microsoft Edge installation...'; Mode = '/fa'; Description = 'The Microsoft Edge repair' }
                )) {
                Write-AtlasStep -Text $transaction.Status
                try {
                    # Revalidate the exact bytes and independent publisher identity
                    # immediately before both the install and repair executions.
                    Assert-MicrosoftSignedInstaller `
                        -Path $msi `
                        -StagingDirectory $stagingDirectory `
                        -Description 'The Microsoft Edge MSI' `
                        -ExpectedSha256 $hash `
                        -ExpectedBytes $expectedBytes | Out-Null

                    $installerResult = Invoke-AtlasContainedProcess `
                        -FilePath $msiexec.FullName `
                        -WorkingDirectory $stagingDirectory `
                        -ArgumentList ([string[]]@(
                                $transaction.Mode
                                $msi
                                '/l'
                                $msiLog
                                '/quiet'
                                '/norestart'
                            )) `
                        -Description $transaction.Description `
                        -Hidden
                    if ($installerResult.ExitCodeUInt32 -notin @([uint32]0, [uint32]3010)) {
                        throw "$($transaction.Description) failed with exit code $($installerResult.ExitCodeUInt32)."
                    }
                }
                catch {
                    if (Test-AtlasContainedProcessContainmentUnconfirmed -Exception $_.Exception) {
                        $retainStaging = $true
                    }
                    Write-Status "The Microsoft Edge installer was stopped: $_" -Level Critical -Exit -ExitCode 10
                }
            }
        }
        finally {
            [Environment]::SetEnvironmentVariable('TEMP', $originalTemp, 'Process')
            [Environment]::SetEnvironmentVariable('TMP', $originalTmp, 'Process')
        }

        if (!(Test-Path -LiteralPath $msiLog -PathType Leaf)) {
            Write-Status "The installer log at `"$msiLog`" is missing, so the installation most likely failed." -Level Critical -Exit -ExitCode 7
        }

        Write-AtlasLog -Message "Edge installer log: '$msiLog' (removed after verification)."
        if (@($(Get-Content -LiteralPath $msiLog) -like '*Product: Microsoft Edge -- * completed successfully.*').Count -eq 0) {
            Write-Status 'The Edge installer log does not report a successful installation.' -Level Error -Exit -ExitCode 8
        }

        Write-Status -Text 'Microsoft Edge is installed.' -Level Success
    }
    finally {
        if ($retainStaging) {
            Write-Status "The protected staging folder '$stagingDirectory' was kept because process containment could not be confirmed." -Level Warning
        }
        elseif ($stagingDirectory -and (Test-Path -LiteralPath $stagingDirectory -PathType Container)) {
            Remove-Item -LiteralPath $stagingDirectory -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function InstallWebView {
    InternetCheck

    $link = [uri]'https://go.microsoft.com/fwlink/p/?LinkId=2124703'
    $stagingDirectory = $null
    $retainStaging = $false
    try {
        $stagingDirectory = New-AtlasProtectedStagingDirectory
        $dlPath = Join-Path -Path $stagingDirectory -ChildPath 'MicrosoftEdgeWebview2Setup.exe'

        Write-AtlasStep -Text 'Downloading the Edge WebView2 runtime...'
        try {
            $download = Invoke-MicrosoftWebViewDownload `
                -Uri $link `
                -Destination $dlPath `
                -StagingDirectory $stagingDirectory
        }
        catch {
            Write-Status "The Edge WebView2 runtime could not be downloaded and verified from `"$link`": $_" -Level Critical -Exit -ExitCode 9
        }

        Write-AtlasLog -Message "Resolved the Microsoft WebView bootstrapper from '$($download.FinalUri.Host)'."
        Write-AtlasStep -Text 'Installing the Edge WebView2 runtime. This can take a few minutes...'
        $originalTemp = [Environment]::GetEnvironmentVariable('TEMP', 'Process')
        $originalTmp = [Environment]::GetEnvironmentVariable('TMP', 'Process')
        try {
            # The bootstrapper extracts a second stage. Keep inherited TEMP/TMP
            # inside the same protected directory as the verified outer payload.
            [Environment]::SetEnvironmentVariable('TEMP', $stagingDirectory, 'Process')
            [Environment]::SetEnvironmentVariable('TMP', $stagingDirectory, 'Process')

            # The fwlink has no stable digest. Recheck its independent Microsoft
            # publisher identity at the last possible point before execution.
            Assert-MicrosoftSignedInstaller `
                -Path $download.Path `
                -StagingDirectory $stagingDirectory `
                -Description 'The Edge WebView2 bootstrapper' | Out-Null

            $installerResult = Invoke-AtlasContainedProcess `
                -FilePath $download.Path `
                -WorkingDirectory $stagingDirectory `
                -ArgumentList ([string[]]@('/silent', '/install')) `
                -Description 'The Edge WebView2 bootstrapper' `
                -Hidden
            if ($installerResult.ExitCodeUInt32 -notin @([uint32]0, [uint32]3010)) {
                throw "Installing Edge WebView failed with exit code $($installerResult.ExitCodeUInt32)."
            }
        }
        catch {
            if (Test-AtlasContainedProcessContainmentUnconfirmed -Exception $_.Exception) {
                $retainStaging = $true
            }
            Write-Status "The Edge WebView2 installer was stopped: $_" -Level Critical -Exit -ExitCode 9
        }
        finally {
            [Environment]::SetEnvironmentVariable('TEMP', $originalTemp, 'Process')
            [Environment]::SetEnvironmentVariable('TMP', $originalTmp, 'Process')
        }

        Write-Status 'The Edge WebView2 runtime is installed.' -Level Success
    }
    finally {
        if ($retainStaging) {
            Write-Status "The protected staging folder '$stagingDirectory' was kept because process containment could not be confirmed." -Level Warning
        }
        elseif ($stagingDirectory -and (Test-Path -LiteralPath $stagingDirectory -PathType Container)) {
            Remove-Item -LiteralPath $stagingDirectory -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Deliberately self-contained (standalone script). MachineContext is a narrow install-only
# contract: Components already proves strict TI, user registry/data is split into a separate
# exact-user script, and no install/update/WebView route is accepted here.
$currentUserSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
if ($currentUserSid -eq 'S-1-5-18') {
    if (-not $MachineContext) {
        Write-Status 'This script cannot run as TrustedInstaller or SYSTEM outside the fixed Atlas machine-removal contract. Run it from a regular administrator account.' -Level Critical -Exit
    }
}
else {
    if ($MachineContext) {
        throw 'MachineContext requires the SYSTEM token supplied by the strict TrustedInstaller phase.'
    }
    if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        if ($PSBoundParameters.Count -le 0 -and !$args) {
            # A standalone run relaunches itself elevated in a visible window; the Atlas
            # launcher never reaches this branch because its engine elevates first.
            # cmd /c strips the first and last quote of a multi-quote command line, so the
            # whole command is wrapped in one extra outer pair.
            Start-Process "$sys32\cmd.exe" "/c `"`"$sys32\WindowsPowerShell\v1.0\powershell.exe`" -NoP -EP RemoteSigned -File `"$PSCommandPath`"`"" -Verb RunAs
            exit
        }
        else {
            throw 'This script must be run as an administrator.'
        }
    }
}

$edgeInstalled = EdgeInstalled
if (!$UninstallEdge -and !$InstallEdge -and !$InstallWebView) {
    if (!$Embedded) {
        Set-AtlasLogConsoleStyle -Style Interactive
        Write-AtlasTitle -Text 'Install or Remove Edge'
    }
    $RemoveEdgeData = $false

    Write-AtlasNote -Text "Microsoft Edge is currently $(@('not installed', 'installed')[$edgeInstalled])."
    Write-AtlasBlankLine
    switch (Read-AtlasChoice -Question 'What would you like to do?' -Option @(
                'Remove Microsoft Edge'
                'Install Microsoft Edge'
                'Install the Edge WebView2 runtime'
                'Install both Microsoft Edge and the WebView2 runtime'
            )) {
        1 { $UninstallEdge = $true }
        2 { $InstallEdge = $true }
        3 { $InstallWebView = $true }
        4 {
            $InstallWebView = $true
            $InstallEdge = $true
        }
    }
    Write-AtlasBlankLine
}

if ($UninstallEdge) {
    Write-AtlasStep -Text 'Removing Microsoft Edge. This can take a minute...'
    KillEdgeProcesses
    DisableEdgeBrowserServices

    # Kick off Edge's own uninstaller detached. A synchronous system-level
    # --force-uninstall can reach RestartManager and sign out the live user on 24H2/25H2.
    # Track the detached processes so they receive only a bounded launch window and are
    # confirmed stopped before direct file deletion begins.
    $edgeUninstallers = New-Object Collections.Generic.List[object]
    foreach ($root in @(
            "$([Environment]::GetFolderPath('ProgramFilesx86'))\Microsoft\Edge\Application",
            "$([Environment]::GetFolderPath('ProgramFiles'))\Microsoft\Edge\Application"
        )) {
        if (-not (Test-Path $root)) {
            continue
        }
        foreach ($setup in @(Get-ChildItem -Path $root -Filter 'setup.exe' -Recurse -ErrorAction SilentlyContinue | Sort-Object -Property FullName -Unique)) {
            Write-AtlasLog -Message "Launching the Edge uninstaller at '$($setup.FullName)'."
            try {
                $edgeUninstaller = Start-Process -FilePath $setup.FullName `
                    -ArgumentList '--uninstall --system-level --force-uninstall' `
                    -WindowStyle Hidden -PassThru -ErrorAction Stop
                if ($null -ne $edgeUninstaller) {
                    $edgeUninstallers.Add($edgeUninstaller)
                }
            }
            catch {
                Write-Status "The Edge uninstaller '$($setup.FullName)' could not be started: $($_.Exception.Message)" -Level Warning
            }
        }
    }

    Wait-EdgeUninstallerProcesses -Process @($edgeUninstallers)
    KillEdgeProcesses

    # Remove only the Edge browser. EdgeCore, EdgeUpdate and EdgeWebView are shared
    # runtime/update infrastructure and must survive removal of the browser.
    foreach ($programFiles in @([Environment]::GetFolderPath('ProgramFilesX86'), [Environment]::GetFolderPath('ProgramFiles'))) {
        foreach ($folder in @('Edge')) {
            Remove-EdgePath -Path (Join-Path -Path $programFiles -ChildPath "Microsoft\$folder")
        }
    }
    Get-ChildItem -LiteralPath ([Environment]::GetFolderPath('System')) -Filter 'MicrosoftEdge*.exe' -ErrorAction SilentlyContinue | ForEach-Object {
        & "$sys32\takeown.exe" /F "$($_.FullName)" *> $null
        & "$sys32\icacls.exe" "$($_.FullName)" /grant '*S-1-5-32-544:(F)' /C *> $null
        Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
    }

    # User-owned shortcut cleanup runs separately under the exact install-state user.
    # This machine contract touches only the protected common shortcut locations.
    $edgeShortcutNames = @('edge.lnk', 'Microsoft Edge.lnk')
    $shortcutDirs = @([Environment]::GetFolderPath('CommonDesktopDirectory'), [Environment]::GetFolderPath('CommonPrograms'))
    foreach ($shortcutDir in ($shortcutDirs | Select-Object -Unique)) {
        if ([string]::IsNullOrWhiteSpace($shortcutDir) -or -not [IO.Directory]::Exists($shortcutDir)) {
            continue
        }
        $shortcutAttributes = [IO.File]::GetAttributes($shortcutDir)
        if (($shortcutAttributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            Write-Status "The shortcut folder '$shortcutDir' is a reparse point and was left alone." -Level Warning
            continue
        }
        foreach ($edgeShortcutName in $edgeShortcutNames) {
            $shortcutPath = [IO.Path]::Combine($shortcutDir, $edgeShortcutName)
            if ([IO.File]::Exists($shortcutPath)) {
                try {
                    [IO.File]::SetAttributes($shortcutPath, [IO.FileAttributes]::Normal)
                    [IO.File]::Delete($shortcutPath)
                }
                catch {
                    Write-Status "The Edge shortcut '$shortcutPath' could not be removed: $($_.Exception.Message)" -Level Warning
                }
            }
        }
    }

    # Drop the now-dangling Edge shell registration (protocol handlers, App Paths,
    # Apps-list Uninstall row, StartMenuInternet, EdgeUpdate clients).
    Remove-EdgeRegistration

    if (EdgeInstalled) {
        if ($NonInteractive) {
            Write-Status 'Some Microsoft Edge files were not removed. Continuing so playbook cleanup can finish.' -Level Warning
        }
        else {
            Write-AtlasPartial -Text 'Some Microsoft Edge files could not be removed.'
        }
    }
    else {
        Write-Status 'Microsoft Edge was removed.' -Level Success
    }
}

if ($RemoveEdgeData) {
    KillEdgeProcesses
    DeleteIfExist "$([Environment]::GetFolderPath('LocalApplicationData'))\Microsoft\Edge"
    Write-Status 'Existing Edge user data was removed.'
}

if ($InstallEdge) {
    InstallEdgeChromium
}
if ($InstallWebView) {
    InstallWebView
}

if ($NonInteractive) { exit 0 }
if (!$Embedded) {
    Write-AtlasCompletion -Title 'Install or Remove Edge'
}
Pause
exit 0
