# Run with PowerShell 7. Reads the scripts; never starts the app or touches a window.
Describe 'UI review tools' {
    BeforeAll {
        $manifest = Get-Content (Join-Path $PSScriptRoot '../../Cargo.toml') -Raw
        $script:binary = [regex]::Match($manifest, '(?m)^\[\[bin\]\]\s*\r?\nname\s*=\s*"([^"]+)"').Groups[1].Value
    }
    It '<Script> looks for the app under its executable name by default' -ForEach @(
        @{ Script = 'Capture-Window.ps1' }
        @{ Script = 'Get-AccessibilityTree.ps1' }
    ) {
        $binary | Should -Not -BeNullOrEmpty
        $path = Join-Path $PSScriptRoot "../$Script"
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$null)
        $parameter = $ast.ParamBlock.Parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'ProcessName' }
        $parameter.DefaultValue.Value | Should -Be $binary
    }
}
