# Whether a Windows build is a public release: one Microsoft lists under the General
# Availability Channel, or as a hotpatch in its hotpatch calendar. This says nothing about
# whether the installation or media is genuine. Dot-sourcing only defines functions; the
# network is used only when the bundled catalog cannot decide.
#
# Install-Atlas.ps1 dot-sources it elevated to check the running Windows before an
# install, and Atlas Manager's elevated ISO worker (Build-Iso.ps1) checks the chosen media
# with it. tools/dev/Update-WindowsReleaseCatalog.ps1 uses it to refresh
# windows-releases.json.
function ConvertFrom-AtlasWindowsReleaseMarkdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Markdown,
        [datetime]$AsOfDate = [datetime]::UtcNow.Date,
        [ValidateSet(26200,26300)][int]$Build = 26200
    )
    $Markdown = $Markdown.Replace("`r`n", "`n")
    $releaseName = if ($Build -eq 26200) { '25H2' } else { '26H2' }
    $headingText = [regex]::Escape("Version $releaseName (OS build $Build)")
    $heading = [regex]::Match($Markdown, "(?m)^\s*(?:\*\*|#{1,6}\s*)?$headingText(?:\*\*)?\s*$")
    if (-not $heading.Success) { throw "The official $releaseName release section is missing." }
    $section = $Markdown.Substring($heading.Index + $heading.Length)
    $nextHeading = [regex]::Match($section, '(?m)^\s*(?:\*\*|#{1,6}\s*)?Version [^\r\n]+$')
    if ($nextHeading.Success) { $section = $section.Substring(0, $nextHeading.Index) }
    if ($section -notmatch '\|\s*Servicing option\s*\|\s*Update type\s*\|\s*Availability date\s*\|\s*Build\s*\|\s*KB article\s*\|') {
        throw 'The official release table has an unexpected format.'
    }
    $seen = @{}
    $rows = foreach ($line in ($section -split '\r?\n')) {
        if ($line -notmatch '^\|\s*General Availability Channel\s*\|') { continue }
        $row = [regex]::Match($line, "^\|\s*General Availability Channel\s*\|\s*([^|]*)\|\s*(\d{4}-\d{2}-\d{2})\s*\|\s*($Build\.\d+)\s*\|\s*([^|]*)\|\s*$")
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
    if (-not @($rows).Count) { throw "No published $releaseName General Availability releases were found." }
    @($rows | Sort-Object { [version]$_.version })
}

# The released hotpatches of one supported release in Microsoft's hotpatch calendar, which
# Windows Update also offers outside hotpatch enrolment. Its baseline rows are monthly
# updates the General Availability table lists already, and any other kind of row is left
# out. A missing calendar gives none; a row of the release that can't be read throws, so a
# reworked calendar is never misread. windows_release.rs reads the calendar the same way.
function ConvertFrom-AtlasWindowsHotpatchMarkdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Markdown,
        [datetime]$AsOfDate = [datetime]::UtcNow.Date,
        [ValidateSet(26200,26300)][int]$Build = 26200
    )
    $Markdown = $Markdown.Replace("`r`n", "`n")
    $releaseName = if ($Build -eq 26200) { '25H2' } else { '26H2' }
    $calendar = [regex]::Match($Markdown, '(?m)^\s*#{1,2} +Windows 11 hotpatch calendar\s*$')
    if (-not $calendar.Success) { return @() }
    $section = $Markdown.Substring($calendar.Index + $calendar.Length)
    $nextHeading = [regex]::Match($section, '(?m)^\s*#{1,2} ')
    if ($nextHeading.Success) { $section = $section.Substring(0, $nextHeading.Index) }
    $inRelease = $false
    $header = $false
    $seen = @{}
    $rows = foreach ($line in ($section -split '\n')) {
        # A release's heading, bold or as a heading, can carry the calendar year after it.
        $heading = [regex]::Match($line, '^\s*(?:#{1,6}\s*)?(?:\*\*)?(Version [^*]+?)\s*(?:\*\*.*)?$')
        if ($heading.Success) {
            $inRelease = $heading.Groups[1].Value.Trim() -ceq "Version $releaseName (OS build $Build)"
            $header = $false
            continue
        }
        if ($line -notmatch '^\s*\|') { continue }
        $cells = @($line.Trim().Split('|') | ForEach-Object { $_.Trim() })
        if (($cells -join '|') -ceq '|Month|Update type|Type|Availability date|Build|KB article|') { $header = $true; continue }
        if (-not @($cells | Where-Object { $_ -notmatch '^[-:]*$' }).Count) { continue }
        if (-not $inRelease) { continue }
        if (-not $header) { throw 'A hotpatch row has no table header.' }
        if ($cells.Count -ne 8 -or $cells[0] -or $cells[7]) { throw 'A hotpatch row is malformed.' }
        if ($cells[3] -cne 'Hotpatch') { continue }
        # A month the calendar announces before its hotpatch is released.
        if (-not $cells[4] -and -not $cells[5]) { continue }
        $date = [datetime]::MinValue
        if (-not [datetime]::TryParseExact($cells[4], 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$date)) {
            throw 'A hotpatch row is malformed.'
        }
        if ($cells[5] -notmatch "^$Build\.\d+$") { throw 'A hotpatch row is malformed.' }
        $version = [version]("10.0." + $cells[5])
        if ($seen.ContainsKey($version.ToString())) { throw 'Duplicate hotpatch versions need review.' }
        $seen[$version.ToString()] = $true
        if ($date.Date -gt $AsOfDate.Date) { continue }
        $kb = $null
        if ($cells[6]) {
            $kbMatch = [regex]::Match($cells[6], '^\[(KB\d+)\]\(https://support\.microsoft\.com/(?:help/\d+|[^\s)]+)\)$')
            if (-not $kbMatch.Success) { throw 'The hotpatch KB reference has an unexpected format.' }
            $kb = $kbMatch.Groups[1].Value
        }
        [pscustomobject][ordered]@{
            version = $version.ToString()
            availableDate = $date.ToString('yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
            updateType = $cells[2]
            kb = $kb
        }
    }
    if (-not $rows) { return @() }
    @($rows | Sort-Object { [version]$_.version })
}

# Tests mock this to serve fixed responses.
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
    $timeoutMs = 15000
    $limit = 1MB
    for ($redirect = 0; $redirect -le 3; $redirect++) {
        if ($uri.Scheme -ne 'https' -or $uri.Host -ne 'learn.microsoft.com' -or $uri.Port -ne 443 -or $uri.UserInfo) {
            throw 'Release information redirected outside its official HTTPS origin.'
        }
        $remaining = $timeoutMs - [int]$clock.ElapsedMilliseconds
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
                throw 'Release information response was not Markdown within the size limit.'
            }
            $stream = $response.GetResponseStream()
            $buffer = New-Object byte[] 8192
            $body = New-Object IO.MemoryStream
            try {
                while ($true) {
                    $remaining = $timeoutMs - [int]$clock.ElapsedMilliseconds
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
        [AllowEmptyString()][string]$BuildLabEx = '',
        # Decide from the bundled catalog alone, never Microsoft's live page.
        [switch]$NoRefresh
    )
    if ($BuildLabEx -match '(?i)(?:^|[._-])prerelease(?:[._-]|$)') { return 'Preview' }
    if ($Version.Major -ne 10 -or $Version.Minor -ne 0 -or $Version.Build -notin @(26200,26300) -or $Version.Revision -lt 1) { return 'Unknown' }
    try {
        $catalog = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'windows-releases.json') -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        if ($catalog.schemaVersion -eq 2 -and @($catalog.supportedReleases.build) -contains $Version.Build) {
            # Hotpatches count as released too, but never as the newest revision below.
            $hotpatches = if ($catalog.PSObject.Properties['hotpatches']) { @($catalog.hotpatches) } else { @() }
            foreach ($release in @(@($catalog.releases) + $hotpatches)) {
                if ($release.version -eq $Version.ToString() -and [datetime]::ParseExact($release.availableDate, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture).Date -le [datetime]::UtcNow.Date) {
                    return 'Released'
                }
            }
            if ($NoRefresh) {
                # Without the live page, only a revision newer than every listed one
                # of its build is taken as an update the catalog predates. Older
                # unlisted revisions, such as pre-release flights, stay unknown.
                $newest = @($catalog.releases | ForEach-Object { [version]$_.version } | Where-Object { $_.Build -eq $Version.Build } | Sort-Object) | Select-Object -Last 1
                if ($null -ne $newest -and $Version -gt $newest) { return 'Released' }
            }
        }
    } catch { Write-Verbose "The bundled Windows release catalog could not be read: $_" }
    if ($NoRefresh) { return 'Unknown' }
    try {
        $cached = Get-Variable -Name AtlasWindowsReleasedVersions -Scope Script -ErrorAction SilentlyContinue
        if ($null -eq $cached) {
            $markdown = Get-AtlasWindowsReleaseMarkdown
            $releases = @(foreach ($build in 26200,26300) { ConvertFrom-AtlasWindowsReleaseMarkdown -Markdown $markdown -Build $build })
            $versions = @($releases | ForEach-Object { $_.version })
            # Hotpatches only add to the General Availability releases: a calendar that
            # can't be read leaves them as they are.
            try {
                $hotpatches = @(foreach ($build in 26200,26300) { ConvertFrom-AtlasWindowsHotpatchMarkdown -Markdown $markdown -Build $build })
                $versions += @($hotpatches | ForEach-Object { $_.version })
            } catch { Write-Verbose "Microsoft's hotpatch calendar couldn't be read, so only General Availability releases count: $_" }
            $script:AtlasWindowsReleasedVersions = $versions
        }
        if ($script:AtlasWindowsReleasedVersions -contains $Version.ToString()) { return 'Released' }
        # Read, but left out: most often a Release Preview build, or an update the
        # page doesn't list yet.
        return 'Unlisted'
    } catch { Write-Verbose "Windows release information is unavailable: $_" }
    # Neither missing enrolment indicators nor a failed lookup proves an Insider build.
    'Unknown'
}
