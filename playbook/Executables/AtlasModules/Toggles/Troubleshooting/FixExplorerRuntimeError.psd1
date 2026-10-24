@{
    Name          = 'FixExplorerRuntimeError'
    Description   = 'Fixes blank Microsoft Visual C++ Runtime Library errors from File Explorer by removing the search redirect that older Atlas builds left. Records no state.'
    Elevation     = 'Admin'
    NoStateRecord = $true
    States        = @(
        @{
            Name     = 'Run'
            Launcher = '9. Troubleshooting\Fix File Explorer Visual C++ Runtime Error.cmd'
            Reboot   = 'RestartExplorer'
            # Machine keys only: HKCU entries would be user work, which an elevated caller can't run.
            Registry = @(
                @{ Path = 'HKLM:\SOFTWARE\Classes\CLSID\{1d64637d-31e9-4b06-9124-e83fb178ac6e}\TreatAs'; Operation = 'DeleteKey' }
                @{ Path = 'HKLM:\SOFTWARE\Classes\WOW6432Node\CLSID\{1d64637d-31e9-4b06-9124-e83fb178ac6e}\TreatAs'; Operation = 'DeleteKey' }
                @{ Path = 'HKLM:\SOFTWARE\WOW6432Node\Classes\CLSID\{1d64637d-31e9-4b06-9124-e83fb178ac6e}\TreatAs'; Operation = 'DeleteKey' }
            )
        }
    )
}
