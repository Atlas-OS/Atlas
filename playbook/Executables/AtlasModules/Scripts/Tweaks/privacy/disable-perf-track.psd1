@{
    Name        = 'Disable Performance Track'
    Description = 'Turns off PerfTrack, which records responsiveness events for Microsoft''s diagnostics.'
    Registry    = @(
        # https://admx.help/?Category=Windows_11_2022&Policy=Microsoft.Policies.PerformancePerftrack::WdiScenarioExecutionPolicy
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WDI\{9c5a40da-b965-4fc3-8781-88dd50a6299d}'; Name = 'ScenarioExecutionEnabled'; Type = 'DWord'; Data = 0 }
    )
}
