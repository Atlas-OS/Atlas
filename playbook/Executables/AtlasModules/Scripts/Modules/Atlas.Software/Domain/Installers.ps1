# Atlas.Software domain: install-time software downloads.
#
# Ported from Executables\SOFTWARE.ps1 + Internal\Software.ps1 (7-Zip/NanaZip, Visual
# C++ Runtimes, DirectX, Brave, Firefox, Chrome, Toolbox) and Executables\LIBREWOLF.ps1
# (LibreWolf + LibreWolf-WinUpdater). Sources and installer arguments are preserved
# exactly; downloads happen at install time.

function Get-AtlasSoftwareComponentMap {
    # Component -> installer function. 'SevenZip' maps to the archive-tool installer,
    # which prefers NanaZip and falls back to 7-Zip (current utilities behavior).
    return @{
        SevenZip  = 'Install-AtlasArchiveTool'
        VCRedist  = 'Install-AtlasVisualCppRuntimes'
        DirectX   = 'Install-AtlasDirectXRuntime'
        Brave     = 'Install-AtlasBraveBrowser'
        Firefox   = 'Install-AtlasFirefoxBrowser'
        LibreWolf = 'Install-AtlasLibreWolfBrowser'
        Chrome    = 'Install-AtlasChromeBrowser'
        Toolbox   = 'Install-AtlasToolbox'
    }
}

function Test-AtlasSoftwareArm64 {
    return ((Get-CimInstance -Class Win32_ComputerSystem).SystemType -match 'ARM64') -or ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
}

function Invoke-AtlasSoftwareDownload {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][string]$Destination,
        [Parameter(Mandatory = $true)][string]$Description
    )

    $curlTimeouts = @('--connect-timeout', '10', '--retry', '5', '--retry-delay', '0', '--retry-all-errors')
    Write-Host "Downloading $Description..."
    & curl.exe -LSs $Uri -o $Destination @curlTimeouts 2>&1 | Out-Host
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
        throw "Downloading $Description from '$Uri' failed with exit code $LASTEXITCODE."
    }
}

function Start-AtlasSoftwareInstaller {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string]$ArgumentList,
        [Parameter(Mandatory = $true)][string]$Description,
        [int[]]$SuccessExitCode = @(0)
    )

    Write-Host "Installing $Description..."
    $process = Start-Process -FilePath $FilePath -WindowStyle Hidden -ArgumentList $ArgumentList -Wait -PassThru
    if ($process.ExitCode -notin $SuccessExitCode) {
        throw "Installing $Description failed with exit code $($process.ExitCode)."
    }
}

function Start-AtlasSoftwareOptionalInstaller {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string]$ArgumentList,
        [Parameter(Mandatory = $true)][string]$Description,
        [int[]]$SuccessExitCode = @(0)
    )

    try {
        Start-AtlasSoftwareInstaller -FilePath $FilePath -ArgumentList $ArgumentList -Description $Description -SuccessExitCode $SuccessExitCode
    }
    catch {
        Write-AtlasLog -Level Warning -Message $_.Exception.Message
    }
}

function Install-AtlasToolbox {
    param([Parameter(Mandatory = $true)][string]$TempDir)

    if ($env:PATH -like '*Atlas Toolbox*') { return }
    $toolboxPath = Join-Path -Path $TempDir -ChildPath 'toolbox.exe'
    Invoke-AtlasSoftwareDownload -Uri 'https://github.com/Atlas-OS/atlas-toolbox/releases/latest/download/AtlasToolbox-Setup.exe' -Destination $toolboxPath -Description 'Toolbox'
    Start-AtlasSoftwareInstaller -FilePath $toolboxPath -ArgumentList '/verysilent /install /MERGETASKS="desktopicon"' -Description 'Toolbox'
}

function Install-AtlasBraveBrowser {
    param([Parameter(Mandatory = $true)][string]$TempDir)

    $installerPath = Join-Path -Path $TempDir -ChildPath 'BraveSetup.exe'
    Invoke-AtlasSoftwareDownload -Uri 'https://laptop-updates.brave.com/latest/winx64' -Destination $installerPath -Description 'Brave'
    Start-AtlasSoftwareInstaller -FilePath $installerPath -ArgumentList '/silent /install' -Description 'Brave'
    Stop-Process -Name 'brave' -Force -ErrorAction SilentlyContinue
}

function Install-AtlasFirefoxBrowser {
    param([Parameter(Mandatory = $true)][string]$TempDir)

    $firefoxArch = if (Test-AtlasSoftwareArm64) { 'win64-aarch64' } else { 'win64' }
    $installerPath = Join-Path -Path $TempDir -ChildPath 'firefox.exe'
    Invoke-AtlasSoftwareDownload -Uri "https://download.mozilla.org/?product=firefox-latest-ssl&os=$firefoxArch&lang=en-US" -Destination $installerPath -Description 'Firefox'
    Start-AtlasSoftwareInstaller -FilePath $installerPath -ArgumentList '/S /ALLUSERS=1' -Description 'Firefox'
}

function Install-AtlasChromeBrowser {
    param([Parameter(Mandatory = $true)][string]$TempDir)

    $chromeArch = if (Test-AtlasSoftwareArm64) { '_Arm64' } else { '64' }
    $installerPath = Join-Path -Path $TempDir -ChildPath 'chrome.msi'
    Invoke-AtlasSoftwareDownload -Uri "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise$chromeArch.msi" -Destination $installerPath -Description 'Google Chrome'
    Start-AtlasSoftwareInstaller -FilePath $installerPath -ArgumentList '/qn' -Description 'Google Chrome'
}

function Install-AtlasLibreWolfBrowser {
    param([Parameter(Mandatory = $true)][string]$TempDir)

    $desktop = [Environment]::GetFolderPath('Desktop')
    $startMenu = [Environment]::GetFolderPath('CommonPrograms')
    $programs = [Environment]::GetFolderPath('ProgramFiles')
    $librewolfPath = Join-Path -Path $programs -ChildPath 'LibreWolf'
    $updaterPath = Join-Path -Path $librewolfPath -ChildPath 'librewolf-winupdater'

    Write-Host 'Getting the latest LibreWolf download link'
    $gitLabId = '44042130'
    $librewolfVersion = (Invoke-RestMethod "https://gitlab.com/api/v4/projects/$gitLabId/releases")[0].Name
    if ([string]::IsNullOrEmpty($librewolfVersion)) {
        throw 'GitLab API returned nothing!'
    }
    $librewolfFileName = "librewolf-$librewolfVersion-windows-x86_64-setup.exe"
    $librewolfDownload = "https://gitlab.com/api/v4/projects/$gitLabId/packages/generic/librewolf/$librewolfVersion/$librewolfFileName"

    $outputLibrewolf = Join-Path -Path $TempDir -ChildPath $librewolfFileName
    Invoke-AtlasSoftwareDownload -Uri $librewolfDownload -Destination $outputLibrewolf -Description 'the latest LibreWolf setup'

    Write-Host 'Installing LibreWolf silently'
    Start-Process -Wait -FilePath $outputLibrewolf -ArgumentList '/S'
    if (-not (Test-Path -LiteralPath $librewolfPath)) {
        throw 'Installing LibreWolf silently failed.'
    }

    Write-Host 'Creating LibreWolf Desktop shortcut'
    New-Shortcut -Source "$librewolfPath\librewolf.exe" -Destination "$desktop\LibreWolf.lnk" -WorkingDir $librewolfPath

    Write-Host 'Getting the latest LibreWolf-WinUpdater download link'
    $librewolfUpdaterURI = 'https://codeberg.org/api/v1/repos/ltguillaume/librewolf-winupdater/releases?draft=false&pre-release=false&page=1&limit=1'
    $librewolfUpdaterDownload = (Invoke-RestMethod -Uri $librewolfUpdaterURI).Assets |
        Where-Object { $_.name -like '*.zip' } |
        Select-Object -ExpandProperty browser_download_url

    $outputLibrewolfUpdater = Join-Path -Path $TempDir -ChildPath 'librewolf-winupdater.zip'
    Invoke-AtlasSoftwareDownload -Uri $librewolfUpdaterDownload -Destination $outputLibrewolfUpdater -Description 'the latest LibreWolf WinUpdater ZIP'

    Write-Host 'Extracting Librewolf-WinUpdater'
    Expand-Archive -Path $outputLibrewolfUpdater -DestinationPath $updaterPath -Force

    Write-Host 'Adding automatic updater task'
    foreach ($user in (Get-CimInstance -ClassName Win32_UserAccount -Filter 'Disabled=False').Name) {
        $action = New-ScheduledTaskAction -Execute "$updaterPath\LibreWolf-WinUpdater.exe" -Argument '/Scheduled'
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RunOnlyIfNetworkAvailable
        $sevenHours = New-ScheduledTaskTrigger -Once -At (Get-Date -Minute 0 -Second 0).AddHours(1) -RepetitionInterval (New-TimeSpan -Hours 7)
        $atLogon = New-ScheduledTaskTrigger -AtLogOn
        $atLogon.Delay = 'PT1M'
        Register-ScheduledTask -TaskName "LibreWolf WinUpdater ($user)" -Action $action -Settings $settings -Trigger $sevenHours, $atLogon -User $user -RunLevel Highest -Force | Out-Null
    }

    Write-Host 'Adding LibreWolf WinUpdater shortcut'
    New-Shortcut -Source "$updaterPath\Librewolf-WinUpdater.exe" -Destination "$startMenu\LibreWolf\LibreWolf WinUpdater.lnk" -WorkingDir $librewolfPath
}

function Install-AtlasVisualCppRuntimes {
    param([Parameter(Mandatory = $true)][string]$TempDir)

    $msiArgs = '/qn /quiet /norestart ALLUSERS=1 REBOOT=ReallySuppress'
    $legacyArgs = '/q /norestart'
    $modernArgs = '/install /quiet /norestart'
    $vcredists = [ordered]@{
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
        $vcExePath = Join-Path -Path $TempDir -ChildPath "vcredist-$vcName.exe"
        Invoke-AtlasSoftwareDownload -Uri $entry.Name -Destination $vcExePath -Description "Visual C++ Runtime $vcName"

        if ($vcArgs -match ':') {
            $msiDir = Join-Path -Path $TempDir -ChildPath "vcredist-$vcName"
            Start-AtlasSoftwareInstaller -FilePath $vcExePath -ArgumentList ($vcArgs + '"' + $msiDir + '"') -Description "Visual C++ Runtime $vcName extractor"
            $msiPaths = @(Get-ChildItem -LiteralPath $msiDir -Filter '*.msi' -ErrorAction SilentlyContinue)
            if (-not $msiPaths) {
                Write-Host "Failed to extract MSI for $vcName, not installing."
                continue
            }
            foreach ($msi in $msiPaths) {
                $msiArguments = '/log "' + (Join-Path -Path $msiDir -ChildPath 'logfile.log') + '" /i "' + $msi.FullName + '" ' + $msiArgs
                Start-AtlasSoftwareOptionalInstaller -FilePath 'msiexec.exe' -ArgumentList $msiArguments -Description "Visual C++ Runtime $vcName MSI"
            }
        }
        else {
            Start-AtlasSoftwareOptionalInstaller -FilePath $vcExePath -ArgumentList $vcArgs -Description "Visual C++ Runtime $vcName"
        }
    }
}

function Install-Atlas7Zip {
    param([Parameter(Mandatory = $true)][string]$TempDir)

    $website = 'https://7-zip.org/'
    $sevenZipArch = if (Test-AtlasSoftwareArm64) { 'arm64' } else { 'x64' }
    $installerHref = (Invoke-WebRequest $website -UseBasicParsing).Links.href | Where-Object { $_ -like "a/7z*-$sevenZipArch.exe" } | Select-Object -First 1
    if (-not $installerHref) {
        throw "Could not find a 7-Zip $sevenZipArch installer link on '$website'."
    }
    $installerPath = Join-Path -Path $TempDir -ChildPath '7zip.exe'
    Invoke-AtlasSoftwareDownload -Uri ($website + $installerHref) -Destination $installerPath -Description '7-Zip'
    Start-AtlasSoftwareInstaller -FilePath $installerPath -ArgumentList '/S' -Description '7-Zip'
}

function Install-AtlasNanaZip {
    param(
        [Parameter(Mandatory = $true)][string]$TempDir,
        [Parameter(Mandatory = $true)][string[]]$Assets
    )

    $nanaZipPath = New-Item -Path (Join-Path -Path $TempDir -ChildPath 'nanazip') -ItemType Directory -Force
    foreach ($asset in $Assets) {
        $filename = $asset -split '/' | Select-Object -Last 1
        Invoke-AtlasSoftwareDownload -Uri $asset -Destination (Join-Path -Path $nanaZipPath.FullName -ChildPath $filename) -Description $filename
    }

    try {
        $appxArgs = @{
            PackagePath = (Get-ChildItem -LiteralPath $nanaZipPath.FullName -Filter '*.msixbundle' | Select-Object -First 1).FullName
            LicensePath = (Get-ChildItem -LiteralPath $nanaZipPath.FullName -Filter '*.xml' | Select-Object -First 1).FullName
        }
        Add-AppxProvisionedPackage -Online @appxArgs | Out-Null
        Write-Host 'Installed NanaZip!'
    }
    catch {
        Write-AtlasLog -Level Warning -Message "Failed to install NanaZip! Getting 7-Zip instead. $($_.Exception.Message)"
        Install-Atlas7Zip -TempDir $TempDir
    }
}

function Install-AtlasArchiveTool {
    param([Parameter(Mandatory = $true)][string]$TempDir)

    $githubApi = Invoke-RestMethod 'https://api.github.com/repos/M2Team/NanaZip/releases/latest' -ErrorAction SilentlyContinue
    $assets = @($githubApi.Assets.browser_download_url | Select-String '.xml', '.msixbundle' | Select-Object -Unique -First 2)
    $nanaZipInstalled = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like '*NanaZip*' }

    if ($nanaZipInstalled) {
        Write-Host 'NanaZip is already installed, skipping installation.'
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
                    Start-AtlasSoftwareInstaller -FilePath 'cmd.exe' -ArgumentList ("/c $sevenZipUninstall") -Description '7-Zip removal'
                }
                Install-AtlasNanaZip -TempDir $TempDir -Assets $assets
            }
            else {
                Write-Host 'Keeping existing 7-Zip installation.'
            }
        }
        else {
            Install-AtlasNanaZip -TempDir $TempDir -Assets $assets
        }
    }
    else {
        Write-AtlasLog -Level Warning -Message "Can't access GitHub API, downloading 7-Zip instead of NanaZip."
        Install-Atlas7Zip -TempDir $TempDir
    }
}

function Install-AtlasDirectXRuntime {
    param([Parameter(Mandatory = $true)][string]$TempDir)

    $installerPath = Join-Path -Path $TempDir -ChildPath 'directx.exe'
    $extractPath = Join-Path -Path $TempDir -ChildPath 'directx'
    Invoke-AtlasSoftwareDownload -Uri 'https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe' -Destination $installerPath -Description 'legacy DirectX runtimes'
    Start-AtlasSoftwareInstaller -FilePath $installerPath -ArgumentList ('/q /c /t:"' + $extractPath + '"') -Description 'legacy DirectX runtime extractor'
    Start-AtlasSoftwareInstaller -FilePath (Join-Path -Path $extractPath -ChildPath 'dxsetup.exe') -ArgumentList '/silent' -Description 'legacy DirectX runtimes'
}

function Install-AtlasSoftware {
    <#
    .SYNOPSIS
        Downloads and installs the given software components at install time. Each
        component failure is logged as a warning and the remaining components still
        install (matching the old one-script-per-component isolation).
    .OUTPUTS
        $true when every component installed successfully, $false otherwise.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('SevenZip', 'VCRedist', 'DirectX', 'Brave', 'Firefox', 'LibreWolf', 'Chrome', 'Toolbox')]
        [string[]]$Component
    )

    Assert-AtlasPrivilege -Administrator

    $componentMap = Get-AtlasSoftwareComponentMap
    $tempDir = Join-Path -Path $env:TEMP -ChildPath ([guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    $allSucceeded = $true
    try {
        foreach ($name in $Component) {
            try {
                Write-AtlasLog -Message "Installing software component '$name'."
                & $componentMap[$name] -TempDir $tempDir
            }
            catch {
                Write-AtlasLog -Level Warning -Message "Installing software component '$name' failed: $($_.Exception.Message)"
                $allSucceeded = $false
            }
        }
    }
    finally {
        if (Test-Path -LiteralPath $tempDir -PathType Container) {
            Remove-Item -LiteralPath $tempDir -Force -Recurse -ErrorAction SilentlyContinue
        }
    }

    return $allSucceeded
}
