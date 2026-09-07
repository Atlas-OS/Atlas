BeforeAll {
    $script:policyFiles = Join-Path (Split-Path $PSScriptRoot -Parent) 'playbook\Executables\AtlasDesktop\2. Drivers\Drivers from Windows Update'
    $script:isolatedKey = 'Software\AtlasDriverPolicyTests\' + [guid]::NewGuid().ToString('N')
    function Import-IsolatedDriverPolicy([string]$Mode) {
        # Exercise the shipped .reg pair without changing any host driver policy.
        $text = [IO.File]::ReadAllText((Join-Path $script:policyFiles "$Mode Drivers from Windows Update.reg"))
        $text = $text.Replace('HKEY_LOCAL_MACHINE\', ('HKEY_CURRENT_USER\' + $script:isolatedKey + '\'))
        $file = Join-Path $TestDrive "$Mode.reg"
        [IO.File]::WriteAllText($file, $text, [Text.Encoding]::Unicode)
        & "$env:WINDIR\System32\reg.exe" import $file | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Could not import isolated driver policy.' }
    }
}
Describe 'Manual and automatic driver policy' {
    AfterAll {
        [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree($script:isolatedKey, $false)
    }
    It 'blocks both update drivers and new-device online searches, then reverses both' {
        Import-IsolatedDriverPolicy Disable
        $base = 'HKCU:\' + $script:isolatedKey + '\SOFTWARE\'
        (Get-ItemProperty ($base + 'Policies\Microsoft\Windows\WindowsUpdate')).ExcludeWUDriversInQualityUpdate | Should -Be 1
        (Get-ItemProperty ($base + 'Policies\Microsoft\Windows\DriverSearching')).SearchOrderConfig | Should -Be 0
        (Get-ItemProperty ($base + 'Microsoft\Windows\CurrentVersion\DriverSearching')).SearchOrderConfig | Should -Be 0
        Import-IsolatedDriverPolicy Enable
        (Get-ItemProperty ($base + 'Policies\Microsoft\Windows\WindowsUpdate')).PSObject.Properties['ExcludeWUDriversInQualityUpdate'] | Should -BeNullOrEmpty
        (Get-ItemProperty ($base + 'Policies\Microsoft\Windows\DriverSearching')).PSObject.Properties['SearchOrderConfig'] | Should -BeNullOrEmpty
        (Get-ItemProperty ($base + 'Microsoft\Windows\CurrentVersion\DriverSearching')).SearchOrderConfig | Should -Be 1
    }
}
