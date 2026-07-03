@{
    Name        = 'Disable Legacy File Explorer Search Redirect'
    Description = 'Removes the legacy File Explorer search COM redirect to prevent Explorer runtime errors on newer Windows builds'
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Classes\CLSID\{1d64637d-31e9-4b06-9124-e83fb178ac6e}\TreatAs'; Operation = 'DeleteKey' }
        @{ Path = 'HKLM:\SOFTWARE\Classes\WOW6432Node\CLSID\{1d64637d-31e9-4b06-9124-e83fb178ac6e}\TreatAs'; Operation = 'DeleteKey' }
        @{ Path = 'HKLM:\SOFTWARE\WOW6432Node\Classes\CLSID\{1d64637d-31e9-4b06-9124-e83fb178ac6e}\TreatAs'; Operation = 'DeleteKey' }
        @{ Path = 'HKCU\Software\Classes\CLSID\{1d64637d-31e9-4b06-9124-e83fb178ac6e}\TreatAs'; Operation = 'DeleteKey' }
        @{ Path = 'HKCU\Software\Classes\WOW6432Node\CLSID\{1d64637d-31e9-4b06-9124-e83fb178ac6e}\TreatAs'; Operation = 'DeleteKey' }
    )
}
