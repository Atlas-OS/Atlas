# Thin forwarder kept for ScriptWrappers\Install-Software.ps1 ("Install Software" in the
# Atlas folder); the WinGet picker UI lives in the Atlas.Software module
# (Show-AtlasSoftwarePicker). Exits 1 when WinGet is unavailable.
$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Modules\Atlas.Software\Atlas.Software.psd1')

if (-not (Show-AtlasSoftwarePicker)) {
    exit 1
}
