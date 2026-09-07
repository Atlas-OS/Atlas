BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $source = Join-Path (Split-Path $PSScriptRoot -Parent) 'app\resources\iso\Build-Iso.ps1'
    $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile($source, [ref]$null, [ref]$errors)
    if ($errors) { throw ($errors | Out-String) }
    foreach ($name in @('Get-AtlasMediaEditions', 'Export-AtlasMediaEditions')) {
        $function = $ast.Find({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name }, $true)
        . ([scriptblock]::Create($function.Extent.Text))
    }
    # Owned stubs ensure a failed mock never calls DISM on the host.
    function Get-WindowsImage { param($ImagePath, $Index) throw "Unmocked image query: $ImagePath, $Index" }
    function Export-WindowsImage { param($SourceImagePath, $SourceIndex, $DestinationImagePath, $CompressionType, [switch]$CheckIntegrity, $ErrorAction) throw "Unmocked image export: $SourceImagePath, $SourceIndex, $DestinationImagePath, $CompressionType, $CheckIntegrity, $ErrorAction" }
    function Write-Stage { param($Stage) throw "Unmocked stage: $Stage" }
    function Get-AtlasWindowsReleaseStatus { param($Version) throw "Unmocked release query: $Version" }
    function New-ImageFixture([int]$Index, [string]$Edition) {
        [pscustomobject]@{ImageIndex=$Index; ImageName="Windows 11 $Edition"; EditionId=$Edition; Version='10.0.26200.6584'; Architecture=9; InstallationType='Client'}
    }
}

Describe 'Supported editions in mixed Microsoft media' {
    BeforeEach {
        $script:Images = @((New-ImageFixture 1 Core), (New-ImageFixture 2 CoreSingleLanguage), (New-ImageFixture 3 Professional), (New-ImageFixture 4 ProfessionalN), (New-ImageFixture 5 Education))
        $script:Exported = [Collections.Generic.List[object]]::new()
        Mock Get-WindowsImage {
            param($ImagePath, $Index)
            if ($ImagePath -eq 'source') {
                if ($Index) { $script:Images | Where-Object ImageIndex -eq $Index } else { $script:Images }
            } else {
                if ($Index) { $script:Exported[$Index - 1] } else { $script:Exported }
            }
        }
        Mock Export-WindowsImage {
            param($SourceIndex)
            $original = $script:Images | Where-Object ImageIndex -eq $SourceIndex
            $copy = New-ImageFixture ($script:Exported.Count + 1) $original.EditionId
            $script:Exported.Add($copy)
        }
        Mock Write-Stage {}
        Mock Get-AtlasWindowsReleaseStatus { 'Released' }
    }
    It 'keeps every supported edition without selecting a default' {
        $result = @(Get-AtlasMediaEditions source @(26200))
        ($result.EditionId -join ',') | Should -Be 'Professional,ProfessionalN,Education'
        ($result.ImageIndex -join ',') | Should -Be '3,4,5'
    }
    It 'does not retain Home-only or LTSC media' {
        $script:Images = @((New-ImageFixture 1 Core), (New-ImageFixture 2 EnterpriseS))
        @(Get-AtlasMediaEditions source @(26200)) | Should -HaveCount 0
    }
    It 'rejects unidentified editions instead of assuming support' {
        $script:Images[0].EditionId = ''
        { Get-AtlasMediaEditions source @(26200) } | Should -Throw '*no edition identity*'
    }
    It 'rejects a wrong build even on an otherwise supported edition' {
        $script:Images[2].Version = '10.0.26100.1'
        { Get-AtlasMediaEditions source @(26200) } | Should -Throw '*Unsupported Windows image*'
    }
    It 'rejects a wrong architecture' {
        $script:Images[2].Architecture = 12
        { Get-AtlasMediaEditions source @(26200) } | Should -Throw '*Unsupported Windows image*'
    }
    It 'rejects an unverified full version before exporting any edition' {
        Mock Get-AtlasWindowsReleaseStatus { 'Unknown' }
        { Get-AtlasMediaEditions source @(26200) } | Should -Throw '*could not be verified as a public release*'
        Should -Invoke Get-AtlasWindowsReleaseStatus -Times 1 -Exactly -ParameterFilter { $Version -eq [version]'10.0.26200.6584' }
        Should -Invoke Export-WindowsImage -Times 0 -Exactly
    }
    It 'rejects server media' {
        $script:Images[2].InstallationType = 'Server'
        { Get-AtlasMediaEditions source @(26200) } | Should -Throw '*client*'
    }
    It 'exports the original supported indices and verifies their new contiguous indices' {
        $selected = @(Get-AtlasMediaEditions source @(26200))
        Export-AtlasMediaEditions source (Join-Path $TestDrive 'output.wim') $selected
        ($script:Exported.EditionId -join ',') | Should -Be 'Professional,ProfessionalN,Education'
        Should -Invoke Export-WindowsImage -Times 3 -Exactly -ParameterFilter { $CheckIntegrity -and $CompressionType -eq 'Max' -and $SourceImagePath -eq 'source' }
        Should -Invoke Export-WindowsImage -Times 0 -Exactly -ParameterFilter { $SourceIndex -in @(1,2) }
    }
    It 'does not append to an existing image' {
        $destination = Join-Path $TestDrive 'existing.wim'
        Set-Content -LiteralPath $destination 'fixture'
        { Export-AtlasMediaEditions source $destination @(Get-AtlasMediaEditions source @(26200)) } | Should -Throw '*already exists*'
        Should -Invoke Export-WindowsImage -Times 0 -Exactly
    }
    It 'fails when the export produces a different edition' {
        Mock Export-WindowsImage { $script:Exported.Add((New-ImageFixture ($script:Exported.Count + 1) Core)) }
        { Export-AtlasMediaEditions source (Join-Path $TestDrive 'wrong.wim') @(Get-AtlasMediaEditions source @(26200)) } | Should -Throw '*does not match*'
    }
    It 'stops exporting after cancellation at an edition boundary' {
        Mock Write-Stage { throw 'Cancelled at a safe checkpoint.' }
        { Export-AtlasMediaEditions source (Join-Path $TestDrive 'cancelled.wim') @(Get-AtlasMediaEditions source @(26200)) } | Should -Throw '*Cancelled*'
        Should -Invoke Export-WindowsImage -Times 0 -Exactly
    }
}
