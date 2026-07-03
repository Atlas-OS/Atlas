@{
    Name        = 'Remove Previous Versions from Explorer'
    Description = 'Removes previous versions from context menu and file''s properties, for QoL'
    Registry    = @(
        @{ Path = 'HKCR\AllFilesystemObjects\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}'; Operation = 'DeleteKey' }
        @{ Path = 'HKCR\CLSID\{450D8FBA-AD25-11D0-98A8-0800361B1103}\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}'; Operation = 'DeleteKey' }
        @{ Path = 'HKCR\Directory\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}'; Operation = 'DeleteKey' }
        @{ Path = 'HKCR\Drive\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}'; Operation = 'DeleteKey' }
        @{ Path = 'HKCR\AllFilesystemObjects\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}'; Operation = 'DeleteKey' }
        @{ Path = 'HKCR\CLSID\{450D8FBA-AD25-11D0-98A8-0800361B1103}\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}'; Operation = 'DeleteKey' }
        @{ Path = 'HKCR\Directory\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}'; Operation = 'DeleteKey' }
        @{ Path = 'HKCR\Drive\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}'; Operation = 'DeleteKey' }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'; Name = 'NoPreviousVersionsPage'; Operation = 'Delete' }
        @{ Path = 'HKCU\SOFTWARE\Policies\Microsoft\PreviousVersions'; Name = 'DisableLocalPage'; Operation = 'Delete' }
    )
}
