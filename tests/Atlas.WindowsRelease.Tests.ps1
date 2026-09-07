BeforeAll {
    $script:policy = Join-Path $PSScriptRoot '../playbook/Executables/AtlasModules/Scripts/Compatibility/Windows-Release.ps1'
    . $policy
    function New-ReleaseMarkdownFixture {
        param([string]$Version = '26200.9999', [string]$Date = '2025-09-30')
        @"
---
git_commit_id: 0123456789012345678901234567890123456789
updated_at: 2026-08-28T08:57:00.0000000Z
---
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

Describe 'Windows release eligibility' {
    BeforeEach {
        Remove-Variable AtlasWindowsReleasedVersions -Scope Script -ErrorAction SilentlyContinue
        Mock Get-AtlasWindowsReleaseMarkdown { throw 'offline fixture' }
    }
    It 'recognizes a released full version offline, including one previously offered to Insiders' {
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.7309' | Should -Be 'Released'
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.9168' | Should -Be 'Released'
        Should -Invoke Get-AtlasWindowsReleaseMarkdown -Times 0 -Exactly
    }
    It 'rejects an explicit prerelease branch marker without a network lookup' {
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.5551' -BuildLabEx '26200.1.amd64fre.rs_prerelease_flt.250101-0000' | Should -Be 'Preview'
        Should -Invoke Get-AtlasWindowsReleaseMarkdown -Times 0 -Exactly
    }
    It 'does not match an incidental substring as a prerelease branch token' {
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.9168' -BuildLabEx '26100.1.amd64fre.notprerelease.240331-1435' | Should -Be 'Released'
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
    It 'does not permanently cache a failed lookup' {
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.9999' | Should -Be 'Unknown'
        Get-AtlasWindowsReleaseStatus -Version '10.0.26200.9999' | Should -Be 'Unknown'
        Should -Invoke Get-AtlasWindowsReleaseMarkdown -Times 2 -Exactly
    }
}

Describe 'Bounded official release transport' {
    BeforeEach {
        $script:requestFixture = New-ReleaseResponseFixture -Text (New-ReleaseMarkdownFixture)
        Mock New-AtlasWindowsReleaseRequest { $script:requestFixture }
    }
    It 'requests Markdown with automatic redirects disabled and a bounded timeout' {
        Get-AtlasWindowsReleaseMarkdown | Should -Match 'Version 25H2'
        $requestFixture.AllowAutoRedirect | Should -BeFalse
        $requestFixture.Accept | Should -Be 'text/markdown'
        $requestFixture.Timeout | Should -BeGreaterThan 0
        $requestFixture.Timeout | Should -BeLessOrEqual 15000
        $requestFixture.Aborted | Should -BeTrue
        $requestFixture.Response.Disposed | Should -BeTrue
    }
    It 'does not follow a redirect to another origin' {
        $script:requestFixture = New-ReleaseResponseFixture -Text '' -Status 302 -Location 'https://example.invalid/releases'
        { Get-AtlasWindowsReleaseMarkdown } | Should -Throw '*outside its official HTTPS origin*'
        Should -Invoke New-AtlasWindowsReleaseRequest -Times 1 -Exactly
    }
    It 'rejects HTTPS downgrade redirects' {
        $script:requestFixture = New-ReleaseResponseFixture -Text '' -Status 302 -Location 'http://learn.microsoft.com/releases'
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
        { Get-AtlasWindowsReleaseMarkdown } | Should -Throw '*not bounded Markdown*'
    }
    It 'bounds same-origin redirect loops' {
        $script:requestFixture = New-ReleaseResponseFixture -Text '' -Status 302 -Location 'https://learn.microsoft.com/redirect-loop'
        { Get-AtlasWindowsReleaseMarkdown } | Should -Throw '*redirect limit*'
        Should -Invoke New-AtlasWindowsReleaseRequest -Times 4 -Exactly
    }
}

Describe 'Reviewed release catalog regeneration' {
    It 'reproduces identical catalog bytes from the same saved source and cutoff' {
        $markdownPath = Join-Path $TestDrive 'release-source.md'
        [IO.File]::WriteAllText($markdownPath, (New-ReleaseMarkdownFixture), [Text.UTF8Encoding]::new($false))
        $first = Join-Path $TestDrive 'first.json'
        $second = Join-Path $TestDrive 'second.json'
        $generator = Join-Path $PSScriptRoot '../tools/dev/Update-WindowsReleaseCatalog.ps1'
        & $generator -MarkdownPath $markdownPath -AsOfDate ([datetime]'2026-09-07') -OutputPath $first
        & $generator -MarkdownPath $markdownPath -AsOfDate ([datetime]'2026-09-07') -OutputPath $second
        (Get-FileHash $first).Hash | Should -Be (Get-FileHash $second).Hash
        $catalog = Get-Content $first -Raw | ConvertFrom-Json
        $catalog.sourceCommit | Should -Be '0123456789012345678901234567890123456789'
        $catalog.releases[0].version | Should -Be '10.0.26200.9999'
        $catalog.asOfDate | Should -Be '2026-09-07'
    }
}
