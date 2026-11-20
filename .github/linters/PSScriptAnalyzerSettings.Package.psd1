@{
    # Profile for the scripts that run on users' PCs (package/**, app/resources/**)
    # under Windows PowerShell 5.1. Tooling and tests use the stricter
    # PSScriptAnalyzerSettings.psd1.
    # Information is included for PSProvideCommentHelp, which reports at that severity.
    Severity = @('Error', 'Warning', 'Information')

    ExcludeRules = @(
        # Reports at Information severity, which is here only for PSProvideCommentHelp
        'PSUseOutputTypeCorrectly',
        # Atlas scripts use Write-Host intentionally for coloured console output
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
        # Exported functions need comment-based help (docs/style.md). PSScriptAnalyzer reads
        # each file alone, so it sees only functions exported with a name list
        # (Export-ModuleMember -Function A, B) in the file that defines them.
        PSProvideCommentHelp  = @{
            Enable                  = $true
            ExportedOnly            = $true
            BlockComment            = $true
            VSCodeSnippetCorrection = $false
            Placement               = 'begin'
        }
    }
}
