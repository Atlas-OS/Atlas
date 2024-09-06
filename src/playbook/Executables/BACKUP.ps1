param (
	[Parameter( Mandatory = $True )]
	[string]$FilePath
)

if (Test-Path $FilePath) { exit }

$content = [System.Collections.Generic.List[string]]::new()
$content.Add("Windows Registry Editor Version 5.00")
Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services" | ForEach-Object {
	if ((Get-ItemProperty $_.PSPath).PSObject.Properties.Name -contains "Start") {
		$startValue = (Get-ItemProperty -Path $_.PSPath -Name "Start").Start
		for ($c = 0; $c -le 4; $c++) {
			if ($startValue -eq "0x$c") {
				$content.Add("`n[$($_.Name)]")
				$content.Add('"Start"=dword:0000000' + $c)
			}
		}
	}
}

Set-Content -Path $FilePath -Value $content -Force -Encoding UTF8