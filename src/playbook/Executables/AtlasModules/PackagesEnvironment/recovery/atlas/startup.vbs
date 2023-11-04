Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objShell = CreateObject("WScript.Shell")
systemDrive = objShell.ExpandEnvironmentStrings("%SystemDrive%")

strHTAPath = systemDrive & "\atlas\hta\hta.html"
Dim objProcess, strHTAPath, bHTARunning
objShell.Run systemDrive & "\atlas\packages.cmd", 0

Do
    If objFSO.FileExists(systemDrive & "\AtlasComponentPackageInstallation") Then
        Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
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
            
            If objFSO.FileExists(systemDrive & "\atlas\FocusMSHTA") Then
                objShell.AppActivate("Atlas Component Removal")
                WScript.Sleep 500
            Else
                WScript.Sleep 3000
            End If
        Loop
    ElseIf objFSO.FileExists(systemDrive & "\AtlasNormalWindowsRecovery") Then
        WScript.Quit
    End If
    
    WScript.Sleep 1000
    packagesCheck = packagesCheck + 1
    If packagesCheck >= 8 Then
        WScript.Quit
    End If
Loop