Describe 'Start pinned-folder policy' {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot `
            '..\playbook\Executables\AtlasModules\Scripts\Tweaks\qol\config-start-menu.ps1'
        $tokens = $null
        $errors = $null
        $script:ast = [Management.Automation.Language.Parser]::ParseFile(
            $scriptPath, [ref]$tokens, [ref]$errors
        )
        @($errors).Count | Should -Be 0
    }

    It 'uses the documented device Start CSP class' {
        $source = $script:ast.Extent.Text
        $source | Should -Match ([regex]::Escape('root\cimv2\mdm\dmmap'))
        $source | Should -Match 'MDM_Policy_Config01_Start02'
        $source | Should -Match ([regex]::Escape('./Vendor/MSFT/Policy/Config'))
    }

    It 'hides every folder exposed by Windows 11 Start settings' {
        $expected = @(
            'AllowPinnedFolderSettings'
            'AllowPinnedFolderFileExplorer'
            'AllowPinnedFolderDocuments'
            'AllowPinnedFolderDownloads'
            'AllowPinnedFolderMusic'
            'AllowPinnedFolderPictures'
            'AllowPinnedFolderVideos'
            'AllowPinnedFolderNetwork'
            'AllowPinnedFolderPersonalFolder'
        )
        $function = $script:ast.Find({
                param($node)
                $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -eq 'Set-AtlasStartPinnedFolderPolicy'
            }, $true)

        $function | Should -Not -BeNullOrEmpty
        foreach ($name in $expected) {
            @($function.FindAll({
                        param($node)
                        $node -is [Management.Automation.Language.StringConstantExpressionAst] -and
                        $node.Value -eq $name
                    }, $true)).Count | Should -Be 1
        }
    }

    It 'invokes folder configuration before clearing the Start cache' {
        $commands = @($script:ast.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.CommandAst]
                }, $true))
        $policy = @($commands | Where-Object {
                $_.GetCommandName() -eq 'Set-AtlasStartPinnedFolderPolicy'
            })
        $cleanup = @($commands | Where-Object {
                $_.GetCommandName() -eq 'Invoke-AtlasUserAppxCacheCleanup'
            })

        $policy.Count | Should -Be 1
        $cleanup.Count | Should -Be 1
        $policy[0].Extent.EndOffset | Should -BeLessThan $cleanup[0].Extent.StartOffset
    }
}
