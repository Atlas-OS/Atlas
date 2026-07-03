@{
    # Profile for the shipped payload (playbook/**), which runs under Windows PowerShell 5.1
    # on target machines. Tooling and tests use the stricter PSScriptAnalyzerSettings.psd1.
    Severity = @('Error', 'Warning')

    ExcludeRules = @(
        # Atlas scripts use Write-Host intentionally for colored playbook output
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
        # The payload must parse and run on both Windows PowerShell 5.1 and PowerShell 7
        PSUseCompatibleSyntax = @{
            Enable         = $true
            TargetVersions = @('5.1', '7.4')
        }
    }
}
