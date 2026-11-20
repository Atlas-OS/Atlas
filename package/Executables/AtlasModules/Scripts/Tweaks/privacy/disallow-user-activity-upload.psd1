@{
    Name        = 'Disallow Upload and Publish of User Activities'
    Description = 'Stops Windows publishing your activity history and uploading it to Microsoft.'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'UploadUserActivities'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'PublishUserActivities'; Type = 'DWord'; Data = 0 }
    )
}
