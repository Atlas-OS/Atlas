# Atlas Source
Here will contain the files required to build Atlas. Such as:
- XML files (required for NTLite)
- Registry Files 
- Scripts
- Others, such as programs needed to interface with windows easier.

# How do I utlize this?
There will be instructions in the future on how to use the source files.

## Cloning the Repo

We utilize submodules to manage different Windows versions the normal `git clone` will not include it. To include submodules, run the following:
```git clone --recurse-submodules https://github.com/Atlas-OS/Atlas.git```

Done! You now can see and develop within our repo and submodules!

## Creating scripts and making them accessible
First, you'll need to [add a flag/argument](https://github.com/Atlas-OS/Atlas/blob/4d0b53506631be2dda469dce3330722507e9aaec/atlas-config.bat#L65) to `atlas-config.bat`. This will allow it to be called from a seperate script on the desktop.

For this we will use the [Bluetooth Disable Script](https://github.com/Atlas-OS/Atlas/blob/4d0b53506631be2dda469dce3330722507e9aaec/atlas-config.bat#L529) as an example. 
```batch
:: the :btD flag is part of allowing the script to be called when a specific flag is used, as mentioned previously.
:btD
:: Now the script disables the services required for bluetooth.
sc config BthAvctpSvc start=disabled
sc stop BthAvctpSvc >nul 2>&1
:: This line simply parses the registry for CDPUserSvc_xxxxx which can't be configured through "sc"
for /f %%I in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services" /s /k /f CDPUserSvc ^| find /i "CDPUserSvc" ') do (
  reg add "%%I" /v "Start" /t REG_DWORD /d "4" /f
  sc stop %%~nI
)
sc config CDPSvc start=disabled
:: Once finished it is redirected to a generic message to reboot for changes, then exits at the end of the file.
:: If the script does not need to reboot, use "goto finishNRB"
goto finish
```
<!-- 
TODO:
 - Add sample for desktop script
-->

## Resources 
- [DevManView](https://www.nirsoft.net/utils/device_manager_view.html)
- [ServiWin](https://www.nirsoft.net/utils/serviwin.html)
- [7-Zip](https://www.7-zip.org)
- [aria2](https://github.com/aria2/aria2)
- [NSudo](https://github.com/m2team/NSudo)
