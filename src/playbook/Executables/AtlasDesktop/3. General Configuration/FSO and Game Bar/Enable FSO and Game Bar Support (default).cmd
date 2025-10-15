@echo off

:: TI required for ActivatableClassId
whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

(
	reg delete "HKCU\System\GameConfigStore" /v "GameDVR_DSEBehavior" /f
	reg add "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t REG_DWORD /d "0" /f
	reg add "HKCU\System\GameConfigStore" /v "GameDVR_EFSEFeatureFlags" /t REG_DWORD /d "0" /f
	reg delete "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehavior" /f
	reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d "2" /f
	reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d "0" /f

	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v "__COMPAT_LAYER" /f

	reg delete "HKCU\System\GameBar" /v "GamePanelStartupTipIndex" /f
	reg delete "HKCU\System\GameBar" /v "ShowStartupPanel" /f
	reg delete "HKCU\System\GameBar" /v "UseNexusForGameBarEnabled" /f

	reg add "HKLM\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter" /v "ActivationType" /t REG_DWORD /d "1" /f

	reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /f

	reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" /v "value" /t REG_DWORD /d "1" /f

	reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d "1" /f

	reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" /f
) > nul 2>&1

echo Finished, FSO is now enabled and you should be able to use Game Bar.
echo Press any key to exit...
pause > nul
exit /b