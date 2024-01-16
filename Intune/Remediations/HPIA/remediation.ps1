<# scan for HP drivers and firmware for HP devices. #>
#Functions
Function Update-HPObjects {
    param($HPIA_exe,$HPIAReco,$HPSoftPaqFolder,$wait,$type)
    If($type -like 'BIOS'){
         & Choco install 'hpia.file' -r --no-progress
        If($LastExitCode -eq 0){
            $HPBIOSFile = 'C:\Res\Res.bin'
            Start-Process $HPIA_exe -ArgumentList "/BIOSPwdFile:$HPBIOSFile /Operation:Analyze /Category:All /Selection:All /Action:Install /Silent /ReportFolder:$HPIAReco /SoftPaqDownloadFolder:$HPSoftPaqFolder /Debug /AutoCleanup /Wait:$wait" -Wait
            Write-Output 0
        }
        Else{
            Write-Output '===>>> Unable to gather hpia.file'
            Write-Output 1
        }
    }
    If($type -like 'Others'){
        Try { 
              Start-Process $HPIA_exe -ArgumentList "/Operation:Analyze /Category:All /Selection:All /Action:Install /Silent /ReportFolder:$HPIAReco /SoftPaqDownloadFolder:$HPSoftPaqFolder /Debug /AutoCleanup /Wait:$wait" -Wait
              Write-Output 0
        }
        Catch { 
              Write-Output 1
        }
    }
}
#Evaluations
$HPIAFolder = "${Env:SystemDrive}\hpia"
$HPIA_exe = "$HPIAFolder\HPImageAssistant.exe"
$HPSoftPaqFolder = "${env:systemdrive}\swsetup"
$HPIAReco = "$HPIAFolder\Recommendations"
$HPIACategory = "All"
If ((Test-Path $HPSoftPaqFolder) -eq $False) { New-Item -ItemType Directory -Name 'swsetup' -Path "${Env:SystemDrive}\" | Out-Null }
If ((Test-Path $HPIAFolder) -eq $False) { & Choco install 'HPIA.PerMachine' -r --no-progress -y }
#Stage
Switch(Test-Path $HPIAReco){
    $True{
        $HPIAAnalyze = Get-Content "$HPIAReco\*.json" | ConvertFrom-Json
            If(($HPIAAnalyze.HPIA.Recommendations.Name | Select-String -Pattern 'BIOS*').count -gt 0){$Type = 'BIOS'}
            If(($HPIAAnalyze.HPIA.Recommendations.Name | Select-String -Pattern 'BIOS*').count -eq 0){$Type = 'Others'}
    }
    $False{
        Start-Process $HPIA_exe -ArgumentList "/Operation:Analyze /Category:$HPIACategory /Action:List /silent /ReportFolder:""$HPIAReco""" -Wait
        $HPIAAnalyze = Get-Content "$HPIAReco\*.json" | ConvertFrom-Json
        If(($HPIAAnalyze.HPIA.Recommendations.Name | Select-String -Pattern 'BIOS*').count -gt 0){$Type = 'BIOS'}
        If(($HPIAAnalyze.HPIA.Recommendations.Name | Select-String -Pattern 'BIOS*').count -eq 0){$Type = 'Others'}
    }
}
#Actions
If($Type -like 'BIOS'){
    $UpdateHPObjects = Update-HPObjects -HPIA_exe $HPIA_exe -HPIAReco $HPIAReco -HPSoftPaqFolder $HPSoftPaqFolder -wait '180' -type $Type
}
If($Type -like 'Others'){
    $UpdateHPObjects = Update-HPObjects -HPIA_exe $HPIA_exe -HPIAReco $HPIAReco -HPSoftPaqFolder $HPSoftPaqFolder -wait '180' -type $Type
}
#Post Evaluations
Switch ($UpdateHPObjects) {
    0 { 
        & Choco uninstall 'hpia.file' -r --no-progress
        Exit 0 
    }
    1 {
        Write-Output '===>>> unable to run HPIA process'
        Exit 1
    }
}
