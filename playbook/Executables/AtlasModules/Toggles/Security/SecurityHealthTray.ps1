function Set-AtlasSecurityHealthTrayStartup {
    param($Toggle)

    $regFile = if ($Toggle.State -ceq 'Enable') { 'enable.reg' } else { 'disable.reg' }
    Import-AtlasRegFile -Path (Join-Path -Path $Toggle.ScriptsPath -ChildPath "Registry\SecurityHealthTray\$regFile")
}
