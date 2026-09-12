[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Voicemeeter Banana is distributed as VoicemeeterSetup_vXXXX.zip on VB-Audio's site.
# The build number in the URL changes over time, so resolve the current link from the
# official Banana page instead of hardcoding a version.
$pageUrl = 'https://vb-audio.com/Voicemeeter/banana.htm'
$fallbackUrl = 'https://download.vb-audio.com/Download_CABLE/VoicemeeterSetup_v2119.zip'

Write-Output "Resolving latest Voicemeeter Banana setup URL..."
$link = $fallbackUrl
try {
    $html = (Invoke-WebRequest -Uri $pageUrl -UseBasicParsing -TimeoutSec 60 -Headers @{ 'User-Agent' = 'EBOS-Playbook' }).Content
    $match = [regex]::Match($html, 'https://download\.vb-audio\.com/[^"''>]*VoicemeeterSetup[^"''>]*\.zip')
    if ($match.Success) { $link = $match.Value }
} catch {
    Write-Warning "Could not fetch the Banana page ($_); using fallback URL: $fallbackUrl"
}
Write-Output "Download URL: $link"

$work = Join-Path $env:TEMP ('VoicemeeterBanana_' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $work | Out-Null
$zip = Join-Path $work 'VoicemeeterSetup.zip'

Invoke-WebRequest -Uri $link -OutFile $zip -UseBasicParsing -TimeoutSec 300

$extract = Join-Path $work 'extracted'
Expand-Archive -Path $zip -DestinationPath $extract -Force

$setup = Get-ChildItem -Path $extract -Recurse -Filter 'VoicemeeterSetup.exe' | Select-Object -First 1
if (-not $setup) { throw 'VoicemeeterSetup.exe was not found after extraction.' }

Write-Output "Running silent install: $($setup.FullName) -h -i"
$proc = Start-Process -FilePath $setup.FullName -ArgumentList '-h', '-i' -Wait -PassThru -NoNewWindow
Write-Output "Setup exited with code $($proc.ExitCode)"
Write-Output "NOTE: the VB-Audio driver finalizes after a reboot; AME Wizard reboots after apply."

# Cleanup
Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
exit 0
