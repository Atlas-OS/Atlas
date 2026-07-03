@{
    # Strict profile for build tooling (tools/**) and tests (tests/**), which run under
    # PowerShell 5.1 or 7 on developer machines and CI. The shipped payload uses the more
    # lenient PSScriptAnalyzerSettings.Payload.psd1.
    Severity = @('Error', 'Warning')

    ExcludeRules = @(
        # Build scripts print progress/results intentionally with colors
        'PSAvoidUsingWriteHost',
        # Internal tooling functions are not published cmdlets; ShouldProcess is not applicable
        'PSUseShouldProcessForStateChangingFunctions'
    )
}
