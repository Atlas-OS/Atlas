function Get-AtlasUserFailureDetail {
    <#
    .SYNOPSIS
        Returns the tail of the newest operation transcript for a user, so a
        failed user operation reports why instead of only an exit code. The child runs in
        the user's session, where its output never reaches this console.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$UserSid,

        [Parameter(Mandatory = $true)]
        [string]$TranscriptPattern,

        [datetime]$NotBefore = [datetime]::MinValue
    )

    try {
        $profileKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$UserSid"
        $profilePath = (Get-ItemProperty -LiteralPath $profileKey -Name 'ProfileImagePath' -ErrorAction Stop).ProfileImagePath
        $profilePath = [Environment]::ExpandEnvironmentVariables([string]$profilePath)
        $logDirectory = [IO.Path]::Combine($profilePath, 'AppData', 'Local', 'AtlasOS', 'Logs')
        if (-not [IO.Directory]::Exists($logDirectory)) {
            return ''
        }

        $transcript = @(Get-ChildItem -LiteralPath $logDirectory -Filter $TranscriptPattern -File -ErrorAction Stop |
                Where-Object { $_.LastWriteTimeUtc -ge $NotBefore } | Sort-Object -Property LastWriteTimeUtc -Descending) | Select-Object -First 1
        if ($null -eq $transcript) {
            return ''
        }

        $tail = @(Get-Content -LiteralPath $transcript.FullName -Tail 20 -ErrorAction Stop)
        if ($tail.Count -eq 0) {
            return ''
        }
        return " Last lines of '$($transcript.FullName)':`n$($tail -join "`n")"
    }
    catch {
        # Diagnostics must never replace the failure they are describing.
        return " The user operation transcript could not be read: $($_.Exception.Message)"
    }
}

