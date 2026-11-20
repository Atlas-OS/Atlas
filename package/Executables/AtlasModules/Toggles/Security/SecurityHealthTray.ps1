# Companion for the SecurityHealthTray toggle: imports the .reg file that adds or removes the
# Windows Security notification icon from startup. Set-AtlasSecurityHealthTrayStartup runs as
# Administrator when you run a launcher and when an update replays the recorded state.

function Set-AtlasSecurityHealthTrayStartup {
    param($Toggle)

    $regFile = if ($Toggle.State -ceq 'Enable') { 'enable.reg' } else { 'disable.reg' }
    Import-AtlasRegFile -Path (Join-Path -Path $Toggle.ScriptsPath -ChildPath "Registry\SecurityHealthTray\$regFile")
}
