#Details
$Application = 'tradeweb'
$ChocolateyAppPackage = 'tradeweb-europe-live-viewer'
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
        If ([Version]$_ -lt [Version]$ExpectedVersion) { 
            & Choco pin remove -n="$ChocolateyAppPackage"
            & Choco upgrade $ChocolateyAppPackage --version '8.09.6' -r --no-progress -n --skip-powershell
            & Choco uninstall $ChocolateyAppPackage -r --no-progress
            & Choco upgrade $ChocolateyAppPackage -r --no-progress
            & Choco pin add -n="$ChocolateyAppPackage"
        }
    }
    { $_.count -eq 0 } { 
        & Choco upgrade $ChocolateyAppPackage -r --no-progress
        & Choco pin add -n="$ChocolateyAppPackage"
    }
}
