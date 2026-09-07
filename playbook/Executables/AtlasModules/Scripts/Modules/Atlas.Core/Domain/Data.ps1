# Atlas.Core domain: data-file loading and sibling module import.

function Import-AtlasDataFile {
    <#
    .SYNOPSIS
        Loads a PowerShell data file (.psd1) as a hashtable without executing code.
        Every Atlas process pins module resolution through Initialize-AtlasPowerShell.ps1
        before it reaches this function, so the inbox cmdlet is always the one that runs.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LiteralPath
    )

    return Microsoft.PowerShell.Utility\Import-PowerShellDataFile -LiteralPath $LiteralPath -ErrorAction Stop
}

function Import-AtlasModule {
    <#
    .SYNOPSIS
        Imports a sibling Atlas module by name from its exact manifest beside Atlas.Core,
        so callers never depend on PSModulePath or an ambient module with the same name.
        An already-loaded module is reused; nested forced imports would unload the
        command surface of a long-running caller in Windows PowerShell 5.1.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^Atlas\.[A-Za-z]+$')]
        [string]$Name
    )

    $manifest = [IO.Path]::GetFullPath(
        [IO.Path]::Combine($PSScriptRoot, '..', '..', $Name, "$Name.psd1")
    )
    if (-not [IO.File]::Exists($manifest)) {
        throw "The Atlas module manifest '$manifest' is missing."
    }

    # Import into the global session state, where entry scripts and toggle companion
    # functions run. Every sibling module imports Atlas.Core itself, and importing such a
    # sibling from inside Atlas.Core's own session state recurses without end.
    Import-Module -Name $manifest -Global -ErrorAction Stop
}
