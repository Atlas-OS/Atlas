@{
    OnUpgrade   = 'Skip'
    OnRebase    = 'Run'
    Name        = 'Delete Windows-version Specific Tweaks'
    Description = 'Removes the Open-Shell launchers from AtlasDesktop on ARM64, where they don''t apply. It only changes Atlas''s own desktop folder, never Windows files.'
    # Delete files that don't apply on ARM64.
    # performance\disable-fth removes the FTH files, which don't apply on ARM64 either.
    Arch        = 'ARM64'
    Script      = 'delete-windows-specific-files.ps1'
}
