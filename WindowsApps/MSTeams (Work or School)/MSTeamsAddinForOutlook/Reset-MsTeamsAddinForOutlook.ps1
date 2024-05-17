<#
add teams addin for MS outlook
https://www.reddit.com/r/MicrosoftTeams/comments/18gwkrb/workaround_for_teams_meeting_outlook_addin_not/
https://learn.microsoft.com/en-us/microsoftteams/troubleshoot/meetings/resolve-teams-meeting-add-in-issues
#>
#Functions:
Function Get-LocalTeamsAddin {
    param($Evaluate, $Stipulate, $FileName)
    If ($Evaluate -eq 1) {
        $FolderName = Get-ChildItem "${Env:ProgramFiles}\WindowsApps\" | Where-Object { $_.Name -like 'MSTeams*' } | Sort-Object -Descending | Select-Object -First 1 | Select-Object Fullname 
        $FolderPath = $FolderName.Fullname
        $FileName = "$FolderPath\MicrosoftTeamsMeetingAddinInstaller.msi"
        Write-Output "$Filename" 
    }
    If ($Stipulate -eq 1) {
        & msiexec.exe /a "$FileName" /qn TARGETDIR="${Env:Public}\unpack"
        Start-Sleep -Seconds 10 
        $MSI = "${Env:Public}\unpack\MicrosoftTeamsMeetingAddinInstaller.msi" 
        #Catch version from dll
        $Version = (Get-Item "${Env:Public}\unpack\AddinInstaller.dll").VersionInfo.ProductVersion
        New-Item -ItemType Directory -Path "${Env:ProgramFiles}\Microsoft\TeamsMeetingAddin\" -Name $Version -ErrorAction SilentlyContinue | Out-Null
        $Unbucket = "${Env:ProgramFiles}\Microsoft\TeamsMeetingAddin\$Version"
        Switch (Test-Path $Unbucket) {
            $True {
                Start-Process -FilePath "$MSI" -ArgumentList "TARGETDIR=`"$Unbucket`" ALLUSERS=1 /qn /norestart /l*v `"${Env:windir}\Logs\MsTeamsAddInInstall.log`"" -WindowStyle Hidden -Wait
            }
            $False { 
                Write-Output 'unable to create folder in programfiles for teams addin for outlook exit on code 9339'
                Exit 9339
            }
        }
        Start-Sleep -Seconds 5 
        Remove-Item -Path "${Env:Public}\unpack" -Force -Recurse -ErrorAction SilentlyContinue
    }
}
#Evalutions:
$Evaluations = Get-LocalTeamsAddin -Evaluate 1
#Actions:
Switch (Test-Path $Evaluations) {
    $True { Get-LocalTeamsAddin -Stipulate 1 -FileName "$Evaluations" }
    $False { 
        & Choco upgrade 'microsoft-teams-new-bootstrapper' -r --no-progress
        Start-Sleep -Seconds 5	
        & Choco uninstall 'microsoft-teams-new-bootstrapper' -r -no-progress -n --skip-autouninstaller
        $Evaluations = Get-LocalTeamsAddin -Evaluate 1
        Switch (Test-Path $Evaluations) {
            $True { Get-LocalTeamsAddin -Stipulate 1 -FileName $Evaluations }
            $False {
                Write-Output 'No local Teams Addin found exit on code 9999'
                Exit 9999 
            }		
        }
    }
}
