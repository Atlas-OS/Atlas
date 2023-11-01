# If -DefenderOnly and -EverythingButDefender is missing, then all packages are added
param (
    [switch]$DefenderOnly,
    [switch]$EverythingButDefender,
    [switch]$NextStartup,
    [switch]$DeleteBitLockerPassword,
    [switch]$RecoveryBroken,
    [float]$SpaceFailure,
    [switch]$PlaybookInstall
)

function Test-PathOrCommand {
    param (
        [string]$Path,
        [string]$Message,
        [string]$ExitCode
    )

    function WriteError {
        Write-Host "Error: " -NoNewLine -ForegroundColor Red
        Write-Host "$message"
        exit $ExitCode
    }

    if ($Path -like "*\*") {
        if (!(Test-Path $Path)) { WriteError }
    } else {
        if (!(Get-Command $Path -EA SilentlyContinue)) { WriteError }
    }
}

# ======================================================================================================================= #
# VARIABLES                                                                                                               #
# ======================================================================================================================= #

Write-Warning "Setting variables..."

# Required paths
$requiredPaths = @{
    recoveryXML = "$env:windir\System32\Recovery\ReAgent.xml"
    atlasEnvironmentItems = "$env:windir\AtlasModules\PackagesEnvironment\recovery"
    reagentc = 'reagentc.exe'
}
foreach ($path in $requiredPaths.Keys) {
    Test-PathOrCommand -Path $($requiredPaths.$path) -Message "$($requiredPaths.$path) not found." -ExitCode 1
    New-Variable -Name $path -Value $requiredPaths.$path
}

# Scheduled Tasks
$user = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty UserName) -replace ".*\\"
$bitlockerTaskName = 'AtlasBitlockerRemovalTask'
$failCheck = 'RecoveryFailureCheck'
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$trigger = New-ScheduledTaskTrigger -AtLogon
$taskArgs = @{
    'Trigger'     = $trigger
    'Settings'    = $settings
    'User'        = $user
    'RunLevel'    = 'Highest'
    'Force'       = $true
}

# Misc
$packageListPath = "$env:windir\AtlasModules\packagesToInstall"
$failurePath = "$env:windir\System32\AtlasPackagesFailure"
# https://ss64.com/vb/popup.html
$sh = New-Object -ComObject "Wscript.Shell"
$featureStatusIndicator = "$env:windir\AtlasModules\AtlasHaventUpdatedFeaturesYet"
if ($DeleteBitLockerPassword -and (Test-Path $featureStatusIndicator)) {
    Remove-Item $featureStatusIndicator -Force -EA SilentlyContinue
    exit
}

# Docs links and messages
$failedRemovalLink = 'https://docs.atlasos.net/faq-and-troubleshooting/failed-component-removal'
$bitlockerDecryptLink = 'https://docs.atlasos.net/faq-and-troubleshooting/common-questions/decryptying-using-bitlocker'
$genericRecoveryFailure = @"
Something went wrong while trying to use Windows Recovery to remove components.

$failedRemovalLink
"@

# ======================================================================================================================= #
# FUNCTIONS                                                                                                               #
# ======================================================================================================================= #
function MakePackageList {
    $packageList = (Get-ChildItem "$env:windir\AtlasModules\Packages\*.cab").FullName -replace "$env:systemdrive\\", ''
    if ($DefenderOnly) {
        Write-Warning "Making package list only with Defender...."
        $packageList = $packageList | Where-Object { $_ -like '*NoDefender*' }
    } elseif ($EverythingButDefender) {
        Write-Warning "Making package list without Defender...."
        $packageList = $packageList | Where-Object { $_ -notlike '*NoDefender*' }
    } else {
        Write-Warning "Making package list with everything...."
    }
    if ($packageList.GetType().IsArray) {
        $packageList += 'dismCleanup'
    } else {
        $packageList = @($packageList, 'dismCleanup')
    }
    [IO.File]::WriteAllLines($packageListPath, $packageList)
}

function MakeLogDirectory {
    $global:logDirectory = $null
    if ($SafeMode) {$folder = 'AtlasSafeMode'} else {$folder = 'AtlasPreWinRE'}

    do {
        $logDirectory = "$rootLogDirectory\$($logNumCount++)-$folder-$((Get-Date).ToShortDateString() -replace '[^0-9]','-')"
        if (!(Test-Path $logDirectory)) {
            New-Item $logDirectory -ItemType Directory -Force
            $global:logDirectory = $logDirectory
        }
    } until ($global:logDirectory)
}

function PauseNul ($message = "Press any key to exit... ") {
	Write-Host $message -NoNewLine
	$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
}

function FatalError ($recoveryError) {
    $null = $sh.Popup($recoveryError,20,'Components Error - Atlas',0+48)
}

function NoDiskSpaceError ($space) {
    FatalError @"
You need more than $space GB of free disk space for Atlas' component removals to work.

Without this, you won't be able to use disable Defender, remove telemetry and have Atlas do other removals.

This is an unsupported state.

$failedRemovalLink
"@
    exit 1
}

function StartupTask ($RecoveryBroken, $SpaceFailure) {
    $arguments = '/c powershell -NoP -EP Unrestricted -WindowStyle Hidden -C "& $(Join-Path $env:windir ''\AtlasModules\PackagesEnvironment\winrePackages.ps1'') -NextStartup ' `
        + $(if ($RecoveryBroken) {'-RecoveryBroken'} elseif ($SpaceFailure) {"-SpaceFailure $spaceFailure"}) `
        + $(if ($PlaybookInstall) {'-PlaybookInstall'}) + '"'
    $action = New-ScheduledTaskAction -Execute 'cmd' -Argument $arguments
    Register-ScheduledTask -TaskName $failCheck -Action $action @taskArgs | Out-Null
    if ($RecoveryBroken -or $SpaceFailure) { exit 1 }
}

# ======================================================================================================================= #
# Next startup error                                                                                                      #
# ======================================================================================================================= #
if ($NextStartup) {
    if ($spaceFailurePath) {
        Write-Warning "Running disk space failure message..."
        NoDiskSpaceError $(Get-Content $spaceFailurePath -Raw)
    }

    if ($PlaybookInstall) {
        Start-Job -Name FinalizingPopup -ScriptBlock {
            (New-Object -ComObject "Wscript.Shell").Popup(`
            @'
Atlas is finalizing the installation by enabling and disabling Windows features. Once completed, your computer will automatically restart.

This should take 2-15 minutes depending on your internet connection and computer speed.

Ideally don't use your computer until it's completed.
'@,0,'Finalizing Installation - Atlas',0+64)
        }

        # Disable legacy software for security reasons and them mostly being bloat
        if ([System.Environment]::OSVersion.Version.Build -lt 20000) {
            Disable-WindowsOptionalFeature -Online -FeatureName "Internet-Explorer-Optional-amd64" -NoRestart
        }
        Disable-WindowsOptionalFeature -Online -FeatureName "MicrosoftWindowsPowerShellV2" -NoRestart
        Disable-WindowsOptionalFeature -Online -FeatureName "MicrosoftWindowsPowerShellV2Root" -NoRestart

        # Disable printing features
        Disable-WindowsOptionalFeature -Online -FeatureName "Printing-Foundation-Features" -NoRestart
        Disable-WindowsOptionalFeature -Online -FeatureName "Printing-Foundation-InternetPrinting-Client" -NoRestart
        Disable-WindowsOptionalFeature -Online -FeatureName "Printing-XPSServices-Features" -NoRestart

        # Enable features for compatibility
        Enable-WindowsOptionalFeature -Online -FeatureName "DirectPlay" -All -NoRestart
        Enable-WindowsOptionalFeature -Online -FeatureName "NetFx3" -All -NoRestart

        # Indiciate to the BitLocker section that it should be ran 
        Remove-Item $featureStatusIndicator -Force -EA SilentlyContinue

        $PlaybookInstall = $false
        if ($RecoveryBroken) {
            StartupTask $true
        } elseif ($SpaceFailure) {
            StartupTask $false $true
        } else {
            StartupTask
        }
        Restart-Computer
        exit
    }

    if ((Test-Path $failurePath) -or $RecoveryBroken) {
        $WindowTitle = 'Failed removing components - Atlas'

        if (!$RecoveryBroken) {
            Write-Warning "Running specific Windows Recovery failure message..."
            Unregister-ScheduledTask -TaskName $failCheck -Confirm:$false | Out-Null
            $AtlasPackagesFailure = Get-Content $failurePath
            $logPath = ($AtlasPackagesFailure -split '"')[1] -replace [regex]::Escape($env:windir), '%windir%'
            $errorLevel = ($AtlasPackagesFailure -split '"')[3]
            
            Remove-Item $failurePath -Force

            $Message = @"
Something went wrong while removing components using Windows Recovery.

Log: $logPath
Exit code: $errorLevel

$failedRemovalLink
"@
        } else {
            Write-Warning "Running Windows Recovery enablement failure message..."
            $Message = $genericRecoveryFailure
        }
    
        $sh.Popup($Message,0,$WindowTitle,0+48)
        Start-Process $failedRemovalLink
        exit 1
    }
    exit
}

# ======================================================================================================================= #
# Windows Recovery modification                                                                                           #
# ======================================================================================================================= #

# Playbook insall
if ($PlaybookInstall) {
    Write-Warning 'Setting startup task due to $PlaybookInstall...'
    StartupTask
}

try {
    # Initial BCD values
    Write-Warning 'Initial Windows Recovery variables...'
    $recoveryBCD = $([xml]$(Get-Content -Path $recoveryXML)).WindowsRE.WinreBCD.id
    $bcdeditRecoveryOutput = bcdedit /enum "$recoveryBCD" | Select-String 'device' | Select-Object -First 1
    $deviceDrive = ($bcdeditRecoveryOutput -split '\]' -split '\[')[1]
    $winrePath = ($bcdeditRecoveryOutput -split '\]' -split ',')[1]

    # Enable Windows Recovery
    # Does nothing if it's already enabled
    Write-Warning 'Enabling WinRE...'
    reagentc /enable | Out-Null
    if (!$? -and $PlaybookInstall) {
        Write-Warning 'Failed enabling WinRE, exiting due to $PlaybookInstall...'
        StartupTask $true
    } elseif (!$?) {
        Write-Warning 'Failed enabling WinRE, displaying error...'
        FatalError @"
Something went wrong while trying to enable Windows Recovery for component removal.

$failedRemovalLink
"@

        Start-Process $failedRemovalLink
        exit 1
    }

    # If WinRE is on Recovery partition, mount it
    if ($deviceDrive -notlike '*:*') {
        Write-Warning 'Detected Windows Recovery partition...'
        $recoveryPartition = $true

        Write-Warning 'Getting WinRE partition ID...'
        $Kernel32 = Add-Type -Name 'Kernel32' -Namespace '' -PassThru -MemberDefinition @"
            [DllImport("kernel32")]
            public static extern int QueryDosDevice(string name, System.Text.StringBuilder path, int pathMaxLength);
"@; $DevicePath = [System.Text.StringBuilder]::new(255)
        $recoveryID = Get-Volume | ForEach-Object {
            $UniqueId = $_.UniqueId.TrimStart('\\?\').TrimEnd('\')
            $Kernel32::QueryDosDevice($UniqueId, $DevicePath, $DevicePath.Capacity) | Out-Null
            [PSCustomObject]@{
                DevicePath = $DevicePath.ToString()
                UniqueId = $_.UniqueId
            }
        } | Where-Object { $_.DevicePath -eq $deviceDrive } | Select-Object -ExpandProperty UniqueId

        # Create mount point
        Write-Warning 'Creating mount point...'
        do {
            $mountPoint = Join-Path -Path $env:WinDir -ChildPath ("atlasRecovery." + $([System.IO.Path]::GetRandomFileName()))
        } until (!(Test-Path $mountPoint))
        if (-Not (Test-Path $mountPoint)) { New-Item -Path $mountPoint -Type Directory -Force | Out-Null }
        mountvol $mountPoint $recoveryID | Out-Null
        if (!$? -and $PlaybookInstall) {
            Write-Warning 'Failed mounting WinRE partition, exiting silently due to $PlaybookInstall...'
            StartupTask $true
        } elseif (!$?) {
            Write-Warning 'Failed mounting WinRE partition, displaying mesage...'
            $null = $sh.Popup($genericRecoveryFailure,0,$WindowTitle,0+16)
            Start-Process $failedRemovalLink
            exit
        }
        $deviceDrive = $mountPoint
    }

    $fullWimPath = "$deviceDrive\$winrePath"
    $bitlockerRecoveryKeyTxt = "$mountPoint\bitlockerAtlas.txt"
    $componentInstallationIndicator = "$deviceDrive\AtlasComponentPackageInstallation"

    if ($DeleteBitLockerPassword) {
        Write-Warning "Deleting BitLocker password..."
        $ErrorActionPreference = 'SilentlyContinue'
        Remove-Item $bitlockerRecoveryKeyTxt -Force
        Remove-Item $componentInstallationIndicator -Force
        $ErrorActionPreference = 'Continue'
        Unregister-ScheduledTask -TaskName $bitlockerTaskName -Confirm:$false | Out-Null
        exit
    }

    # Storage space check
    $wimSize = (Get-WindowsImage -ImagePath $fullWimPath -Index 1).ImageSize
    if ($wimSize -gt (Get-PSDrive ($env:systemdrive -replace ':','') | Select-Object -ExpandProperty Free)) {
        $spaceNeeded = $([math]::round($wimSize /1Gb, 3) * 2)
        if (!$PlaybookInstall) {
            Write-Warning 'Not enough storage space, displaying mesage...'
            NoDiskSpaceError $spaceNeeded
        } else {
            Write-Warning 'Not enough storage space, silently exiting...'
            StartupTask $false $spaceNeeded
        }
        exit 1
    }

    # Save BitLocker password for use in WinRE
    # It's deleted next reboot
    $bitlockerVolume = Get-BitLockerVolume -MountPoint $env:systemdrive
    if ($bitlockerVolume.ProtectionStatus -eq 'On') {
        Write-Warning 'BitLocker detected...'
        $bitlockerRecoveryKey = ($bitlockerVolume.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }).RecoveryPassword

        if ($recoveryPartition) {
            Write-Warning 'Writing BitLocker key to WinRE partition...'
            [IO.File]::WriteAllLines($bitlockerRecoveryKeyTxt, $bitlockerRecoveryKey)
            if ($PlaybookInstall) {
                New-Item $featureStatusIndicator -Force | Out-Null
            }
            $action = New-ScheduledTaskAction -Execute 'cmd' `
                    -Argument '/c powershell -EP Unrestricted -WindowStyle Hidden -NP & $(Join-Path $env:windir ''\AtlasModules\PackagesEnvironment\winrePackages.ps1'') -DeleteBitLockerPassword'
            Register-ScheduledTask -TaskName $bitlockerTaskName -Action $action @taskArgs | Out-Null
        } else {
            if (!$? -and $PlaybookInstall) {
                Write-Warning 'No WinRE partition with BitLocker, failing silently...'
                StartupTask $true
            } elseif (!$?) {
                Write-Warning 'No WinRE partition with BitLocker, displaying message...'
                $null = $sh.Popup(@"
A BitLocker install with Windows Recovery on the system drive was detected.

You need to decrypt your drive.

$failedRemovalLink
"@,0,$WindowTitle,0+16)
                Start-Process $bitlockerDecryptLink
                exit 1
            }
        }
    }

    # Mount the Recovery WIM
    Write-Warning 'Mounting WinRE WIM...'
    do {
        $atlasWinreWim = Join-Path -Path $env:WinDir -ChildPath ("atlasWinreWim." + $([System.IO.Path]::GetRandomFileName()))
    } until (!(Test-Path $atlasWinreWim))
    New-Item -Path $atlasWinreWim -Type Directory -Force | Out-Null
    Mount-WindowsImage -ImagePath $fullWimPath -Index 1 -Path $atlasWinreWim | Out-Null
    if (!$? -and $PlaybookInstall) {
        Write-Warning 'No WinRE partition with BitLocker, failing silently...'
        StartupTask $true
    } elseif (!$?) {
        Write-Warning 'No WinRE partition with BitLocker, displaying message...'
        $null = $sh.Popup(@"
A BitLocker install with Windows Recovery on the system drive was detected.

You need to decrypt your drive.

$failedRemovalLink
"@,0,$WindowTitle,0+16)
        Start-Process $bitlockerDecryptLink
        exit 1
    }

    # Set startup application
    # https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/winpeshlini-reference-launching-an-app-when-winpe-starts
    Write-Warning 'Setting startup application...'
    [IO.File]::WriteAllLines("$atlasWinreWim\Windows\System32\winpeshl.ini", @"
[LaunchApps]
%WINDIR%\System32\wscript.exe, %SYSTEMDRIVE%\atlas\startup.vbs //B
"@)
    # [IO.File]::WriteAllLines("$atlasWinreWim\Windows\System32\winpeshl.ini", @"
# [LaunchApps]
# %WINDIR%\System32\cmd.exe
# "@)

    # Copy Atlas Package Installation Environment items
    Write-Warning 'Creating package list and copying files...'
    MakePackageList
    Copy-Item "$atlasEnvironmentItems\*" -Destination "$atlasWinreWim\atlas" -Recurse -Force

    # Notify WinRE that it's package install next boot
    New-Item $componentInstallationIndicator -Force | Out-Null

    # Boot into Windows Recovery
    reagentc /boottore | Out-Null
    if (!$PlaybookInstall) { $restart = $true }
} finally {
    Write-Warning 'Cleaning up...'
    if ((Test-Path "$atlasWinreWim\Windows") -and $atlasWinreWim) {
        Dismount-WindowsImage -Path $atlasWinreWim -Save
        if (!$? -and $PlaybookInstall) {
            Write-Warning 'Failed to save WinRE image, silently failing...'
            StartupTask $true
        } elseif (!$?) {
            Write-Warning 'Failed to save WinRE image, displaying message...'
            $null = $sh.Popup(@"
Failed to save the Windows Recovery image, see the documentation below.

$failedRemovalLink
"@,0,'Component failure - Atlas',0+16)
            Start-Process $failedRemovalLink
            exit 1
        }
        Remove-Item $atlasWinreWim -Force
    }
    if ($mountPoint) {
        mountvol "$mountPoint" /D
        if ($?) { Remove-Item $mountPoint -Force }
    }
}

if ($restart) {
    Write-Warning 'Restarting...'
    Restart-Computer
}