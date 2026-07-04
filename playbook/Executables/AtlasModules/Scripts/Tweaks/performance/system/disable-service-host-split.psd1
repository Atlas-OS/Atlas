@{
    Name        = 'Disable Service Host Splitting'
    Description = 'Disables Service Host splitting for a much lower process count (~70 svchost processes down to ~20) and a modest memory reduction, excluding Xbox services to fix issues with Game Bar. Trade-off per Microsoft: shared hosts lose per-service isolation, so one crashing service can take down the others in its host.'
    # https://learn.microsoft.com/en-us/windows/application-management/svchost-service-refactoring
    Script      = 'disable-service-host-split.ps1'
}
