BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')

    $script:scriptPath = Join-Path $script:AtlasTestScriptsRoot 'Tweaks\qol\config-start-menu.ps1'
    $tokens = $null
    $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile($script:scriptPath, [ref]$tokens, [ref]$errors)
    @($errors).Count | Should -Be 0

    # The policy function is defined inside the companion script; lift it out so it can
    # run against mocked CIM cmdlets without executing the rest of the tweak.
    $functionAst = $ast.Find({
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

    It 'hides the folders after setting the layout and before clearing the Start cache' {
        # Clearing the cache first would leave Start showing the folders until the next reset.
        function Set-AtlasStartLayout { }
        function Invoke-AtlasUserAppxCacheCleanup { param([string]$Mode) [void]$Mode }
        $calls = [Collections.Generic.List[string]]::new()
        Mock Import-Module { }
        Mock Set-AtlasStartLayout { $calls.Add('layout') }
        Mock New-CimInstance { $calls.Add('folders'); New-TestStartPolicyInstance -Value 0 }
        Mock Invoke-AtlasUserAppxCacheCleanup { $calls.Add("cache:$Mode") }

        & $script:scriptPath

        @($calls) | Should -Be @('layout', 'folders', 'cache:StartMenu')
    }
}
