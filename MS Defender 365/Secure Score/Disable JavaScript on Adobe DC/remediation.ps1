<#
Disable JavaScript on Adobe DC
Determines whether to globally disable and lock JavaScript execution in Adobe DC
#>
Function Set-RegistryKeys {
	param($ItemValue, $Path, $RegistryItemName, $RegistryItemPath, $ObjectName)
	Switch ($ItemValue) {
		0 {
			New-Item -Path 'HKLM:\SOFTWARE\Policies' -Name 'Adobe' -ErrorAction SilentlyContinue | Out-Null
			New-Item -Path 'HKLM:\SOFTWARE\Policies\Adobe' -Name 'Adobe Acrobat' -ErrorAction SilentlyContinue | Out-Null
			New-Item -Path 'HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat' -Name 'DC' -ErrorAction SilentlyContinue | Out-Null
			New-Item -Path $Path -Name $RegistryItemName -ErrorAction SilentlyContinue | Out-Null
			New-ItemProperty -Path $RegistryItemPath -Name $ObjectName -Value 1 -PropertyType DWORD -ErrorAction SilentlyContinue | Out-Null
		}
		1 {
			New-Item -Path 'HKLM:\SOFTWARE\Policies\Adobe' -Name 'Adobe Acrobat' -ErrorAction SilentlyContinue | Out-Null
			New-Item -Path 'HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat' -Name 'DC' -ErrorAction SilentlyContinue | Out-Null
			New-Item -Path $Path -Name $RegistryItemName -ErrorAction SilentlyContinue | Out-Null
			New-ItemProperty -Path $RegistryItemPath -Name $ObjectName -Value 1 -PropertyType DWORD -ErrorAction SilentlyContinue | Out-Null
		}
		2 {
			New-Item -Path 'HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat' -Name 'DC' -ErrorAction SilentlyContinue | Out-Null
			New-Item -Path $Path -Name $RegistryItemName -ErrorAction SilentlyContinue | Out-Null
			New-ItemProperty -Path $RegistryItemPath -Name $ObjectName -Value 1 -PropertyType DWORD -ErrorAction SilentlyContinue | Out-Null
		}
		3 {
			New-Item -Path $Path -Name $RegistryItemName -ErrorAction SilentlyContinue | Out-Null
			New-ItemProperty -Path $RegistryItemPath -Name $ObjectName -Value 1 -PropertyType DWORD -ErrorAction SilentlyContinue | Out-Null
		}
		{ $_ -like 'New' } { New-ItemProperty -Path $RegistryItemPath -Name $ObjectName -Value 1 -PropertyType DWORD -ErrorAction SilentlyContinue | Out-Null }
		{ $_ -like 'Set' } { Set-ItemProperty -Path $RegistryItemPath -Name $registryName -Value 1 -ErrorAction SilentlyContinue | Out-Null }
	}
}
#Values
$Path = 'HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC'
$RegistryItemPath = "$Path\FeatureLockDown"
#AdditionalValues
$chk0 = $Path -replace ('\w*Adobe\s\w*Acrobat\\DC', '')
$chk1 = $Path -replace ('\w*DC', '')
$chk2 = $Path
$ConfigurationArguments = @{
	Path             = 'HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC'
	RegistryItemName = 'FeatureLockDown'
	RegistryItemPath = "$Path\FeatureLockDown"
	ObjectName       = 'bDisableJavaScript'
}
#Evaluations
Switch (Test-Path $Path) {
	$True {
		$Evaluation = Get-ItemProperty -Path $RegistryItemPath -ErrorAction SilentlyContinue
		If ($Evaluation.bDisableJavaScript.count -gt 0) { Set-RegistryKeys -ItemValue 'Set' }
		Else {
			Switch (Test-Path $RegistryItemPath) {
				$True { Set-RegistryKeys -ItemValue 'New' }
				$False { Set-RegistryKeys -ItemValue 3 }
			}	
		}
	}
	$False {
		If ((Test-Path $chk0) -eq $False) { Set-RegistryKeys -ItemValue 0 }
		If ((Test-Path $chk1) -eq $False) { Set-RegistryKeys -ItemValue 1 }
		If ((Test-Path $chk2) -eq $False) { Set-RegistryKeys -ItemValue 2 }
	}
}
