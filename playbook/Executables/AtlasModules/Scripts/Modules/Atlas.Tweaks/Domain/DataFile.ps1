# Atlas.Tweaks domain: safe .psd1 data-file loading.

function Import-AtlasDataFile {
    <#
    .SYNOPSIS
        Loads a PowerShell data file (.psd1) as a hashtable without executing code.
        Equivalent to Import-PowerShellDataFile, with an AST fallback because machines
        that installed PowerShell 7 can carry a PSModulePath that shadows Windows
        PowerShell 5.1's Microsoft.PowerShell.Utility module, making the cmdlet
        unresolvable.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LiteralPath
    )

    $cmdlet = Get-Command -Name 'Import-PowerShellDataFile' -ErrorAction SilentlyContinue
    if ($cmdlet) {
        return & $cmdlet -LiteralPath $LiteralPath -ErrorAction Stop
    }

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($LiteralPath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors -and $parseErrors.Count -gt 0) {
        throw "Failed to parse data file '$LiteralPath': $($parseErrors[0].Message)"
    }

    $hashtableAst = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.HashtableAst] }, $false)
    if ($null -eq $hashtableAst) {
        throw "Data file '$LiteralPath' does not contain a hashtable."
    }

    # SafeGetValue evaluates constant expressions only - same guarantee the cmdlet gives.
    return $hashtableAst.SafeGetValue()
}
