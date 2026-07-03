@{
    Name        = 'Disallow Upload and Publish of User Activities'
    Description = 'Disables the upload and publish of user activities for privacy'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'UploadUserActivities'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'PublishUserActivities'; Type = 'DWord'; Data = 0 }
    )
}
