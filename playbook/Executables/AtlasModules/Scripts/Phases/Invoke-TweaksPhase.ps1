# Tweaks phase.
# Stub: the legacy YAML task chain still performs this phase's work. Real logic moves
# here as the corresponding YAML is retired during the PowerShell migration.
param(
    [string]$Category
)

Write-AtlasLog -Message "Tweaks phase stub executed for category '$Category'; work currently handled by the legacy YAML chain."
