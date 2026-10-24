@{
    Name        = 'Add Power Plan File Association'
    Description = 'Adds a file association for .pow files, so you can simply double click on it and import it'
    Registry    = @(
        @{ Path = 'HKCR\.pow'; Name = ''; Type = 'String'; Data = 'powerscheme' }
        @{ Path = 'HKCR\.pow'; Name = 'FriendlyTypeName'; Type = 'String'; Data = 'Power Scheme' }
        @{ Path = 'HKCR\powerscheme\DefaultIcon'; Name = ''; Type = 'String'; Data = '%windir%\System32\powercpl.dll,1' }
        # Show the UAC shield on the open verb (the import elevates).
        @{ Path = 'HKCR\powerscheme\Shell\open'; Name = 'HasLUAShield'; Type = 'String' }
        # Keep the selected path in argv. The protected handler validates one absolute .pow
        # file, then elevates only the exact inbox powercfg executable.
        @{ Path = 'HKCR\powerscheme\Shell\open\command'; Name = ''; Type = 'ExpandString'; Data = '"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%SystemRoot%\AtlasModules\Scripts\Entry\Import-PowerPlanFile.ps1" -PowerPlanPath "%1"' }
    )
}
