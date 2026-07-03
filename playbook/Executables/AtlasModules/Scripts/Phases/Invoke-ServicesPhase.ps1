# Services phase.
# Backs up the default Windows services, applies the scripted network/search
# configuration and disables the curated set of services/drivers. custom.yml gates
# this phase (onUpgrade: false) and runs it as TrustedInstaller.
#
# ----------------------------------
# - Potential references           -
# - Mostly upon IoT recommendation -
# ----------------------------------
# https://learn.microsoft.com/en-us/windows-server/remote/remote-desktop-services/rds-vdi-recommendations-2004
# https://learn.microsoft.com/en-us/windows-server/security/windows-services/security-guidelines-for-disabling-system-services-in-windows-server
# https://learn.microsoft.com/en-us/windows/iot/iot-enterprise/optimize/services

Assert-AtlasPrivilege -TrustedInstaller

Import-Module Atlas.Services -Force

$context = Get-AtlasContext
$internalRoot = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'Internal'

# Back up default Windows services & drivers (kept if a backup already exists)
Export-AtlasServicesBackup

# Disable File Sharing
try {
    & (Join-Path -Path $internalRoot -ChildPath 'Disable-FileSharing.ps1') -Silent
}
catch {
    Write-AtlasLog -Level Warning -Message "Disabling file sharing failed: $($_.Exception.Message)"
}

# Disable Location, configure Indexing (records toggle state like a user double-click)
foreach ($toggle in @(
    'AtlasDesktop\3. General Configuration\Location\Disable Location (default).cmd'
    'AtlasDesktop\3. General Configuration\Search Indexing\Minimal Search Indexing (default).cmd'
)) {
    $togglePath = Join-Path -Path $context.WinDir -ChildPath $toggle
    try {
        Start-Process -FilePath $togglePath -ArgumentList '/silent' -Wait
    }
    catch {
        Write-AtlasLog -Level Warning -Message "Running '$togglePath' failed: $($_.Exception.Message)"
    }
}

# Services (Start = 4 -> disabled)
$services = @(
    # ------ Microsoft recommendation - 'OK to disable' ------
    'OneSyncSvc'
    'TrkWks'
    'PcaSvc'
    'DiagTrack'
    # ------ Microsoft recommendation - 'Do not disable' -----
    'diagnosticshub.standardcollector.service'
    'WerSvc'
    # ------- Microsoft recommendation - 'No guidance' -------
    'wercplsupport'
    'UCPD'
)

# Drivers (Start = 4 -> disabled)
$drivers = @(
    'GpuEnergyDrv'
    # NetBios support can be enabled with the file sharing script
    'NetBT'
    'Telemetry'
)

foreach ($name in ($services + $drivers)) {
    Set-AtlasServiceStartup -Name $name -StartupType 4
}
