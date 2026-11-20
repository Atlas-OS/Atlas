Option Explicit
Dim shell, windows, host, script
Set shell = CreateObject("WScript.Shell")
windows = shell.ExpandEnvironmentStrings("%windir%")
host = windows & "\System32\WindowsPowerShell\v1.0\powershell.exe"
script = windows & "\AtlasModules\Scripts\Entry\Update-AtlasUser.ps1"
shell.Run """" & host & """ -NoProfile -ExecutionPolicy Bypass -File """ & script & """", 0, False
