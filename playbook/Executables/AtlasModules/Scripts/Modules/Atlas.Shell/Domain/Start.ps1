# Atlas.Shell domain: Windows 11 Start layout.
#
# The Configure Start Pins policy points at the checked StartLayout.json; this domain
# validates that layout, reports whether the running build honours the policy, and
# clears the default-user Start cache so new accounts receive the layout.

function Test-AtlasStartPinPolicySupported {
    <#
    .SYNOPSIS
        Reports whether the Configure Start Pins local GPO can replace the default
        promotional pins on the given OS build and update revision.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [int]$Build,

        [Parameter(Mandatory = $true)]
        [int]$Revision
    )

    # Microsoft added the local Configure Start Pins GPO in 24H2 KB5062660
    # (26100.4770). Later cumulative updates and later Windows builds include it.
    return ($Build -gt 26100 -or ($Build -eq 26100 -and $Revision -ge 4770))
}

function Get-AtlasStartLayoutPath {
    <#
    .SYNOPSIS
        Returns the shipped Start layout JSON path under the Windows directory.
    #>
    return Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Other\StartLayout.json'
}

function Get-AtlasStartWindowsVersion {
    <#
    .SYNOPSIS
        Reads the OS build number and update revision from the machine's CurrentVersion key.
    #>
    $currentVersion = Get-ItemProperty -LiteralPath `
        'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion' `
        -ErrorAction Stop
    $windowsBuild = 0
    $windowsRevision = 0
    $null = [int]::TryParse([string]$currentVersion.CurrentBuildNumber, [ref]$windowsBuild)
    $null = [int]::TryParse([string]$currentVersion.UBR, [ref]$windowsRevision)
    return [pscustomobject]@{
        Build    = $windowsBuild
        Revision = $windowsRevision
    }
}

function Get-AtlasStartDefaultUserKey {
    <#
    .SYNOPSIS
        Returns the fixed loaded default-user hive root that TrustedInstaller owns.
    #>
    # TrustedInstaller owns only the fixed loaded default-user hive. Never enumerate
    # loaded live-user hives or traverse user-controlled registry links from this process.
    return 'Registry::HKEY_USERS\Atlas_DefaultUser'
}

function Set-AtlasStartLayout {
    <#
    .SYNOPSIS
        Validates the shipped Windows 11 Start layout and removes the default Start
        advertisements from the fixed default-user hive.
    .DESCRIPTION
        Runs in the privileged install phase with the default-user hive loaded. The
        layout must apply once and contain at least one pin. A build older than the
        Configure Start Pins GPO is reported as a warning, not a failure.
    #>
    $layoutJson = Get-AtlasStartLayoutPath
    if (-not (Test-Path -LiteralPath $layoutJson -PathType Leaf)) {
        throw "The Windows 11 Start layout is missing at '$layoutJson'."
    }

    try {
        $layout = Get-Content -LiteralPath $layoutJson -Raw -ErrorAction Stop |
            ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "The Windows 11 Start layout is invalid: $($_.Exception.Message)"
    }
    if ($layout.applyOnce -ne $true -or @($layout.pinnedList).Count -eq 0) {
        throw 'The Windows 11 Start layout must apply once and contain at least one pin.'
    }

    $version = Get-AtlasStartWindowsVersion
    if (Test-AtlasStartPinPolicySupported -Build $version.Build -Revision $version.Revision) {
        Write-AtlasLog -Message "Configure Start Pins policy support detected on OS build $($version.Build).$($version.Revision)."
    }
    else {
        Write-AtlasLog -Level Warning -Message (
            "Configure Start Pins cannot remove the default promotional pins on OS build " +
            "$($version.Build).$($version.Revision). Microsoft supports this local GPO starting with " +
            'Windows 11 24H2 KB5062660 (26100.4770); install that or a later cumulative update.'
        )
    }

    $userKey = Get-AtlasStartDefaultUserKey
    Write-AtlasLog -Message 'Configuring the Windows 11 Start Menu...'
    Write-AtlasLog -Message "Using the checked Start pin layout at '$layoutJson'."
    Write-AtlasLog -Message 'Removing advertisements/stubs from the default Start Menu'
    Remove-ItemProperty -Path "$userKey\SOFTWARE\Microsoft\Windows\CurrentVersion\Start" `
        -Name 'Config' -Force -ErrorAction SilentlyContinue
}
