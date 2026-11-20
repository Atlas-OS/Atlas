# Atlas.Services domain: service and driver startup configuration.
# Start values: 0 = Boot, 1 = System, 2 = Automatic, 3 = Manual, 4 = Disabled.
# https://learn.microsoft.com/windows-hardware/drivers/install/inf-addservice-directive

function Assert-AtlasServiceRegistryName {
    <#
    .SYNOPSIS
        Throws unless a name can only address one key directly under Services: no path
        separators, no ']' (it would end a .reg section), no control characters, and
        at most 256 characters, the service name limit.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    if ($Name -in @('.', '..') -or $Name.Length -gt 256 -or
        $Name.IndexOfAny([char[]]@('\', '/', ']')) -ge 0) {
        throw "Service or driver name '$Name' is not canonical."
    }
    foreach ($character in $Name.ToCharArray()) {
        if ([char]::IsControl($character)) {
            throw "Service or driver name '$Name' is not canonical."
        }
    }
}

function Set-AtlasServiceStartup {
    <#
    .SYNOPSIS
        Sets the Start value of a service or driver and checks that it kept it.
    .DESCRIPTION
        Writes the Start value in the service's registry key, because Set-Service can't
        change protected services or drivers, then reads it back, because a
        tamper-protected service can silently discard the write. A running service
        keeps running. A missing service is skipped when disabling, since it can't
        run anyway.
    .PARAMETER Name
        The service or driver key name under HKLM\SYSTEM\CurrentControlSet\Services.
    .PARAMETER StartupType
        The Start value: 0 Boot, 1 System, 2 Automatic, 3 Manual or 4 Disabled.
    .PARAMETER AllowMissing
        Logs and skips a missing service instead of throwing.
    .PARAMETER PassThru
        Returns an object with Name, Applied and StartupType.
    .PARAMETER ServicesRoot
        The Services key to change. Tests pass an isolated registry root.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 4)]
        [int]$StartupType,

        [switch]$AllowMissing,
        [switch]$PassThru,

        [ValidateNotNullOrEmpty()]
        [string]$ServicesRoot = 'HKLM:\SYSTEM\CurrentControlSet\Services'
    )

    Assert-AtlasServiceRegistryName -Name $Name
    $servicePath = Join-Path -Path $ServicesRoot -ChildPath $Name
    if (-not (Test-Path -LiteralPath $servicePath -ErrorAction Stop)) {
        if ($StartupType -eq 4) {
            Write-AtlasLog -Message "Service or driver '$Name' is absent and cannot run; skipping disable."
            if ($PassThru) {
                return [pscustomobject]@{ Name = $Name; Applied = $false; StartupType = $null }
            }
            return
        }
        if (-not $AllowMissing) {
            throw "Required service or driver '$Name' does not exist under '$ServicesRoot'."
        }
        # Optional entries name services some Windows versions or PCs don't have,
        # such as BthPan without Bluetooth: nothing to do, and nothing wrong.
        Write-AtlasLog -Message "Service or driver '$Name' isn't on this PC; nothing to change."
        if ($PassThru) {
            return [pscustomobject]@{ Name = $Name; Applied = $false; StartupType = $null }
        }
        return
    }

    $key = Get-Item -LiteralPath $servicePath -ErrorAction Stop
    try {
        $alreadyConfigured = $key.GetValueNames() -contains 'Start' -and
            $key.GetValueKind('Start') -eq [Microsoft.Win32.RegistryValueKind]::DWord -and
            [int]$key.GetValue('Start') -eq $StartupType
    }
    finally {
        $key.Close()
    }
    if ($alreadyConfigured) {
        Write-AtlasLog -Message "Service or driver '$Name' already has startup type '$StartupType'; skipping change."
        if ($PassThru) {
            return [pscustomobject]@{ Name = $Name; Applied = $true; StartupType = $StartupType }
        }
        return
    }

    Set-ItemProperty -LiteralPath $servicePath -Name 'Start' -Value $StartupType `
        -Type DWord -Force -ErrorAction Stop
    $key = Get-Item -LiteralPath $servicePath -ErrorAction Stop
    try {
        if ($key.GetValueKind('Start') -ne [Microsoft.Win32.RegistryValueKind]::DWord -or
            [int]$key.GetValue('Start') -ne $StartupType) {
            throw "Service or driver '$Name' did not retain startup type '$StartupType'."
        }
    }
    finally {
        $key.Close()
    }

    if ($PassThru) {
        return [pscustomobject]@{
            Name = $Name
            Applied = $true
            StartupType = $StartupType
        }
    }
}

function Stop-AtlasService {
    <#
    .SYNOPSIS
        Stops a service and the services that depend on it, logging a warning instead
        of failing when it can't.
    .PARAMETER Name
        The service name.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    try {
        Stop-Service -Name $Name -Force -ErrorAction Stop
    }
    catch {
        Write-AtlasLog -Level Warning -Message (
            "Couldn't stop service '$Name': $($_.Exception.Message)"
        )
    }
}
