@{
    Name        = 'Debloat Send-To Context Menu'
    Description = 'Removes commonly un-used items from the Send-To context menu in Explorer'
    Run         = @(
        @{ Exe = '{windir}\AtlasDesktop\4. Interface Tweaks\Context Menus\Send To\Debloat Send To Context Menu.cmd'; Args = '-Disable @(''Documents'', ''Mail Recipient'', ''Fax recipient'', ''Bluetooth'')'; Wait = $true }
    )
}
