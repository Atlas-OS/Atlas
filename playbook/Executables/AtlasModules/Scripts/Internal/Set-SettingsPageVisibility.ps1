[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet('/hide', '/unhide', 'hide', 'unhide')]
    [string]$Operation,

    [Parameter(Position = 1, Mandatory = $true)]
    [string]$Page,

    [switch]$Silent,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs
)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $PSScriptRoot '..\Modules\Atlas.Core\Atlas.Core.psd1') -Force

if (-not (Test-AtlasAdmin)) {
    Write-AtlasLog -Level Warning -Message 'You must run this script as admin.'
    exit 1
}

$normalizedOperation = $Operation.TrimStart('/').ToLowerInvariant()
$pageKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'

if (-not (Test-Path -LiteralPath $pageKey)) {
    New-Item -Path $pageKey -Force | Out-Null
}

# try/catch instead of property access on a possibly-null result: StrictMode-safe.
$currentValue = $null
try {
    $currentValue = Get-ItemPropertyValue -LiteralPath $pageKey -Name 'SettingsPageVisibility' -ErrorAction Stop
}
catch {
    $currentValue = $null
}
$pages = @()
if (-not [string]::IsNullOrWhiteSpace($currentValue)) {
    $withoutPrefix = if ($currentValue -like 'hide:*') { $currentValue.Substring(5) } else { $currentValue }
    $pages = @($withoutPrefix -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

if ($normalizedOperation -eq 'hide') {
    Write-AtlasLog -Message 'Hiding Settings pages...'

    if ($pages -notcontains $Page) {
        $pages += $Page
    }

    Set-ItemProperty -LiteralPath $pageKey -Name 'SettingsPageVisibility' -Value ('hide:' + (($pages | Select-Object -Unique) -join ';')) -Type String
}
else {
    Write-AtlasLog -Message 'Unhiding Settings pages...'

    $pages = @($pages | Where-Object { $_ -ne $Page })
    if ($pages.Count -gt 0) {
        Set-ItemProperty -LiteralPath $pageKey -Name 'SettingsPageVisibility' -Value ('hide:' + (($pages | Select-Object -Unique) -join ';')) -Type String
    }
    else {
        Remove-ItemProperty -LiteralPath $pageKey -Name 'SettingsPageVisibility' -Force -ErrorAction SilentlyContinue
    }
}

Get-Process -Name SystemSettings -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
