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

	.LINK
	https://github.com/he3als/EdgeRemover
#>

param (
    [switch]$UninstallEdge,
    [switch]$InstallEdge,
    [switch]$InstallWebView,
    [switch]$RemoveEdgeData,
    [switch]$KeepAppX,
    [switch]$NonInteractive
)

Set-StrictMode -Version 3.0

$downloadIntegrity = [IO.Path]::Combine($PSScriptRoot, 'Download-Integrity.ps1')
if (-not [IO.File]::Exists($downloadIntegrity)) {
    throw "The Atlas download-integrity helper is missing at '$downloadIntegrity'."
}
. $downloadIntegrity

$version = '1.9.5'

$ProgressPreference = 'SilentlyContinue'
$sys32 = [Environment]::GetFolderPath('System')
$windir = [Environment]::GetFolderPath('Windows')
$env:path = "$windir;$sys32;$sys32\Wbem;$sys32\WindowsPowerShell\v1.0;" + $env:path
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

function Pause ($message = 'Press Enter to exit') {
    if (!$NonInteractive) { $null = Read-Host $message }
}

enum LogLevel {
    Success
    Info
    Warning
    Error
    Critical
}
function Write-Status {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Text,
        [LogLevel]$Level = 'Info',
        [switch]$Exit,
        [string]$ExitString = 'Press Enter to exit',
        [int]$ExitCode = 1
    )

    $colour = @(
        'Green',
        'White',
        'Yellow',
        'Red',
        'Red'
    )[$([LogLevel].GetEnumValues().IndexOf($Level))]

    $Text -split "`n" | ForEach-Object {
        Write-Host "[$($Level.ToString().ToUpper())] $_" -ForegroundColor $colour
    }

    if ($Exit) {
        Write-Output ''
        Pause $ExitString
        exit $ExitCode
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
        Write-Status "Failed to reach Microsoft.com via web request. You must have an internet connection to reinstall Edge and its components.`n$($_.Exception.Message)" -Level Critical -Exit -ExitCode 404
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

    & takeown.exe /F "$Path" /R /D Y *> $null
    & icacls.exe "$Path" /grant '*S-1-5-32-544:(F)' /T /C *> $null
    Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $Path) {
        & cmd.exe /c rd /s /q "$Path" *> $null
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
    foreach ($service in (Get-Service -Name '*edge*' | Where-Object { $_.DisplayName -like '*Microsoft Edge*' }).Name) {
        Stop-Service -Name $service -Force
    }

    # Match only the Edge browser and update infrastructure; a bare '\Microsoft\*' would
    # also kill classic Teams, x86 Office and OneDrive. Trailing '\' stops the 'Edge' glob
    # from also matching '\Microsoft\EdgeWebView'.
    $edgePathPatterns = @()
    foreach ($programFiles in @([Environment]::GetFolderPath('ProgramFilesX86'), [Environment]::GetFolderPath('ProgramFiles'))) {
        foreach ($edgeComponent in @('Edge', 'EdgeUpdate', 'EdgeCore')) {
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
                ($_.Name -match '^(msedge|MicrosoftEdge|edgeupdate)')
            )
        }).Id
    ) {
        Stop-Process -Id $process -Force
    }
    $ErrorActionPreference = 'Continue'
}

function DisableEdgeUpdateInfrastructure {
    $serviceNames = @(
        'edgeupdate',
        'edgeupdatem',
        'MicrosoftEdgeUpdate',
        'MicrosoftEdgeElevationService'
    )

    try {
        $serviceNames += Get-CimInstance Win32_Service -ErrorAction Stop |
        Where-Object {
            ($_.Name -like '*edge*' -and $_.DisplayName -like '*Microsoft Edge*') -or
            ($_.PathName -like '*\Microsoft\EdgeUpdate\*') -or
            ($_.PathName -like '*\Microsoft\Edge\Application\*')
        } |
        Select-Object -ExpandProperty Name
    }
    catch {
        Write-Status "Failed to discover Edge services: $($_.Exception.Message)" -Level Warning
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
            Write-Status "Failed to disable Edge update service '$serviceName': $($_.Exception.Message)" -Level Warning
        }
    }

    # The update tasks can carry a GUID suffix (MicrosoftEdgeUpdateTaskMachineCore{GUID}),
    # so match by prefix - deleting only the bare names leaves orphaned tasks that fail
    # 0x80070002 every run. Remove the on-disk definitions too.
    Get-ScheduledTask -TaskName 'MicrosoftEdge*' -ErrorAction SilentlyContinue |
        Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
    Get-ChildItem -LiteralPath (Join-Path -Path ([Environment]::GetFolderPath('System')) -ChildPath 'Tasks') -Filter 'MicrosoftEdge*' -ErrorAction SilentlyContinue |
        ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
}

function Remove-EdgeRegistration {
    # Edge leaves shell registration behind after its binaries are gone: dead protocol
    # handlers (microsoft-edge:), App Paths\msedge.exe, a binary-less Apps-list Uninstall
    # row, StartMenuInternet and EdgeUpdate\Clients. Each key is removed from both the
    # 64- and 32-bit views. WebView2 keys are untouched.
    $edgeKeys = @(
        'HKLM\SOFTWARE\Microsoft\Edge'
        'HKLM\SOFTWARE\Microsoft\EdgeUpdate'
        'HKLM\SOFTWARE\Microsoft\MicrosoftEdge'
        'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{9459C573-B17A-45AE-9F64-1857B5D58CEE}'
        'HKLM\SOFTWARE\Microsoft\Internet Explorer\EdgeIntegration'
        'HKLM\SOFTWARE\Microsoft\Internet Explorer\EdgeDebugActivation'
        'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MicrosoftEdgeUpdate.exe'
        'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe'
        'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge'
        'HKLM\SOFTWARE\Clients\StartMenuInternet\Microsoft Edge'
        'HKLM\SOFTWARE\Classes\microsoft-edge'
        'HKLM\SOFTWARE\Classes\microsoft-edge-holographic'
        'HKLM\SOFTWARE\Classes\MSEdgeHTM'
        'HKLM\SOFTWARE\Classes\MSEdgeMHT'
        'HKLM\SOFTWARE\Classes\AppID\MicrosoftEdgeUpdate.exe'
        'HKCU\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\microsoft-edge'
        'HKCU\SOFTWARE\Classes\microsoft-edge'
        'HKCU\SOFTWARE\Classes\MSEdgeHTM'
    )
    foreach ($edgeKey in $edgeKeys) {
        foreach ($view in @('/reg:64', '/reg:32')) {
            & reg.exe delete "$edgeKey" /f $view *> $null
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

    Write-Status 'Requesting from the Microsoft Edge Update API...'
    try {
        try {
            $edgeUpdateApi = (Microsoft.PowerShell.Utility\Invoke-WebRequest `
                    -Uri 'https://edgeupdates.microsoft.com/api/products' `
                    -UseBasicParsing `
                    -TimeoutSec 30 `
                    -ErrorAction Stop).Content | Microsoft.PowerShell.Utility\ConvertFrom-Json
        }
        catch {
            Write-Status "Failed to request from EdgeUpdate API!
Error: $_" -Level Critical -Exit -ExitCode 4
        }

        $edgeItem = ($edgeUpdateApi | Where-Object { $_.Product -eq 'Stable' }).Releases |
            Where-Object { $_.Platform -eq 'Windows' -and $_.Architecture -eq $archString } |
            Where-Object { $_.Artifacts.Count -ne 0 } | Select-Object -First 1

        if ($null -eq $edgeItem) {
            Write-Status 'Failed to parse EdgeUpdate API! No matching artifacts found.' -Level Critical -Exit
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
        Write-Status "Failed to parse Microsoft Edge from `"$link`"!
Error: $_" -Level Critical -Exit -ExitCode 5
    }
    Write-Status 'Parsed Microsoft Edge Update API!' -Level Success

    Write-Host "`nDownloading Microsoft Edge:" -ForegroundColor Cyan
    @(
        @('Released on: ', $released),
        @('Version: ', "$version (Stable)"),
        @('Size: ', "$sizeInMb Mb")
    ) | Foreach-Object {
        Write-Host ' - ' -NoNewline -ForegroundColor Magenta
        Write-Host $_[0] -NoNewline -ForegroundColor Yellow
        Write-Host $_[1]
    }

    $stagingDirectory = $null
    $retainStaging = $false
    try {
        $stagingDirectory = New-AtlasProtectedStagingDirectory
        $msi = Join-Path -Path $stagingDirectory -ChildPath $expectedMsiName
        $msiLog = Join-Path -Path $stagingDirectory -ChildPath 'edgeMsi.log'

        Write-Output ''
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
            Write-Status "Failed to download and verify Microsoft Edge from `"$link`"!
Error: $_" -Level Critical -Exit -ExitCode 6
        }
        Write-Status 'Verified the Microsoft Edge installer hash and byte length!' -Level Success
        Write-Output ''

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
                    @{ Status = 'Installing Microsoft Edge...'; Mode = '/i'; Description = 'The Microsoft Edge installation' }
                    @{ Status = 'Repairing Microsoft Edge...'; Mode = '/fa'; Description = 'The Microsoft Edge repair' }
                )) {
                Write-Status $transaction.Status
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
                        -TimeoutSeconds 1800 `
                        -Description $transaction.Description `
                        -Hidden
                    if (-not $installerResult.ContainmentConfirmed -or
                        -not $installerResult.RootExited -or
                        -not $installerResult.JobDrained) {
                        $retainStaging = $true
                        throw "$($transaction.Description) returned without confirmed process-tree containment and drain."
                    }
                    if ($installerResult.ExitCodeUInt32 -notin @([uint32]0, [uint32]3010)) {
                        throw "$($transaction.Description) failed with exit code $($installerResult.ExitCodeUInt32)."
                    }
                }
                catch {
                    if (Test-AtlasContainedProcessContainmentUnconfirmed -Exception $_.Exception) {
                        $retainStaging = $true
                    }
                    Write-Status "Refusing to continue the Edge installer transaction.
Error: $_" -Level Critical -Exit -ExitCode 10
                }
            }
        }
        finally {
            [Environment]::SetEnvironmentVariable('TEMP', $originalTemp, 'Process')
            [Environment]::SetEnvironmentVariable('TMP', $originalTmp, 'Process')
        }

        if (!(Test-Path -LiteralPath $msiLog -PathType Leaf)) {
            Write-Status "Couldn't find installer log at `"$msiLog`"! This likely means it failed." -Level Critical -Exit -ExitCode 7
        }

        Write-Status -Text "Installer log path: `"$msiLog`" (removed after verification)"
        if (@($(Get-Content -LiteralPath $msiLog) -like '*Product: Microsoft Edge -- * completed successfully.*').Count -eq 0) {
            Write-Status "Can't find success string from Edge install log - it seems like the install was a failure." -Level Error -Exit -ExitCode 8
        }

        Write-Status -Text 'Installed Microsoft Edge!' -Level Success
    }
    finally {
        if ($retainStaging) {
            Write-Status "Retaining protected staging at '$stagingDirectory' because process containment could not be confirmed." -Level Warning
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

        Write-Status 'Downloading Edge WebView...'
        try {
            $download = Invoke-MicrosoftWebViewDownload `
                -Uri $link `
                -Destination $dlPath `
                -StagingDirectory $stagingDirectory
        }
        catch {
            Write-Status "Failed to download and verify Edge WebView from `"$link`"!
Error: $_" -Level Critical -Exit -ExitCode 9
        }

        Write-Status "Resolved the Microsoft WebView bootstrapper from '$($download.FinalUri.Host)'."
        Write-Status 'Installing Edge WebView...'
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
                -TimeoutSeconds 1800 `
                -Description 'The Edge WebView2 bootstrapper' `
                -Hidden
            if (-not $installerResult.ContainmentConfirmed -or
                -not $installerResult.RootExited -or
                -not $installerResult.JobDrained) {
                $retainStaging = $true
                throw 'The Edge WebView2 bootstrapper returned without confirmed process-tree containment and drain.'
            }
            if ($installerResult.ExitCodeUInt32 -notin @([uint32]0, [uint32]3010)) {
                throw "Installing Edge WebView failed with exit code $($installerResult.ExitCodeUInt32)."
            }
        }
        catch {
            if (Test-AtlasContainedProcessContainmentUnconfirmed -Exception $_.Exception) {
                $retainStaging = $true
            }
            Write-Status "Refusing to continue the Edge WebView installer transaction.
Error: $_" -Level Critical -Exit -ExitCode 9
        }
        finally {
            [Environment]::SetEnvironmentVariable('TEMP', $originalTemp, 'Process')
            [Environment]::SetEnvironmentVariable('TMP', $originalTmp, 'Process')
        }

        Write-Status 'Installed Edge WebView!' -Level Success
    }
    finally {
        if ($retainStaging) {
            Write-Status "Retaining protected staging at '$stagingDirectory' because process containment could not be confirmed." -Level Warning
        }
        elseif ($stagingDirectory -and (Test-Path -LiteralPath $stagingDirectory -PathType Container)) {
            Remove-Item -LiteralPath $stagingDirectory -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Deliberately self-contained (standalone script); canonical check lives in Atlas.Core\Test-AtlasAdmin.
# Running as TrustedInstaller/SYSTEM breaks parts of the removal
if ([Security.Principal.WindowsIdentity]::GetCurrent().User.Value -eq 'S-1-5-18') {
    Write-Status "This script can't be ran as TrustedInstaller/SYSTEM.
Please relaunch this script under a regular admin account." -Level Critical -Exit
}
else {
    if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        if ($PSBoundParameters.Count -le 0 -and !$args) {
            Start-Process cmd "/c PowerShell -NoP -EP RemoteSigned -File `"$PSCommandPath`"" -Verb RunAs -WindowStyle Hidden
            exit
        }
        else {
            throw 'This script must be run as an administrator.'
        }
    }
}

$edgeInstalled = EdgeInstalled
if (!$UninstallEdge -and !$InstallEdge -and !$InstallWebView) {
    $host.UI.RawUI.WindowTitle = "AtlasOS EdgeRemover"

    $continue = $false
    $RemoveEdgeData = $false
    while (!$continue) {
        Clear-Host
        $description = "This script removes or installs Microsoft Edge."
        Write-Host "$description`n" -ForegroundColor Blue
        Write-Host @"
To select an option, type its number.
To perform an action, also type its number.
"@ -ForegroundColor Yellow

        Write-Host "`nEdge is currently detected as: " -NoNewline -ForegroundColor Green
        Write-Host "$(@("Uninstalled", "Installed")[$edgeInstalled])" -ForegroundColor Cyan

        Write-Host "`n$("-" * $description.Length)" -ForegroundColor Magenta

        Write-Host "`nActions:"
        Write-Host @"
[1] Uninstall Edge
[2] Install Edge
[3] Install WebView
[4] Install both Edge & WebView
"@ -ForegroundColor Cyan

        $userInput = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

        switch ($userInput.VirtualKeyCode) {
            49 {
                # uninstall Edge (1)
                $UninstallEdge = $true
                $continue = $true
            }
            50 {
                # reinstall Edge (2)
                $InstallEdge = $true
                $continue = $true
            }
            51 {
                # reinstall WebView (3)
                $InstallWebView = $true
                $continue = $true
            }
            52 {
                # reinstall both (4)
                $InstallWebView = $true
                $InstallEdge = $true
                $continue = $true
            }
        }
    }

    Clear-Host
}

if ($UninstallEdge) {
    Write-Status 'Uninstalling Edge Chromium...'
    KillEdgeProcesses
    DisableEdgeUpdateInfrastructure

    # Kick off Edge's own uninstaller detached and DO NOT wait for it. A synchronous
    # system-level --force-uninstall runs its RestartManager phase in the live session and
    # signs the user out on 24H2/25H2; launching it detached lets the direct file deletion
    # below finish the removal first.
    foreach ($root in @(
            "$([Environment]::GetFolderPath('ProgramFilesx86'))\Microsoft\Edge\Application",
            "$([Environment]::GetFolderPath('ProgramFiles'))\Microsoft\Edge\Application"
        )) {
        if (-not (Test-Path $root)) {
            continue
        }
        foreach ($setup in @(Get-ChildItem -Path $root -Filter 'setup.exe' -Recurse -ErrorAction SilentlyContinue | Sort-Object -Property FullName -Unique)) {
            Write-Status "Launching uninstaller at '$($setup.FullName)'..."
            Start-Process -FilePath $setup.FullName -ArgumentList '--uninstall --system-level --force-uninstall' -WindowStyle Hidden -ErrorAction SilentlyContinue
        }
    }

    Start-Sleep -Seconds 3
    KillEdgeProcesses

    # Remove the Edge browser install directly. Only the browser and its update
    # infrastructure - never WebView2 (\Microsoft\EdgeWebView), which stays installed.
    foreach ($programFiles in @([Environment]::GetFolderPath('ProgramFilesX86'), [Environment]::GetFolderPath('ProgramFiles'))) {
        foreach ($folder in @('Edge', 'EdgeCore', 'EdgeUpdate')) {
            Remove-EdgePath -Path (Join-Path -Path $programFiles -ChildPath "Microsoft\$folder")
        }
    }
    Get-ChildItem -LiteralPath ([Environment]::GetFolderPath('System')) -Filter 'MicrosoftEdge*.exe' -ErrorAction SilentlyContinue | ForEach-Object {
        & takeown.exe /F "$($_.FullName)" *> $null
        & icacls.exe "$($_.FullName)" /grant '*S-1-5-32-544:(F)' /C *> $null
        Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
    }

    # Remove leftover Edge shortcuts (they now point at deleted binaries and fail to open):
    # every user's Desktop, Quick Launch and taskbar pin, plus the Public Desktop and the
    # common Start Menu.
    $edgeShortcutNames = @('edge.lnk', 'Microsoft Edge.lnk')
    $relativeShortcutDirs = @(
        'Desktop'
        'AppData\Roaming\Microsoft\Internet Explorer\Quick Launch'
        'AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar'
        'AppData\Roaming\Microsoft\Windows\Start Menu\Programs'
    )
    $profilePaths = @()
    try {
        Get-ChildItem -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ErrorAction Stop | ForEach-Object {
            $profilePath = (Get-ItemProperty -LiteralPath $_.PSPath -Name 'ProfileImagePath' -ErrorAction SilentlyContinue).ProfileImagePath
            if ($profilePath) {
                $profilePaths += $profilePath
            }
        }
    }
    catch {
        $null = $_
    }
    $shortcutDirs = @([Environment]::GetFolderPath('CommonDesktopDirectory'), [Environment]::GetFolderPath('CommonPrograms'))
    foreach ($profilePath in $profilePaths) {
        foreach ($relativeShortcutDir in $relativeShortcutDirs) {
            $shortcutDirs += (Join-Path -Path $profilePath -ChildPath $relativeShortcutDir)
        }
    }
    foreach ($shortcutDir in ($shortcutDirs | Select-Object -Unique)) {
        foreach ($edgeShortcutName in $edgeShortcutNames) {
            Remove-Item -LiteralPath (Join-Path -Path $shortcutDir -ChildPath $edgeShortcutName) -Force -ErrorAction SilentlyContinue
        }
    }

    # Drop the now-dangling Edge shell registration (protocol handlers, App Paths,
    # Apps-list Uninstall row, StartMenuInternet, EdgeUpdate clients).
    Remove-EdgeRegistration

    if (EdgeInstalled) {
        Write-Status 'Edge binaries were not fully removed. Continuing so playbook cleanup can finish.' -Level Warning
    }
    else {
        Write-Status 'Successfully removed Microsoft Edge.' -Level Success
    }

    Write-Output ""
}

if ($RemoveEdgeData) {
    KillEdgeProcesses
    DeleteIfExist "$([Environment]::GetFolderPath('LocalApplicationData'))\Microsoft\Edge"
    Write-Status 'Removed any existing Edge Chromium user data.'
    Write-Output ''
}

if ($InstallEdge) {
    InstallEdgeChromium
    Write-Output ''
}
if ($InstallWebView) {
    InstallWebView
    Write-Output ''
}

Write-Host 'Completed.' -ForegroundColor Cyan
if ($NonInteractive) { exit }
Pause
