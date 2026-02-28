param (
	[Parameter( Mandatory = $True )]
	[string]$FilePath
)

Set-StrictMode -Version 3.0

if (Test-Path $FilePath) { exit }

$content = [System.Collections.Generic.List[string]]::new()
$content.Add("Windows Registry Editor Version 5.00")
foreach ($serviceKey in (Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services")) {
	$serviceProps = Get-ItemProperty -Path $serviceKey.PSPath -ErrorAction SilentlyContinue
	if ($null -eq $serviceProps) {
		continue
	}

	$startProperty = $serviceProps.PSObject.Properties['Start']
	if ($null -eq $startProperty) {
		continue
	}
	$startValue = $startProperty.Value

	$description = $null
	$descriptionProperty = $serviceProps.PSObject.Properties['Description']
	if ($null -ne $descriptionProperty) {
		$description = [string]$descriptionProperty.Value
	}

	if (($null -ne $description) -and ($description -match 'Windows Defender')) {
		Write-Output "Excluding $($serviceKey.Name)..."
		continue
	}

	$content.Add("`n[$($serviceKey.Name)]")
	$content.Add('"Start"=dword:0000000' + $startValue)
}

# Set-Content can only do UTF8 with BOM, which doesn't work with reg.exe
[System.IO.File]::WriteAllLines($FilePath, $content, (New-Object System.Text.UTF8Encoding $false))
