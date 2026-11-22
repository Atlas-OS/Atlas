# Uninstalls Process Explorer in its own process for Stop-ProcessExplorerUpgrade.ps1, which
# runs it as TrustedInstaller before the installed Atlas files are replaced. It does no
# user profile work and changes no toggle record.
$ErrorActionPreference = 'Stop'
$scriptsRoot = [IO.Path]::GetFullPath([IO.Path]::Combine($PSScriptRoot, '..', '..'))
. ([IO.Path]::Combine($scriptsRoot, 'Initialize-AtlasPowerShell.ps1'))
try {
    Import-Module ([IO.Path]::Combine($scriptsRoot, 'Modules', 'Atlas.Core', 'Atlas.Core.psd1')) -ErrorAction Stop
    Assert-AtlasPrivilege -Admin
    . ([IO.Path]::Combine($scriptsRoot, 'Operations', 'ProcessExplorer-Package.ps1'))
    Uninstall-AtlasProcessExplorerPackage
    exit 0
}
catch {
    Write-AtlasLog -Level Error -Message "Installer Process Explorer cleanup failed: $($_.Exception.Message)" -ErrorRecord $_
    exit 1
}
