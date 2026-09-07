# Companion of disable-core-isolation.psd1.
$ErrorActionPreference = 'Stop'

Import-AtlasModule -Name Atlas.Security
Set-AtlasVbsConfiguration -State Disable
