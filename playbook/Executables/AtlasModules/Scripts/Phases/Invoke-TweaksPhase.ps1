# Tweaks phase.
# Applies one category of declarative tweak definitions (Scripts\Tweaks\<category>).
# Runs as TrustedInstaller so ACL-protected keys and HKCU redirection behave exactly
# like the AME !registryValue actions this replaces.
param(
    [Parameter(Mandatory = $true)]
    [string]$Category
)

Assert-AtlasPrivilege -TrustedInstaller

Import-Module Atlas.Registry -Force
Import-Module Atlas.Tweaks -Force

Invoke-AtlasTweakCategory -Name $Category
