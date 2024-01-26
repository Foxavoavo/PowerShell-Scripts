#MS Secure Score - Disable Solicited Remote Assistance
Switch (Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services') {
    $True {
        $Evaluation = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -ErrorAction SilentlyContinue -ErrorVariable Serror
        If ($Serror) { 1 }
        Switch ($Evaluation) {
            { $Null -eq $_.fAllowToGetHelp } { 1 }
            { $Null -ne $_.fAllowToGetHelp } { 
                If ($_.fAllowToGetHelp -ne 0) { 1 }
                If ($_.fAllowToGetHelp -eq 0) { 0 }
            }
        }
    }
    $False { 1 }
}
