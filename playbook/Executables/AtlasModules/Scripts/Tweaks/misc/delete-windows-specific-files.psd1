@{
    Name        = 'Delete Windows-version Specific Tweaks'
    Description = 'Deletes Windows 10 or Windows 11-only tweaks in the Atlas folder, depending on the current version'
    # Delete ARM-specific files
    # FTH files (which are also non-ARM) are deleted in its own tweak (performance\disable-fth)
    Arch        = 'ARM64'
    Script      = 'delete-windows-specific-files.ps1'
}
