[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet('/hide', '/unhide', 'hide', 'unhide')]
    [string]$Operation,

    [Parameter(Position = 1, Mandatory = $true)]
    [string]$Page,

    [switch]$Silent,

    [switch]$NoProcessCleanup,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs
)

$ErrorActionPreference = 'Stop'
[void]$Silent

if (@($RemainingArgs).Count -ne 0) {
    throw "Unsupported Settings page visibility arguments: $($RemainingArgs -join ' ')."
}
if ([string]::IsNullOrWhiteSpace($Page) -or
    $Page.Length -gt 256 -or
    $Page -cnotmatch '^[a-z0-9-]+$') {
    throw "Settings page '$Page' is not a canonical page identifier."
}

Import-Module -Name (Join-Path $PSScriptRoot '..\Modules\Atlas.Core\Atlas.Core.psd1') `
    -ErrorAction Stop

if (-not (Test-AtlasAdmin)) {
    throw 'Settings page visibility changes require Administrator rights.'
}

$normalizedOperation = $Operation.TrimStart('/').ToLowerInvariant()
$pageKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'

if (-not (Test-Path -LiteralPath $pageKey)) {
    New-Item -Path $pageKey -Force | Out-Null
}

$currentValue = $null
$currentKey = $null
try {
    $currentKey = Get-Item -LiteralPath $pageKey -ErrorAction Stop
    if (@($currentKey.GetValueNames()) -contains 'SettingsPageVisibility') {
        if ($currentKey.GetValueKind('SettingsPageVisibility') -ne
            [Microsoft.Win32.RegistryValueKind]::String) {
            throw 'SettingsPageVisibility exists with an unsupported registry value kind.'
        }
        $currentValue = [string]$currentKey.GetValue(
            'SettingsPageVisibility',
            $null,
            [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
        )
    }
}
finally {
    if ($null -ne $currentKey) {
        $currentKey.Close()
    }
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

    Set-ItemProperty -LiteralPath $pageKey -Name 'SettingsPageVisibility' -Value ('hide:' + (($pages | Select-Object -Unique) -join ';')) -Type String -ErrorAction Stop
}
else {
    Write-AtlasLog -Message 'Unhiding Settings pages...'

    $pages = @($pages | Where-Object { $_ -ne $Page })
    if (@($pages).Count -gt 0) {
        Set-ItemProperty -LiteralPath $pageKey -Name 'SettingsPageVisibility' -Value ('hide:' + (($pages | Select-Object -Unique) -join ';')) -Type String -ErrorAction Stop
    }
    else {
        $key = $null
        try {
            $key = Get-Item -LiteralPath $pageKey -ErrorAction Stop
            $hasVisibilityValue = @($key.GetValueNames()) -contains `
                'SettingsPageVisibility'
        }
        finally {
            if ($null -ne $key) {
                $key.Close()
            }
        }
        if ($hasVisibilityValue) {
            Remove-ItemProperty -LiteralPath $pageKey -Name 'SettingsPageVisibility' `
                -Force -ErrorAction Stop
        }
    }
}

# Closing an already-open Settings window is presentation-only and must never occur in
# strict machine replay, where the privileged token does not own an interactive user's
# session. Interactive callers retain the legacy cleanup unless they opt out explicitly.
if (-not $NoProcessCleanup) {
    $settingsProcesses = @(Get-Process -ErrorAction Stop | Where-Object {
            $_.ProcessName -ceq 'SystemSettings'
        })
    foreach ($settingsProcess in $settingsProcesses) {
        try {
            $settingsProcess | Stop-Process -Force -ErrorAction Stop
        }
        catch {
            Write-AtlasLog -Level Warning -Message `
                "SettingsPageVisibility was updated, but SystemSettings process $($settingsProcess.Id) could not be stopped: $($_.Exception.Message)"
        }
    }
}
