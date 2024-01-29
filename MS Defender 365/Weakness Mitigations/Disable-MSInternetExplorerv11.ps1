<# Microsoft Internet Explorer Unsupported Version Detection 
https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.InternetExplorer::DisableInternetExplorerApp
#>
$path = 'HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Main'
$hive = test-path $path
if ($hive -eq 'True') {
	$eval = Get-ItemProperty $path | select NotifyDisableIEOptions -ea silentlycontinue
	if ($eval.NotifyDisableIEOptions -eq 1) {
		'All good here'
		exit 0
	}
	elseif ($eval.NotifyDisableIEOptions -eq 0) {
		Set-ItemProperty $path -Name NotifyDisableIEOptions -Value '1' -ea SilentlyContinue
		'Set to 0'
		exit 0
	}
	elseif ($eval.NotifyDisableIEOptions -eq $null) {
		new-ItemProperty -Path $path -Name NotifyDisableIEOptions -PropertyType DWORD -Value '1' -ea SilentlyContinue
		exit 0
		'Created key'
	}
}
