@{
    Name        = 'Add Power Plan File Association'
    Description = 'Adds a file association for .pow files, so you can simply double click on it and import it'
    Registry    = @(
        @{ Path = 'HKCR\.pow'; Name = 'FriendlyTypeName'; Type = 'String'; Data = 'Power Scheme' }
        # Show the UAC shield on the open verb (the import elevates).
        @{ Path = 'HKCR\powerscheme\Shell\open'; Name = 'HasLUAShield'; Type = 'String' }
    )
    # The default ('') values cannot be expressed in the Registry schema (a value name
    # is required), so they are written by the companion script.
    Script      = 'import-power-plan.ps1'
}
