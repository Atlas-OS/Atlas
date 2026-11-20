@{
    Name        = 'Disable Automatic Store App Archiving'
    Description = 'Stops Microsoft Store archiving apps you rarely use, so they don''t disappear and need downloading again.'
    Toggle      = @(
        @{ Name = 'AppStoreArchiving'; State = 'Disable' }
    )
}
