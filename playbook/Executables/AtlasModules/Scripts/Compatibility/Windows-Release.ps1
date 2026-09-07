# Windows release eligibility, not installation/media authenticity. Dot-sourcing
# defines functions only; network access is deferred until an unknown build is checked.
function ConvertFrom-AtlasWindowsReleaseMarkdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Markdown,
        [datetime]$AsOfDate = [datetime]::UtcNow.Date
    )
    $Markdown = $Markdown.Replace("`r`n", "`n")
    $heading = [regex]::Match($Markdown, '(?m)^\s*(?:\*\*|#{1,6}\s*)?Version 25H2 \(OS build 26200\)(?:\*\*)?\s*$')
    if (-not $heading.Success) { throw 'The official 25H2 release section is missing.' }
    $section = $Markdown.Substring($heading.Index + $heading.Length)
    $nextHeading = [regex]::Match($section, '(?m)^\s*(?:\*\*|#{1,6}\s*)?Version [^\r\n]+$')
    if ($nextHeading.Success) { $section = $section.Substring(0, $nextHeading.Index) }
    if ($section -notmatch '\|\s*Servicing option\s*\|\s*Update type\s*\|\s*Availability date\s*\|\s*Build\s*\|\s*KB article\s*\|') {
        throw 'The official release table has an unexpected format.'
    }
    $seen = @{}
    $rows = foreach ($line in ($section -split '\r?\n')) {
        if ($line -notmatch '^\|\s*General Availability Channel\s*\|') { continue }
        $row = [regex]::Match($line, '^\|\s*General Availability Channel\s*\|\s*([^|]*)\|\s*(\d{4}-\d{2}-\d{2})\s*\|\s*(26200\.\d+)\s*\|\s*([^|]*)\|\s*$')
        if (-not $row.Success) { throw 'A General Availability release row is malformed.' }
        $date = [datetime]::ParseExact($row.Groups[2].Value, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
        $version = [version]("10.0." + $row.Groups[3].Value)
        if ($seen.ContainsKey($version.ToString())) { throw 'Duplicate release versions need review.' }
        $seen[$version.ToString()] = $true
        if ($date.Date -gt $AsOfDate.Date) { continue }
        $kbText = $row.Groups[4].Value.Trim()
        $kb = $null
        if ($kbText) {
            $kbMatch = [regex]::Match($kbText, '^\[(KB\d+)\]\(https://support\.microsoft\.com/(?:help/\d+|[^\s)]+)\)$')
            if (-not $kbMatch.Success) { throw 'The release KB reference has an unexpected format.' }
            $kb = $kbMatch.Groups[1].Value
        }
        [pscustomobject][ordered]@{
            version = $version.ToString()
            availableDate = $date.ToString('yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
            updateType = $row.Groups[1].Value.Trim()
            kb = $kb
        }
    }
    if (-not @($rows).Count) { throw 'No published 25H2 General Availability releases were found.' }
    @($rows | Sort-Object { [version]$_.version })
}

function New-AtlasWindowsReleaseRequest {
    [CmdletBinding()]
    param([Parameter(Mandatory)][uri]$Uri)
    [Net.HttpWebRequest]::Create($Uri)
}

function Get-AtlasWindowsReleaseMarkdown {
    [CmdletBinding()]
    param()
    $uri = [uri]'https://learn.microsoft.com/en-us/windows/release-health/windows11-release-information'
    $clock = [Diagnostics.Stopwatch]::StartNew()
    $limit = 1MB
    for ($redirect = 0; $redirect -le 3; $redirect++) {
        if ($uri.Scheme -ne 'https' -or $uri.Host -ne 'learn.microsoft.com' -or $uri.Port -ne 443 -or $uri.UserInfo) {
            throw 'Release information redirected outside its official HTTPS origin.'
        }
        $remaining = 15000 - [int]$clock.ElapsedMilliseconds
        if ($remaining -le 0) { throw 'Release information request timed out.' }
        $request = New-AtlasWindowsReleaseRequest -Uri $uri
        $request.AllowAutoRedirect = $false
        $request.Timeout = $remaining
        $request.ReadWriteTimeout = $remaining
        $request.Accept = 'text/markdown'
        $request.UserAgent = 'Atlas-WindowsReleasePolicy/1.0'
        $request.AutomaticDecompression = [Net.DecompressionMethods]::GZip -bor [Net.DecompressionMethods]::Deflate
        $response = $null
        try {
            $response = $request.GetResponse()
            $status = [int]$response.StatusCode
            if ($status -in @(301, 302, 303, 307, 308)) {
                $uri = [uri]::new($uri, [string]$response.Headers['Location'])
                continue
            }
            if ($status -ne 200 -or $response.ContentType -notmatch '^text/markdown(?:;|$)' -or $response.ContentLength -gt $limit) {
                throw 'Release information response was not bounded Markdown.'
            }
            $stream = $response.GetResponseStream()
            $buffer = New-Object byte[] 8192
            $body = New-Object IO.MemoryStream
            try {
                while ($true) {
                    $remaining = 15000 - [int]$clock.ElapsedMilliseconds
                    if ($remaining -le 0) { throw 'Release information request timed out.' }
                    if ($stream.CanTimeout) { $stream.ReadTimeout = $remaining }
                    $count = $stream.Read($buffer, 0, $buffer.Length)
                    if ($count -eq 0) { break }
                    if ($body.Length + $count -gt $limit) { throw 'Release information exceeded the size limit.' }
                    $body.Write($buffer, 0, $count)
                }
                return [Text.UTF8Encoding]::new($false, $true).GetString($body.ToArray())
            } finally { $body.Dispose(); $stream.Dispose() }
        } finally { if ($null -ne $response) { $response.Dispose() }; $request.Abort() }
    }
    throw 'Release information exceeded the redirect limit.'
}

function Get-AtlasWindowsReleaseStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][version]$Version,
        [AllowEmptyString()][string]$BuildLabEx = ''
    )
    if ($BuildLabEx -match '(?i)(?:^|[._-])prerelease(?:[._-]|$)') { return 'Preview' }
    if ($Version.Major -ne 10 -or $Version.Minor -ne 0 -or $Version.Build -ne 26200 -or $Version.Revision -lt 1) { return 'Unknown' }
    try {
        $catalog = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'windows-releases.json') -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        if ($catalog.schemaVersion -eq 1 -and $catalog.build -eq 26200 -and $catalog.release -eq '25H2') {
            foreach ($release in $catalog.releases) {
                if ($release.version -eq $Version.ToString() -and [datetime]::ParseExact($release.availableDate, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture).Date -le [datetime]::UtcNow.Date) {
                    return 'Released'
                }
            }
        }
    } catch { Write-Verbose "The bundled Windows release catalog could not be read: $_" }
    try {
        $cached = Get-Variable -Name AtlasWindowsReleasedVersions -Scope Script -ErrorAction SilentlyContinue
        if ($null -eq $cached) {
            $markdown = Get-AtlasWindowsReleaseMarkdown
            $releases = @(ConvertFrom-AtlasWindowsReleaseMarkdown -Markdown $markdown)
            $script:AtlasWindowsReleasedVersions = @($releases | ForEach-Object { $_.version })
        }
        if ($script:AtlasWindowsReleasedVersions -contains $Version.ToString()) { return 'Released' }
    } catch { Write-Verbose "Windows release information is unavailable: $_" }
    # Neither missing enrollment indicators nor a failed lookup proves an Insider build.
    'Unknown'
}
