BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $source = Join-Path $script:AtlasTestScriptsRoot 'Tweaks\misc\add-newUser-script.ps1'
    $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile($source, [ref]$null, [ref]$errors)
    if ($errors) { throw ($errors | Out-String) }
    $definition = $ast.Find({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Revoke-AtlasInstallLogUserAccess' }, $true)
    . ([scriptblock]::Create($definition.Extent.Text))

    function Get-UsersWriteRule([string]$Path) {
        $write = [Security.AccessControl.FileSystemRights]'WriteData, AppendData, WriteExtendedAttributes, WriteAttributes, Delete, ChangePermissions, TakeOwnership'
        @((Get-Acl -LiteralPath $Path).GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]) | Where-Object {
                $_.IdentityReference.Value -eq 'S-1-5-32-545' -and
                $_.AccessControlType -eq [Security.AccessControl.AccessControlType]::Allow -and
                ($_.FileSystemRights -band $write) -ne 0
            })
    }
}

Describe 'Install log access for standard users' {
    It 'removes the Users write grant from the log folder and everything in it' {
        $logs = Join-Path $TestDrive 'Logs'
        $log = Join-Path $logs 'install\atlas-install.log'
        New-Item -ItemType Directory -Path (Split-Path -Parent $log) -Force | Out-Null
        Set-Content -LiteralPath $log -Value 'line'
        # The grant pre-release builds made.
        & (Join-Path ([Environment]::SystemDirectory) 'icacls.exe') $logs /grant '*S-1-5-32-545:(OI)(CI)M' /T /Q | Out-Null
        $LASTEXITCODE | Should -Be 0
        Get-UsersWriteRule $log | Should -Not -BeNullOrEmpty

        Revoke-AtlasInstallLogUserAccess $logs

        foreach ($path in @($logs, (Split-Path -Parent $log), $log)) {
            Get-UsersWriteRule $path | Should -BeNullOrEmpty -Because $path
        }
    }
}
