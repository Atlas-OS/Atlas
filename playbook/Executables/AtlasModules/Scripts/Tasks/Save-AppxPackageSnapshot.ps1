# Thin forwarder; the logic lives in the Atlas.Appx module (Save-AtlasAppxSnapshot),
# called by the AppxSupport install phase. Kept so external invocations of this path
# keep working until the migration completes.
$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Modules\Atlas.Appx\Atlas.Appx.psd1')
Save-AtlasAppxSnapshot
