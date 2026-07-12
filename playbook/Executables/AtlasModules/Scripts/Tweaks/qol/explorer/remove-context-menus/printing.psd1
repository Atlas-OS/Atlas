@{
    Name        = 'Remove ''Printing'' from Context Menus'
    Description = 'Removes printing from context menus as users normally print from apps anyways'
    Registry    = @(
        # This is the exact Printing/Disable ContextAction set. It intentionally does not
        # record the full Printing toggle state or change services, features, or Settings.
        @{ Path = 'Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\image\shell\print'; Name = 'ProgrammaticAccessOnly'; Type = 'String'; Data = '' }
        @{ Path = 'Registry::HKEY_CLASSES_ROOT\batfile\shell\print'; Name = 'ProgrammaticAccessOnly'; Type = 'String'; Data = '' }
        @{ Path = 'Registry::HKEY_CLASSES_ROOT\cmdfile\shell\print'; Name = 'ProgrammaticAccessOnly'; Type = 'String'; Data = '' }
        @{ Path = 'Registry::HKEY_CLASSES_ROOT\docxfile\shell\print'; Name = 'ProgrammaticAccessOnly'; Type = 'String'; Data = '' }
        @{ Path = 'Registry::HKEY_CLASSES_ROOT\fonfile\shell\print'; Name = 'ProgrammaticAccessOnly'; Type = 'String'; Data = '' }
        @{ Path = 'Registry::HKEY_CLASSES_ROOT\htmlfile\shell\print'; Name = 'ProgrammaticAccessOnly'; Type = 'String'; Data = '' }
        @{ Path = 'Registry::HKEY_CLASSES_ROOT\inffile\shell\print'; Name = 'ProgrammaticAccessOnly'; Type = 'String'; Data = '' }
        @{ Path = 'Registry::HKEY_CLASSES_ROOT\inifile\shell\print'; Name = 'ProgrammaticAccessOnly'; Type = 'String'; Data = '' }
        @{ Path = 'Registry::HKEY_CLASSES_ROOT\JSEFile\shell\print'; Name = 'ProgrammaticAccessOnly'; Type = 'String'; Data = '' }
        @{ Path = 'Registry::HKEY_CLASSES_ROOT\otffile\shell\print'; Name = 'ProgrammaticAccessOnly'; Type = 'String'; Data = '' }
        @{ Path = 'Registry::HKEY_CLASSES_ROOT\pfmfile\shell\print'; Name = 'ProgrammaticAccessOnly'; Type = 'String'; Data = '' }
        @{ Path = 'Registry::HKEY_CLASSES_ROOT\regfile\shell\print'; Name = 'ProgrammaticAccessOnly'; Type = 'String'; Data = '' }
        @{ Path = 'Registry::HKEY_CLASSES_ROOT\rtffile\shell\print'; Name = 'ProgrammaticAccessOnly'; Type = 'String'; Data = '' }
        @{ Path = 'Registry::HKEY_CLASSES_ROOT\ttcfile\shell\print'; Name = 'ProgrammaticAccessOnly'; Type = 'String'; Data = '' }
        @{ Path = 'Registry::HKEY_CLASSES_ROOT\ttffile\shell\print'; Name = 'ProgrammaticAccessOnly'; Type = 'String'; Data = '' }
        @{ Path = 'Registry::HKEY_CLASSES_ROOT\txtfile\shell\print'; Name = 'ProgrammaticAccessOnly'; Type = 'String'; Data = '' }
        @{ Path = 'Registry::HKEY_CLASSES_ROOT\VBEFile\shell\print'; Name = 'ProgrammaticAccessOnly'; Type = 'String'; Data = '' }
        @{ Path = 'Registry::HKEY_CLASSES_ROOT\VBSFile\shell\print'; Name = 'ProgrammaticAccessOnly'; Type = 'String'; Data = '' }
        @{ Path = 'Registry::HKEY_CLASSES_ROOT\WSFFile\shell\print'; Name = 'ProgrammaticAccessOnly'; Type = 'String'; Data = '' }
    )
}
