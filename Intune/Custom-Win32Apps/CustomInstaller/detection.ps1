#Details
$Application = 'tradeweb'
$ExpectedVersion = '8.10.20'
#Evaluation
$Evaluations = & Choco list -i | Select-String -Pattern "$Application*"
Switch ($LASTEXITCODE) {
    { $_ -eq 0 } {
        #version check
        [regex]$Regex = '\d.*'
        Try { $Version = $Regex.Matches($Evaluations).Value }
        Catch {
            $Evaluations = Get-WmiObject -Class Win32_Product | where-object { $_.Name -like "$Application*" } 
            $Version = $Evaluations.Version
        }
    }
    { $_ -ne 0 } { 
        $Evaluations = Get-WmiObject -Class Win32_Product | where-object { $_.Name -like "$Application*" } 
        $Version = $Evaluations.Version
    }
}
Switch ($Version) {
    { $_.count -gt 0 } {
        If ([Version]$_ -ge [Version]$ExpectedVersion) { 
            Write-Output '===>>> Latest TradeWeb install'
            Exit 0 
        }
        If ([Version]$_ -lt [Version]$ExpectedVersion) { 
            Write-Output '===>>> Latest TradeWeb not install'
            Exit 1 
        }
    }
    { $_.count -eq 0 } { 
        Write-Output '===>>> Latest TradeWeb not install'
        Exit 1 
    }
}
