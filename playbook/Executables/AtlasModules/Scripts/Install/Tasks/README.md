# Atlas Install Tasks

Install-only task scripts that the Atlas install orchestrator
(`Scripts\Entry\Invoke-AtlasInstall.ps1`) and the install phases under
`Scripts\Install\Phases` invoke while applying the playbook. They run from the
extracted playbook payload or from `%windir%\AtlasModules\Scripts\Install\Tasks`
and are not toggles or post-install operations; those live under
`Scripts\Entry` and `Scripts\Operations`.

Scripts resolve the Atlas Scripts root two levels above this folder and load the
shared bootstrap from `Scripts\Initialize-AtlasPowerShell.ps1` and modules from
`Scripts\Modules`.
