# Atlas.Services domain: service/driver startup configuration.
#
# The startup type is written straight to the service key because Set-Service cannot
# touch kernel drivers or protected services, even as TrustedInstaller. Start values:
# 0 = Boot, 1 = System, 2 = Automatic, 3 = Manual, 4 = Disabled.

function Set-AtlasServiceStartup {
    <#
    .SYNOPSIS
        Sets the Start value of a service or driver by writing the registry directly.
        A missing service key logs a warning instead of failing, as service presence
        differs between Windows editions and builds.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 4)]
        [int]$StartupType,

        # Overridable for tests; production callers always use the live services root.
        [ValidateNotNullOrEmpty()]
        [string]$ServicesRoot = 'HKLM:\SYSTEM\CurrentControlSet\Services'
    )

    $serviceKey = Join-Path -Path $ServicesRoot -ChildPath $Name
    if (-not (Test-Path -LiteralPath $serviceKey)) {
        Write-AtlasLog -Level Warning -Message "Service or driver '$Name' does not exist; not changing its startup type."
        return
    }

    Set-ItemProperty -LiteralPath $serviceKey -Name 'Start' -Value $StartupType -Type DWord -Force
}

function Stop-AtlasService {
    <#
    .SYNOPSIS
        Stops a service (forcing dependent services to stop too). Failures - including a
        missing service - are logged as warnings so install phases keep going.
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
        Write-AtlasLog -Level Warning -Message "Couldn't stop service '$Name': $($_.Exception.Message)"
    }
}
