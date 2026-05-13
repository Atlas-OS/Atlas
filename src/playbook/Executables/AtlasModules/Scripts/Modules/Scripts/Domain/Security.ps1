# System script domain functions: Security

function Disable-CoreIsolation {
    & ".\AtlasModules\Scripts\ScriptWrappers\ConfigVBS.ps1" -DisableAllVBS
}

function Disable-Mitigations {
    Start-Process -FilePath "AtlasDesktop\7. Security\Mitigations\Disable All Mitigations.cmd" -ArgumentList "/silent" -NoNewWindow -Wait
}
