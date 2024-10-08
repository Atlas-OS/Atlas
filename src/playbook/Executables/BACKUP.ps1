param (
	[Parameter( Mandatory = $True )]
	[string]$FilePath
)

if (Test-Path $FilePath) { exit }

$content = [System.Collections.Generic.List[string]]::new()
$content.Add("Windows Registry Editor Version 5.00")
Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services" | ForEach-Object {
	try {
		$values = Get-ItemProperty -Path $_.PSPath -Name 'Start', 'Description' -EA Stop
		if ($values.Description -notmatch 'Windows Defender') {
			$content.Add("`n[$($_.Name)]")
			$content.Add('"Start"=dword:0000000' + $values.Start)	
		} else {
			Write-Output "Excluding $($_.Name)..."
		}
	} catch {}
}

# Set-Content can only do UTF8 with BOM, which doesn't work with reg.exe
[System.IO.File]::WriteAllLines($FilePath, $content, (New-Object System.Text.UTF8Encoding $false))