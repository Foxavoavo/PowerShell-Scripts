#MS Secure Score - Disable Solicited Remote Assistance
Function Set-RegItem {
    Param ($Path, $Name, $PropertyType, $Value, $ItemType) 
    Switch ($ItemType) {
        { $_ -eq 'Set' } { Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction SilentlyContinue | Out-null ; break }
        { $_ -eq 'New' } { New-ItemProperty -Path $Path -Name $Name -PropertyType $PropertyType -Value $Value -ErrorAction SilentlyContinue | Out-null ; break }
        { $_ -eq 'MissingKey' } { 
            $BasePath = $Path -replace ('\w*Terminal\s\w*Services', '')
            Switch (Test-Path $BasePath) {
                $True {
                    New-Item -Path $BasePath -Name 'Terminal Services' -ErrorAction SilentlyContinue | Out-Null # The RegKey you need to create.
                    New-ItemProperty -Path $Path -Name $Name -PropertyType $PropertyType -Value $Value -ErrorAction SilentlyContinue | Out-null ; break 
                }
                $False { Exit 127 }
            }      
        }
    }
}
#Values
$Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
$ConfigurationParams = @{
    Path         = $Path
    Name         = 'fAllowToGetHelp'
    PropertyType = 'DWORD'
    Value        = 0
}
Switch (Test-Path $Path) {
    $True {
        $Evaluation = Get-ItemProperty $Path -ErrorAction SilentlyContinue -ErrorVariable Serror
        If ($Serror) { Exit 137 }
        Switch ($Evaluation) {
            { $Null -eq $_.fAllowToGetHelp } { Set-RegItem @ConfigurationParams -ItemType 'New' }
            { $Null -ne $_.fAllowToGetHelp } { 
                If ($_.fAllowToGetHelp -ne 0) { Set-RegItem @ConfigurationParams -ItemType 'Set' }
                If ($_.fAllowToGetHelp -eq 0) { Exit 0 }
            }
        }
    }
    $False { Set-RegItem @ConfigurationParams -ItemType 'MissingKey' }
}
