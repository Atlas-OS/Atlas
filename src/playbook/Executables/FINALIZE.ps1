# Disable brightness slider service if it's not supported on the current display
$startup = 'Automatic'
try {
    Get-CimInstance -Class WmiMonitorBrightnessMethods -Namespace root/wmi -ErrorAction Stop | Out-Null
} catch {
    if ((Get-ComputerInfo).CsPCSystemType -eq 'Desktop') {
        $startup = 'Disabled'
    }
}
Set-Service -Name DisplayEnhancementService -StartupType $startup