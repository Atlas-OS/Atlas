# Remove ads from the 'Accounts' page in Immersive Control Panel
# Made by Xyueta

$Cbs = "$env:windir\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy"
$content = Get-Content -Path "$Cbs\Public\wsxpacks.json"
$pattern = '^\s"Windows\.Settings\.Account".'
$modifiedContent = $content -replace $pattern, ''
$modifiedContent = ($modifiedContent | Where-Object { $_.Trim() -ne "" }) -join "`n"
Set-Content -Path "$Cbs\Public\wsxpacks.json" -Value $modifiedContent

# Prevent provisioned applications from being reinstalled
# https://learn.microsoft.com/en-us/windows/application-management/remove-provisioned-apps-during-update

$filePath = "$env:windir\AtlasModules\AtlasPackagesOld.txt"
$rootPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned"
$applications = @(
    "3DViewer",
    "549981C3F5F10",
    "Advertising.Xaml",
    "Alarms",
    "Bing",
    "Camera",
    "Client.WebExperience",
    "clipchamp",
    "ContentDeliveryManager",
    "communicationsapps",
    "DevHome",
    "Disney",
    "FeedbackHub",
    "GetHelp",
    "Getstarted",
    "Maps",
    "MicrosoftCorporationII",
    "MixedReality.Portal",
    "MSPaint",
    "Office",
    "OOBENetworkCaptivePortal",
    "OOBENetworkConnectionFlow",
    "Outlook",
    "Paint",
    "ParentalControls",
    "People",
    "PeopleExperienceHost",
    "Photos",
    "PowerAutomateDesktop",
    "ScreenSketch",
    "SecureAssessmentBrowser",
    "SkypeApp",
    "SolitaireCollection",
    "SoundRecorder",
    "Spotify",
    "StickyNotes",
    "Teams",
    "Todos",
    "Wallet",
    "WebExperienceHost",
    "WindowsBackup",
    "YourPhone",
    "ZuneMusic",
    "ZuneVideo"
)

$packageFamilyNames = Get-Content -Path "$filePath"

foreach ($packageFamilyName in $packageFamilyNames) {
    $containsApplication = $applications | Where-Object {$packageFamilyName -like "*$_*"}

    if ($containsApplication) {
        $fullPath = Join-Path -Path "$rootPath" -ChildPath "$packageFamilyName"
        New-Item -Path "$fullPath" -Force
    }
}