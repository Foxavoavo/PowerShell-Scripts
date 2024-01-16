#HPIA Folders
$HPIAFolder = "${Env:SystemDrive}\hpia"
$HPIA_exe = "$HPIAFolder\HPImageAssistant.exe"
$HPIACategory = "All"
$HPIAReco = "$HPIAFolder\Recommendations"
Switch (Test-Path $HPIA_exe) {
    $True {
        Remove-Item $HPIAReco -Recurse -Force -ErrorAction SilentlyContinue
        Start-Process $HPIA_exe -ArgumentList "/Operation:Analyze /Category:$HPIACategory /Action:List /silent /ReportFolder:""$HPIAReco""" -Wait
        $HPIAAnalyze = Get-Content "$HPIAReco\*.json" | ConvertFrom-Json
            If ($HPIAAnalyze.HPIA.Recommendations.count -lt 1) { 
                Exit 0
            }
            If ($HPIAAnalyze.HPIA.Recommendations.count -ge 1) { 
                Exit 1
            }
        }
    $False {
        Write-Output '===>>> HPIA Not found'
        Exit 1
    }
}
