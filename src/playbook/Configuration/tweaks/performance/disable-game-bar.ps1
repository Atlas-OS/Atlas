$keys = @(
    "HKCU\System\GameConfigStore",
    "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR",
    "HKCU\SOFTWARE\Microsoft\GameBar",
    "HKLM\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter",
    "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR",
    "HKLM\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR"
)

$values = @(
    @{ Key = $keys[0]; Name = "GameDVR_Enabled"; Data = 0 },
    @{ Key = $keys[1]; Name = "AppCaptureEnabled"; Data = 0 },
    @{ Key = $keys[2]; Name = "GamePanelStartupTipIndex"; Data = 3 },
    @{ Key = $keys[2]; Name = "ShowStartupPanel"; Data = 0 },
    @{ Key = $keys[2]; Name = "UseNexusForGameBarEnabled"; Data = 0 },
    @{ Key = $keys[3]; Name = "ActivationType"; Data = 0 },
    @{ Key = $keys[4]; Name = "AllowGameDVR"; Data = 0 },
    @{ Key = $keys[5]; Name = "value"; Data = 0 }
)

foreach ($entry in $values) {
    reg add $entry.Key /v $entry.Name /t REG_DWORD /d $entry.Data /f
}