@{
    Name        = 'Disable Service Host Splitting'
    Description = 'Disables Service Host splitting for much lower RAM usage and process count, excluding XBOX services to fix issues with Game Bar'
    # https://learn.microsoft.com/en-us/windows/application-management/svchost-service-refactoring
    Script      = 'disable-service-host-split.ps1'
}
