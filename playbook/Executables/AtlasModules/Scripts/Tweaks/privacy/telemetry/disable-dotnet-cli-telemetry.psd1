@{
    Name        = 'Disable .NET CLI Telemetry'
    Description = 'Disables .NET CLI telemetry for privacy'
    Run         = @(
        # https://learn.microsoft.com/en-us/dotnet/core/tools/telemetry
        @{ Exe = 'cmd.exe'; Args = '/c setx DOTNET_CLI_TELEMETRY_OPTOUT 1' }
    )
}
