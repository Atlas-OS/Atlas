# SHA256 of every CBS package shipped in this folder, verified before install by
# Atlas.Software\Domain\CbsPackages.ps1 (Assert-AtlasCbsHash). The signing cert is
# regenerated on every CAB rebuild, so its thumbprint is not stable and cannot be
# pinned; the content hash is. REGENERATE THIS FILE WHENEVER THE CABS ARE REBUILT:
#   Get-ChildItem *.cab | Sort-Object Name | ForEach-Object {
#     "    '$($_.Name)' = '$((Get-FileHash $_ -Algorithm SHA256).Hash)'" }
# A PayloadLayout test fails CI if this drifts from the shipped CABs.
@{
    'Z-Atlas-NoDefender-Package31bf3856ad364e35amd645.0.0.0.cab' = '6A8D1F8788277B425766FAD069A8192EDC33EEA2D6F7F9B061A42C941A21D2EC'
    'Z-Atlas-NoDefender-Package31bf3856ad364e35arm645.0.0.0.cab' = '39500FA6DF403F162C02A9C36D37D2C787BF459C05376872B9962FA649F4E081'
    'Z-Atlas-NoTelemetry-Package31bf3856ad364e35amd645.0.0.0.cab' = '11C5E3502DCB962F2FAE456712C7982DC1864D686B76194628CBFF8D1CD77ECA'
    'Z-Atlas-NoTelemetry-Package31bf3856ad364e35arm645.0.0.0.cab' = 'C6526330F660E654B249B63A974793BAE0E39F6714A0B79E03942145195E29A3'
}
