@{
    Name        = 'Disable Service Host Splitting'
    Description = 'Groups services into fewer service host processes, cutting about 70 svchost processes to about 20 and saving some memory. Xbox services stay separate so Game Bar keeps working. Microsoft notes that services sharing a host lose their isolation, so one crashing service can stop the others in its host.'
    # https://learn.microsoft.com/windows/application-management/svchost-service-refactoring
    Script      = 'disable-service-host-split.ps1'
}
