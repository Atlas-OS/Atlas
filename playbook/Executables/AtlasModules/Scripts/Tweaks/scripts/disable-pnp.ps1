# Companion of disable-pnp.psd1 (was Configuration\tweaks\scripts\script-devices.yml).
$windir = [Environment]::GetFolderPath('Windows')

# Disable rarely-needed network adapter bindings to cut background usage.
Get-NetAdapterBinding -Name '*' -ComponentID ms_msclient, ms_server, ms_lldp, ms_lltdio, ms_rspndr -ErrorAction SilentlyContinue |
    Disable-NetAdapterBinding -ErrorAction SilentlyContinue |
    Out-Null

# Disable PnP devices most users don't need.
& (Join-Path -Path $windir -ChildPath 'AtlasModules\Scripts\Internal\Disable-PnpDevices.ps1')
