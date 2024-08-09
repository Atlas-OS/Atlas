function Write-Title {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Text
    )

    $dashes = '-' * $text.Length
    Write-Host "`n$dashes`n$text`n$dashes" -ForegroundColor Yellow
}

Export-ModuleMember -Function Write-Title