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
        tamper-protected service can silently discard the write. The service manager
        reads that value only when Windows starts, and until then refuses to start a
        service it still holds as disabled (error 1058). So when it holds another
        startup type, sc.exe changes it there too, also when the registry already had
        the new value. A service the service manager won't change, as Windows can
        refuse for a protected one, keeps the registry write, which applies after a
        restart, and is logged, as a warning when this call changed the registry
        (see Sync-AtlasServiceManagerStartup). A running service keeps running. A
        missing service is skipped when disabling, since it can't run anyway.
    .PARAMETER Name
        The service or driver key name under HKLM\SYSTEM\CurrentControlSet\Services.
    .PARAMETER StartupType
        The Start value: 0 Boot, 1 System, 2 Automatic, 3 Manual or 4 Disabled.
    .PARAMETER AllowMissing
        Logs and skips a missing service instead of throwing.
    .PARAMETER PassThru
        Returns an object with Name, Applied, StartupType and ServiceManager: Synced
        when the service manager holds the startup type, Refused when it kept another,
        or $null when it wasn't asked or doesn't list the service.
    .PARAMETER ServicesRoot
        The Services key to change. Tests pass an isolated registry root, which the
        service manager never reads, so it isn't asked then.
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
                return [pscustomobject]@{ Name = $Name; Applied = $false; StartupType = $null; ServiceManager = $null }
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
            return [pscustomobject]@{ Name = $Name; Applied = $false; StartupType = $null; ServiceManager = $null }
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
    }
    else {
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
    }

    # A value already in the registry can still be one the service manager hasn't
    # read, from an earlier write without it.
    $serviceManager = $null
    if (Test-AtlasServiceRootLive -ServicesRoot $ServicesRoot) {
        $serviceManager = Sync-AtlasServiceManagerStartup -Name $Name -StartupType $StartupType -ServicePath $servicePath `
            -Unchanged:$alreadyConfigured
    }

    if ($PassThru) {
        return [pscustomobject]@{
            Name = $Name
            Applied = $true
            StartupType = $StartupType
            ServiceManager = $serviceManager
        }
    }
}

function Test-AtlasServiceRootLive {
    <#
    .SYNOPSIS
        Whether a Services root is this PC's own, the one the service manager reads.
    #>
    param([Parameter(Mandatory = $true)][string]$ServicesRoot)

    return $ServicesRoot.TrimEnd('\') -ieq 'HKLM:\SYSTEM\CurrentControlSet\Services'
}

function Sync-AtlasServiceManagerStartup {
    <#
    .SYNOPSIS
        Gives the service manager a service's startup type when it holds another.
        Returns Synced when it holds the type, Refused when it kept another, or $null
        when it doesn't list the service.
    .DESCRIPTION
        sc.exe changes the service manager's startup type and the registry value
        together. An automatic service whose key marks it delayed (DelayedAutostart
        1) stays delayed. A per-user service's template (Type 0x50 or 0x60) isn't
        changed there: Windows gives each account's copy the template's registry
        value when it creates it. Nothing is asked of sc.exe when the service
        manager's startup type can't be read. A refusal is a warning when this call
        changed the registry, and only noted with -Unchanged, when the registry
        already held the value: the same refusal then comes on every run.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][ValidateRange(0, 4)][int]$StartupType,
        [Parameter(Mandatory = $true)][string]$ServicePath,
        [switch]$Unchanged
    )

    $type = Get-ItemProperty -LiteralPath $ServicePath -Name 'Type' -ErrorAction SilentlyContinue
    # SERVICE_USER_SERVICE (0x40) without SERVICE_USERSERVICE_INSTANCE (0x80).
    if ($null -ne $type -and ([int64]$type.Type -band 0xC0) -eq 0x40) {
        Write-AtlasLog -Message "'$Name' is a per-user service template; each account's copy takes its startup type when Windows creates it."
        return $null
    }
    $held = Get-AtlasServiceManagerStartup -Name $Name
    if ($null -eq $held) {
        Write-AtlasLog -Message "The service manager doesn't list '$Name'; Windows reads its startup type when it next starts."
        return $null
    }
    if ($held -lt 0) {
        Write-AtlasLog -Message "The service manager's startup type for '$Name' couldn't be read; Windows reads the registry's when it next starts."
        return $null
    }
    if ($held -eq $StartupType) {
        return 'Synced'
    }

    $mode = @('boot', 'system', 'auto', 'demand', 'disabled')[$StartupType]
    if ($StartupType -eq 2) {
        $delayed = Get-ItemProperty -LiteralPath $ServicePath -Name 'DelayedAutostart' -ErrorAction SilentlyContinue
        if ($null -ne $delayed -and [int]$delayed.DelayedAutostart -eq 1) { $mode = 'delayed-auto' }
    }
    try {
        Invoke-AtlasServiceControlConfig -Name $Name -Mode $mode
    }
    catch {
        Write-AtlasLog -Level $(if ($Unchanged) { 'Info' } else { 'Warning' }) -Message (
            "The service manager kept '$held' for '$Name': $($_.Exception.Message) " +
            "The registry has '$StartupType', which Windows uses after a restart."
        )
        return 'Refused'
    }
    Write-AtlasLog -Message "The service manager held '$held' for '$Name'; it now has '$mode'."
    return 'Synced'
}

function Get-AtlasServiceManagerStartup {
    <#
    .SYNOPSIS
        The startup type the service manager holds for a service or driver, as a Start
        value, $null when it doesn't list it, or -1 when it can't be read.
    #>
    param([Parameter(Mandatory = $true)][string]$Name)

    Add-Type -AssemblyName System.ServiceProcess
    $controller = New-Object System.ServiceProcess.ServiceController($Name)
    try {
        # Read through reflection: PowerShell turns a property getter's exception,
        # such as the one for a service that doesn't exist, into $null, which would
        # read as Boot.
        return [int][System.ServiceProcess.ServiceController].GetProperty('StartType').GetValue($controller, $null)
    }
    catch {
        for ($cause = $_.Exception; $null -ne $cause; $cause = $cause.InnerException) {
            # ERROR_SERVICE_DOES_NOT_EXIST
            if ($cause -is [ComponentModel.Win32Exception] -and $cause.NativeErrorCode -eq 1060) { return $null }
        }
        return -1
    }
    finally {
        $controller.Dispose()
    }
}

function Invoke-AtlasServiceControlConfig {
    <#
    .SYNOPSIS
        Sets a service's startup type with sc.exe, which changes the service manager's
        copy and the registry value, and throws when sc.exe refuses.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)]
        [ValidateSet('boot', 'system', 'auto', 'delayed-auto', 'demand', 'disabled')]
        [string]$Mode
    )

    $sc = Join-Path -Path ([Environment]::SystemDirectory) -ChildPath 'sc.exe'
    # Redirected native stderr becomes an error record; the exit code decides.
    $previousPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& $sc config $Name start= $Mode 2>&1 | ForEach-Object { [string]$_ })
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($exitCode -ne 0) {
        $said = (($output -join ' ') -replace '\s+', ' ').Trim()
        throw "sc.exe exited $exitCode$(if ($said) { ": $said" })."
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
