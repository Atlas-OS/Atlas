function Get-AtlasProcessExplorerHelperPath {
    # ProcessExplorer-Package.ps1 is a function library; each action dot-sources it
    # into its own scope before calling the package operations.
    param($Toggle)

    $helper = Join-Path -Path $Toggle.OperationsPath -ChildPath 'ProcessExplorer-Package.ps1'
    if (-not [IO.File]::Exists($helper)) {
        throw "ProcessExplorer: the package helper is missing at '$helper'."
    }

    return $helper
}

function Install-AtlasProcessExplorer {
    param($Toggle)

    . (Get-AtlasProcessExplorerHelperPath -Toggle $Toggle)

    # Silent upgrades preserve the current driver state. An earlier explicit disable
    # already persists; package ownership metadata remains available for uninstall.
    $disablePcw = $false
    if (-not $Toggle.Silent) {
        $layout = Get-AtlasProcessExplorerLayout
        $pcwStart = Get-AtlasProcessExplorerPcwStart -PcwPath $layout.PcwPath
        if ($pcwStart -in @(0, 1)) {
            Write-AtlasNote -Text 'The Windows boot driver pcw stays enabled.'
        }
        else {
            Write-AtlasNote -Text "The 'pcw' service is used by Task Manager and performance counters; disabling it can make some performance tools misbehave."
            $disablePcw = Read-AtlasYesNo -Question 'Disable the pcw service anyway?'
        }
        Write-AtlasStep -Text 'Downloading and installing Process Explorer...'
    }

    Install-AtlasProcessExplorerPackage -DisablePcw:$disablePcw
}

function Set-AtlasProcessExplorerUserPreference {
    param($Toggle)

    . (Get-AtlasProcessExplorerHelperPath -Toggle $Toggle)
    Write-AtlasProcessExplorerUserPreference
}

function Uninstall-AtlasProcessExplorer {
    param($Toggle)

    . (Get-AtlasProcessExplorerHelperPath -Toggle $Toggle)

    if (-not $Toggle.Silent) {
        Write-AtlasStep -Text 'Uninstalling Process Explorer and restoring Task Manager...'
    }
    Uninstall-AtlasProcessExplorerPackage
}
