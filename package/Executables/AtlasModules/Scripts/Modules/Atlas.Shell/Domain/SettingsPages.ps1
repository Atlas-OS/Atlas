# Atlas.Shell domain: Settings page visibility.
#
# Windows hides Settings pages through the SettingsPageVisibility Explorer policy, one
# "hide:page;page" string. Every caller edits a single page so the pages hidden by
# other Atlas features are preserved.

function Get-AtlasSettingsPageVisibilityKey {
    <#
    .SYNOPSIS
        Returns the Explorer policy key that stores the SettingsPageVisibility value.
    #>
    return 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
}

function Get-AtlasHiddenSettingsPage {
    <#
    .SYNOPSIS
        Reads the pages currently listed in the SettingsPageVisibility value of one key.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [ref]$Mode
    )

    $currentValue = $null
    $key = $null
    try {
        $key = Get-Item -LiteralPath $Path -ErrorAction Stop
        if (@($key.GetValueNames()) -contains 'SettingsPageVisibility') {
            if ($key.GetValueKind('SettingsPageVisibility') -ne
                [Microsoft.Win32.RegistryValueKind]::String) {
                throw 'SettingsPageVisibility exists with an unsupported registry value kind.'
            }
            $currentValue = [string]$key.GetValue(
                'SettingsPageVisibility',
                $null,
                [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
            )
        }
    }
    finally {
        if ($null -ne $key) {
            $key.Close()
        }
    }

    if ($null -ne $Mode) { $Mode.Value = 'hide' }
    if ([string]::IsNullOrWhiteSpace($currentValue)) {
        return [string[]]@()
    }
    if ($currentValue -like 'hide:*') {
        $withoutPrefix = $currentValue.Substring(5)
    }
    elseif ($currentValue -like 'showonly:*') {
        if ($null -eq $Mode) { throw 'SettingsPageVisibility uses an allowlist, not a hidden-page list.' }
        $Mode.Value = 'showonly'
        $withoutPrefix = $currentValue.Substring(9)
    }
    else { throw 'SettingsPageVisibility has an unsupported policy prefix.' }
    return [string[]]@($withoutPrefix -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Set-AtlasSettingsPageVisibility {
    <#
    .SYNOPSIS
        Hides or unhides one Settings page through the SettingsPageVisibility policy
        while keeping every other listed page as it was.
    .DESCRIPTION
        Requires an administrator token because the policy lives under HKLM. Unhiding
        the last listed page removes the value entirely. Unless -NoProcessCleanup is
        given, open Settings windows are closed so the change becomes visible; strict
        machine replay must pass -NoProcessCleanup because the privileged token does not
        own an interactive user's session.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('hide', 'unhide')]
        [string]$Operation,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Page,

        [switch]$NoProcessCleanup
    )

    if ([string]::IsNullOrWhiteSpace($Page) -or
        $Page.Length -gt 256 -or
        $Page -cnotmatch '^[a-z0-9-]+$') {
        throw "Settings page '$Page' is not a canonical page identifier."
    }
    if (-not (Test-AtlasAdmin)) {
        throw 'Settings page visibility changes require Administrator rights.'
    }

    $pageKey = Get-AtlasSettingsPageVisibilityKey
    if (-not (Test-Path -LiteralPath $pageKey)) {
        New-Item -Path $pageKey -Force | Out-Null
    }
    $mode = 'hide'
    $pages = @(Get-AtlasHiddenSettingsPage -Path $pageKey -Mode ([ref]$mode))

    if ($mode -eq 'showonly') {
        # Preserve the allowlist even when empty: deleting it would expose all pages.
        if ($Operation -eq 'hide') {
            $pages = @($pages | Where-Object { $_ -ne $Page })
        }
        elseif ($pages -notcontains $Page) { $pages += $Page }
        Set-ItemProperty -LiteralPath $pageKey -Name 'SettingsPageVisibility' `
            -Value ('showonly:' + (($pages | Select-Object -Unique) -join ';')) -Type String -ErrorAction Stop
    }
    elseif ($Operation -eq 'hide') {
        Write-AtlasLog -Message "Hiding Settings page '$Page'..."

        if ($pages -notcontains $Page) {
            $pages += $Page
        }
        Set-ItemProperty -LiteralPath $pageKey -Name 'SettingsPageVisibility' `
            -Value ('hide:' + (($pages | Select-Object -Unique) -join ';')) -Type String -ErrorAction Stop
    }
    else {
        Write-AtlasLog -Message "Unhiding Settings page '$Page'..."

        $pages = @($pages | Where-Object { $_ -ne $Page })
        if ($pages.Count -gt 0) {
            Set-ItemProperty -LiteralPath $pageKey -Name 'SettingsPageVisibility' `
                -Value ('hide:' + (($pages | Select-Object -Unique) -join ';')) -Type String -ErrorAction Stop
        }
        else {
            $key = $null
            try {
                $key = Get-Item -LiteralPath $pageKey -ErrorAction Stop
                $hasVisibilityValue = @($key.GetValueNames()) -contains 'SettingsPageVisibility'
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

    # Closing an already-open Settings window is presentation-only; interactive callers
    # keep it unless they opt out explicitly.
    if ($NoProcessCleanup) {
        return
    }
    $callerSessionId = [Diagnostics.Process]::GetCurrentProcess().SessionId
    if ($callerSessionId -eq 0) { return }
    $settingsProcesses = @(Get-Process -ErrorAction Stop | Where-Object {
            $_.ProcessName -ceq 'SystemSettings' -and $_.SessionId -eq $callerSessionId
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
