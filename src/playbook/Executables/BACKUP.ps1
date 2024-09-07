param (
	[Parameter( Mandatory = $True )]
	[string]$FilePath
)

if (Test-Path $FilePath) { exit }

$content = [System.Collections.Generic.List[string]]::new()
$content.Add("Windows Registry Editor Version 5.00")
Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services" | ForEach-Object {
	try {
		$startValue = Get-ItemPropertyValue -Path $_.PSPath -Name "Start" -EA Stop
		$content.Add("`n[$($_.Name)]")
		$content.Add('"Start"=dword:0000000' + $startValue)
	} catch {}
}

Set-Content -Path $FilePath -Value $content -Force -Encoding UTF8