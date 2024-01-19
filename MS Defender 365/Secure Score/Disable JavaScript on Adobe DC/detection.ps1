<#
Disable JavaScript on Adobe DC
Determines whether to globally disable and lock JavaScript execution in Adobe DC
#>
#Values
$Path = 'HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\\FeatureLockDown'
Switch (Test-Path $Path) {
	$True {
		$Evaluations = Get-ItemProperty $Path
		If ($Evaluations.bDisableJavaScript -eq 1) { 1 }
		Else { 0 }
	}
	$False { 0 }
}
