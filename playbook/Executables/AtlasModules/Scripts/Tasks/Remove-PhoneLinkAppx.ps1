# Thin forwarder; the logic lives in the Atlas.Appx module (Remove-AtlasPhoneLinkAppx),
# called by the AppxSupport install phase. Kept so external invocations of this path
# keep working.
$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Modules\Atlas.Appx\Atlas.Appx.psd1')
Remove-AtlasPhoneLinkAppx
