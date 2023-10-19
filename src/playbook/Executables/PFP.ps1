Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile((Get-Item '.\user.png'))

$perUserResolutions = @(1080, 448, 424, 240, 208, 192, 96, 64, 48, 40, 32)
$resolutions = @{
    "user.png" = 448
    "user.bmp" = 448
    "guest.png" = 448
    "guest.bmp" = 448
    "user-192.png" = 192
    "user-48.png" = 48
    "user-40.png" = 40
    "user-32.png" = 32
}

# Set default profile pictures
foreach ($image in $resolutions.Keys) {
    $resolution = $resolutions[$image]

    $a = New-Object System.Drawing.Bitmap($resolution, $resolution)
    $graph = [System.Drawing.Graphics]::FromImage($a)
    $graph.DrawImage($img, 0, 0, $resolution, $resolution)
    $a.Save("$env:ProgramData\Microsoft\User Account Pictures\$image")
}

# Set Atlas profile picture for each user
function SetUserProfileImage($sid) {
    $usrPfpDir = "$env:public\AccountPictures\$sid"

    if (!(Test-Path $usrPfpDir)) {
        # New-Item -Path $usrPfpDir -ItemType Directory -Force | Out-Null
        # This doesn't overwrite users that have manually set profile pictures
        return
    }

    foreach ($resolution in $perUserResolutions) {
        $a = New-Object System.Drawing.Bitmap($resolution, $resolution)
        $graph = [System.Drawing.Graphics]::FromImage($a)
        $graph.DrawImage($img, 0, 0, $resolution, $resolution)
        $a.Save("$usrPfpDir\$resolution`x$resolution.png")
    
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AccountPicture\Users\$sid" -Name "Image$resolution" `
        -PropertyType String -Value "$usrPfpDir\$resolution`x$resolution.png" -Force | Out-Null
    }
}

# Recurse through user keys and set profile pictures
foreach ($userKey in $((Get-ChildItem -Path "Registry::HKEY_USERS").Name | Where-Object { $_ -like 'HKEY_USERS\S-*' })) {
    Get-ItemProperty -Path "Registry::$userKey\Volatile Environment" -ErrorAction SilentlyContinue | Out-Null
    if ($?) {
        SetUserProfileImage "$($userKey -replace 'HKEY_USERS\\','')"
    }
}