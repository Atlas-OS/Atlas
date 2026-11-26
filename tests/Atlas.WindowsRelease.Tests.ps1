BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:policy = Join-Path $PSScriptRoot '../package/Executables/AtlasModules/Scripts/Compatibility/Windows-Release.ps1'
    . $policy
    function New-ReleaseMarkdownFixture {
        param([string]$Version = '26200.9999', [string]$Date = '2025-09-30')
        @"
---
git_commit_id: 0123456789012345678901234567890123456789
updated_at: 2026-08-28T08:57:00.0000000Z
---
**Version 26H2 (OS build 26300)**
| Servicing option | Update type | Availability date | Build | KB article |
| --- | --- | --- | --- | --- |
| General Availability Channel | 2026-09 D | 2026-09-29 | 26300.9550 | [KB5124010](https://support.microsoft.com/help/5124010) |
| General Availability Channel | | 2026-09-29 | 26300.9457 | |
| Release Preview Channel | | 2026-09-29 | 26300.9990 | |

**Version 25H2 (OS build 26200)**

| Servicing option | Update type | Availability date | Build | KB article |
| --- | --- | --- | --- | --- |
| General Availability Channel | 2025-09 D | $Date | $Version | [KB5120998](https://support.microsoft.com/help/5120998) |
| Release Preview Channel | 2025-09 D | 2025-09-30 | 26200.5551 | |

**Version 26H1 (OS build 28000)**
| Servicing option | Update type | Availability date | Build | KB article |
| --- | --- | --- | --- | --- |
| General Availability Channel | 2025-09 D | 2025-09-30 | 26200.8888 | |
"@
    }
    # The release fixture with Microsoft's hotpatch calendar after it: a 26H2 heading that
    # carries the year on the same line, baseline rows, an announced month and 24H2 rows.
    function New-HotpatchMarkdownFixture {
        (New-ReleaseMarkdownFixture) + @"

## Windows 11 hotpatch calendar

Note

Hotpatching is not available on Windows 11, version 26H1.
**Version 26H2 (OS build 26300)** **Calendar year 2026**

| Month | Update type | Type | Availability date | Build | KB article |
| --- | --- | --- | --- | --- | --- |
| October | 2026.10 B | Baseline (Restart) | 2026-10-13 | 26300.9711 | [KB5127648](https://support.microsoft.com/help/5127648) |
| November | 2026.11 B | Hotpatch | 2026-11-10 | 26300.9911 | [KB5132043](https://support.microsoft.com/help/5132043) |
| December | 2026.12 B | Hotpatch |  |  |  |

**Version 25H2 (OS build 26200)**
**Calendar year 2026**

| Month | Update type | Type | Availability date | Build | KB article |
| --- | --- | --- | --- | --- | --- |
| November | 2026.11 B | Hotpatch | 2026-11-10 | 26200.9911 | [KB5132043](https://support.microsoft.com/help/5132043) |

**Calendar year 2025**

| Month | Update type | Type | Availability date | Build | KB article |
| --- | --- | --- | --- | --- | --- |
| November | 2025.11 B | Hotpatch | 2025-11-11 | 26200.7092 | [KB5068966](https://support.microsoft.com/topic/november-11-2025-hotpatch-kb5068966) |

**Version 24H2 (OS build 26100)**
**Calendar year 2026**

| Month | Update type | Type | Availability date | Build | KB article |
| --- | --- | --- | --- | --- | --- |
| November | 2026.11 B | Hotpatch | 2026-11-10 | 26100.9911 | [KB5132043](https://support.microsoft.com/help/5132043) |
"@
    }
    function New-ReleaseResponseFixture {
        param([string]$Text, [int]$Status = 200, [long]$Length = -1, [string]$Location = '')
        $response = [pscustomobject]@{
            StatusCode = $Status; ContentType = 'text/markdown; charset=utf-8'; ContentLength = $Length
            Headers = @{ Location = $Location }; Body = [IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($Text))
            Disposed = $false
        }
        $response | Add-Member ScriptMethod GetResponseStream { $this.Body }
        $response | Add-Member ScriptMethod Dispose { $this.Disposed = $true; $this.Body.Dispose() }
        $request = [pscustomobject]@{
            Response = $response; AllowAutoRedirect = $true; Timeout = 0; ReadWriteTimeout = 0
            Accept = ''; UserAgent = ''; AutomaticDecompression = 0; Aborted = $false
        }
        $request | Add-Member ScriptMethod GetResponse { $this.Response }
        $request | Add-Member ScriptMethod Abort { $this.Aborted = $true }
        $request
    }
}

Describe 'Windows release catalog parser' {
    It 'reads only published 26H2 rows from their matching section' {
        $rows = @(ConvertFrom-AtlasWindowsReleaseMarkdown (New-ReleaseMarkdownFixture) -Build 26300 -AsOfDate ([datetime]'2026-09-30'))
        $rows.version | Should -Be @('10.0.26300.9457','10.0.26300.9550')
        { ConvertFrom-AtlasWindowsReleaseMarkdown ((New-ReleaseMarkdownFixture).Replace('26300.9457','26200.9457')) -Build 26300 } | Should -Throw '*malformed*'
        { ConvertFrom-AtlasWindowsReleaseMarkdown (New-ReleaseMarkdownFixture) -Build 26300 -AsOfDate ([datetime]'2026-09-28') } | Should -Throw '*No published*'
    }
    It 'accepts a public optional preview update and excludes other channels and sections' {
        $rows = @(ConvertFrom-AtlasWindowsReleaseMarkdown (New-ReleaseMarkdownFixture) -AsOfDate ([datetime]'2026-09-07'))
        $rows.Count | Should -Be 1
        $rows[0].version | Should -Be '10.0.26200.9999'
        $rows[0].updateType | Should -Be '2025-09 D'
    }
    It 'handles both CRLF and LF without leaking rows from the next section' {
        $markdown = (New-ReleaseMarkdownFixture).Replace("`r`n", "`n")
        @(ConvertFrom-AtlasWindowsReleaseMarkdown $markdown).Count | Should -Be 1
        @(ConvertFrom-AtlasWindowsReleaseMarkdown ($markdown.Replace("`n", "`r`n"))).Count | Should -Be 1
    }
    It 'does not accept a future release merely because it is in the table' {
        { ConvertFrom-AtlasWindowsReleaseMarkdown (New-ReleaseMarkdownFixture -Date '2099-01-01') } | Should -Throw '*No published*'
    }
    It 'rejects malformed GA versions rather than silently omitting them' {
        { ConvertFrom-AtlasWindowsReleaseMarkdown (New-ReleaseMarkdownFixture -Version 'not-a-build') } | Should -Throw '*malformed*'
    }
    It 'requires the expected official section and table format' {
        { ConvertFrom-AtlasWindowsReleaseMarkdown ((New-ReleaseMarkdownFixture).Replace('Version 25H2', 'Version 99H9')) } | Should -Throw '*section is missing*'
        { ConvertFrom-AtlasWindowsReleaseMarkdown ((New-ReleaseMarkdownFixture).Replace('Servicing option', 'Unreviewed column')) } | Should -Throw '*unexpected format*'
    }
    It 'rejects off-origin KB references' {
        { ConvertFrom-AtlasWindowsReleaseMarkdown ((New-ReleaseMarkdownFixture).Replace('https://support.microsoft.com/', 'https://example.invalid/')) } | Should -Throw '*KB reference*'
    }
    It 'rejects duplicate versions that would make the release evidence ambiguous' {
        $markdown = New-ReleaseMarkdownFixture
        $row = @($markdown -split '\r?\n' | Where-Object { $_ -match '^\| General Availability Channel.*26200\.9999' })[0]
        { ConvertFrom-AtlasWindowsReleaseMarkdown ($markdown.Replace($row, "$row`n$row")) } | Should -Throw '*Duplicate release*'
    }
}

Describe 'Windows hotpatch calendar parser' {
    It 'reads the released hotpatches of one release, without its baseline rows or announced months' {
        $rows = @(ConvertFrom-AtlasWindowsHotpatchMarkdown (New-HotpatchMarkdownFixture) -Build 26200 -AsOfDate ([datetime]'2026-11-20'))
        $rows.version | Should -Be @('10.0.26200.7092', '10.0.26200.9911')
        $rows[1].availableDate | Should -Be '2026-11-10'
        $rows[1].updateType | Should -Be '2026.11 B'
        $rows[1].kb | Should -Be 'KB5132043'
        $rows = @(ConvertFrom-AtlasWindowsHotpatchMarkdown (New-HotpatchMarkdownFixture) -Build 26300 -AsOfDate ([datetime]'2026-11-20'))
        $rows.version | Should -Be @('10.0.26300.9911')
    }
    It 'leaves out a hotpatch that is not released yet' {
        @(ConvertFrom-AtlasWindowsHotpatchMarkdown (New-HotpatchMarkdownFixture) -Build 26300 -AsOfDate ([datetime]'2026-11-09')).Count | Should -Be 0
        @(ConvertFrom-AtlasWindowsHotpatchMarkdown (New-HotpatchMarkdownFixture) -Build 26200 -AsOfDate ([datetime]'2026-11-09')).version | Should -Be @('10.0.26200.7092')
    }
    It 'gives none without a calendar' {
        @(ConvertFrom-AtlasWindowsHotpatchMarkdown (New-ReleaseMarkdownFixture) -Build 26200).Count | Should -Be 0
    }
    It 'leaves out a row of another kind, such as a preview' {
        $markdown = (New-HotpatchMarkdownFixture).Replace('| Hotpatch | 2025-11-11', '| Hotpatch (Release Preview) | 2025-11-11')
        @(ConvertFrom-AtlasWindowsHotpatchMarkdown $markdown -Build 26200 -AsOfDate ([datetime]'2026-11-20')).version | Should -Be @('10.0.26200.9911')
    }
    It 'rejects a hotpatch row of its release that it can''t read' {
        $markdown = New-HotpatchMarkdownFixture
        foreach ($broken in @(
                $markdown.Replace('2025-11-11 | 26200.7092', '2025-11-11 | 26100.7092')
                $markdown.Replace('2025-11-11 | 26200.7092', 'November 11 | 26200.7092')
                $markdown.Replace('2025-11-11 | 26200.7092', '2025-11-11 | ')
                $markdown.Replace('26200.7092', '26200.9911')
                $markdown.Replace('https://support.microsoft.com/topic/november-11-2025', 'https://example.invalid/november-11-2025')
                $markdown.Replace('| Month | Update type | Type |', '| Month | Update type | Kind |')
            )) {
            { ConvertFrom-AtlasWindowsHotpatchMarkdown $broken -Build 26200 -AsOfDate ([datetime]'2026-11-20') } | Should -Throw
        }
        # A row of another release can't stop this one.
        @(ConvertFrom-AtlasWindowsHotpatchMarkdown ($markdown.Replace('26100.9911', 'not-a-build')) -Build 26200 -AsOfDate ([datetime]'2026-11-20')).Count | Should -Be 2
    }
}

Describe 'Windows hotpatch eligibility' {
    BeforeAll {
        # Listed: 26200.100, .200 and .300 as releases, and .250 and .400 as hotpatches, with
        # .500 a hotpatch not released yet.
        $hotpatchRoot = Join-Path $TestDrive 'Hotpatches'
        $null = New-Item -ItemType Directory -Path $hotpatchRoot
        Copy-Item -LiteralPath $policy -Destination $hotpatchRoot
        $catalog = [ordered]@{
            schemaVersion = 2
            supportedReleases = @([ordered]@{ release = '25H2'; build = 26200 }, [ordered]@{ release = '26H2'; build = 26300 })
            releases = @(foreach ($build in '26200.100', '26200.200', '26200.300') {
                [ordered]@{ version = "10.0.$build"; availableDate = '2025-10-14' }
            })
            hotpatches = @(
                [ordered]@{ version = '10.0.26200.250'; availableDate = '2025-11-11' }
                [ordered]@{ version = '10.0.26200.400'; availableDate = '2025-12-09' }
                [ordered]@{ version = '10.0.26200.500'; availableDate = '2099-01-01' }
            )
        }
        [IO.File]::WriteAllText((Join-Path $hotpatchRoot 'windows-releases.json'), ($catalog | ConvertTo-Json -Depth 5), [Text.UTF8Encoding]::new($false))
        . (Join-Path $hotpatchRoot 'Windows-Release.ps1')
    }
    BeforeEach {
        Remove-Variable AtlasWindowsReleasedVersions -Scope Script -ErrorAction SilentlyContinue
        Mock Get-AtlasWindowsReleaseMarkdown { throw 'offline fixture' }
    }
    It 'recognises a listed hotpatch offline' {
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.250' | Should -Be 'Released'
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.400' -NoRefresh | Should -Be 'Released'
        Should -Invoke Get-AtlasWindowsReleaseMarkdown -Times 0 -Exactly
    }
    It 'never counts a hotpatch as the newest listed revision' {
        # Newer than every listed release, so an update the catalog predates, though older
        # than a listed hotpatch.
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.350' -NoRefresh | Should -Be 'Released'
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.299' -NoRefresh | Should -Be 'Unknown'
    }
    It 'does not accept a hotpatch before its date' {
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.500' | Should -Be 'Unknown'
        Should -Invoke Get-AtlasWindowsReleaseMarkdown -Times 1 -Exactly
    }
    It 'accepts a hotpatch the live calendar lists' {
        Mock Get-AtlasWindowsReleaseMarkdown { New-HotpatchMarkdownFixture }
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.9911' | Should -Be 'Released'
        Get-AtlasWindowsReleaseStatus -Version '10.0.26300.9911' | Should -Be 'Released'
        # Baseline rows, announced months and other releases add nothing.
        Get-AtlasWindowsReleaseStatus -Version '10.0.26300.9711' | Should -Be 'Unlisted'
        Should -Invoke Get-AtlasWindowsReleaseMarkdown -Times 1 -Exactly
    }
    It 'keeps the General Availability releases when the live calendar can''t be read' {
        Mock Get-AtlasWindowsReleaseMarkdown { (New-HotpatchMarkdownFixture).Replace('2026-11-10 | 26200.9911', 'soon | 26200.9911') }
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.9999' | Should -Be 'Released'
        Get-AtlasWindowsReleaseStatus -Version '10.0.26300.9911' | Should -Be 'Unlisted'
    }
}

Describe 'Windows release eligibility' {
    BeforeAll {
        # A copy of the policy beside a fixed catalog, so a routine refresh of the bundled
        # one can't change these results. Listed: 26200.100, .200 and .300; 26300.100 and .200.
        $fixtureRoot = Join-Path $TestDrive 'Compatibility'
        $null = New-Item -ItemType Directory -Path $fixtureRoot
        Copy-Item -LiteralPath $policy -Destination $fixtureRoot
        $catalog = [ordered]@{
            schemaVersion = 2
            supportedReleases = @([ordered]@{ release = '25H2'; build = 26200 }, [ordered]@{ release = '26H2'; build = 26300 })
            releases = @(foreach ($build in '26200.100', '26200.200', '26200.300', '26300.100', '26300.200') {
                [ordered]@{ version = "10.0.$build"; availableDate = '2025-10-14' }
            })
        }
        [IO.File]::WriteAllText((Join-Path $fixtureRoot 'windows-releases.json'), ($catalog | ConvertTo-Json -Depth 5), [Text.UTF8Encoding]::new($false))
        . (Join-Path $fixtureRoot 'Windows-Release.ps1')
    }
    BeforeEach {
        Remove-Variable AtlasWindowsReleasedVersions -Scope Script -ErrorAction SilentlyContinue
        Mock Get-AtlasWindowsReleaseMarkdown { throw 'offline fixture' }
    }
    It 'recognizes a listed full version offline' {
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.100' | Should -Be 'Released'
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.300' | Should -Be 'Released'
        Should -Invoke Get-AtlasWindowsReleaseMarkdown -Times 0 -Exactly
    }
    It 'recognizes the listed 26H2 versions offline and still rejects prerelease branches' {
        foreach ($version in '10.0.26300.100','10.0.26300.200') {
            Get-AtlasWindowsReleaseStatus -Version $version | Should -Be 'Released'
            Get-AtlasWindowsReleaseStatus -Version $version -BuildLabEx '26300.1.amd64fre.rs_prerelease' | Should -Be 'Preview'
        }
        Get-AtlasWindowsReleaseStatus -Version '10.0.26300.9999' | Should -Be 'Unknown'
        Should -Invoke Get-AtlasWindowsReleaseMarkdown -Times 1 -Exactly
    }
    It 'rejects an explicit prerelease branch marker without a network lookup' {
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.5551' -BuildLabEx '26200.1.amd64fre.rs_prerelease_flt.250101-0000' | Should -Be 'Preview'
        Should -Invoke Get-AtlasWindowsReleaseMarkdown -Times 0 -Exactly
    }
    It 'does not match an incidental substring as a prerelease branch token' {
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.200' -BuildLabEx '26100.1.amd64fre.notprerelease.240331-1435' | Should -Be 'Released'
    }
    It 'does not classify an unrecognized full version as Insider after a lookup failure' {
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.9999' -BuildLabEx '26100.1.amd64fre.ge_release.240331-1435' | Should -Be 'Unknown'
        Should -Invoke Get-AtlasWindowsReleaseMarkdown -Times 1 -Exactly
    }
    It 'does not query unrelated or incomplete build versions' {
        Get-AtlasWindowsReleaseStatus -Version '10.0.26100.9168' | Should -Be 'Unknown'
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200' | Should -Be 'Unknown'
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.0' | Should -Be 'Unknown'
        Should -Invoke Get-AtlasWindowsReleaseMarkdown -Times 0 -Exactly
    }
    It 'accepts newly published GA versions and reuses only the successful in-process result' {
        Mock Get-AtlasWindowsReleaseMarkdown { New-ReleaseMarkdownFixture }
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.9999' | Should -Be 'Released'
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.9999' | Should -Be 'Released'
        Should -Invoke Get-AtlasWindowsReleaseMarkdown -Times 1 -Exactly
    }
    It 'tells a build the published list leaves out from a failed lookup' {
        Mock Get-AtlasWindowsReleaseMarkdown { New-ReleaseMarkdownFixture }
        # A Release Preview row and an unlisted newer revision alike.
        Get-AtlasWindowsReleaseStatus -Version '10.0.26300.9990' | Should -Be 'Unlisted'
        Get-AtlasWindowsReleaseStatus -Version '10.0.26300.300' | Should -Be 'Unlisted'
        Get-AtlasWindowsReleaseStatus -Version '10.0.26300.300' -NoRefresh | Should -Be 'Released'
        Should -Invoke Get-AtlasWindowsReleaseMarkdown -Times 1 -Exactly
    }
    It 'does not permanently cache a failed lookup' {
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.9999' | Should -Be 'Unknown'
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.9999' | Should -Be 'Unknown'
        Should -Invoke Get-AtlasWindowsReleaseMarkdown -Times 2 -Exactly
    }
    It 'decides from the bundled catalog alone without a live lookup' {
        # Newer than every listed revision of its build: an update the catalog predates.
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.301' -NoRefresh | Should -Be 'Released'
        Get-AtlasWindowsReleaseStatus -Version '10.0.26300.201' -NoRefresh | Should -Be 'Released'
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.200' -NoRefresh | Should -Be 'Released'
        # Unlisted and older than the newest listed revision, as a pre-release flight is.
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.299' -NoRefresh | Should -Be 'Unknown'
        Get-AtlasWindowsReleaseStatus -Version '10.0.26100.9999' -NoRefresh | Should -Be 'Unknown'
        Get-AtlasWindowsReleaseStatus -Version '10.0.26300.201' -BuildLabEx '26300.1.amd64fre.rs_prerelease' -NoRefresh | Should -Be 'Preview'
        Should -Invoke Get-AtlasWindowsReleaseMarkdown -Times 0 -Exactly
    }
}

Describe 'Bundled Windows release catalog' {
    It 'is read by the policy script for each supported build' {
        $catalog = Get-Content -LiteralPath (Join-Path (Split-Path -Parent $policy) 'windows-releases.json') -Raw | ConvertFrom-Json
        foreach ($build in 26200, 26300) {
            # Taken from the catalog so a routine refresh keeps this passing.
            $newest = @($catalog.releases | ForEach-Object { [version]$_.version } | Where-Object Build -eq $build | Sort-Object) | Select-Object -Last 1
            $newest | Should -Not -BeNullOrEmpty -Because "the catalog lists build $build"
            Get-AtlasWindowsReleaseStatus -Version $newest -NoRefresh | Should -Be 'Released'
        }
    }
    It 'counts each bundled hotpatch as released, apart from the releases' {
        $catalog = Get-Content -LiteralPath (Join-Path (Split-Path -Parent $policy) 'windows-releases.json') -Raw | ConvertFrom-Json
        @($catalog.hotpatches).Count | Should -BeGreaterThan 0
        foreach ($hotpatch in $catalog.hotpatches) {
            @($catalog.releases.version) | Should -Not -Contain $hotpatch.version
            Get-AtlasWindowsReleaseStatus -Version $hotpatch.version -NoRefresh | Should -Be 'Released'
        }
    }
}

Describe 'Limits on the official release transport' {
    BeforeEach {
        $script:requestFixture = New-ReleaseResponseFixture -Text (New-ReleaseMarkdownFixture)
        Mock New-AtlasWindowsReleaseRequest { $script:requestFixture }
    }
    It 'requests Markdown with automatic redirects disabled and a timeout' {
        Get-AtlasWindowsReleaseMarkdown | Should -Match 'Version 25H2'
        $requestFixture.AllowAutoRedirect | Should -BeFalse
        $requestFixture.Accept | Should -Be 'text/markdown'
        $requestFixture.Timeout | Should -BeGreaterThan 0
        $requestFixture.Timeout | Should -BeLessOrEqual 15000
        $requestFixture.Aborted | Should -BeTrue
        $requestFixture.Response.Disposed | Should -BeTrue
    }
    It 'does not follow a redirect to <Location>' -TestCases @(
        @{ Location = 'https://example.invalid/releases' }
        @{ Location = 'http://learn.microsoft.com/releases' }
    ) {
        $script:requestFixture = New-ReleaseResponseFixture -Text '' -Status 302 -Location $Location
        { Get-AtlasWindowsReleaseMarkdown } | Should -Throw '*outside its official HTTPS origin*'
        Should -Invoke New-AtlasWindowsReleaseRequest -Times 1 -Exactly
    }
    It 'enforces the decompressed body limit even when no length is declared' {
        $script:requestFixture = New-ReleaseResponseFixture -Text ('x' * (1MB + 1))
        { Get-AtlasWindowsReleaseMarkdown } | Should -Throw '*size limit*'
        $requestFixture.Response.Disposed | Should -BeTrue
    }
    It 'rejects HTML fallback content instead of parsing it as release evidence' {
        $requestFixture.Response.ContentType = 'text/html'
        { Get-AtlasWindowsReleaseMarkdown } | Should -Throw '*not Markdown within the size limit*'
    }
    It 'limits same-origin redirect loops' {
        $script:requestFixture = New-ReleaseResponseFixture -Text '' -Status 302 -Location 'https://learn.microsoft.com/redirect-loop'
        { Get-AtlasWindowsReleaseMarkdown } | Should -Throw '*redirect limit*'
        Should -Invoke New-AtlasWindowsReleaseRequest -Times 4 -Exactly
    }
}

Describe 'Reviewed release catalog regeneration' {
    BeforeAll {
        $script:generator = Join-Path $PSScriptRoot '../tools/dev/Update-WindowsReleaseCatalog.ps1'
        $script:markdownPath = Join-Path $TestDrive 'release-source.md'
        [IO.File]::WriteAllText($markdownPath, (New-ReleaseMarkdownFixture), [Text.UTF8Encoding]::new($false))
    }
    It 'reproduces identical catalog bytes from the same saved source and cutoff' {
        $first = Join-Path $TestDrive 'first.json'
        $second = Join-Path $TestDrive 'second.json'
        # Separate PowerShell 7 processes, as maintainers run it: each orders an unordered
        # hashtable differently.
        foreach ($path in $first, $second) {
            $output = & $script:AtlasTestToolsHost -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $generator -MarkdownPath $markdownPath -AsOfDate '2026-09-07' -Build 26200 -OutputPath $path 2>&1
            $LASTEXITCODE | Should -Be 0 -Because ($output -join "`n")
        }
        (Get-FileHash $first).Hash | Should -Be (Get-FileHash $second).Hash
        $text = [IO.File]::ReadAllText($first)
        $text.Contains("`r") | Should -BeFalse
        $text | Should -Match '[^\n]\n\z'
        $catalog = $text | ConvertFrom-Json
        $catalog.supportedReleases.build | Should -Be 26200
        $catalog.releases.version | Should -Be '10.0.26200.9999'
        $catalog.asOfDate | Should -Be '2026-09-07'
    }
    It 'generates both supported release families with the same provenance' {
        $catalogPath = Join-Path $TestDrive 'both.json'
        $output = & $script:AtlasTestToolsHost -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $generator -MarkdownPath $markdownPath -AsOfDate '2026-09-30' -OutputPath $catalogPath 2>&1
        $LASTEXITCODE | Should -Be 0 -Because ($output -join "`n")
        $catalog = Get-Content $catalogPath -Raw | ConvertFrom-Json
        $catalog.schemaVersion | Should -Be 2
        $catalog.supportedReleases.build | Should -Be @(26200,26300)
        $catalog.releases.version | Should -Be @('10.0.26200.9999','10.0.26300.9457','10.0.26300.9550')
        $catalog.sourceCommit | Should -Be '0123456789012345678901234567890123456789'
        $catalog.sourceSha256 | Should -Be (Get-FileHash $markdownPath -Algorithm SHA256).Hash
        $catalog.updatedAt | Should -Be '2026-08-28T08:57:00.0000000Z'
        $catalog.asOfDate | Should -Be '2026-09-30'
        @($catalog.hotpatches).Count | Should -Be 0
    }
    It 'lists the calendar''s hotpatches apart from the releases, which stay as they were' {
        $hotpatchSource = Join-Path $TestDrive 'hotpatch-source.md'
        [IO.File]::WriteAllText($hotpatchSource, (New-HotpatchMarkdownFixture), [Text.UTF8Encoding]::new($false))
        $catalogPath = Join-Path $TestDrive 'hotpatches.json'
        $output = & $script:AtlasTestToolsHost -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $generator -MarkdownPath $hotpatchSource -AsOfDate '2026-11-20' -OutputPath $catalogPath 2>&1
        $LASTEXITCODE | Should -Be 0 -Because ($output -join "`n")
        $catalog = Get-Content $catalogPath -Raw | ConvertFrom-Json
        $catalog.releases.version | Should -Be @('10.0.26200.9999', '10.0.26300.9457', '10.0.26300.9550')
        $catalog.hotpatches.version | Should -Be @('10.0.26200.7092', '10.0.26200.9911', '10.0.26300.9911')
        $catalog.hotpatches[0].updateType | Should -Be '2025.11 B'
    }
    It 'refuses a version listed both as a release and as a hotpatch' {
        $overlap = Join-Path $TestDrive 'overlap-source.md'
        [IO.File]::WriteAllText($overlap, (New-HotpatchMarkdownFixture).Replace('26300.9911', '26300.9550'), [Text.UTF8Encoding]::new($false))
        # Windows PowerShell turns redirected native stderr into error records.
        # Capture the expected failure even when CI uses ErrorActionPreference=Stop.
        $savedPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $output = & $script:AtlasTestToolsHost -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $generator -MarkdownPath $overlap -AsOfDate '2026-11-20' -OutputPath (Join-Path $TestDrive 'overlap.json') 2>&1
        }
        finally {
            $ErrorActionPreference = $savedPreference
        }
        $LASTEXITCODE | Should -Not -Be 0
        ($output -join "`n") | Should -Match 'both as releases and as hotpatches'
    }
}
