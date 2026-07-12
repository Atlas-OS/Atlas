' Launches Initialize-NewUser.ps1 with zero visible window. WScript.Shell.Run's window
' style 0 hides the console from the moment it's created - unlike powershell.exe's own
' -WindowStyle Hidden switch, which still flashes briefly because its console exists
' before the process can hide itself. wscript.exe itself has no console to flash either.
strWindir = CreateObject("WScript.Shell").ExpandEnvironmentStrings("%windir%")
strScript = strWindir & "\AtlasModules\Scripts\Initialize-NewUser.ps1"
strPowerShell = strWindir & "\System32\WindowsPowerShell\v1.0\powershell.exe"

strArgs = ""
For i = 0 To WScript.Arguments.Count - 1
    strArgs = strArgs & " " & WScript.Arguments(i)
Next

CreateObject("WScript.Shell").Run """" & strPowerShell & """ -ExecutionPolicy RemoteSigned -NoProfile -File """ & strScript & """" & strArgs, 0, False
