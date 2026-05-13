$ErrorActionPreference = 'Stop'

try {
    $efiPartition = Get-Partition |
        Where-Object { $_.GptType -eq '{C12A7328-F81F-11D2-BA4B-00A0C93EC93B}' } |
        Select-Object -First 1

    if ($null -eq $efiPartition) {
        Write-Output 'No EFI partition found, skipping.'
        exit 0
    }

    if ([string]::IsNullOrEmpty($efiPartition.DriveLetter)) {
        Write-Output 'EFI partition has no drive letter, skipping.'
        exit 0
    }

    $accessPath = '{0}:\' -f $efiPartition.DriveLetter
    Write-Output "Removing drive letter '$accessPath' from EFI partition..."
    Remove-PartitionAccessPath -DiskNumber $efiPartition.DiskNumber -PartitionNumber $efiPartition.PartitionNumber -AccessPath $accessPath
    Write-Output 'Successfully removed EFI partition drive letter.'
}
catch {
    Write-Warning "Failed to remove EFI partition drive letter: $($_.Exception.Message)"
    exit 0
}
