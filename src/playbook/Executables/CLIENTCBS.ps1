# Configure Client CBS related entires
# Made by Xyueta

## Set the Client CBS path
$Cbs = "$env:SystemRoot\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy"

## Remove Get started from Start Menu
$Manifest = Join-Path $Cbs 'appxmanifest.xml'
takeown /a /f $Manifest
icacls $Manifest /grant Administrators:F
$AtlasManifest = Join-Path $Cbs "appxmanifest.xml.atlas"
if (!(Test-Path $AtlasManifest)) {
    Copy-Item -Path $Manifest -Destination $AtlasManifest -Force
    Remove-Item $Manifest -Force
}
[xml]$xml = Get-Content -Path "$Cbs\appxmanifest.xml.atlas" -Raw
$applicationNode = $xml.Package.Applications.Application | Where-Object { $_.Id -eq 'WebExperienceHost' }
if ($applicationNode -ne $null) {
    $xml.Package.Applications.RemoveChild($applicationNode)
}
$xml.Save($Manifest)

## Remove ads from the 'Accounts' page in Immersive Control Panel
$content = Get-Content -Path "$Cbs\Public\wsxpacks.json"
$pattern = '^\s*"Windows\.Settings\.Account".*'
$modifiedContent = $content -replace $pattern, ''
$modifiedContent = ($modifiedContent | Where-Object { $_.Trim() -ne "" }) -join "`n"
Set-Content -Path "$Cbs\Public\wsxpacks.json" -Value $modifiedContent

## Remove banner from Immersive Control Panel
Remove-Item -Path "$Cbs\SystemSettingsExtensions.dll" -Force