' Completes installing-user OneDrive cleanup without flashing a console.
Option Explicit
Dim shell, windowsDirectory, scriptPath, powerShellPath, sid, bootTicks, pattern, command
If WScript.Arguments.Count <> 2 Then WScript.Quit 2
sid = WScript.Arguments(0)
bootTicks = WScript.Arguments(1)
Set pattern = New RegExp
pattern.Pattern = "^S-1-5-21-[0-9]+-[0-9]+-[0-9]+-[0-9]+$"
If Not pattern.Test(sid) Then WScript.Quit 2
pattern.Pattern = "^[0-9]{1,19}$"
If Not pattern.Test(bootTicks) Then WScript.Quit 2
Set shell = CreateObject("WScript.Shell")
windowsDirectory = shell.ExpandEnvironmentStrings("%windir%")
scriptPath = windowsDirectory & "\AtlasModules\Scripts\Operations\Remove-OneDriveCurrentUserData.ps1"
powerShellPath = windowsDirectory & "\System32\WindowsPowerShell\v1.0\powershell.exe"
command = """" & powerShellPath & """ -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File """ & scriptPath & """ -ExpectedUserSid " & sid & " -AfterBootUtcTicks " & bootTicks
WScript.Quit shell.Run(command, 0, True)
