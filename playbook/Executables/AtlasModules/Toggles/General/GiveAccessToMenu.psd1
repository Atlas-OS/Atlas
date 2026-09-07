@{
    Name        = 'GiveAccessToMenu'
    Description = 'Give access to (Sharing) context menu entries.'
    Elevation   = 'Admin'
    States      = @(
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = '3. General Configuration\File Sharing\Give Access To Menu\Disable Give Access To Menu (default).cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKCR\*\shellex\ContextMenuHandlers\Sharing'; Operation = 'DeleteKey' }
                @{ Path = 'HKCR\Directory\Background\shellex\ContextMenuHandlers\Sharing'; Operation = 'DeleteKey' }
                @{ Path = 'HKCR\Directory\shellex\ContextMenuHandlers\Sharing'; Operation = 'DeleteKey' }
                @{ Path = 'HKCR\Drive\shellex\ContextMenuHandlers\Sharing'; Operation = 'DeleteKey' }
                @{ Path = 'HKCR\LibraryFolder\background\shellex\ContextMenuHandlers\Sharing'; Operation = 'DeleteKey' }
                @{ Path = 'HKCR\UserLibraryFolder\shellex\ContextMenuHandlers\Sharing'; Operation = 'DeleteKey' }
            )
        }
        @{
            Name       = 'Enable'
            StateValue = 1
            Launcher   = '3. General Configuration\File Sharing\Give Access To Menu\Enable Give Access To Menu.cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKCR\*\shellex\ContextMenuHandlers\Sharing'; Name = ''; Type = 'String'; Data = '{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}' }
                @{ Path = 'HKCR\Directory\Background\shellex\ContextMenuHandlers\Sharing'; Name = ''; Type = 'String'; Data = '{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}' }
                @{ Path = 'HKCR\Directory\shellex\ContextMenuHandlers\Sharing'; Name = ''; Type = 'String'; Data = '{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}' }
                @{ Path = 'HKCR\Drive\shellex\ContextMenuHandlers\Sharing'; Name = ''; Type = 'String'; Data = '{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}' }
                @{ Path = 'HKCR\LibraryFolder\background\shellex\ContextMenuHandlers\Sharing'; Name = ''; Type = 'String'; Data = '{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}' }
                @{ Path = 'HKCR\UserLibraryFolder\shellex\ContextMenuHandlers\Sharing'; Name = ''; Type = 'String'; Data = '{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}' }
            )
        }
    )
}
