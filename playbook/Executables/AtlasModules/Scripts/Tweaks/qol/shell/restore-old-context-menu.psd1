@{
    Name        = 'Restore Old Context Menu'
    Description = 'Restores the old context menu in Windows 11'
    Registry    = @(
        @{ Path = 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'; Name = ''; Type = 'String'; Data = '' }
    )
}
