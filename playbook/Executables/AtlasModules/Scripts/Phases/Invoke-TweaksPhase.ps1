# Tweaks phase.
# Applies one category of declarative tweak definitions (Scripts\Tweaks\<category>).
# Runs as TrustedInstaller so ACL-protected keys can be written and HKCU redirection
# resolves correctly.
param(
    [Parameter(Mandatory = $true)]
    [string]$Category
)

Assert-AtlasPrivilege -TrustedInstaller

$modulesRoot = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'Modules'
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Tweaks\Atlas.Tweaks.psd1') -Force -ErrorAction Stop

Invoke-AtlasTweakCategory -Name $Category
