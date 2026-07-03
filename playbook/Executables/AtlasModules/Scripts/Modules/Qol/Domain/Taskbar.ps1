# QOL domain functions: Taskbar

function Disable-MicrosoftCopilot {
    # Policy key is required; the user-facing toggle alone does not survive updates
    $null = New-Item -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot' -Value 1 -Type DWord -Force
}

# Function to disable Show Desktop peek on taskbar

function Disable-ShowDesktopPeek {
    # DisablePreviewDesktop 1 disables the transparent preview when hovering over the Show Desktop button
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'DisablePreviewDesktop' -Value 1 -Type DWord -Force
}

# Function to never use tablet mode

function Hide-TabletMode {
    # SignInMode 1 forces desktop mode at sign-in regardless of whether a keyboard is attached
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell' -Name 'SignInMode' -Value 1 -Type DWord -Force
}

# Function to disable Windows Chat

function Disable-WindowsChat {
    # ChatIcon 3 hides the Teams/Chat icon; policy key enforces it so it does not reappear after updates
    $null = New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat' -Name 'ChatIcon' -Value 3 -Type DWord -Force
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarMn' -Value 0 -Type DWord -Force
}

# Function to add 'End task' to the taskbar

function Add-EndTaskToTaskbar {
    # TaskbarEndTask 1 adds a right-click 'End task' option directly on running apps in the taskbar
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings' -Name 'TaskbarEndTask' -Value 1 -Type DWord -Force
}

# Function to disable Task View on taskbar

function Disable-TaskViewOnTaskbar {
    # Remove the Enabled value first; if it stays set it can override ShowTaskViewButton
    Remove-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MultiTaskingView\AllUpView' -Name 'Enabled' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowTaskViewButton' -Value 0 -Type DWord -Force
}

# Function to set taskbar alignment to left

function Set-TaskbarAlignLeft {
    # TaskbarAl 0 moves the taskbar icons to the left; 1 is the Windows 11 centered default
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAl' -Value 0 -Type DWord -Force
}

# Function to add network sharing shortcut
