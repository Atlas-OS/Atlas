BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $removeEdgePath = Join-Path -Path $repoRoot `
        -ChildPath 'playbook\Executables\AtlasModules\Scripts\Operations\Remove-Edge.ps1'

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

    foreach ($name in @(
            'Assert-MicrosoftSignedInstaller',
            'Invoke-MicrosoftWebViewDownload',
            'Wait-EdgeUninstallerProcesses',
            'Remove-EdgeRegistration',
            'Remove-EdgeRegistryKey',
            'DisableEdgeBrowserServices',
            'KillEdgeProcesses'
        )) {
        if (-not $functions.ContainsKey($name)) {
            throw "$name was not found in '$removeEdgePath'."
        }
    }

    $script:assertMicrosoftSignedInstaller = $functions['Assert-MicrosoftSignedInstaller']
    $script:invokeMicrosoftWebViewDownload = $functions['Invoke-MicrosoftWebViewDownload']
    $script:waitEdgeUninstallerProcesses = $functions['Wait-EdgeUninstallerProcesses']
    $script:edgeFunctions = $functions
}

Describe 'Edge removal preserves shared WebView2 infrastructure' {
    BeforeEach {
        . $script:edgeFunctions['Remove-EdgeRegistration']
        . $script:edgeFunctions['Remove-EdgeRegistryKey']
        . $script:edgeFunctions['DisableEdgeBrowserServices']
        . $script:edgeFunctions['KillEdgeProcesses']
        function Write-Status { param($Text, $Level) $null = $Text; $null = $Level }
    }

    It 'removes only the browser client and preserves WebView2 registration in both registry views' {
        Set-Variable -Name MachineContext -Value $true
        $scratchRoot = 'HKCU:\Software\AtlasRewriteTest\EdgeRegistration'
        $edgeId = '{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}'
        $webViewId = '{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
        try {
            foreach ($view in '32', '64') {
                foreach ($branch in 'Clients', 'ClientState', 'ClientStateMedium') {
                    foreach ($clientId in $edgeId, $webViewId) {
                        $path = "$scratchRoot\$view\Microsoft\EdgeUpdate\$branch\$clientId"
                        New-Item -Path $path -Force | Out-Null
                        New-ItemProperty -LiteralPath $path -Name pv -Value '152.0.4191.62' -PropertyType String | Out-Null
                    }
                }
            }
            Mock Remove-EdgeRegistryKey {
                $KeyPath.StartsWith('HKLM\SOFTWARE\') | Should -BeTrue
                $relative = $KeyPath.Substring('HKLM\SOFTWARE\'.Length)
                $target = "$scratchRoot\$RegistryView\$relative"
                if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
            }
            Remove-EdgeRegistration
            foreach ($view in '32', '64') {
                foreach ($branch in 'Clients', 'ClientState', 'ClientStateMedium') {
                    Test-Path -LiteralPath "$scratchRoot\$view\Microsoft\EdgeUpdate\$branch\$edgeId" | Should -BeFalse
                    (Get-ItemProperty -LiteralPath "$scratchRoot\$view\Microsoft\EdgeUpdate\$branch\$webViewId").pv | Should -Be '152.0.4191.62'
                }
            }
        }
        finally {
            Remove-Item -LiteralPath $scratchRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'disables browser services without stopping or disabling the shared updater' {
        Mock Get-CimInstance { @(
            [pscustomobject]@{ Name = 'edgeupdate'; PathName = 'C:\Program Files (x86)\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe' }
            [pscustomobject]@{ Name = 'BrowserElevation'; PathName = 'C:\Program Files (x86)\Microsoft\Edge\Application\elevation_service.exe' }
        ) }
        Mock Get-Service { [pscustomobject]@{ Status = 'Running' } }
        Mock Stop-Service {}
        Mock Set-Service {}
        DisableEdgeBrowserServices
        Should -Invoke Set-Service -Times 1 -Exactly -ParameterFilter { $Name -eq 'BrowserElevation' -and $StartupType -eq 'Disabled' }
        Should -Invoke Get-Service -Times 0 -ParameterFilter { $Name -eq 'edgeupdate' }
        Should -Invoke Set-Service -Times 0 -ParameterFilter { $Name -eq 'edgeupdate' }
    }

    It 'stops Edge while leaving WebView2 and the updater running' {
        Mock Get-Service { @() }
        Mock Stop-Service {}
        Mock Get-Process { @(
            [pscustomobject]@{ Id = 101; Name = 'msedge'; Path = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe' }
            [pscustomobject]@{ Id = 102; Name = 'msedgewebview2'; Path = 'C:\Program Files (x86)\Microsoft\EdgeWebView\Application\msedgewebview2.exe' }
            [pscustomobject]@{ Id = 103; Name = 'MicrosoftEdgeUpdate'; Path = 'C:\Program Files (x86)\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe' }
        ) }
        Mock Stop-Process {}
        KillEdgeProcesses
        Should -Invoke Stop-Process -Times 1 -Exactly -ParameterFilter { $Id -eq 101 }
        Should -Invoke Stop-Process -Times 0 -ParameterFilter { $Id -in @(102, 103) }
    }
}

Describe 'Remove-Edge detached uninstaller boundary' {
    BeforeEach {
        . $script:waitEdgeUninstallerProcesses
        function Write-Status {
            param([string]$Text, $Level)
            $null = $Text
            $null = $Level
        }
    }

    It 'returns without delay or termination when every tracked uninstaller has exited' {
        Mock Get-Process
        Mock Start-Sleep
        Mock Stop-Process

        Wait-EdgeUninstallerProcesses -Process @([pscustomobject]@{ Id = 4101 })

        Should -Invoke Get-Process -Times 1 -Exactly -ParameterFilter { $Id -eq 4101 }
        Should -Invoke Start-Sleep -Times 0
        Should -Invoke Stop-Process -Times 0
    }

    It 'terminates and verifies an uninstaller that outlives its launch window' {
        $script:edgeUninstallerRunning = $true
        Mock Get-Process {
            if ($script:edgeUninstallerRunning) {
                return [pscustomobject]@{ Id = $Id }
            }
        }
        Mock Stop-Process { $script:edgeUninstallerRunning = $false }
        Mock Start-Sleep

        Wait-EdgeUninstallerProcesses -Process @([pscustomobject]@{ Id = 4102 }) `
            -LaunchWindowSeconds 0 -TerminationSeconds 0

        Should -Invoke Stop-Process -Times 1 -Exactly -ParameterFilter {
            $Id -eq 4102 -and $Force
        }
        Should -Invoke Get-Process -Times 2 -Exactly -ParameterFilter { $Id -eq 4102 }
    }

    It 'refuses direct removal when uninstaller termination cannot be confirmed' {
        Mock Get-Process { [pscustomobject]@{ Id = $Id } }
        Mock Stop-Process
        Mock Start-Sleep

        {
            Wait-EdgeUninstallerProcesses -Process @([pscustomobject]@{ Id = 4103 }) `
                -LaunchWindowSeconds 0 -TerminationSeconds 0
        } | Should -Throw '*Could not confirm termination*4103*'

        Should -Invoke Stop-Process -Times 1 -Exactly -ParameterFilter {
            $Id -eq 4103 -and $Force
        }
    }
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
