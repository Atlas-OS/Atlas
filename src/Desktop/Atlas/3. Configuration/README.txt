# Animations
  Default: Disabled
  - Virtually, all Windows animations are disabled.

# Background Apps
  Default: Disabled
  - Enable if you need to toggle background apps.

# Bluetooth
  Default: Disabled
  - Enable if you use Bluetooth-connected devices, make sure you have proper drivers for them as well.

# Clipboard History
  Default: Disabled
  - Clipboard History, seems to break any UWP copying to clipboard as well. Minimal impact, do not resist to re-enable it.

# DEP
  Default: Disabled
  - In layman's terms, a mitigation (security fix) to prevent unauthorized programs from writing to protected memory. Game anti-cheats like Valorant/FACEIT use this.
    So if you play any of those, you might want to enable it, so that you can launch your game.

# Firewall
  Default: Enabled
  Configures windows firewall, frequently needed for Microsoft Store.

# FSO
  Default: Disabled
  - FSO (Fullscreen Optimizations) runs Fullscreen Exclusive games in a "highly optimized" borderless window, which allows for faster alt-tabbing.
    Disabling it is technically better for latency in theory, but FSO has developed quite significantly, and you probably won't notice a difference.

# HDD
  Default: Disabled
  - Enables features that improve hard disk performance, like prefetching and font caching.

# Hyper-V and VBS
  Default: Disabled
  - Enables Hyper-V and Virtualization-based security.
  
# Microsoft Store
  Default: Enabled
  - Disables Microsoft Store, can break a lot of things in the process. Please READ THE DISCLAIMER in the script before continuing.

# Network Discovery
  Default: Disabled
  - Also known as network sharing, used to, as the name implies share files over the netork. There is no disable script as it is only other dependencies.

# Notifications
  Default: Disabled
  - If you do not understand what this is you should not be allowed to use a computer.

# Power
  Default: Enabled
  - Sleep States:
	  https://github.com/Atlas-OS/Atlas/wiki/3.-Post-Install#sleep-states
      Allows you to use sleep/hibernate.
  - CPU Idle:
      Disables CPU idle, will DISPLAY your CPU being used at 100%. It is not actually under 100% load.=

# Printing
  Default: Disabled

# Process Explorer
  Default: Disabled
  - Enable if you want to install and use Process Explorer instead of Task Manager.

# Search Indexing
  Default: Disabled
  - Enables indexing of files for faster searching within explorer (uses lots of cycles)

# Start Menu
  - Various scripts, including removing the start menu and replacing it with Open-Shell

# Troubleshooting
  Default: Disabled
  - Enable if you want to use Windows Troubleshooting.

# UAC (User Account Control)
  Default: Enabled (Minimum)
  - Prompt which asks for admin, if disabled, everything runs as an administrator (no option to run as a standard user)
	Breaks some things if disabled and slightly worsened security
	Set to not dim the desktop by default so that it's convienient, but not disabled

# UWP
  Default: Enabled
  - Disables many components related to UWP/AppX applications, will break many things like Store, Photos, Calculator, parts of Settings, etc...
    This is a pretty extreme form of 'debloating', only do this if you understand the risks.

# VPN
  Default: Disabled

# Wi-Fi
  Default: Enabled

# Workstation (SMB)
  Default: Disabled
  - If you use SMB shares or AMD Ryzen Master, enable this.

# Mitigations
  Default: Disabled
  - Disabled: 
      - Maximum potential performance, although, this comes at a further risk of security
      - Could see issues with anti-cheats, check 'Anti-cheat compatibility' folder
  - Fully enabled: 
      - Good for security, but you may see worse compatibility and worse performance
  - Windows Default:
      - Balanced for security, performance and compatibility. Should not impact performance too too much (especially on newer CPUs).
