# Remove ads from the 'Accounts' page in Immersive Control Panel
# Made by Xyueta

$file = "$env:windir\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\Public\wsxpacks.json"
$content = Get-Content -Path "$file"
$pattern = '^\s*"Windows\.Settings\.Account".*'
$modifiedContent = $content -replace $pattern, ''
$modifiedContent = ($modifiedContent | Where-Object { $_.Trim() -ne "" }) -join "`n"

takeown /f "$file"
icacls "$file" /grant *S-1-3-4:F /t /c /l

Set-Content -Path "$file" -Value "$modifiedContent"
