BeforeAll {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $removeEdgePath = Join-Path -Path $repoRoot `
        -ChildPath 'playbook\Executables\AtlasModules\Scripts\Internal\Remove-Edge.ps1'

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
            'Wait-EdgeUninstallerProcesses'
        )) {
        if (-not $functions.ContainsKey($name)) {
            throw "$name was not found in '$removeEdgePath'."
        }
    }

    $script:assertMicrosoftSignedInstaller = $functions['Assert-MicrosoftSignedInstaller']
    $script:invokeMicrosoftWebViewDownload = $functions['Invoke-MicrosoftWebViewDownload']
    $script:waitEdgeUninstallerProcesses = $functions['Wait-EdgeUninstallerProcesses']
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
