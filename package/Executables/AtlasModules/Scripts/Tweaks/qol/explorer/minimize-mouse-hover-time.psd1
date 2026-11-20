@{
    Name        = 'Minimize Mouse Hover Time for Item Info'
    Description = 'Shortens the hover delay before item information appears, mostly in File Explorer, from 400 ms to 20 ms.'
    Registry    = @(
        # Where Windows keeps the hover time (SPI_SETMOUSEHOVERTIME); it doesn't read it from Desktop.
        @{ Path = 'HKCU\Control Panel\Mouse'; Name = 'MouseHoverTime'; Type = 'String'; Data = '20' }
    )
}
