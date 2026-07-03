@{
    Name        = 'Disable Performance Track'
    Description = 'Disables tracking of responsiveness events for privacy'
    Registry    = @(
        # https://admx.help/?Category=Windows_11_2022&Policy=Microsoft.Policies.PerformancePerftrack::WdiScenarioExecutionPolicy
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WDI\{9c5a40da-b965-4fc3-8781-88dd50a6299d}'; Name = 'ScenarioExecutionEnabled'; Type = 'DWord'; Data = 0 }
    )
}
