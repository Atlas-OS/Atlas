@{
    Name        = 'Show All Tasks in Control Panel'
    Description = 'Shows ''All Tasks'' in Control Panel (God Mode), so that people can easily access all settings for QoL'
    Registry    = @(
        @{ Path = 'HKCR\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}'; Name = ''; Type = 'String'; Data = 'All Tasks' }
        @{ Path = 'HKCR\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}'; Name = 'InfoTip'; Type = 'String'; Data = 'View list of all Control Panel tasks' }
        @{ Path = 'HKCR\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}'; Name = 'System.ControlPanel.Category'; Type = 'String'; Data = '5' }
        @{ Path = 'HKCR\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}\DefaultIcon'; Name = ''; Type = 'String'; Data = '%windir%\System32\imageres.dll,-27' }
        @{ Path = 'HKCR\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}\Shell\Open\Command'; Name = ''; Type = 'String'; Data = 'explorer.exe shell:::{ED7BA470-8E54-465E-825C-99712043E01C}' }
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel\NameSpace\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}'; Name = ''; Type = 'String'; Data = 'All Tasks' }
    )
}
