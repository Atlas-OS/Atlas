# Atlas.Services domain: service and driver startup configuration.
# Start values: 0 = Boot, 1 = System, 2 = Automatic, 3 = Manual, 4 = Disabled.

function Assert-AtlasServiceRegistryName {
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
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 4)]
        [int]$StartupType,

        [switch]$AllowMissing,
        [switch]$PassThru,

        # Tests can supply an isolated registry root.
        [ValidateNotNullOrEmpty()]
        [string]$ServicesRoot = 'HKLM:\SYSTEM\CurrentControlSet\Services'
    )

    Assert-AtlasServiceRegistryName -Name $Name
    $servicePath = Join-Path -Path $ServicesRoot -ChildPath $Name
    if (-not (Test-Path -LiteralPath $servicePath -ErrorAction Stop)) {
        if (-not $AllowMissing) {
            throw "Required service or driver '$Name' does not exist under '$ServicesRoot'."
        }
        Write-AtlasLog -Level Warning -Message (
            "Optional service or driver '$Name' does not exist; skipping it."
        )
        if ($PassThru) {
            return [pscustomobject]@{ Name = $Name; Applied = $false; StartupType = $null }
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
