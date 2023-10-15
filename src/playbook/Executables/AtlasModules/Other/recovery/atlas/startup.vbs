Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objShell = CreateObject("WScript.Shell")
systemDrive = objShell.ExpandEnvironmentStrings("%SystemDrive%")

strHTAPath = systemDrive & "\atlas\hta\hta.html"
Dim objProcess, strHTAPath, bHTARunning
Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")

If objFSO.FileExists("C:\Windows\AtlasModules\packagestoInstall") Then
    objShell.Run systemDrive & "\atlas\packages.cmd", 0
Else
    objShell.Run systemDrive & "\sources\recovery\RecEnv.exe", 1
End If

Do
    bHTARunning = False
    For Each objProcess in objWMIService.ExecQuery("Select * from Win32_Process")
        If LCase(objProcess.Name) = "mshta.exe" Then
            If InStr(1, objProcess.CommandLine, strHTAPath, vbTextCompare) > 0 Then
                bHTARunning = True
                Exit For
            End If
        End If
    Next

    If Not bHTARunning Then
        objShell.Run "mshta " & strHTAPath
    End If

    WScript.Sleep 3000
Loop