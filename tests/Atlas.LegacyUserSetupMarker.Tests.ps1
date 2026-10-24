BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $source = Join-Path $script:AtlasTestScriptsRoot 'Tweaks\misc\add-newUser-script.ps1'
    $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile($source, [ref]$null, [ref]$errors)
    if ($errors) { throw ($errors | Out-String) }
    $definition = $ast.Find({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Revoke-AtlasLegacyMarkerUserAccess' }, $true)
    . ([scriptblock]::Create($definition.Extent.Text))

    $script:parentSubKey = 'Software\AtlasRewriteTestUserSetupMarker'
    $script:usersSid = New-Object Security.Principal.SecurityIdentifier('S-1-5-32-545')

    # Builds Parent\Marker, where the parent hands Users $InheritedRights and the marker
    # carries the explicit 'ReadKey, SetValue' grant pre-release builds made.
    function New-MarkerKey([Security.AccessControl.RegistryRights]$InheritedRights) {
        Remove-Item -Path "HKCU:\$script:parentSubKey" -Recurse -Force -ErrorAction SilentlyContinue
        $parent = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($script:parentSubKey)
        try {
            $acl = $parent.GetAccessControl()
            $acl.AddAccessRule((New-Object Security.AccessControl.RegistryAccessRule(
                        $script:usersSid, $InheritedRights,
                        [Security.AccessControl.InheritanceFlags]::ContainerInherit,
                        [Security.AccessControl.PropagationFlags]::None,
                        [Security.AccessControl.AccessControlType]::Allow)))
            $parent.SetAccessControl($acl)
            $marker = $parent.CreateSubKey('Marker')
            try {
                $acl = $marker.GetAccessControl()
                $acl.AddAccessRule((New-Object Security.AccessControl.RegistryAccessRule(
                            $script:usersSid, [Security.AccessControl.RegistryRights]'ReadKey, SetValue',
                            [Security.AccessControl.AccessControlType]::Allow)))
                $marker.SetAccessControl($acl)
            }
            finally {
                $marker.Close()
            }
        }
        finally {
            $parent.Close()
        }

        [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey(
            "$script:parentSubKey\Marker",
            [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
            [Security.AccessControl.RegistryRights]'ReadPermissions, ChangePermissions')
    }

    function Get-UsersRule([Microsoft.Win32.RegistryKey]$Key, [bool]$Inherited) {
        @($Key.GetAccessControl().GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]) |
                Where-Object { $_.IdentityReference.Value -eq $script:usersSid.Value -and $_.IsInherited -eq $Inherited })
    }
}

AfterAll {
    Remove-Item -Path "HKCU:\$script:parentSubKey" -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Legacy UserSetup marker access for standard users' {
    It 'removes the explicit Users grant and accepts the inherited read rule' {
        $key = New-MarkerKey -InheritedRights ReadKey
        try {
            Get-UsersRule $key $false | Should -Not -BeNullOrEmpty

            { Revoke-AtlasLegacyMarkerUserAccess $key } | Should -Not -Throw

            Get-UsersRule $key $false | Should -BeNullOrEmpty
            Get-UsersRule $key $true | Should -Not -BeNullOrEmpty
        }
        finally {
            $key.Close()
        }
    }

    It 'fails closed while an inherited Users rule can still write the marker' {
        $key = New-MarkerKey -InheritedRights 'ReadKey, SetValue'
        try {
            { Revoke-AtlasLegacyMarkerUserAccess $key } | Should -Throw '*still grants write access*'
        }
        finally {
            $key.Close()
        }
    }
}
