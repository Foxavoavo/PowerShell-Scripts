#Enable LSA protection
Switch (Test-Path 'HKLM:\system\CurrentControlSet\Control\Lsa') {
    $True {
        $Evaluation = Get-ItemProperty 'HKLM:\system\CurrentControlSet\Control\Lsa' -ErrorAction SilentlyContinue -ErrorVariable Serror
        If ($Serror) { 0 }
        Switch ($Evaluation) {
            { $Null -eq $_.RunAsPPL } { 0 }
            { $Null -ne $_.RunAsPPL } { 
                If ($_.RunAsPPL -ne 1) { 0 }
                If ($_.RunAsPPL -eq 1) { 1 }
            }
        }
    }
    $False { 0 }
}
