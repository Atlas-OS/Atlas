BeforeAll {
    $script:repoRoot = Split-Path -Parent $PSScriptRoot
    $script:removeEdgePath = Join-Path `
        -Path $script:repoRoot `
        -ChildPath 'playbook\Executables\AtlasModules\Scripts\Internal\Remove-Edge.ps1'
    $script:removeEdgeContent = Get-Content -LiteralPath $script:removeEdgePath -Raw

    $tokens = $null
    $script:parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $script:removeEdgePath,
        [ref]$tokens,
        [ref]$script:parseErrors
    )

    $script:functionText = @{}
    $ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true) | ForEach-Object {
        $script:functionText[$_.Name] = $_.Extent.Text
    }
}

Describe 'Remove-Edge direct download integrity contracts' {
    It 'parses without errors and imports the shared integrity boundary explicitly' {
        $script:parseErrors.Count | Should -Be 0
        $script:removeEdgeContent | Should -Match '\[IO\.Path\]::Combine\(\$PSScriptRoot, ''Download-Integrity\.ps1''\)'
        $script:removeEdgeContent | Should -Match '(?m)^\. \$downloadIntegrity$'
    }

    It 'fails closed unless the Edge API supplies one canonical SHA-256-pinned MSI' {
        $edge = $script:functionText['InstallEdgeChromium']

        $edge | Should -Match '\$artifacts\.Count -ne 1'
        $edge | Should -Match "ArtifactName -eq 'msi'"
        $edge | Should -Match "HashAlgorithm[\s\S]+?Equals\('SHA256'"
        $edge | Should -Match '\$hash -notmatch ''\^\[0-9a-fA-F\]\{64\}\$'''
        $edge | Should -Match '\$expectedBytes -lt 1[\s\S]+?1073741824'
        $edge | Should -Match 'MicrosoftEdgeEnterprise\$architectureName\.msi'
        $script:removeEdgeContent | Should -Match 'msedge\.sf\.tlu\.dl\.delivery\.mp\.microsoft\.com'
        $script:removeEdgeContent | Should -Match 'msedge\.sf\.dl\.delivery\.mp\.microsoft\.com'
        $script:removeEdgeContent | Should -Match 'msedge\.sb\.tlu\.dl\.delivery\.mp\.microsoft\.com'
        $script:removeEdgeContent | Should -Match 'msedge\.sb\.dl\.delivery\.mp\.microsoft\.com'
        $edge | Should -Match '\$downloadUri\.Host -notin \$microsoftEdgeDownloadHosts'
        $edge | Should -Not -Match 'Not verifying hash|hash.+undefined'
    }

    It 'downloads the Edge MSI only through pinned protected staging' {
        $edge = $script:functionText['InstallEdgeChromium']

        $edge | Should -Match '\$stagingDirectory = New-AtlasProtectedStagingDirectory'
        $edge | Should -Match 'Invoke-AtlasPinnedDownload[\s\S]+?-Sha256 \$hash[\s\S]+?-ExpectedBytes \$expectedBytes'
        $edge | Should -Not -Match 'GetTempPath|Get-Command\s+curl|Invoke-WebRequest[\s\S]+?-OutFile|(?m)^\s*curl(?:\.exe)?\b'
        $edge | Should -Match 'finally[\s\S]+?Remove-Item -LiteralPath \$stagingDirectory -Recurse -Force'
    }

    It 'uses Microsoft Authenticode as an independent publisher boundary' {
        $publisherCheck = $script:functionText['Assert-MicrosoftSignedInstaller']

        $publisherCheck | Should -Match 'Microsoft\.PowerShell\.Security\\Get-AuthenticodeSignature'
        $publisherCheck | Should -Match 'SignatureStatus\]::Valid'
        $publisherCheck | Should -Match 'CN=Microsoft Corporation'
        $publisherCheck | Should -Match 'ExpectedSha256[\s\S]+?Get-FileHash'
        $publisherCheck | Should -Match 'ExpectedBytes[\s\S]+?file\.Length'
    }

    It 'dynamically rejects unsigned payloads and an unreviewed WebView source before execution' {
        $unsignedPayload = Join-Path -Path $TestDrive -ChildPath 'unsigned.exe'
        Set-Content -LiteralPath $unsignedPayload -Value 'not an executable payload' -NoNewline

        $publisherProbe = [scriptblock]::Create(
            $script:functionText['Assert-MicrosoftSignedInstaller'] +
            "`nAssert-MicrosoftSignedInstaller -Path `$args[0] -StagingDirectory `$args[1] -Description 'Test payload'"
        )
        { & $publisherProbe $unsignedPayload $TestDrive } |
            Should -Throw '*not validly signed by Microsoft Corporation*'

        $sourceProbe = [scriptblock]::Create(
            $script:functionText['Invoke-MicrosoftWebViewDownload'] +
            "`nInvoke-MicrosoftWebViewDownload -Uri 'https://example.test/payload.exe' -Destination `$args[0] -StagingDirectory `$args[1]"
        )
        { & $sourceProbe (Join-Path $TestDrive 'payload.exe') $TestDrive } |
            Should -Throw '*not the reviewed Microsoft forwarding URL*'
    }

    It 'constrains the moving WebView fwlink and final Microsoft delivery identity' {
        $download = $script:functionText['Invoke-MicrosoftWebViewDownload']

        $download | Should -Match 'https://go\.microsoft\.com/fwlink/p/\?LinkId=2124703'
        $download | Should -Match '\$effectiveUri\.Host -notin \$microsoftEdgeDownloadHosts'
        $download | Should -Match 'MicrosoftEdgeWebview2Setup\.exe'
        $download | Should -Match "GetFolderPath\('System'\), 'curl\.exe'"
        $download | Should -Match '(?s)\$curlArguments = @\(\s*#.+?\s*''--disable'''
        $download | Should -Match "'--proto-redir', '=https'"
        $download | Should -Match "'--max-time', '300'"
        $download | Should -Match "'--write-out', '%\{url_effective\}'"
        $download | Should -Match 'Test-AtlasProtectedStagingAcl'
        $download | Should -Match 'Assert-MicrosoftSignedInstaller'
        $download | Should -Not -Match 'GetTempPath|Get-Command\s+curl|Invoke-WebRequest|''--retry'
    }

    It 'revalidates each payload immediately before bounded protected execution' {
        $edge = $script:functionText['InstallEdgeChromium']
        $webView = $script:functionText['InstallWebView']

        $edgeSignature = $edge.IndexOf('Assert-MicrosoftSignedInstaller')
        $edgeLaunch = $edge.IndexOf('Invoke-AtlasContainedProcess')
        $edgeSignature | Should -BeGreaterThan -1
        $edgeLaunch | Should -BeGreaterThan $edgeSignature
        $edge | Should -Match "Mode = '/i'[\s\S]+?Mode = '/fa'"
        $edge | Should -Match 'Invoke-AtlasContainedProcess[\s\S]+?-ArgumentList \(\[string\[\]\]@\('
        $edge | Should -Match '-TimeoutSeconds 1800[\s\S]+?-Hidden'
        $edge | Should -Match "GetFolderPath\('System'\), 'msiexec\.exe'"
        $edge | Should -Not -Match "-FilePath 'msiexec\.exe'|Start-Process|Wait-AtlasProcessWithTimeout"
        $edge | Should -Match 'SetEnvironmentVariable\(''TEMP'', \$stagingDirectory'
        $edge | Should -Match 'SetEnvironmentVariable\(''TMP'', \$stagingDirectory'
        $edge | Should -Match 'ContainmentConfirmed[\s\S]+?RootExited[\s\S]+?JobDrained'
        $edge | Should -Match 'ExitCodeUInt32 -notin @\(\[uint32\]0, \[uint32\]3010\)'
        ([regex]::Matches($edge, 'Test-AtlasContainedProcessContainmentUnconfirmed')).Count |
            Should -BeGreaterOrEqual 2
        $edge | Should -Match 'if \(\$retainStaging\)[\s\S]+?elseif[\s\S]+?Remove-Item -LiteralPath \$stagingDirectory -Recurse -Force'

        $webViewSignature = $webView.IndexOf('Assert-MicrosoftSignedInstaller')
        $webViewLaunch = $webView.IndexOf('Invoke-AtlasContainedProcess')
        $webViewSignature | Should -BeGreaterThan -1
        $webViewLaunch | Should -BeGreaterThan $webViewSignature
        $webView | Should -Match 'Invoke-AtlasContainedProcess[\s\S]+?-ArgumentList \(\[string\[\]\]@\(''/silent'', ''/install''\)\)'
        $webView | Should -Match '-TimeoutSeconds 1800[\s\S]+?-Hidden'
        $webView | Should -Not -Match 'Start-Process|Wait-AtlasProcessWithTimeout'
        $webView | Should -Match 'SetEnvironmentVariable\(''TEMP'', \$stagingDirectory'
        $webView | Should -Match 'SetEnvironmentVariable\(''TMP'', \$stagingDirectory'
        $webView | Should -Match 'ContainmentConfirmed[\s\S]+?RootExited[\s\S]+?JobDrained'
        $webView | Should -Match 'ExitCodeUInt32 -notin @\(\[uint32\]0, \[uint32\]3010\)'
        $webView | Should -Match 'Test-AtlasContainedProcessContainmentUnconfirmed'
        $webView | Should -Match 'if \(\$retainStaging\)[\s\S]+?elseif[\s\S]+?Remove-Item -LiteralPath \$stagingDirectory -Recurse -Force'
    }
}
