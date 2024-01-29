<#
Enable LSA protection
Set the following registry value:
HKLM\SYSTEM\CurrentControlSet\Control\Lsa\RunAsPPL
To the following REG_DWORD value:
1
#>
#evaluation
$eval = get-itemproperty hklm:\system\CurrentControlSet\Control\Lsa
if($null -eq $eval.RunAsPPL){exit 1}
if($null -ne $eval.RunAsPPL){exit 0}

#remediation
function New-RegItem{
	param($Path, $Name, $PropertyType,$Value)
	New-ItemProperty -Path $Path -Name $Name -PropertyType $PropertyType -Value $Value -ea SilentlyContinue | Out-null
}
$path = 'HKLM:\System\CurrentControlSet\Control\Lsa'
$eval = get-itemproperty $path
if($null -eq $eval.RunAsPPL){New-RegItem -Path $path -Name RunAsPPL -PropertyType Dword -Value 1}
else{exit 0}
