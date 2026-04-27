@{
    Severity = @('Error', 'Warning')

    ExcludeRules = @(
        # Atlas scripts use Write-Host intentionally for colored playbook output
        'PSAvoidUsingWriteHost',
        # Positional parameters are common in short Atlas helper calls
        'PSAvoidUsingPositionalParameters'
    )
}
