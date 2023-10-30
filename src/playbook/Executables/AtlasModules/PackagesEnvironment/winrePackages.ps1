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
$sh = New-Object -ComObject "Wscript.Shell"

# Docs links and messages
$failedRemovalLink = 'https://docs.atlasos.net/troubleshooting-and-faq/failed-component-removal'
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
    $arguments = '-NoP -EP Unrestricted -C "& $(Join-Path $env:windir ''\AtlasModules\PackagesEnvironment\winrePackages.ps1'') -NextStartup ' `
        + $(if ($RecoveryBroken) {'-RecoveryBroken'} elseif ($SpaceFailure) {"-SpaceFailure $spaceFailure"}) + '"'
    $action = New-ScheduledTaskAction -Execute 'powershell' -Argument $arguments
    Register-ScheduledTask -TaskName 'FailedRecovery' -Action $action @taskArgs | Out-Null
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

    if ((Test-Path $failurePath) -or $RecoveryBroken) {
        $WindowTitle = 'Failed removing components - Atlas'

        if (!$RecoveryBroken) {
            Write-Warning "Running specific Windows Recovery failure message..."
            $AtlasPackagesFailure = Get-Content $failurePath
            $logPath = ($AtlasPackagesFailure -split '"')[1]
            $errorLevel = ($AtlasPackagesFailure -split '"')[3]
            
            Remove-Item $failurePath -Force

            $Message = @"
Something went wrong while removing components using Windows Recovery.

Log: $logPath
Last exit code: $errorLevel

$failedRemovalLink
"@
        } else {
            Write-Warning "Running Windows Recovery enablement failure message..."
            $Message = $genericRecoveryFailure
        }
    
        $sh.Popup($Message,0,$WindowTitle,0+48)
        exit 1
    }

    Write-Warning "No issues :)"
    pause
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

if ($DeleteBitLockerPassword) {
    if (Test-Path $bitlockerRecoveryKeyTxt) {
        Remove-Item $bitlockerRecoveryKeyTxt -Force
        exit
    }
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
        $action = New-ScheduledTaskAction -Execute 'powershell' `
                  -Argument "-EP Unrestricted -WindowStyle Hidden -NP -File `"$env:windir\AtlasModules\Scripts\components.ps1`" -DeleteBitLockerPassword"
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
    $atlasWinRE = Join-Path -Path $env:WinDir -ChildPath ("atlasWinRE." + $([System.IO.Path]::GetRandomFileName()))
} until (!(Test-Path $atlasWinRE))
New-Item -Path $atlasWinRE -Type Directory -Force | Out-Null
Mount-WindowsImage -ImagePath $fullWimPath -Index 1 -Path $atlasWinRE | Out-Null
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
[IO.File]::WriteAllLines("$atlasWinRE\Windows\System32\winpeshl.ini", @"
[LaunchApps]
%WINDIR%\System32\wscript.exe, %SYSTEMDRIVE%\atlas\startup.vbs //B
"@)
# [IO.File]::WriteAllLines("$atlasWinRE\Windows\System32\winpeshl.ini", @"
# [LaunchApps]
# %WINDIR%\System32\cmd.exe
# "@)

# Copy Atlas Package Installation Environment items
Write-Warning 'Creating package list and copying files...'
MakePackageList
Copy-Item "$atlasEnvironmentItems\*" -Destination "$atlasWinRe\atlas" -Recurse -Force

# Notify WinRE that it's package install next boot
New-Item "$deviceDrive\AtlasComponentPackageInstallation" -Force | Out-Null

# Cleanup
Write-Warning 'Cleaning up...'
Dismount-WindowsImage -Path $atlasWinRE -Save
Remove-Item $atlasWinRE -Force
if ($mountPoint) {
    mountvol "$mountPoint" /D
    if (!$?) { Remove-Item $mountPoint -Force }
}

# Boot into Windows Recovery
Write-Warning 'Restarting...'
reagentc /boottore | Out-Null
Restart-Computer