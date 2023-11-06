param (
    [string]$LogPath,
    [switch]$NextStartup,
    [switch]$DeleteBitLockerPassword
)

if ((Get-WmiObject -Class Win32_ComputerSystem).SystemType -match '*ARM64*') {
    Write-Host "This script is not supported on ARM64." -ForegroundColor Yellow
    pause
}

# Task Scheduler is needed for this script to function correctly
if ((Get-Service -Name 'Schedule' -EA SilentlyContinue).Status -ne 'Running') {
    Set-Service -Name 'Schedule' -StartupType Automatic
    Start-Service -Name 'Schedule'
}

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

function Write-Log {
    $args | Out-File "$LogPath" -Append -Force
}

function Write-Info {
    param (
        [string]$Text,
        [switch]$NewLine,
        [switch]$UseError
    )

    if ($UseError) {
        Write-Host "ERROR: " -NoNewLine -ForegroundColor Red
    } else {
        Write-Host "INFO: " -NoNewLine -ForegroundColor Blue
    }
    Write-Host "$Text"

    if ($NewLine) { Write-Host "" }
    if ($LogPath) {
        Write-Log "$Text"
    }
}

# ======================================================================================================================= #
# VARIABLES                                                                                                               #
# ======================================================================================================================= #

Write-Info -Text "Setting variables..."

# Required paths
$requiredPaths = @{
    recoveryXML = "$env:windir\System32\Recovery\ReAgent.xml"
    modules = "$env:windir\AtlasModules"
    atlasEnvironmentItems = "$env:windir\AtlasModules\PackagesEnvironment\recovery"
    atlasWinrePackages = "$env:windir\AtlasModules\winrePackagesToInstall"
    reagentc = 'reagentc.exe'
}
foreach ($path in $requiredPaths.Keys) {
    Test-PathOrCommand -Path $($requiredPaths.$path) -Message "$($requiredPaths.$path) not found." -ExitCode 1
    New-Variable -Name $path -Value $requiredPaths.$path
}

# Scheduled Tasks
$user = (Get-CimInstance -ClassName Win32_ComputerSystem).UserName -replace ".*\\"
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
$failurePath = "$env:windir\System32\AtlasPackagesFailure"
# https://ss64.com/vb/popup.html
$sh = New-Object -ComObject "Wscript.Shell"

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

function StartupTask {
    $arguments = '/c title Finalizing installation - Atlas & echo Do not close this window. & schtasks /delete /tn "RecoveryFailureCheck" /f > nul & ' `
        + 'powershell -NoP -EP Unrestricted -WindowStyle Hidden -C "& $(Join-Path $env:windir ''\AtlasModules\PackagesEnvironment\winrePackages.ps1'') -NextStartup"'
    $action = New-ScheduledTaskAction -Execute 'cmd' -Argument $arguments
    Register-ScheduledTask -TaskName $failCheck -Action $action @taskArgs | Out-Null
}

# ======================================================================================================================= #
# Next startup error                                                                                                      #
# ======================================================================================================================= #
if ($NextStartup -and (Test-Path $failurePath)) {
    $WindowTitle = 'Failed removing components - Atlas'

    Write-Info -Text "Running specific Windows Recovery failure message..." -UseError
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
    
    $sh.Popup($Message,0,$WindowTitle,0+48)
    Start-Process $failedRemovalLink
    exit 1
} elseif ($NextStartup) { exit }

# ======================================================================================================================= #
# Windows Recovery modification                                                                                           #
# ======================================================================================================================= #

try {
    # Initial BCD values
    Write-Info -Text 'Initial Windows Recovery variables...'
    $recoveryBCD = $([xml]$(Get-Content -Path $recoveryXML)).WindowsRE.WinreBCD.id
    $bcdeditRecoveryOutput = bcdedit /enum "$recoveryBCD" | Select-String 'device' | Select-Object -First 1
    $deviceDrive = ($bcdeditRecoveryOutput -split '\]' -split '\[')[1]
    $winrePath = ($bcdeditRecoveryOutput -split '\]' -split ',')[1]

    # Enable Windows Recovery
    # Does nothing if it's already enabled
    Write-Info -Text 'Enabling WinRE...'
    reagentc /enable | Out-Null
    if (!$?) {
        Write-Info -Text 'Failed enabling WinRE, displaying error...' -UseError
        FatalError @"
Something went wrong while trying to enable Windows Recovery for component removal.

$failedRemovalLink
"@

        Start-Process $failedRemovalLink
        exit 1
    }

    # If WinRE is on Recovery partition, mount it
    if ($deviceDrive -notlike '*:*') {
        Write-Info -Text 'Detected Windows Recovery partition...'
        $recoveryPartition = $true

        Write-Info -Text 'Getting WinRE partition ID...'
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
        Write-Info -Text 'Creating mount point...'
        do {
            $mountPoint = Join-Path -Path $env:WinDir -ChildPath ("atlasRecovery." + $([System.IO.Path]::GetRandomFileName()))
        } until (!(Test-Path $mountPoint))
        if (-Not (Test-Path $mountPoint)) { New-Item -Path $mountPoint -Type Directory -Force | Out-Null }
        mountvol $mountPoint $recoveryID | Out-Null
        if (!$?) {
            Write-Info -Text 'Failed mounting WinRE partition, displaying mesage...' -UseError
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
        Write-Info -Text "Deleting BitLocker password..."
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
        Write-Info -Text 'Not enough storage space, displaying mesage...' -UseError
        NoDiskSpaceError $spaceNeeded
        exit 1
    }

    # Save BitLocker password for use in WinRE
    # It's deleted next reboot
    $bitlockerVolume = Get-BitLockerVolume -MountPoint $env:systemdrive
    if ($bitlockerVolume.ProtectionStatus -eq 'On') {
        Write-Info -Text 'BitLocker detected...'
        $bitlockerRecoveryKey = ($bitlockerVolume.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }).RecoveryPassword

        if ($recoveryPartition) {
            Write-Info -Text 'Writing BitLocker key to WinRE partition...'
            [IO.File]::WriteAllLines($bitlockerRecoveryKeyTxt, $bitlockerRecoveryKey)
            $action = New-ScheduledTaskAction -Execute 'cmd' `
                    -Argument '/c schtasks /delete /tn "AtlasBitlockerRemovalTask" /f > nul & powershell -EP Unrestricted -WindowStyle Hidden -NoP & $(Join-Path $env:windir ''\AtlasModules\PackagesEnvironment\winrePackages.ps1'') -DeleteBitLockerPassword'
            Register-ScheduledTask -TaskName $bitlockerTaskName -Action $action @taskArgs | Out-Null
        } else {
            if (!$?) {
                Write-Info -Text 'No WinRE partition with BitLocker, displaying message...' -UseError
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
    Write-Info -Text 'Mounting WinRE WIM...'
    do {
        $atlasWinreWim = Join-Path -Path $env:WinDir -ChildPath ("atlasWinreWim." + $([System.IO.Path]::GetRandomFileName()))
    } until (!(Test-Path $atlasWinreWim))
    New-Item -Path $atlasWinreWim -Type Directory -Force | Out-Null
    Mount-WindowsImage -ImagePath $fullWimPath -Index 1 -Path $atlasWinreWim | Out-Null
    if (!$?) {
        Write-Info -Text 'No WinRE partition with BitLocker, displaying message...' -UseError
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
    Write-Info -Text 'Setting startup application...'
    [IO.File]::WriteAllLines("$atlasWinreWim\Windows\System32\winpeshl.ini", @"
[LaunchApps]
%WINDIR%\System32\wscript.exe, %SYSTEMDRIVE%\atlas\startup.vbs //B
"@)
    # [IO.File]::WriteAllLines("$atlasWinreWim\Windows\System32\winpeshl.ini", @"
# [LaunchApps]
# %WINDIR%\System32\cmd.exe
# "@)

    # Copy Atlas Package Installation Environment items
    Write-Info -Text 'Copying files...'
    Copy-Item "$atlasEnvironmentItems\*" -Destination "$atlasWinreWim\atlas" -Recurse -Force    

    # Notify WinRE that it's package install next boot
    New-Item $componentInstallationIndicator -Force | Out-Null

    # Set startup task
    StartupTask
    
    # Boot into Windows Recovery
    reagentc /boottore | Out-Null
} finally {
    Write-Info -Text 'Cleaning up...'
    if ((Test-Path "$atlasWinreWim\Windows") -and $atlasWinreWim) {
        Dismount-WindowsImage -Path $atlasWinreWim -Save | Out-Null
        if (!$?) {
            Write-Info -Text 'Failed to save WinRE image, displaying message...' -UseError
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

Write-Info -Text 'Restarting...'
Restart-Computer