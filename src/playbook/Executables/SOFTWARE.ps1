# ----------------------------------------------------------------------------------------------------------- #
# Software is no longer installed with a package manager anymore to be as fast and as reliable as possible.   #
# ----------------------------------------------------------------------------------------------------------- #

param (
    [switch]$Chrome,
    [switch]$Brave,
    [switch]$Firefox,
    [switch]$Toolbox
)

.\AtlasModules\initPowerShell.ps1

# ----------------------------------------------------------------------------------------------------------- #
# Shared environment detection and download policy configuration                                             #
# ----------------------------------------------------------------------------------------------------------- #

$script:isArm64 = ((Get-CimInstance -Class Win32_ComputerSystem).SystemType -match 'ARM64') -or ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')

$downloadTimeoutRaw = [Environment]::GetEnvironmentVariable('ATLAS_DOWNLOAD_TIMEOUT')
if ([string]::IsNullOrWhiteSpace($downloadTimeoutRaw)) { $downloadTimeoutRaw = '45' }
$downloadRetriesRaw = [Environment]::GetEnvironmentVariable('ATLAS_DOWNLOAD_RETRIES')
if ([string]::IsNullOrWhiteSpace($downloadRetriesRaw)) { $downloadRetriesRaw = '4' }
$downloadRetryDelayRaw = [Environment]::GetEnvironmentVariable('ATLAS_DOWNLOAD_RETRY_DELAY')
if ([string]::IsNullOrWhiteSpace($downloadRetryDelayRaw)) { $downloadRetryDelayRaw = '5' }

$script:downloadSettings = @{
    TimeoutSeconds    = [int]$downloadTimeoutRaw
    Retries           = [int]$downloadRetriesRaw
    RetryDelaySeconds = [int]$downloadRetryDelayRaw
}

$curlCommand = Get-Command -Name 'curl.exe' -ErrorAction SilentlyContinue
$script:curlPath = if ($curlCommand) { $curlCommand.Source } else { $null }

$script:msiArgs    = "/qn /quiet /norestart ALLUSERS=1 REBOOT=ReallySuppress"
$script:legacyArgs = '/q /norestart'
$script:modernArgs = "/install /quiet /norestart"

# ----------------------------------------------------------------------------------------------------------- #
# Shared helper functions used across installer routines                                                      #
# ----------------------------------------------------------------------------------------------------------- #

# helper writes progress messages for playbook logs
function Write-Step {
    param([Parameter(Mandatory)] [string]$Message)
    Write-Host $Message
}

# retry wrapper protects network operations from transient failures
function Invoke-WithRetry {
    param(
        [Parameter(Mandatory)] [scriptblock]$Script,
        [int]$Retries,
        [int]$DelaySeconds
    )

    if (-not $Retries -or $Retries -lt 1) { $Retries = 1 }
    if (-not $DelaySeconds -or $DelaySeconds -lt 1) { $DelaySeconds = 1 }

    for ($attempt = 1; $attempt -le $Retries; $attempt++) {
        try {
            return & $Script
        }
        catch {
            if ($attempt -ge $Retries) {
                throw
            }
            # give remote endpoints a breather before the next attempt
            Start-Sleep -Seconds $DelaySeconds
        }
    }
}

# ----------------------------------------------------------------------------------------------------------- #
# Hashed staging path prevents collisions when vendors reuse identical file names                              #
# ----------------------------------------------------------------------------------------------------------- #
function Get-DownloadPath {
    param(
        [Parameter(Mandatory)] [string]$Uri,
        [string]$Hint
    )

    $uriObject = [uri]$Uri
    $hashSource = [Text.Encoding]::UTF8.GetBytes($uriObject.AbsoluteUri)
    $hashBytes = [Security.Cryptography.MD5]::Create().ComputeHash($hashSource)
    $hash = [BitConverter]::ToString($hashBytes).Replace('-', '')
    $hashPrefix = $hash.Substring(0, 12)

    $fileName = $Hint
    if (-not $fileName) {
        $fileName = [IO.Path]::GetFileName($uriObject.AbsolutePath)
        if ([string]::IsNullOrWhiteSpace($fileName)) {
            $fileName = 'payload.bin'
        }
    }

    if ($fileName.Length -gt 80) {
        # favor keeping the trailing portion so version/build info remains visible
        $fileName = $fileName.Substring($fileName.Length - 80)
    }

    $basePath = if ($script:workspacePath) { $script:workspacePath } else { [IO.Path]::GetTempPath() }
    $uniquePrefix = [Guid]::NewGuid().ToString('N').Substring(0, 12)
    return Join-Path $basePath ("$uniquePrefix-$fileName")
}

# ----------------------------------------------------------------------------------------------------------- #
# Central download primitive funnels all network transfers through retry/timeout policy                        #
# ----------------------------------------------------------------------------------------------------------- #
function Invoke-Download {
    param(
        [Parameter(Mandatory)] [string]$Uri,
        [string]$Description,
        [string]$Hint,
        [switch]$Force
    )

    $destination = Get-DownloadPath -Uri $Uri -Hint $Hint

    $downloadLabel = if ($Description) { $Description } else { $Uri }

    $downloadAction = {
        Write-Step "Downloading $downloadLabel..."
        if ($script:curlPath) {
            $curlArgs = @(
                '-fL', '--silent', '--show-error',
                '--max-time', [string]$script:downloadSettings.TimeoutSeconds,
                '--retry', [string]$script:downloadSettings.Retries,
                '--retry-delay', [string]$script:downloadSettings.RetryDelaySeconds,
                '--retry-all-errors',
                '--output', $destination,
                $Uri
            )

            & $script:curlPath @curlArgs
            if ($LASTEXITCODE -ne 0) {
                throw "curl exited with code $LASTEXITCODE for $Uri."
            }
        }
        else {
            Invoke-WebRequest -Uri $Uri -OutFile $destination -UseBasicParsing -TimeoutSec $script:downloadSettings.TimeoutSeconds
        }
    }

    Invoke-WithRetry -Script $downloadAction -Retries $script:downloadSettings.Retries -DelaySeconds $script:downloadSettings.RetryDelaySeconds

    if (-not (Test-Path -LiteralPath $destination)) {
        throw "Download failed for $Uri."
    }

    $downloaded = Get-Item -LiteralPath $destination -ErrorAction SilentlyContinue
    if (-not $downloaded -or $downloaded.Length -le 0) {
        throw "Downloaded file for $Uri is empty."
    }

    return $destination
}

# ----------------------------------------------------------------------------------------------------------- #
# Workspace helpers isolate installers from polluting host directories                                         #
# ----------------------------------------------------------------------------------------------------------- #
function New-TemporaryWorkspace {
    $path = Join-Path ([IO.Path]::GetTempPath()) ("Atlas-" + [guid]::NewGuid())
    New-Item -Path $path -ItemType Directory -Force | Out-Null
    Push-Location $path
    $script:workspacePath = $path
    return $path
}

function Remove-TemporaryWorkspace {
    param([Parameter(Mandatory)] [string]$Path)
    try { Pop-Location } catch { }
    Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
    if ($script:workspacePath -and ($script:workspacePath -eq $Path)) {
        $script:workspacePath = $null
    }
}

# ----------------------------------------------------------------------------------------------------------- #
# Process wrapper hides UI and optionally waits for completion                                                 #
# ----------------------------------------------------------------------------------------------------------- #
function Invoke-SilentProcess {
    param(
        [Parameter(Mandatory)] [string]$FilePath,
        [string]$Arguments,
        [switch]$Wait
    )

    $parameters = @{
        FilePath     = $FilePath
        ArgumentList = $Arguments
        WindowStyle  = 'Hidden'
        ErrorAction  = 'Stop'
    }

    if ($Wait) { $parameters.Wait = $true }
    Start-Process @parameters
}

# ----------------------------------------------------------------------------------------------------------- #
# Generic detection pipeline lets installers skip work when software already present                           #
# ----------------------------------------------------------------------------------------------------------- #
function Test-Installed {
    param(
        [string[]]$DisplayNamePatterns,
        [scriptblock]$CustomTest,
        [string[]]$RegistryRoots
    )

    if ($CustomTest) {
        return & $CustomTest
    }

    if (-not $DisplayNamePatterns) { return $false }

    if (-not $RegistryRoots) {
        $RegistryRoots = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )
    }

    foreach ($root in $RegistryRoots) {
        $entries = Get-ItemProperty -Path $root -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName }
        foreach ($entry in $entries) {
            foreach ($pattern in $DisplayNamePatterns) {
                if ($entry.DisplayName -like $pattern) {
                    return $true
                }
            }
        }
    }

    return $false
}

# ----------------------------------------------------------------------------------------------------------- #
# Browser installers reuse shared helpers but target vendor-specific endpoints                                 #
# ----------------------------------------------------------------------------------------------------------- #
function Install-Brave {
    if (Test-Installed -DisplayNamePatterns 'Brave*') {
        Write-Step 'Brave already installed - skipping.'
        return
    }

    $architecture = if ($script:isArm64) { 'winarm64' } else { 'winx64' }
    $uri = "https://laptop-updates.brave.com/latest/$architecture"
    $installer = Invoke-Download -Uri $uri -Description 'Brave browser' -Hint "BraveSetup-$architecture.exe"

    Write-Step 'Installing Brave...'
    Invoke-SilentProcess -FilePath $installer -Arguments '/silent /install'

    Start-Sleep -Seconds 2
    while (Get-Process -Name 'BraveSetup' -ErrorAction SilentlyContinue) {
        # brave bootstrapper spawns a background installer, poll until it exits
        Start-Sleep -Seconds 2
    }

    Stop-Process -Name 'brave' -Force -ErrorAction SilentlyContinue
    Write-Step 'Brave installation complete.'
}

function Install-Firefox {
    if (Test-Installed -DisplayNamePatterns 'Mozilla Firefox*') {
        Write-Step 'Firefox already installed - skipping.'
        return
    }

    $archToken = if ($script:isArm64) { 'win64-aarch64' } else { 'win64' }
    $uri = "https://download.mozilla.org/?product=firefox-latest-ssl&os=$archToken&lang=en-US"
    $installer = Invoke-Download -Uri $uri -Description 'Firefox' -Hint "Firefox-$archToken.exe"

    Write-Step 'Installing Firefox...'
    Invoke-SilentProcess -FilePath $installer -Arguments '/S /ALLUSERS=1' -Wait
    Write-Step 'Firefox installation complete.'
}

function Install-Chrome {
    if (Test-Installed -DisplayNamePatterns 'Google Chrome*') {
        Write-Step 'Google Chrome already installed - skipping.'
        return
    }

    $archToken = if ($script:isArm64) { '_Arm64' } else { '64' }
    $uri = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise$archToken.msi"
    $installer = Invoke-Download -Uri $uri -Description 'Google Chrome' -Hint "chrome$archToken.msi"

    Write-Step 'Installing Google Chrome...'
    Invoke-SilentProcess -FilePath 'msiexec.exe' -Arguments "/i `"$installer`" $script:msiArgs" -Wait
    Write-Step 'Google Chrome installation complete.'
}

function Install-Toolbox {
    if (Test-Installed -DisplayNamePatterns 'Atlas Toolbox*') {
        Write-Step 'Atlas Toolbox already installed - skipping.'
        return
    }

    $uri = 'https://github.com/Atlas-OS/atlas-toolbox/releases/latest/download/AtlasToolbox-Setup.exe'
    $installer = Invoke-Download -Uri $uri -Description 'Atlas Toolbox' -Hint 'AtlasToolbox-Setup.exe'

    Write-Step 'Installing Atlas Toolbox...'
    Invoke-SilentProcess -FilePath $installer -Arguments '/verysilent /install /MERGETASKS="desktopicon"'
    Write-Step 'Atlas Toolbox install initiated.'
}

# ----------------------------------------------------------------------------------------------------------- #
# Thin wrapper exposes redistributable detection via the generic Test-Installed helper                         #
# ----------------------------------------------------------------------------------------------------------- #
function Test-RedistributableInstalled {
    param(
        [string[]]$Patterns,
        [string[]]$RegistryRoots,
        [scriptblock]$CustomTest
    )
    return Test-Installed -DisplayNamePatterns $Patterns -RegistryRoots $RegistryRoots -CustomTest $CustomTest
}

function Install-VcRedistributables {
    # ----------------------------------------------------------------------------------------------------------- #
    # Visual C++ Redistributables (2005-2022) follow Microsoft guidance:                                          #
    # https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist                                    #
    # ----------------------------------------------------------------------------------------------------------- #
    $packages = @(
        # 2005 legacy runtimes (extract embedded MSI)
        [pscustomobject]@{
            Name           = 'Microsoft Visual C++ 2005 Redistributable (x64)'
            Uri            = 'https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x64.exe'
            Args           = '/c /q /t:'
            ExtractsMsi    = $true
            DetectPatterns = @('Microsoft Visual C++ 2005 Redistributable (x64)*')
            RegistryRoots  = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*')
            CustomTest     = $null
        }
        [pscustomobject]@{
            Name           = 'Microsoft Visual C++ 2005 Redistributable (x86)'
            Uri            = 'https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.exe'
            Args           = '/c /q /t:'
            ExtractsMsi    = $true
            DetectPatterns = @('Microsoft Visual C++ 2005 Redistributable')
            RegistryRoots  = @('HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')
            CustomTest     = $null
        }
        # 2008 runtimes (extract embedded MSI)
        [pscustomobject]@{
            Name           = 'Microsoft Visual C++ 2008 Redistributable (x64)'
            Uri            = 'https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x64.exe'
            Args           = '/q /extract:'
            ExtractsMsi    = $true
            DetectPatterns = @('Microsoft Visual C++ 2008 Redistributable - x64*')
            RegistryRoots  = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*')
            CustomTest     = $null
        }
        [pscustomobject]@{
            Name           = 'Microsoft Visual C++ 2008 Redistributable (x86)'
            Uri            = 'https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe'
            Args           = '/q /extract:'
            ExtractsMsi    = $true
            DetectPatterns = @('Microsoft Visual C++ 2008 Redistributable - x86*')
            RegistryRoots  = @('HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')
            CustomTest     = $null
        }
        # 2010 runtimes (legacy installer switches)
        [pscustomobject]@{
            Name           = 'Microsoft Visual C++ 2010 Redistributable (x64)'
            Uri            = 'https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x64.exe'
            Args           = $script:legacyArgs
            ExtractsMsi    = $false
            DetectPatterns = @('Microsoft Visual C++ 2010  x64 Redistributable*')
            RegistryRoots  = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*')
            CustomTest     = $null
        }
        [pscustomobject]@{
            Name           = 'Microsoft Visual C++ 2010 Redistributable (x86)'
            Uri            = 'https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x86.exe'
            Args           = $script:legacyArgs
            ExtractsMsi    = $false
            DetectPatterns = @('Microsoft Visual C++ 2010  x86 Redistributable*')
            RegistryRoots  = @('HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')
            CustomTest     = $null
        }
        # 2012 runtimes (modern installer pipeline)
        [pscustomobject]@{
            Name           = 'Microsoft Visual C++ 2012 Redistributable (x64)'
            Uri            = 'https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe'
            Args           = $script:modernArgs
            ExtractsMsi    = $false
            DetectPatterns = @('Microsoft Visual C++ 2012 Redistributable (x64)*')
            RegistryRoots  = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*')
            CustomTest     = $null
        }
        [pscustomobject]@{
            Name           = 'Microsoft Visual C++ 2012 Redistributable (x86)'
            Uri            = 'https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe'
            Args           = $script:modernArgs
            ExtractsMsi    = $false
            DetectPatterns = @('Microsoft Visual C++ 2012 Redistributable (x86)*')
            RegistryRoots  = @('HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')
            CustomTest     = $null
        }
        # 2013 runtimes (High DPI / MFC updates)
        [pscustomobject]@{
            Name           = 'Microsoft Visual C++ 2013 Redistributable (x64)'
            Uri            = 'https://aka.ms/highdpimfc2013x64enu'
            Args           = $script:modernArgs
            ExtractsMsi    = $false
            DetectPatterns = @('Microsoft Visual C++ 2013 Redistributable (x64)*')
            RegistryRoots  = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*')
            CustomTest     = $null
        }
        [pscustomobject]@{
            Name           = 'Microsoft Visual C++ 2013 Redistributable (x86)'
            Uri            = 'https://aka.ms/highdpimfc2013x86enu'
            Args           = $script:modernArgs
            ExtractsMsi    = $false
            DetectPatterns = @('Microsoft Visual C++ 2013 Redistributable (x86)*')
            RegistryRoots  = @('HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')
            CustomTest     = $null
        }
        # Unified 2015-2022 runtime (supports 2015 through 2022 toolsets)
        [pscustomobject]@{
            Name           = 'Microsoft Visual C++ 2015-2022 Redistributable (x64)'
            Uri            = 'https://aka.ms/vs/17/release/vc_redist.x64.exe'
            Args           = $script:modernArgs
            ExtractsMsi    = $false
            DetectPatterns = @('Microsoft Visual C++ 2015-2022 Redistributable (x64)*')
            RegistryRoots  = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*')
            CustomTest     = $null
        }
        [pscustomobject]@{
            Name           = 'Microsoft Visual C++ 2015-2022 Redistributable (x86)'
            Uri            = 'https://aka.ms/vs/17/release/vc_redist.x86.exe'
            Args           = $script:modernArgs
            ExtractsMsi    = $false
            DetectPatterns = @('Microsoft Visual C++ 2015-2022 Redistributable (x86)*')
            RegistryRoots  = @('HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')
            CustomTest     = $null
        }
    )

    foreach ($package in $packages) {
        if (Test-RedistributableInstalled -Patterns $package.DetectPatterns -RegistryRoots $package.RegistryRoots -CustomTest $package.CustomTest) {
            # keep existing runtimes untouched instead of reinstalling them
            Write-Step ("{0} already present - skipping." -f $package.Name)
            continue
        }

        $hintName = ($package.Name -replace '\s+', '-') + '.exe'
        $installer = Invoke-Download -Uri $package.Uri -Description $package.Name -Hint $hintName
        Write-Step ("Installing {0}..." -f $package.Name)

        if ($package.ExtractsMsi) {
            $safeName = $package.Name -replace '[^\w]', '_'
            $extractionDir = Join-Path (Get-Location).Path ($safeName + '_msi')
            New-Item -Path $extractionDir -ItemType Directory -Force | Out-Null
            # older redistributables wrap real MSI payloads, so unpack them first
            Invoke-SilentProcess -FilePath $installer -Arguments ("{0}`"{1}`"" -f $package.Args, $extractionDir) -Wait

            $msiFiles = Get-ChildItem -Path $extractionDir -Filter *.msi -ErrorAction SilentlyContinue
            foreach ($msi in $msiFiles) {
                # run each MSI silently and capture output for troubleshooting
                Invoke-SilentProcess -FilePath 'msiexec.exe' -Arguments "/i `"$($msi.FullName)`" $script:msiArgs /log `"$extractionDir\install.log`"" -Wait
            }
        }
        else {
            Invoke-SilentProcess -FilePath $installer -Arguments $package.Args -Wait
        }

        Write-Step ("Finished installing {0}." -f $package.Name)
    }
}

function Install-ArchiveUtility {
    # ----------------------------------------------------------------------------------------------------------- #
    # Prefer NanaZip via Microsoft Store packaging but fall back to 7-Zip when API access fails                   #
    # ----------------------------------------------------------------------------------------------------------- #
    $nanaZipInstalled = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like '*NanaZip*' }
    if ($nanaZipInstalled) {
        Write-Step 'NanaZip already provisioned - skipping archive setup.'
        return
    }

    $nanazipAssets = @()
    try {
        $release = Invoke-WithRetry -Script { Invoke-RestMethod -Uri 'https://api.github.com/repos/M2Team/NanaZip/releases/latest' -UseBasicParsing } -Retries 3 -DelaySeconds 3
        if ($release -and $release.assets) {
            $nanazipAssets = $release.assets.browser_download_url | Where-Object { $_ -match '\.(msixbundle|xml)$' }
        }
    }
    catch {
        Write-Step "Unable to query NanaZip release API. Falling back to 7-Zip. $_"
    }

    if ($nanazipAssets.Count -ge 2) {
        $stagingPath = Join-Path (Get-Location).Path 'NanaZip'
        New-Item -ItemType Directory -Path $stagingPath -Force | Out-Null

        foreach ($asset in ($nanazipAssets | Select-Object -Unique)) {
            # download both the package and license the provisioning cmdlet expects
            $fileName = Split-Path $asset -Leaf
            $downloadPath = Invoke-Download -Uri $asset -Description "NanaZip asset $fileName" -Hint $fileName
            Copy-Item -Path $downloadPath -Destination (Join-Path $stagingPath $fileName) -Force
        }

        try {
            $packagePath = (Get-ChildItem -Path $stagingPath -Filter *.msixbundle -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
            $licensePath = (Get-ChildItem -Path $stagingPath -Filter *.xml -ErrorAction SilentlyContinue | Select-Object -First 1).FullName

            if ($packagePath -and $licensePath) {
                Write-Step 'Installing NanaZip...'
                Add-AppxProvisionedPackage -Online -PackagePath $packagePath -LicensePath $licensePath | Out-Null
                Write-Step 'NanaZip installation completed.'
                return
            }
        }
        catch {
            Write-Step "NanaZip installation failed, falling back to 7-Zip. $_"
        }
    }

    Write-Step 'Installing 7-Zip (fallback)...'
    $rootUrl = 'https://www.7-zip.org/'
    $archToken = if ($script:isArm64) { 'a/7z*-arm64.exe' } else { 'a/7z*-x64.exe' }
    $downloadPage = Invoke-WithRetry -Script { Invoke-WebRequest -Uri $rootUrl -UseBasicParsing } -Retries 3 -DelaySeconds 3
    $relativeLink = $downloadPage.Links.href | Where-Object { $_ -like $archToken } | Select-Object -First 1
    if (-not $relativeLink) {
        throw 'Unable to determine 7-Zip download link.'
    }

    $downloadUri = $rootUrl + $relativeLink
    $installer = Invoke-Download -Uri $downloadUri -Description '7-Zip' -Hint (Split-Path $relativeLink -Leaf)
    Invoke-SilentProcess -FilePath $installer -Arguments '/S' -Wait
    Write-Step '7-Zip installed.'
}

function Install-LegacyDirectX {
    # ----------------------------------------------------------------------------------------------------------- #
    # Legacy DirectX (June 2010) ensures compatibility with older games expecting deprecated runtimes             #
    # ----------------------------------------------------------------------------------------------------------- #
    $uri = 'https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe'
    $installer = Invoke-Download -Uri $uri -Description 'Legacy DirectX runtime' -Hint 'directx_Jun2010_redist.exe'
    $extractRoot = Join-Path (Get-Location).Path 'DirectX'
    New-Item -ItemType Directory -Path $extractRoot -Force | Out-Null

    Write-Step 'Extracting legacy DirectX runtimes...'
    Invoke-SilentProcess -FilePath $installer -Arguments "/q /c /t:`"$extractRoot`"" -Wait

    Write-Step 'Installing legacy DirectX runtimes...'
    $dxSetup = Join-Path $extractRoot 'DXSETUP.exe'
    Invoke-SilentProcess -FilePath $dxSetup -Arguments '/silent' -Wait
    Write-Step 'Legacy DirectX runtimes installed.'
}

# ----------------------------------------------------------------------------------------------------------- #
# Main execution path prioritizes targeted switches before baseline stack                                      #
# ----------------------------------------------------------------------------------------------------------- #
$workspace = New-TemporaryWorkspace
try {
    if ($Toolbox) {
        Install-Toolbox
        return
    }

    if ($Brave) {
        Install-Brave
        return
    }

    if ($Firefox) {
        Install-Firefox
        return
    }

    if ($Chrome) {
        Install-Chrome
        return
    }

    Write-Step 'Installing Visual C++ Redistributables...'
    Install-VcRedistributables

    Write-Step 'Ensuring archive utility is installed...'
    Install-ArchiveUtility

    Install-LegacyDirectX
}
finally {
    Remove-TemporaryWorkspace -Path $workspace
}

