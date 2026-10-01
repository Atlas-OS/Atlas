@{
    # Profile for the scripts that run on users' PCs (playbook/**, app/resources/**)
    # under Windows PowerShell 5.1. Tooling and tests use the stricter
    # PSScriptAnalyzerSettings.psd1.
    Severity = @('Error', 'Warning')

    ExcludeRules = @(
        # Atlas scripts use Write-Host intentionally for colored console output
        'PSAvoidUsingWriteHost',
        # Positional parameters are common in short Atlas helper calls
        'PSAvoidUsingPositionalParameters',
        # Internal Atlas scripts are not published cmdlets; ShouldProcess is not applicable
        'PSUseShouldProcessForStateChangingFunctions',
        # Internal function names do not need to follow module-publishing conventions
        'PSUseSingularNouns',
        # Script-level params used inside nested functions trigger a false positive in PSSA
        'PSReviewUnusedParameter'
    )

    Rules = @{
        # Check syntax for 5.1 and 7.4; runtime tests for these scripts target Windows PowerShell 5.1
        PSUseCompatibleSyntax = @{
            Enable         = $true
            TargetVersions = @('5.1', '7.4')
        }
    }
}
