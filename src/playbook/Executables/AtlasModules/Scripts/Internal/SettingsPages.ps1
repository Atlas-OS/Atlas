[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet('/hide', '/unhide', 'hide', 'unhide')]
    [string]$Operation,

    [Parameter(Position = 1, Mandatory = $true)]
    [string]$Page,

    [switch]$Silent
)

$ErrorActionPreference = 'Stop'

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdministrator)) {
    Write-Output 'You must run this script as admin.'
    exit 1
}

$normalizedOperation = $Operation.TrimStart('/').ToLowerInvariant()
$isSilent = $Silent.IsPresent
$pageKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'

if (-not (Test-Path -LiteralPath $pageKey)) {
    New-Item -Path $pageKey -Force | Out-Null
}

$currentValue = (Get-ItemProperty -LiteralPath $pageKey -Name 'SettingsPageVisibility' -ErrorAction SilentlyContinue).SettingsPageVisibility
$pages = @()
if (-not [string]::IsNullOrWhiteSpace($currentValue)) {
    $withoutPrefix = if ($currentValue -like 'hide:*') { $currentValue.Substring(5) } else { $currentValue }
    $pages = @($withoutPrefix -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

if ($normalizedOperation -eq 'hide') {
    if (-not $isSilent) {
        Write-Output 'Hiding Settings pages...'
    }

    if ($pages -notcontains $Page) {
        $pages += $Page
    }

    Set-ItemProperty -LiteralPath $pageKey -Name 'SettingsPageVisibility' -Value ('hide:' + (($pages | Select-Object -Unique) -join ';')) -Type String
}
else {
    if (-not $isSilent) {
        Write-Output 'Unhiding Settings pages...'
    }

    $pages = @($pages | Where-Object { $_ -ne $Page })
    if ($pages.Count -gt 0) {
        Set-ItemProperty -LiteralPath $pageKey -Name 'SettingsPageVisibility' -Value ('hide:' + (($pages | Select-Object -Unique) -join ';')) -Type String
    }
    else {
        Remove-ItemProperty -LiteralPath $pageKey -Name 'SettingsPageVisibility' -Force -ErrorAction SilentlyContinue
    }
}

Get-Process -Name SystemSettings -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
