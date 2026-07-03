# QOL domain functions: SystemShortcuts

function Add-NetworkSharingShortcut {
    & "$windir\AtlasModules\initPowerShell.ps1"
    New-Shortcut -Source 'control.exe' `
        -Destination "$([Environment]::GetFolderPath('Windows'))\AtlasDesktop\3. General Configuration\File Sharing\Sharing Settings.lnk" `
        -Arguments '/name Microsoft.NetworkAndSharingCenter /page Advanced'
}

# Function to configure boot configuration

function Set-BootConfiguration {
    # Set boot menu timeout to 10 seconds and use the legacy (text-based) boot menu
    & bcdedit /timeout 10
    & bcdedit /set bootmenupolicy legacy
}

# Function to disable wallpaper compression

function Set-WindowsInkWorkspace {
    # Stops the Ink Workspace from showing app suggestions (ads) on the pen menu
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PenWorkspace' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PenWorkspace' -Name 'PenWorkspaceAppSuggestionsEnabled' -Value 0 -Type DWord -Force
}

# Function to disable automatic Store app archiving

function Disable-AutomaticStoreAppArchiving {
    & "$windir\AtlasDesktop\3. General Configuration\Store App Archiving\Disable Store App Archiving (default).cmd" /justcontext
}

# Function to disable dynamic lighting

function Disable-DynamicLighting {
    # AmbientLightingEnabled 0 stops Windows from controlling RGB lighting on supported peripherals
    $null = New-Item -Path 'HKCU:\Software\Microsoft\Lighting' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Lighting' -Name 'AmbientLightingEnabled' -Value 0 -Type DWord -Force
}

# Function to disable mouse acceleration

function Disable-MouseAcceleration {
    # MouseSpeed 0 disables pointer precision; Threshold values must also be 0 to fully remove the acceleration curve
    $path = 'HKCU:\Control Panel\Mouse'
    Set-ItemProperty -Path $path -Name 'MouseSpeed'      -Value '0' -Type String -Force
    Set-ItemProperty -Path $path -Name 'MouseThreshold1' -Value '0' -Type String -Force
    Set-ItemProperty -Path $path -Name 'MouseThreshold2' -Value '0' -Type String -Force
}

# Function to disable screen capture hotkey

function Disable-ScreenCaptureHotkey {
    # PrintScreenKeyForSnippingEnabled 0 stops Print Screen from opening Snipping Tool
    $null = New-Item -Path 'HKCU:\Control Panel\Keyboard' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Control Panel\Keyboard' -Name 'PrintScreenKeyForSnippingEnabled' -Value 0 -Type DWord -Force
}

# Function to disable spell checking

function Disable-SpellChecking {
    # All five values must be set to 0 to fully disable autocorrect and prediction on the touch keyboard
    $path = 'HKCU:\SOFTWARE\Microsoft\TabletTip\1.7'
    $null = New-Item -Path $path -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name 'EnableAutocorrection'          -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'EnableDoubleTapSpace'          -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'EnablePredictionSpaceInsertion' -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'EnableSpellchecking'           -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'EnableTextPrediction'          -Value 0 -Type DWord -Force
}

# Function to disable unnecessary touch keyboard settings

function Disable-WindowsFeedback {
    # NumberOfSIUFInPeriod 0 stops Windows from prompting for feedback; PeriodInNanoSeconds is removed so there is no reset window
    $path = 'HKCU:\SOFTWARE\Microsoft\Siuf\Rules'
    $null = New-Item -Path $path -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name 'NumberOfSIUFInPeriod' -Value 0 -Type DWord -Force
    Remove-ItemProperty -Path $path -Name 'PeriodInNanoSeconds' -Force -ErrorAction SilentlyContinue

    # Machine policy prevents the feedback hub from being re-enabled by Windows Update
    $null = New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' -Name 'DoNotShowFeedbackNotifications' -Value 1 -Type DWord -Force
}

# Function to disable Windows Spotlight
