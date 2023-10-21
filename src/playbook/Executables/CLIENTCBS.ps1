# Remove ads from the 'Accounts' page in Immersive Control Panel
# Made by Xyueta

$Cbs = "$env:windir\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy"
$content = Get-Content -Path "$Cbs\Public\wsxpacks.json"
$pattern = '^\s*"Windows\.Settings\.Account".*'
$modifiedContent = $content -replace $pattern, ''
$modifiedContent = ($modifiedContent | Where-Object { $_.Trim() -ne "" }) -join "`n"
Set-Content -Path "$Cbs\Public\wsxpacks.json" -Value $modifiedContent
