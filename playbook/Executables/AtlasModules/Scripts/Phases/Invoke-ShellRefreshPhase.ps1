# Shell refresh phase.
# Replaces the AME-specific process-kill and run actions with the shared process
# helpers. The phase runs as TrustedInstaller so it can stop shell processes across
# integrity levels, then launches Explorer with the interactive user's unelevated token.

Assert-AtlasPrivilege -TrustedInstaller

$modulesRoot = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'Modules'
Import-Module -Name (Join-Path $modulesRoot 'Atlas.TasksProcs\Atlas.TasksProcs.psd1') -Force -ErrorAction Stop

Stop-AtlasProcess -Name 'explorer', 'ShellExperienceHost'

$explorerPath = Join-Path -Path (Get-AtlasContext).WinDir -ChildPath 'explorer.exe'
$null = Invoke-AtlasAsUser -FilePath $explorerPath -Wait:$false
