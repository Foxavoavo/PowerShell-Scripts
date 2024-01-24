#Enable LSA protection
Function Set-RegItem {
    Param ($Path, $Name, $PropertyType, $Value, $ItemType) 
    Switch ($ItemType) {
        { $_ -eq 'Set' } { Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction SilentlyContinue | Out-null ; break }
        { $_ -eq 'New' } { New-ItemProperty -Path $Path -Name $Name -PropertyType $PropertyType -Value $Value -ErrorAction SilentlyContinue | Out-null ; break }
        { $_ -eq 'MissingKey' } { 
            $BasePath = $Path -replace ('\w*Lsa', '')
            Switch (Test-Path $BasePath) {
                $True {
                    New-Item -Path $BasePath -Name 'Lsa' -ErrorAction SilentlyContinue | Out-Null
                    New-ItemProperty -Path $Path -Name $Name -PropertyType $PropertyType -Value $Value -ErrorAction SilentlyContinue | Out-null ; break 
                }
                $False { Exit 127 }
            }      
        }
    }
}
#Values
$Path = 'HKLM:\system\CurrentControlSet\Control\Lsa'
$ConfigurationParams = @{
    Path         = $Path
    Name         = 'RunAsPPL'
    PropertyType = 'DWORD'
    Value        = 1
}
Switch (Test-Path $Path) {
    $True {
        $Evaluation = Get-ItemProperty 'HKLM:\system\CurrentControlSet\Control\Lsa' -ErrorAction SilentlyContinue -ErrorVariable Serror
        If ($Serror) { Exit 137 }
        Switch ($Evaluation) {
            { $Null -eq $_.RunAsPPL } { Set-RegItem @ConfigurationParams -ItemType 'New' }
            { $Null -ne $_.RunAsPPL } { 
                If ($_.RunAsPPL -ne 1) { Set-RegItem @ConfigurationParams -ItemType 'Set' }
                If ($_.RunAsPPL -eq 1) { Exit 0 }
            }
        }
    }
    $False { Set-RegItem @ConfigurationParams -ItemType 'MissingKey' }
}
