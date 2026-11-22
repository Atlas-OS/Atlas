# Dot-sourced, as TrustedInstaller, by the phases and tasks that start a process as the
# installing user, so a failure names its reason.
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

function Get-AtlasUserLogError {
    <#
    .SYNOPSIS
        Returns the newest error a user's own Atlas log recorded since NotBefore, so a
        failed user pass names the change that failed instead of only an exit code.
        Write-AtlasLog keeps a non-elevated account's log in that account's profile.
    #>
    param(
        # Empty adds nothing, so a missing account never replaces the failure.
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$UserSid,

        # The log's times are local and to the second.
        [datetime]$NotBefore = [datetime]::MinValue
    )

    if ([string]::IsNullOrWhiteSpace($UserSid)) {
        return ''
    }
    try {
        $profileKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$UserSid"
        $profilePath = (Get-ItemProperty -LiteralPath $profileKey -Name 'ProfileImagePath' -ErrorAction Stop).ProfileImagePath
        $profilePath = [Environment]::ExpandEnvironmentVariables([string]$profilePath)
        $log = [IO.Path]::Combine($profilePath, 'AppData', 'Local', 'AtlasOS', 'Logs', 'install', 'atlas-install.log')
        if (-not [IO.File]::Exists($log)) {
            return ''
        }

        if ($NotBefore.Kind -eq [DateTimeKind]::Utc) { $NotBefore = $NotBefore.ToLocalTime() }
        $since = $NotBefore.AddTicks(-($NotBefore.Ticks % [TimeSpan]::TicksPerSecond))
        $pattern = '^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\] \[[^\]]*\] \[ERROR\] (.+)$'
        $newest = ''
        foreach ($line in @(Get-Content -LiteralPath $log -Tail 200 -Encoding UTF8 -ErrorAction Stop)) {
            $match = [regex]::Match([string]$line, $pattern)
            if (-not $match.Success) { continue }
            $written = [datetime]::ParseExact($match.Groups[1].Value, 'yyyy-MM-dd HH:mm:ss', [Globalization.CultureInfo]::InvariantCulture)
            if ($written -ge $since) {
                # Without the script position Write-AtlasLog appends after ' | '.
                $newest = $match.Groups[2].Value -replace ' \| At .*$', ''
            }
        }
        if ($newest -eq '') {
            return ''
        }
        return " $newest"
    }
    catch {
        # Diagnostics must never replace the failure they are describing.
        return ''
    }
}

