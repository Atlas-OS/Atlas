<#
.SYNOPSIS
    Opt-in developer setup: adds a snippet to your PowerShell $PROFILE that puts the
    Atlas payload modules on PSModulePath when working in this repository under VS Code,
    so the PowerShell extension resolves Import-Module and provides IntelliSense.
.DESCRIPTION
    Previously the build script offered this interactively on every build; it is now an
    explicit one-time setup step. Safe to re-run - the snippet is only added once.
#>
Param(
    [switch]$Remove
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$startMarker = '#--LOCAL-BUILD-MODULES-START--#'
$endMarker = '#--LOCAL-BUILD-MODULES-END--#'

$profileContent = if (Test-Path -LiteralPath $PROFILE -PathType Leaf) {
    Get-Content -Path $PROFILE -Raw -Encoding UTF8
}
else {
    ''
}

if ($Remove) {
    if ($profileContent -notmatch [regex]::Escape($startMarker)) {
        Write-Host 'No Atlas dev snippet found in your profile; nothing to remove.'
        return
    }

    $pattern = [regex]::Escape($startMarker) + '.*?' + [regex]::Escape($endMarker) + '\r?\n?'
    $updated = [regex]::Replace($profileContent, $pattern, '', 'Singleline')
    Set-Content -Path $PROFILE -Value $updated -Encoding UTF8
    Write-Host 'Removed the Atlas dev snippet from your PowerShell profile.'
    return
}

if ($profileContent -match [regex]::Escape($startMarker)) {
    Write-Host 'The Atlas dev snippet is already present in your PowerShell profile.'
    return
}

if (-not (Test-Path -LiteralPath $PROFILE -PathType Leaf)) {
    $profileParent = Split-Path -Path $PROFILE -Parent
    if ($profileParent -and -not (Test-Path -LiteralPath $profileParent)) {
        New-Item -ItemType Directory -Path $profileParent -Force | Out-Null
    }
    New-Item -Path $PROFILE -ItemType File -Force | Out-Null
}

Add-Content -Path $PROFILE -Value @'
#--LOCAL-BUILD-MODULES-START--#
$workspace = $psEditor.Workspace.Path
$modulesFile = "$workspace\.atlasPsModulesPath"
if ([bool](Test-Path 'Env:\VSCODE_*') -and (Test-Path $workspace -EA 0) -and (Test-Path $modulesFile -EA 0)) {
    $modulePath = Join-Path $workspace (Get-Content $modulesFile -Raw)
    if (!(Test-Path $modulePath -PathType Container)) {
        Write-Warning "Couldn't find module path specified in '$modulesFile', no Atlas modules can be loaded."
    } else {
        $env:PSModulePath += [IO.Path]::PathSeparator + $modulePath
    }
}
#--LOCAL-BUILD-MODULES-END--#
'@

Write-Host 'Added the Atlas dev snippet to your PowerShell profile. Restart your editor session to apply.'
