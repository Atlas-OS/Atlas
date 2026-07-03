# QOL domain functions: Accessibility

function Disable-ReadAndScan {
    # selfscan and selfvoice are Ease of Access auto-scan settings that read UI aloud; rarely useful on desktop
    $path = 'HKCU:\SOFTWARE\Microsoft\Ease of Access'
    $null = New-Item -Path $path -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name 'selfscan' -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'selfvoice' -Value 0 -Type DWord -Force
}

# Function to disable commonly annoying features and shortcuts

function Disable-AnnoyingFeaturesAndShortcuts {
    $accessBase = 'HKCU:\Control Panel\Accessibility'
    # Flags = '0' disables each accessibility feature; REG_SZ not DWord per Windows spec
    foreach ($sub in @('HighContrast', 'Keyboard Response', 'MouseKeys', 'StickyKeys', 'ToggleKeys')) {
        $null = New-Item -Path "$accessBase\$sub" -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "$accessBase\$sub" -Name 'Flags' -Value '0' -Type String -Force
    }

    # Key 00000104 is the Czech/Slovak layout hot key; removing the key disables the shortcut entirely
    Remove-Item -Path 'HKCU:\Control Panel\Input Method\Hot Keys\00000104' -Force -ErrorAction SilentlyContinue

    # Value '3' means no hotkey assigned for switching keyboard layouts or languages
    $togglePath = 'HKCU:\Keyboard Layout\Toggle'
    $null = New-Item -Path $togglePath -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $togglePath -Name 'Layout Hotkey' -Value '3' -Type String -Force
    Set-ItemProperty -Path $togglePath -Name 'Language Hotkey' -Value '3' -Type String -Force
    Set-ItemProperty -Path $togglePath -Name 'Hotkey' -Value '3' -Type String -Force

    # Stops the Win+Enter shortcut from launching Narrator
    $null = New-Item -Path 'HKCU:\Software\Microsoft\Narrator\NoRoam' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Narrator\NoRoam' -Name 'WinEnterLaunchEnabled' -Value 0 -Type DWord -Force
}

# Function to disable the accessibility tool shortcut

function Disable-AccessibilityToolShortcut {
    # LaunchAT 0 prevents the on-screen keyboard from launching on tablet sign-in
    $null = New-Item -Path 'HKCU:\Control Panel\Accessibility\SlateLaunch' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Control Panel\Accessibility\SlateLaunch' -Name 'LaunchAT' -Value 0 -Type DWord -Force
}

# Function to disable Ease of Access sounds

function Disable-EaseOfAccessSounds {
    # Stop the beeps and tones that play when accessibility features activate
    $path = 'HKCU:\Control Panel\Accessibility'
    $null = New-Item -Path $path -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name 'Warning Sounds' -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'Sound on Activation' -Value 0 -Type DWord -Force

    # WindowsEffect 0 means no visual flash substitute for system sounds
    $null = New-Item -Path "$path\SoundSentry" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "$path\SoundSentry" -Name 'WindowsEffect' -Value '0' -Type String -Force
}

# Function to remove 'Extract' from context menu

function Disable-UnnecessaryTouchKeyboardSettings {
    # EnableAutoShiftEngage auto-capitalizes after a period; EnableKeyAudioFeedback plays click sounds
    $path = 'HKCU:\SOFTWARE\Microsoft\TabletTip\1.7'
    $null = New-Item -Path $path -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name 'EnableAutoShiftEngage'  -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'EnableKeyAudioFeedback' -Value 0 -Type DWord -Force
}

# Function to disable touch visual feedback

function Disable-TouchVisualFeedback {
    # Removes the visual circles that appear on screen when touching with fingers
    $path = 'HKCU:\Control Panel\Cursors'
    Set-ItemProperty -Path $path -Name 'GestureVisualization' -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'ContactVisualization' -Value 0 -Type DWord -Force
}

# Function to disable Windows Feedback

function Disable-ReduceSoundsWhileInCall {
    # UserDuckingPreference 3 disables the automatic volume reduction Windows applies during calls
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Multimedia\Audio' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Multimedia\Audio' -Name 'UserDuckingPreference' -Value 3 -Type DWord -Force
}

# Function to hide disabled and disconnected devices in sounds panel

function Hide-DisabledAndDisconnectedDevicesInSoundsPanel {
    # Cleans up the Sound control panel by hiding devices that are not actively connected
    $path = 'HKCU:\SOFTWARE\Microsoft\Multimedia\Audio\DeviceCpl'
    $null = New-Item -Path $path -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name 'ShowDisconnectedDevices' -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'ShowHiddenDevices'       -Value 0 -Type DWord -Force
}

# Function to configure visual effects
