[CmdletBinding()]
param(
    [string]$Destination = "C:\EBOS",
    # Opt-in: stage the Windhawk engine + installer. SetupComplete.cmd only
    # auto-installs Windhawk when the marker file exists, so the baked image
    # respects the wizard default (checkbox unchecked = no Windhawk).
    # The playbook option (windhawk-transparency) installs on demand anyway.
    [switch]$IncludeWindhawk
)

$ErrorActionPreference = 'Stop'
$exeDir = $PSScriptRoot
$repoRoot = Split-Path $exeDir -Parent

function Resolve-StagingSource {
    param([string]$FileName)
    $exeCandidate = Join-Path $exeDir $FileName
    if (Test-Path $exeCandidate) { return $exeCandidate }
    $rootCandidate = Join-Path $repoRoot $FileName
    if (Test-Path $rootCandidate) { return $rootCandidate }
    # Not found yet: return the preferred location (exeDir for ico, repoRoot for png/apbx)
    if ($FileName -eq 'playbook.ico') { return $exeCandidate }
    return $rootCandidate
}

$files = @(
    (Join-Path $exeDir "Set-ApbkIcon.ps1"),
    (Resolve-StagingSource "playbook.ico"),
    (Resolve-StagingSource "playbook.png"),
    (Join-Path $repoRoot "EBOS Release.apbx")
)
if ($IncludeWindhawk) {
    $files += (Join-Path $exeDir "Install-WindhawkTransparentTaskbar.ps1")
    $files += (Join-Path $exeDir "windhawk-cli-installer.exe")
}

if (-not (Test-Path $Destination)) { New-Item -ItemType Directory -Path $Destination -Force | Out-Null }

# Ensure playbook.ico exists (generate from playbook.png if it is missing) so staging
# never silently ships without the custom icon asset.
# The .ico lives in Executables/ (see Set-ApbkIcon.ps1 Resolve-Asset), the .png in repo root.
$icoSrc = Resolve-StagingSource "playbook.ico"
$pngSrc = Resolve-StagingSource "playbook.png"
if (-not (Test-Path $icoSrc) -and (Test-Path $pngSrc)) {
    & (Join-Path $exeDir "Set-ApbkIcon.ps1") | Out-Null
    $icoSrc = Resolve-StagingSource "playbook.ico"
    # Refresh the staged list in case the ico was just generated
    $files = @(
        (Join-Path $exeDir "Set-ApbkIcon.ps1"),
        $icoSrc,
        $pngSrc,
        (Join-Path $repoRoot "EBOS Release.apbx")
    )
    if ($IncludeWindhawk) {
        $files += (Join-Path $exeDir "Install-WindhawkTransparentTaskbar.ps1")
        $files += (Join-Path $exeDir "windhawk-cli-installer.exe")
    }
}

foreach ($f in $files) {
    if (Test-Path $f) {
        Copy-Item -Path $f -Destination $Destination -Force
        Write-Output "Staged: $(Split-Path $f -Leaf) -> $Destination"
    } else {
        Write-Warning "Missing source file (skipped): $f"
    }
}

# Marker so SetupComplete.cmd knows Windhawk is wanted (opt-in, see above).
$marker = Join-Path $Destination "include-windhawk.txt"
if ($IncludeWindhawk) {
    Set-Content -LiteralPath $marker -Value "staged with -IncludeWindhawk" -Encoding Ascii -Force
    Write-Output "Staged: include-windhawk.txt -> $Destination"
} elseif (Test-Path $marker) {
    Remove-Item -LiteralPath $marker -Force
}

Write-Output ""
Write-Output "Done. Place SetupComplete.cmd in C:\Windows\Setup\Scripts\ of the image,"
Write-Output "and ensure these files end up in $Destination on the deployed system."
