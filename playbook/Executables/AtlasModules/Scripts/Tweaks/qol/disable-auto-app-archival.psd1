@{
    Name        = 'Disable Automatic Store App Archiving'
    Description = 'Disables automatic Store app archiving so that less commonly apps don''t disappear and have to be redownloaded'
    Toggle      = @(
        @{ Name = 'AppStoreArchiving'; State = 'Disable' }
    )
}
