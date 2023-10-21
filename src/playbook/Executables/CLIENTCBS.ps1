## Remove ads from the 'Accounts' page in Immersive Control Panel
$content = Get-Content -Path "$Cbs\Public\wsxpacks.json"
$pattern = '^\s*"Windows\.Settings\.Account".*'
$modifiedContent = $content -replace $pattern, ''
$modifiedContent = ($modifiedContent | Where-Object { $_.Trim() -ne "" }) -join "`n"
Set-Content -Path "$Cbs\Public\wsxpacks.json" -Value $modifiedContent
