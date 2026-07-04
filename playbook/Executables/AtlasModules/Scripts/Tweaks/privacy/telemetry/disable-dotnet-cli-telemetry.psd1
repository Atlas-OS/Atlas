@{
    Name        = 'Disable .NET CLI Telemetry'
    Description = 'Disables .NET CLI telemetry for privacy'
    Registry    = @(
        # Machine-wide environment variable. Written declaratively because a `setx` Run
        # entry executes as TrustedInstaller/SYSTEM and would land in SYSTEM's per-user
        # environment, never reaching real users.
        # https://learn.microsoft.com/en-us/dotnet/core/tools/telemetry
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'; Name = 'DOTNET_CLI_TELEMETRY_OPTOUT'; Type = 'String'; Data = '1' }
    )
}
