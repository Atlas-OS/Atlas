<#
.SYNOPSIS
    Brings back what a Windows that rebuilt itself during Atlas Manager's move to a
    newer release left behind: the service backups and the recorded choices.
.DESCRIPTION
    Runs in Rebase installs only, after Atlas's files are copied and before the
    recorded choices are read. Setup moves %windir%\AtlasModules to Windows.old, so
    the service backups made before Atlas first changed the services are copied back
    from there. The recorded choices come from Atlas Manager's record of the move
    when the registry that held them is gone; existing records are never replaced.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
Assert-AtlasPrivilege -TrustedInstaller
$scriptsRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $scriptsRoot 'Preparation\WindowsTransition.ps1')
Import-Module -Name (Join-Path $scriptsRoot 'Modules\Atlas.Toggles\Atlas.Toggles.psd1') -Force -ErrorAction Stop

$rebase = Get-AtlasWindowsTransitionRebase
if ($null -eq $rebase) {
    throw 'A Rebase install needs Atlas Manager''s record of the Windows move, which is gone or unreadable.'
}
foreach ($name in @('winServices.reg', 'atlasServices.reg')) {
    Write-AtlasLog -Message (Copy-AtlasRebaseServiceBackup -Name $name)
}
foreach ($line in @(Restore-AtlasRebaseChoice $rebase.Carry)) {
    Write-AtlasLog -Message ([string]$line)
}
