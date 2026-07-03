param (
    [switch]$Chrome,
    [switch]$Brave,
    [switch]$Firefox,
    [switch]$Toolbox
)

$ErrorActionPreference = 'Stop'

$executablesRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$initScript = Join-Path -Path $executablesRoot -ChildPath 'AtlasModules\initPowerShell.ps1'
if (-not (Test-Path -LiteralPath $initScript -PathType Leaf)) {
    throw "Atlas PowerShell initialization script '$initScript' is missing."
}

. $initScript

$script:CurlTimeouts = @('--connect-timeout', '10', '--retry', '5', '--retry-delay', '0', '--retry-all-errors')
$script:MsiArgs = '/qn /quiet /norestart ALLUSERS=1 REBOOT=ReallySuppress'
$script:IsArm64 = ((Get-CimInstance -Class Win32_ComputerSystem).SystemType -match 'ARM64') -or ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
$script:TempDir = Join-Path -Path $env:TEMP -ChildPath ([guid]::NewGuid().ToString())

function Remove-AtlasTempDirectory {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir -PathType Container)) {
        Remove-Item -LiteralPath $script:TempDir -Force -Recurse -ErrorAction SilentlyContinue
    }
}

function Invoke-AtlasDownload {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][string]$Destination,
        [Parameter(Mandatory = $true)][string]$Description
    )

    Write-Output "Downloading $Description..."
    & curl.exe -LSs $Uri -o $Destination @script:CurlTimeouts
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
        throw "Downloading $Description from '$Uri' failed with exit code $LASTEXITCODE."
    }
}

function Start-AtlasInstaller {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string]$ArgumentList,
        [Parameter(Mandatory = $true)][string]$Description,
        [int[]]$SuccessExitCode = @(0)
    )

    Write-Output "Installing $Description..."
    $process = Start-Process -FilePath $FilePath -WindowStyle Hidden -ArgumentList $ArgumentList -Wait -PassThru
    if ($process.ExitCode -notin $SuccessExitCode) {
        throw "Installing $Description failed with exit code $($process.ExitCode)."
    }
}

function Start-AtlasOptionalInstaller {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string]$ArgumentList,
        [Parameter(Mandatory = $true)][string]$Description,
        [int[]]$SuccessExitCode = @(0)
    )

    try {
        Start-AtlasInstaller -FilePath $FilePath -ArgumentList $ArgumentList -Description $Description -SuccessExitCode $SuccessExitCode
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}

function Install-AtlasToolbox {
    if ($env:PATH -like '*Atlas Toolbox*') { return }
    $toolboxPath = Join-Path -Path $script:TempDir -ChildPath 'toolbox.exe'
    Invoke-AtlasDownload -Uri 'https://github.com/Atlas-OS/atlas-toolbox/releases/latest/download/AtlasToolbox-Setup.exe' -Destination $toolboxPath -Description 'Toolbox'
    Start-AtlasInstaller -FilePath $toolboxPath -ArgumentList '/verysilent /install /MERGETASKS="desktopicon"' -Description 'Toolbox'
}

function Install-BraveBrowser {
    $installerPath = Join-Path -Path $script:TempDir -ChildPath 'BraveSetup.exe'
    Invoke-AtlasDownload -Uri 'https://laptop-updates.brave.com/latest/winx64' -Destination $installerPath -Description 'Brave'
    Start-AtlasInstaller -FilePath $installerPath -ArgumentList '/silent /install' -Description 'Brave'
    Stop-Process -Name 'brave' -Force -ErrorAction SilentlyContinue
}

function Install-FirefoxBrowser {
    $firefoxArch = if ($script:IsArm64) { 'win64-aarch64' } else { 'win64' }
    $installerPath = Join-Path -Path $script:TempDir -ChildPath 'firefox.exe'
    Invoke-AtlasDownload -Uri "https://download.mozilla.org/?product=firefox-latest-ssl&os=$firefoxArch&lang=en-US" -Destination $installerPath -Description 'Firefox'
    Start-AtlasInstaller -FilePath $installerPath -ArgumentList '/S /ALLUSERS=1' -Description 'Firefox'
}

function Install-ChromeBrowser {
    $chromeArch = if ($script:IsArm64) { '_Arm64' } else { '64' }
    $installerPath = Join-Path -Path $script:TempDir -ChildPath 'chrome.msi'
    Invoke-AtlasDownload -Uri "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise$chromeArch.msi" -Destination $installerPath -Description 'Google Chrome'
    Start-AtlasInstaller -FilePath $installerPath -ArgumentList '/qn' -Description 'Google Chrome'
}

function Install-VisualCppRuntimes {
    $legacyArgs = '/q /norestart'
    $modernArgs = '/install /quiet /norestart'
    $vcredists = [ordered] @{
        'https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x64.exe'                = @('2005-x64', '/c /q /t:')
        'https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.exe'                = @('2005-x86', '/c /q /t:')
        'https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x64.exe'                = @('2008-x64', $legacyArgs)
        'https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe'                = @('2008-x86', $legacyArgs)
        'https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x64.exe'                = @('2010-x64', $legacyArgs)
        'https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x86.exe'                = @('2010-x86', $legacyArgs)
        'https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe'          = @('2012-x64', $modernArgs)
        'https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe'          = @('2012-x86', $modernArgs)
        'https://download.visualstudio.microsoft.com/download/pr/10912041/cee5d6bca2ddbcd039da727bf4acb48a/vcredist_x64.exe' = @('2013-x64', $modernArgs)
        'https://download.visualstudio.microsoft.com/download/pr/10912113/5da66ddebb0ad32ebd4b922fd82e8e25/vcredist_x86.exe' = @('2013-x86', $modernArgs)
        'https://aka.ms/vs/17/release/vc_redist.x64.exe'                                                                     = @('2015+-x64', $modernArgs)
        'https://aka.ms/vs/17/release/vc_redist.x86.exe'                                                                     = @('2015+-x86', $modernArgs)
    }

    foreach ($entry in $vcredists.GetEnumerator()) {
        $vcName = $entry.Value[0]
        $vcArgs = $entry.Value[1]
        $vcExePath = Join-Path -Path $script:TempDir -ChildPath "vcredist-$vcName.exe"
        Invoke-AtlasDownload -Uri $entry.Name -Destination $vcExePath -Description "Visual C++ Runtime $vcName"

        if ($vcArgs -match ':') {
            $msiDir = Join-Path -Path $script:TempDir -ChildPath "vcredist-$vcName"
            Start-AtlasInstaller -FilePath $vcExePath -ArgumentList ($vcArgs + '"' + $msiDir + '"') -Description "Visual C++ Runtime $vcName extractor"
            $msiPaths = @(Get-ChildItem -LiteralPath $msiDir -Filter '*.msi' -ErrorAction SilentlyContinue)
            if (-not $msiPaths) {
                Write-Output "Failed to extract MSI for $vcName, not installing."
                continue
            }
            foreach ($msi in $msiPaths) {
                $msiArguments = '/log "' + (Join-Path -Path $msiDir -ChildPath 'logfile.log') + '" /i "' + $msi.FullName + '" ' + $script:MsiArgs
                Start-AtlasOptionalInstaller -FilePath 'msiexec.exe' -ArgumentList $msiArguments -Description "Visual C++ Runtime $vcName MSI"
            }
        }
        else {
            Start-AtlasOptionalInstaller -FilePath $vcExePath -ArgumentList $vcArgs -Description "Visual C++ Runtime $vcName"
        }
    }
}

function Install-7Zip {
    $website = 'https://7-zip.org/'
    $sevenZipArch = if ($script:IsArm64) { 'arm64' } else { 'x64' }
    $installerHref = (Invoke-WebRequest $website -UseBasicParsing).Links.href | Where-Object { $_ -like "a/7z*-$sevenZipArch.exe" } | Select-Object -First 1
    if (-not $installerHref) {
        throw "Could not find a 7-Zip $sevenZipArch installer link on '$website'."
    }
    $installerPath = Join-Path -Path $script:TempDir -ChildPath '7zip.exe'
    Invoke-AtlasDownload -Uri ($website + $installerHref) -Destination $installerPath -Description '7-Zip'
    Start-AtlasInstaller -FilePath $installerPath -ArgumentList '/S' -Description '7-Zip'
}

function Install-NanaZip {
    param([string[]]$Assets)

    $nanaZipPath = New-Item -Path (Join-Path -Path $script:TempDir -ChildPath 'nanazip') -ItemType Directory -Force
    foreach ($asset in $Assets) {
        $filename = $asset -split '/' | Select-Object -Last 1
        Invoke-AtlasDownload -Uri $asset -Destination (Join-Path -Path $nanaZipPath.FullName -ChildPath $filename) -Description $filename
    }

    try {
        $appxArgs = @{
            PackagePath = (Get-ChildItem -LiteralPath $nanaZipPath.FullName -Filter '*.msixbundle' | Select-Object -First 1).FullName
            LicensePath = (Get-ChildItem -LiteralPath $nanaZipPath.FullName -Filter '*.xml' | Select-Object -First 1).FullName
        }
        Add-AppxProvisionedPackage -Online @appxArgs | Out-Null
        Write-Output 'Installed NanaZip!'
    }
    catch {
        Write-Warning "Failed to install NanaZip! Getting 7-Zip instead. $($_.Exception.Message)"
        Install-7Zip
    }
}

function Install-ArchiveTool {
    $githubApi = Invoke-RestMethod 'https://api.github.com/repos/M2Team/NanaZip/releases/latest' -ErrorAction SilentlyContinue
    $assets = @($githubApi.Assets.browser_download_url | Select-String '.xml', '.msixbundle' | Select-Object -Unique -First 2)
    $nanaZipInstalled = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like '*NanaZip*' }

    if ($nanaZipInstalled) {
        Write-Output 'NanaZip is already installed, skipping installation.'
        return
    }

    if ($assets.Count -eq 2) {
        $sevenZipRegistry = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip'
        if (Test-Path -LiteralPath $sevenZipRegistry) {
            $message = @'
Would you like to uninstall 7-Zip and replace it with NanaZip?

NanaZip is a fork of 7-Zip with an updated user interface and extra features.
'@
            if ((Read-MessageBox -Title 'Installing NanaZip - Atlas' -Body $message -Icon Question) -eq 'Yes') {
                $sevenZipUninstall = (Get-ItemProperty -Path $sevenZipRegistry -Name 'QuietUninstallString' -ErrorAction SilentlyContinue).QuietUninstallString
                if ($sevenZipUninstall) {
                    Start-AtlasInstaller -FilePath 'cmd.exe' -ArgumentList ("/c $sevenZipUninstall") -Description '7-Zip removal'
                }
                Install-NanaZip -Assets $assets
            }
            else {
                Write-Output 'Keeping existing 7-Zip installation.'
            }
        }
        else {
            Install-NanaZip -Assets $assets
        }
    }
    else {
        Write-Warning "Can't access GitHub API, downloading 7-Zip instead of NanaZip."
        Install-7Zip
    }
}

function Install-DirectXRuntime {
    $installerPath = Join-Path -Path $script:TempDir -ChildPath 'directx.exe'
    $extractPath = Join-Path -Path $script:TempDir -ChildPath 'directx'
    Invoke-AtlasDownload -Uri 'https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe' -Destination $installerPath -Description 'legacy DirectX runtimes'
    Start-AtlasInstaller -FilePath $installerPath -ArgumentList ('/q /c /t:"' + $extractPath + '"') -Description 'legacy DirectX runtime extractor'
    Start-AtlasInstaller -FilePath (Join-Path -Path $extractPath -ChildPath 'dxsetup.exe') -ArgumentList '/silent' -Description 'legacy DirectX runtimes'
}

New-Item -ItemType Directory -Path $script:TempDir -Force | Out-Null
try {
    if ($Toolbox) { Install-AtlasToolbox; return }
    if ($Brave) { Install-BraveBrowser; return }
    if ($Firefox) { Install-FirefoxBrowser; return }
    if ($Chrome) { Install-ChromeBrowser; return }

    Install-VisualCppRuntimes
    Install-ArchiveTool
    Install-DirectXRuntime
}
finally {
    Remove-AtlasTempDirectory
}
