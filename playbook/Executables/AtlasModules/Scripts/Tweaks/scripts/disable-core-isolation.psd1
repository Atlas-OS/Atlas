@{
    Name        = 'Disable Virtualization-Based Security'
    Description = 'Disables VBS and Memory Integrity through Microsoft''s documented runtime registry controls. Credential Guard preferences, LSA protection, kernel stack protection preferences, and optional Windows features are preserved rather than guessed or removed.'
    Option      = 'disable-core-isolation'
    Script      = 'disable-core-isolation.ps1'
}
