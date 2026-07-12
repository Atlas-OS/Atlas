BeforeAll {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $removeEdgePath = Join-Path -Path $repoRoot `
        -ChildPath 'playbook\Executables\AtlasModules\Scripts\Internal\Remove-Edge.ps1'

    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $removeEdgePath,
        [ref]$tokens,
        [ref]$errors
    )

    $functions = @{}
    $ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true) | ForEach-Object {
        $functions[$_.Name] = [scriptblock]::Create($_.Extent.Text)
    }

    foreach ($name in @('Assert-MicrosoftSignedInstaller', 'Invoke-MicrosoftWebViewDownload')) {
        if (-not $functions.ContainsKey($name)) {
            throw "$name was not found in '$removeEdgePath'."
        }
    }

    $script:assertMicrosoftSignedInstaller = $functions['Assert-MicrosoftSignedInstaller']
    $script:invokeMicrosoftWebViewDownload = $functions['Invoke-MicrosoftWebViewDownload']
}

Describe 'Remove-Edge download boundaries' {
    It 'rejects an unsigned payload as a Microsoft installer' {
        . $script:assertMicrosoftSignedInstaller
        $payload = Join-Path -Path $TestDrive -ChildPath 'unsigned.exe'
        [IO.File]::WriteAllText($payload, 'not an executable payload')

        {
            Assert-MicrosoftSignedInstaller -Path $payload `
                -StagingDirectory $TestDrive -Description 'Test payload'
        } | Should -Throw '*not validly signed by Microsoft Corporation*'
    }

    It 'rejects an unreviewed WebView download URL' {
        . $script:invokeMicrosoftWebViewDownload
        $destination = Join-Path -Path $TestDrive -ChildPath 'payload.exe'

        {
            Invoke-MicrosoftWebViewDownload -Uri 'https://example.test/payload.exe' `
                -Destination $destination -StagingDirectory $TestDrive
        } | Should -Throw '*not the reviewed Microsoft forwarding URL*'
    }
}
