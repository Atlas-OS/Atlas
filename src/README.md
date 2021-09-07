# Atlas Source
Here will contain the files required to build Atlas. Such as:
- XML files (required for NTLite)
- Registry Files
- Scripts
- Others, such as programs needed to interface with windows easier.

## Building From Source [WIP]

There are plenty of reasons to build atlas from source such as:
- To contribute to the project.
- To personalize the build, by removing components you don't need.
- It is safer to build from source, as you can ensure that the build is done with the same version of the source code.

### Prerequisites

- Currently you need NTLite with a "Home" or higher license.
- An Archive Extractor (7-Zip, WinRar, etc.)
- A local copy of the atlas repository.
- A Default Windows Build from Microsoft.

### Getting Started

1. Extract the Windows Build using the previously mentioned archive extractor.
2. Open NTLite and add the Extracted folder to NTLite's Source List.
3. Import the Atlas XML from the repo and apply it.
4. Integrate Drivers and .reg's if needed.
5. Copy the following Folders/Files to the NTLite Mount Directory (%temp%\NLTmpMount01)
  - Web >> %temp%\NLTmpMount01\Windows\Web (Delete the existing folder first!)
  - layout.xml >> %temp%\NLTmpMount01\Windows\layout.xml
  - AtlasModules >> %temp%\NLTmpMount01\Windows\AtlasModules
  - Desktop/Atlas >> %temp%\NLTmpMount01\Users\Default\Desktop\Atlas
  - Atlas.bat >> %temp%\NLTmpMount01\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\Atlas.bat
6. Delete the following files with a program like IOBit Unlocker or Unlocker
  - %temp%\NLTmpMount01\Windows\System32\mcupdate_genuineintel.dll
  - %temp%\NLTmpMount01\Windows\System32\mcupdate_authenticamd.dll
  - %temp%\NLTmpMount01\Windows\System32\mobsync.exe
  - %temp%\NLTmpMount01\Windows\System32\GameBarPresenceWriter.exe
  - %temp%\NLTmpMount01\Windows\WinSxS\Temp\PendingDeletes\*
  - %temp%\NLTmpMount01\Windows\System32\Catroot2
7. Make any changes you want to NTLite's Components, settings, services etc.
8. Go to the "Apply" tab and click Process
9. Done!
## Contributing

### Creating Scripts
First, you'll need to [add a flag/argument](https://github.com/Atlas-OS/Atlas/blob/628f8305a116f2cc7d6eff258952961b83b9647f/src/20H2/AtlasModules/atlas-config.bat#L44) to `atlas-config.bat`. This will allow it to be called from a seperate script on the desktop.

For this we will use the [Bluetooth Disable Script](hhttps://github.com/Atlas-OS/Atlas/blob/628f8305a116f2cc7d6eff258952961b83b9647f/src/20H2/AtlasModules/atlas-config.bat#L1235) as an example. 

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

Now that we have the script available in `atlas-config`, let's make a desktop script to easily launch it.

```batch
@echo off
C:\Windows\AtlasModules\nsudo -U:T -P:E -UseCurrentConsole -Wait C:\Windows\AtlasModules\atlas-config.bat /btd
```

This file will go in the "Atlas" Folder

### Code Formatting

To keep code "unified" we have a few guidelines. This way it is easier to understand when contributing.

#### Labels

When creating [labels](http://elearning.algonquincollege.com/coursemat/viljoed/gis8746/concepts/dosbatch/advanced/labels.htm), we use camelCase:

```batch
:btD
echo this stands for "Bluetooth Disable"
```

## Resources
- [VCRedist](https://github.com/abbodi1406/vcredist)
- [DevManView](https://www.nirsoft.net/utils/device_manager_view.html)
- [ServiWin](https://www.nirsoft.net/utils/serviwin.html)
- [7-Zip](https://www.7-zip.org)
- [aria2](https://github.com/aria2/aria2)
- [NSudo](https://github.com/m2team/NSudo)
- [PsSuspend](https://docs.microsoft.com/en-us/sysinternals/downloads/pssuspend)