# Companion of disallow-data-collection.psd1: removes Atlas's fixed DiagTrack log-file
# sets through Atlas.Privacy while the install owns the machine.
$ErrorActionPreference = 'Stop'

Import-AtlasModule -Name Atlas.Privacy
Clear-AtlasTelemetryLogFiles
