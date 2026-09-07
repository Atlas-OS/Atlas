BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')

    $scriptPath = Join-Path $PSScriptRoot `
        '..\playbook\Executables\AtlasModules\Scripts\Tweaks\qol\config-start-menu.ps1'
    $tokens = $null
    $errors = $null
    $script:ast = [Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors)
    @($errors).Count | Should -Be 0

    # The policy function is defined inside the companion script; lift it out so it can
    # run against mocked CIM cmdlets without executing the rest of the tweak.
    $functionAst = $script:ast.Find({
            param($node)
            $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -eq 'Set-AtlasStartPinnedFolderPolicy'
        }, $true)
    $functionAst | Should -Not -BeNullOrEmpty
    . ([scriptblock]::Create($functionAst.Extent.Text))

    $script:ExpectedFolders = @(
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

    function New-TestStartPolicyInstance {
        param([int]$Value)

        $properties = @{}
        foreach ($name in $script:ExpectedFolders) {
            $properties[$name] = [pscustomobject]@{ Value = $Value }
        }
        return [pscustomobject]@{ CimInstanceProperties = $properties }
    }
}

Describe 'Start pinned-folder policy' {
    BeforeEach {
        Mock Get-CimInstance { @() }
        Mock New-CimInstance { New-TestStartPolicyInstance -Value 0 }
        Mock Set-CimInstance { $InputObject } -RemoveParameterType 'InputObject'
    }

    It 'addresses the documented device Start CSP class and hides every folder when no instance exists' {
        Set-AtlasStartPinnedFolderPolicy

        Should -Invoke Get-CimInstance -Times 1 -Exactly -ParameterFilter {
            $Namespace -eq 'root\cimv2\mdm\dmmap' -and $ClassName -eq 'MDM_Policy_Config01_Start02' -and
            $Filter -like "*ParentID='./Vendor/MSFT/Policy/Config'*" -and $Filter -like "*InstanceID='Start'*"
        }
        Should -Invoke New-CimInstance -Times 1 -Exactly -ParameterFilter {
            $Namespace -eq 'root\cimv2\mdm\dmmap' -and $ClassName -eq 'MDM_Policy_Config01_Start02' -and
            $Property.ParentID -eq './Vendor/MSFT/Policy/Config' -and $Property.InstanceID -eq 'Start' -and
            @($script:ExpectedFolders | Where-Object { $Property[$_] -ne 0 }).Count -eq 0
        }
        Should -Not -Invoke Set-CimInstance
    }

    It 'updates an existing instance in place and sets every folder to hidden' {
        $existing = New-TestStartPolicyInstance -Value 1
        Mock Get-CimInstance { @($existing) }

        Set-AtlasStartPinnedFolderPolicy

        Should -Not -Invoke New-CimInstance
        Should -Invoke Set-CimInstance -Times 1 -Exactly
        foreach ($name in $script:ExpectedFolders) {
            $existing.CimInstanceProperties[$name].Value | Should -Be 0 -Because $name
        }
    }

    It 'fails when the provider does not retain the hidden state or returns more than one instance' {
        Mock New-CimInstance { New-TestStartPolicyInstance -Value 1 }
        { Set-AtlasStartPinnedFolderPolicy } | Should -Throw '*did not apply the hidden state*'

        Mock Get-CimInstance { @((New-TestStartPolicyInstance -Value 0), (New-TestStartPolicyInstance -Value 0)) }
        { Set-AtlasStartPinnedFolderPolicy } | Should -Throw '*more than one configuration instance*'
    }

    It 'invokes folder configuration before clearing the Start cache' {
        $commands = @($script:ast.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.CommandAst]
                }, $true))
        $policy = @($commands | Where-Object { $_.GetCommandName() -eq 'Set-AtlasStartPinnedFolderPolicy' })
        $cleanup = @($commands | Where-Object { $_.GetCommandName() -eq 'Invoke-AtlasUserAppxCacheCleanup' })

        $policy.Count | Should -Be 1
        $cleanup.Count | Should -Be 1
        $policy[0].Extent.EndOffset | Should -BeLessThan $cleanup[0].Extent.StartOffset
    }
}
