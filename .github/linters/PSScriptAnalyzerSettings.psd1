@{
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
        # InstallSoftware.ps1 uses global vars intentionally for its progress display state machine
        'PSAvoidGlobalVars',
        # BOM handling is a per-file encoding decision, not enforced project-wide
        'PSUseBOMForUnicodeEncodedFile',
        # Script-level params used inside nested functions trigger a false positive in PSSA
        'PSReviewUnusedParameter'
    )
}
