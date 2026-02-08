param (
    [Parameter(Mandatory = $true)]
    [string[]]$Packages,
    [Parameter(Mandatory = $false)]
    [switch]$Unregister = $false
)

$basePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore"
$allPackages = Get-AppxPackage -AllUsers | Select-Object PackageFullName, PackageFamilyName, PackageUserInformation, NonRemovable

foreach ($package in $Packages) {
    $filteredPackages = $allPackages | Where-Object { $_.PackageFullName -like "*$package*" }

    foreach ($filteredPackage in $filteredPackages) {
        $fullPackageName = $filteredPackage.PackageFullName
        $packageFamilyName = $filteredPackage.PackageFamilyName
        if ($filteredPackage.NonRemovable -eq 1) {
            Set-NonRemovableAppsPolicy -Online -PackageFamilyName $packageFamilyName -NonRemovable 0
        }
        $deprovisionedPath = "$basePath\Deprovisioned\$packageFamilyName"
        if (-not (Test-Path -Path $deprovisionedPath)) {
            New-Item -Path $deprovisionedPath -Force
        }
        $inboxPath = "$basePath\InboxApplications\$fullPackageName"
        if (Test-Path $inboxPath) {
            Remove-Item -Path $inboxPath -Force
        }
        foreach ($userInfo in $filteredPackage.PackageUserInformation) {
            $userSid = $userInfo.UserSecurityID.SID
            $endOfLifePath = "$basePath\EndOfLife\$userSid\$fullPackageName"
            New-Item -Path $endOfLifePath -Force

            if ($unregister) {
                Remove-AppxPackage -Package $fullPackageName -User $userSid -PreserveRoamableApplicationData
            }
            else {
                Remove-AppxPackage -Package $fullPackageName -User $userSid
            }
        }
        if ($unregister) {
            Remove-AppxPackage -Package $fullPackageName -AllUsers -PreserveRoamableApplicationData
        }
        else {
            Remove-AppxPackage -Package $fullPackageName -AllUsers
        }
    }
}