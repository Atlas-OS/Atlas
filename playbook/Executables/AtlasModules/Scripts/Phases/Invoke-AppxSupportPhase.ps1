# AppxSupport phase.
# Brackets the AME !appx family removals in atlas\appx.yml (which stay in YAML because
# AME's provisioned/system package removal is battle-tested where Remove-AppxPackage
# documented-fails). Runs elevated (runas: currentUserElevated), invoked twice:
#   -Category Snapshot  before the !appx block: package snapshot + Teams process kills
#   -Category Cleanup   after the !appx block: Phone Link removal, deprovisioning of
#                       everything removed since the snapshot, and AppX cache clearing
# The Teams chat auto-install prevention stays in atlas\appx.yml: its Communications
# key is TrustedInstaller-protected, out of reach of this phase's admin context.
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Snapshot', 'Cleanup')]
    [string]$Category
)

Assert-AtlasPrivilege -Administrator

$modulesRoot = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'Modules'
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Appx\Atlas.Appx.psd1') -Force -ErrorAction Stop
Import-Module -Name (Join-Path $modulesRoot 'Atlas.TasksProcs\Atlas.TasksProcs.psd1') -Force -ErrorAction Stop

switch ($Category) {
    'Snapshot' {
        # Get current AppX packages to deprovision removed ones afterward
        Save-AtlasAppxSnapshot

        # Kill Teams so the !appx removals succeed (legacy AppX Teams + 24H2 MSTeams)
        Stop-AtlasProcess -Name 'msteams*', 'ms-teams*'
    }
    'Cleanup' {
        # Removing Phone Link using AME Wizard causes issues with Cross Device
        # Experience Host installing, so it's removed here instead
        try {
            Remove-AtlasPhoneLinkAppx
        }
        catch {
            Write-AtlasLog -Level Warning -Message "Removing Phone Link failed: $($_.Exception.Message)"
        }

        # Prevent provisioned applications removed by the !appx block from being reinstalled
        # https://learn.microsoft.com/en-us/windows/application-management/remove-provisioned-apps-during-update
        try {
            Set-AtlasAppxDeprovisioned
        }
        catch {
            Write-AtlasLog -Level Warning -Message "Deprovisioning removed AppX packages failed: $($_.Exception.Message)"
        }

        # Clear caches of Client.CBS and more (Start menu cache is cleared later)
        Stop-AtlasProcess -Name 'SearchHost*', 'SearchApp*'
        Clear-AtlasAppxCache -Name '*MicrosoftWindows.Client.CBS*', '*Microsoft.Windows.Search*', '*Microsoft.Windows.SecHealthUI*'
    }
}
