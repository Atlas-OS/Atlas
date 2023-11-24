#Requires -RunAsAdministrator

param (
    [switch]$DefenderOnly,
    [switch]$EverythingButDefender,
    [switch]$PlaybookInstall,
    [switch]$Verbose,
    [switch]$WinRE
)

$ProgressPreference = 'SilentlyContinue'
if ($PlaybookInstall) { $Verbose = $true }

# ======================================================================================================================= #
# FUNCTIONS                                                                                                               #
# ======================================================================================================================= #
function PauseNul ($message = "Press any key to exit... ") {
	Write-Host $message -NoNewLine
	$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
}

function SafeMode {
    param (
        [switch]$Enable
    )

    if ($Enable) {
        $bcdeditArgs = '/set {current} safeboot minimal'
        $shellValue = "PowerShell -NoP -EP Bypass -File `"$envPath\centralScript.ps1`" $arguments"
    } else {
        $bcdeditArgs = '/deletevalue {current} safeboot'
        $shellValue = 'explorer.exe'
    }

    Start-Process -File 'bcdedit' -ArgumentList $bcdeditArgs -WindowStyle Hidden
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name Shell -Value $shellValue -Force
}

function Restart {
	shutdown /f /r /t 0 *>$null
    Start-Sleep 2
    Restart-Computer
    Start-Sleep 2
    Write-Host "Something seems to have went wrong restarting automatically, restart manually." -ForegroundColor Red
    PauseNul
    exit
}

function Write-Log {
    $args | Out-File "$sessionLogDirectory\onlineSxsLog.log" -Append -Force
}

function Write-Info {
    param (
        [string]$Text,
        [switch]$NewLine,
        [switch]$UseError,
        [switch]$DisplayAlways
    )

    if ($Verbose -or $DisplayAlways) {
        if ($UseError) {
            Write-Host "ERROR: " -NoNewLine -ForegroundColor Red
        } else {
            Write-Host "INFO: " -NoNewLine -ForegroundColor Blue
        }
        Write-Host "$Text"
    }

    if ($NewLine) { Write-Host "" }
    Write-Log "$Text"
}

# ======================================================================================================================= #
# VARIABLES                                                                                                               #
# ======================================================================================================================= #
$arm = ((Get-WmiObject -Class Win32_ComputerSystem).SystemType -match 'ARM64') -or ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
$modules = "$env:windir\AtlasModules"

# Create log folder
$atlasLogDirectory = "$modules\Logs"
if (!(Test-Path $atlasLogDirectory)) { New-Item -Path $atlasLogDirectory -Force -ItemType Directory | Out-Null }
do {
    $sessionLogDirectory = "$atlasLogDirectory\$($num++; $num)-AtlasOnlinePackageInstall-$((Get-Date).ToString('dd-MM-yyyy'))"
} until (!(Test-Path $sessionLogDirectory))
New-Item -Path $sessionLogDirectory -Force -ItemType Directory | Out-Null

$envPath = "$modules\PackagesEnvironment"
$useWinreIndicator = "$envPath\AtlasUseWindowsRecovery"
$safeModePackageList = "$modules\safeModePackagesToInstall"
$winrePackageList = "$modules\winrePackagesToInstall"
$safeMode = (Get-WmiObject Win32_ComputerSystem).BootupState -ne 'Normal boot'
$safeModeWithList = $safeMode -and (Test-Path $safeModePackageList)
if ($safeModeWithList) { SafeMode }

# ======================================================================================================================= #
# PACKAGE LIST                                                                                                            #
# ======================================================================================================================= #
if (!$safeModeWithList) {
    $packageList = (Get-ChildItem "$env:windir\AtlasModules\Packages\*.cab").FullName | Where-Object {$_ -like "*$(if ($arm) {'arm64'} else {'amd64'})*"}

    if ($DefenderOnly) {
        $packageList = $packageList | Where-Object { $_ -like '*NoDefender*' }
    } elseif ($EverythingButDefender) {
        $packageList = $packageList | Where-Object { $_ -notlike '*NoDefender*' }
    }
} else {
    $packageList = Get-Content $safeModePackageList
}

foreach ($a in $packageList) {
    Write-Info -Text "Package $($num1++; $num1) - `"$a`""
}; Write-Log " "

if ($Verbose) { Write-Host "" }

# ======================================================================================================================= #
# Fallbacks                                                                                                               #
# ======================================================================================================================= #
if ($WinRE) {
    if (Test-Path $useWinreIndicator) {
        Remove-Item $useWinreIndicator -Force
    } else {
        exit
    }

    Write-Host ''
    & "$envPath\winrePackages.ps1" -LogPath "$sessionLogDirectory\winreSetup.log"
    Restart
}

if ($SafeMode) {
    Write-Info "Installing component removal packages that failed previously in normal boot..." -DisplayAlways -NewLine
}

# ======================================================================================================================= #
# online-sxs                                                                                                              #
# ======================================================================================================================= #
$failedPackages = @()
foreach ($package in $packageList) {
    $packageName = (Get-Item $package).Basename
    Write-Info -Text "Installing $packageName with online-sxs..."
    $onlineSxsOutput = & "$envPath\onlineSxs.ps1" "$package" *>&1
    if (!$?) {
        $failedPackages += $package
        if (!$safeModeWithList) {
            Write-Info "Failed to install $packageName, will try safe mode after completion..." -UseError
        } else {
            Write-Info "Failed to install $packageName, will try in WinRE..." -UseError
        }
    } else {
        Write-Info "Installed $packageName..."
    }

    if ($Verbose) {
        foreach ($a in $onlineSxsOutput) {Write-Host $a -ForegroundColor Cyan}
    }
    Write-Log $onlineSxsOutput
}

if ($failedPackages.Count -ne 0) {
    if (!$safeMode) {
        SafeMode -Enable
        $failedPackages | Out-File $safeModePackageList

        $safeModeStartupTitle = 'AtlasSafeModeComponentCheck'
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries; $trigger = New-ScheduledTaskTrigger -AtLogon
        $taskArgs = @{
            'Trigger'     = $trigger
            'Settings'    = $settings
            'User'        = $((Get-CimInstance -ClassName Win32_ComputerSystem).UserName -replace ".*\\")
            'RunLevel'    = 'Highest'
            'Force'       = $true
        }
        $arguments = "/c title Finalizing installation - Atlas & echo Do not close this window. & echo Atlas is setting up component removal in Windows Recovery... & echo Your computer will automatically restart. & echo] & schtasks /delete /tn `"$safeModeStartupTitle`" /f > nul & " `
        + "PowerShell -NoP -EP Bypass -C `"& '$envPath\centralScript.ps1' -WinRE`" & pause"
        $action = New-ScheduledTaskAction -Execute 'cmd' -Argument $arguments
        Register-ScheduledTask -TaskName $safeModeStartupTitle -Action $action @taskArgs | Out-Null
    }

    # Failure in Safe Mode
    if ($safeMode -and !$PlaybookInstall) {
        if ($failedPackages.GetType().IsArray) {
            $failedPackages += 'dismCleanup'
        } else {
            $failedPackages = @($failedPackages, 'dismCleanup')
        }

        [IO.File]::WriteAllLines($winrePackageList, $($failedPackages -replace "$env:systemdrive\\", ''))
        New-Item $useWinreIndicator -Force | Out-Null

        Write-Info -Text "Failed disabling Defender in Safe Mode, using Windows Recovery next boot..." -NewLine
        4..1 | ForEach-Object {
            Clear-Host
            Write-Host "Some packages failed to install. " -ForegroundColor Yellow -NoNewline
            Write-Host "Again, this is no issue." -ForegroundColor Green
            Write-Host "Your computer will automatically restart twice into Windows Recovery to remove components.`n"
            Write-Host "Restarting in $_ seconds... " -NoNewline -ForegroundColor Gray
            Start-Sleep 1
        }
        Restart
    } elseif ($safeMode) {
        Write-Info -Text "Some packages didn't install sucessfully; WinRE will be set after next boot, exiting..." -NewLine
        exit
    }

    # Failure in normal boot
    if (!$PlaybookInstall) {
        10..1 | ForEach-Object {
            Clear-Host
            Write-Host "Some packages failed to install. " -ForegroundColor Yellow -NoNewline
            Write-Host "This is no issue." -ForegroundColor Green
            Write-Host "Your computer will automatically restart into safe mode to remove components.`n"
            Write-Host "Restarting in $_ seconds... " -NoNewline -ForegroundColor Gray
            Start-Sleep 1
        }
        Restart
    } else {
        Write-Info -Text "Some packages didn't install sucessfully; Safe Mode is set next boot, exiting..." -NewLine
        exit
    }
} else {
    if (!$PlaybookInstall) {
        10..1 | ForEach-Object {
            Clear-Host
            Write-Host "Completed! " -ForegroundColor Green -NoNewline
            Write-Host "Your computer will automatically restart to apply the changes.`n" -ForegroundColor Yellow
            Write-Host "Restarting in $_ seconds... " -NoNewline -ForegroundColor Gray
            Start-Sleep 1
        }
        Restart
    } else {
        Write-Info -Text "All packages installed sucessfully, exiting..." -NewLine
        exit
    }
}