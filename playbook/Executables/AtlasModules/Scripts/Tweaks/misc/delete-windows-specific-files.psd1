@{
    Name        = 'Delete Windows-version Specific Tweaks'
    Description = 'Removes AtlasDesktop tweak scripts that do not apply to this machine (currently: Open-Shell Start Menu items on ARM64). Only touches Atlas''s own desktop folder, never Windows files.'
    # Delete ARM-specific files
    # FTH files (which are also non-ARM) are deleted in its own tweak (performance\disable-fth)
    Arch        = 'ARM64'
    Script      = 'delete-windows-specific-files.ps1'
}
