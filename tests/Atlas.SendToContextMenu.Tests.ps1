BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:HelperPath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Internal\Set-SendToContextMenu.ps1'
    $script:TweakPath = Join-Path $script:RepoRoot `
        'playbook\Executables\AtlasModules\Scripts\Tweaks\qol\explorer\debloat-send-to.psd1'

    $tokens = $null
    $errors = $null
    $script:HelperAst = [Management.Automation.Language.Parser]::ParseFile(
        $script:HelperPath,
        [ref]$tokens,
        [ref]$errors
    )
    if (@($errors).Count -ne 0) {
        throw "The Send-To helper has parse errors: $($errors -join '; ')"
    }

    foreach ($functionName in @(
            'Resolve-AtlasSendToSelectorName'
            'ConvertFrom-AtlasSendToChoice'
            'Set-AtlasSendToItemState'
        )) {
        $functionAst = @($script:HelperAst.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
                        $node.Name -ceq $functionName
                }, $true))
        if ($functionAst.Count -ne 1) {
            throw "Expected one $functionName definition in the Send-To helper."
        }
        . ([scriptblock]::Create($functionAst[0].Extent.Text))
    }

    function Set-AtlasRegistryValue {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
            'PSUseShouldProcessForStateChangingFunctions',
            '',
            Justification = 'This test double records parameters and changes no state.'
        )]
        param($Path, $Name, $Type, $Data)
        $script:SetRegistryCall = [pscustomobject]@{
            Path = $Path
            Name = $Name
            Type = $Type
            Data = $Data
        }
    }
    function Remove-AtlasRegistryValue {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
            'PSUseShouldProcessForStateChangingFunctions',
            '',
            Justification = 'This test double records parameters and changes no state.'
        )]
        param($Path, $Name)
        $script:RemoveRegistryCall = [pscustomobject]@{
            Path = $Path
            Name = $Name
        }
    }
}

Describe 'Send-To context menu behavior' {
    It 'keeps the helper parseable and the tweak bound to the internal script' {
        $tweak = Import-PowerShellDataFile -LiteralPath $script:TweakPath
        $tweak.Run.Count | Should -Be 1
        $tweak.Run[0].RunAs | Should -BeExactly 'User'
        $tweak.Run[0].Wait | Should -BeTrue
        $tweak.Run[0].Args | Should -Contain `
            '{windir}\AtlasModules\Scripts\Internal\Set-SendToContextMenu.ps1'
        $tweak.Run[0].Args | Should -Contain '-DebloatDefaults'
    }

    It 'resolves known names and wildcard selectors in stable order' {
        $known = [string[]]@('Bluetooth', 'Mail recipient', 'Documents')
        @(Resolve-AtlasSendToSelectorName -Selector @('Mail*', 'Bluetooth', 'Mail*') `
                -KnownName $known) | Should -Be @('Mail recipient', 'Bluetooth')
    }

    It 'rejects empty and unsupported selectors' {
        { Resolve-AtlasSendToSelectorName -Selector @() -KnownName @('Documents') } |
            Should -Throw '*cannot be empty*'
        { Resolve-AtlasSendToSelectorName -Selector @('Typo') -KnownName @('Documents') } |
            Should -Throw '*Unsupported Send-To item selector*'
    }

    It 'treats empty multichoice output as cancellation' {
        $result = ConvertFrom-AtlasSendToChoice -Output @() `
            -AvailableName @('Documents') -DisableAllChoice '[disable all]'
        $result.Cancelled | Should -BeTrue
        @($result.Enabled).Count | Should -Be 0

        $blank = ConvertFrom-AtlasSendToChoice -Output @('') `
            -AvailableName @('Documents') -DisableAllChoice '[disable all]'
        $blank.Cancelled | Should -BeTrue
    }

    It 'requires the explicit sentinel to disable every item' {
        $result = ConvertFrom-AtlasSendToChoice -Output @('[disable all]') `
            -AvailableName @('Documents', 'Bluetooth') -DisableAllChoice '[disable all]'
        $result.Cancelled | Should -BeFalse
        @($result.Enabled).Count | Should -Be 0

        {
            ConvertFrom-AtlasSendToChoice -Output @('Documents;[disable all]') `
                -AvailableName @('Documents') -DisableAllChoice '[disable all]'
        } | Should -Throw '*cannot be combined*'
    }

    It 'rejects unsupported and duplicate multichoice output' {
        {
            ConvertFrom-AtlasSendToChoice -Output @('Unknown') `
                -AvailableName @('Documents') -DisableAllChoice '[disable all]'
        } | Should -Throw '*unsupported item*'
        {
            ConvertFrom-AtlasSendToChoice -Output @('Documents;Documents') `
                -AvailableName @('Documents') -DisableAllChoice '[disable all]'
        } | Should -Throw '*duplicate item*'
    }

    It 'hides and unhides an isolated Send-To file' {
        $fixture = Join-Path $TestDrive 'Mail Recipient.MAPIMail'
        [IO.File]::WriteAllText($fixture, 'fixture')
        Set-AtlasSendToItemState -Name 'Mail recipient' -Path $fixture -Enabled $false
        ((Get-Item -LiteralPath $fixture -Force).Attributes -band `
                [IO.FileAttributes]::Hidden) | Should -Be ([IO.FileAttributes]::Hidden)

        Set-AtlasSendToItemState -Name 'Mail recipient' -Path $fixture -Enabled $true
        ((Get-Item -LiteralPath $fixture -Force).Attributes -band `
                [IO.FileAttributes]::Hidden) | Should -Be 0
    }

    It 'uses the removable-drive policy for its registry-backed item' {
        $script:SetRegistryCall = $null
        $script:RemoveRegistryCall = $null
        Set-AtlasSendToItemState -Name 'Removable Drives' -Path $null -Enabled $false
        $script:SetRegistryCall.Path | Should -BeExactly `
            'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
        $script:SetRegistryCall.Name | Should -BeExactly 'NoDrivesInSendToMenu'
        $script:SetRegistryCall.Type | Should -BeExactly 'DWord'
        $script:SetRegistryCall.Data | Should -Be 1

        Set-AtlasSendToItemState -Name 'Removable Drives' -Path $null -Enabled $true
        $script:RemoveRegistryCall.Path | Should -BeExactly `
            'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
        $script:RemoveRegistryCall.Name | Should -BeExactly 'NoDrivesInSendToMenu'
    }
}
