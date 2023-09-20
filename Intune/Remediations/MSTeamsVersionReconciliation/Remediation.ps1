<#
Compare versions of Ms Teams in program files & on the user profiles.

To remediate: 

a) deletes the 'current' folder from MS teams on the User profile if the user is not on session.
    "C:\Users\Username\AppData\Local\Microsoft\Teams\current\Teams.exe"
b) updates the program files teams installer folder:
    C:\Program Files (x86)\Teams Installer -- looks for x64 too

*For my customer, I use a custom chocolatey package script to provide the .msi teams file, which is in the folder too.
once the user logins, teams will update the 'current' folder in his profile with the available version.
#>
Function Get-TeamsObjects {
    param(
        $Usage,
        $Version,
        $RepoAvailablePackage,
        $Username,
        $TeamsUserPath
    )
    #tailor
    $Package = $RepoAvailablePackage | Select-String -Pattern '\w*Microsoft-Teams-Update.PerMachine*'
    [regex]$regex = '(?<=\s).*'
    $RepoAvailableVersion = $regex.Matches($Package).Value
    If ($Usage -eq 'App') {
        Switch ($Version) {
            { $Null -eq $_ } {}
            { [Version]$_ -lt [Version]$RepoAvailableVersion } {
                #Write-Output 'Local Teams needs update'
                & Choco upgrade 'Microsoft-Teams-Update.PerMachine' -r --no-progress -y
            }
            { [Version]$_ -ge [Version]$RepoAvailableVersion } {}
        }
    }
    If ($Usage -eq 'User') {
        Switch ($Version) {
            { $Null -eq $_ } {}
            { [Version]$_ -lt [Version]$RepoAvailableVersion } {
                #Write-Output "===>>> Local Teams needs update for $User"
                $UserSessionEvaluation = & quser
                [Regex]$Regex = '(?<=\>)\w*\d*\S'
                 $UserInSession = $regex.Matches($UserSessionEvaluation).Value
                If ($Username -like $UserInSession) { $InSession = 1 }
                If ($Username -notlike $UserInSession) { $InSession = 0 }
                Switch ($InSession) {
                    0 {
                        #Write-Output '===>>> User not in Session'
                        If ([Version]$Version -lt [Version]$RepoAvailableVersion) {
                            $FolderToRemove = $TeamsUserPath.trim('$\\Teams.exe')
                            Remove-Item $FolderToRemove -Force -Recurse -ErrorAction SilentlyContinue
                            Write-Output "Remove current folder for $Username"
                        } 
                    }
                    1 {
                        #Write-Output '===>>> User in Session, nothing to do'
                    }
                }
            }
            { [Version]$_ -ge [Version]$RepoAvailableVersion } {}
        }
    }
}
       
#Evaluation
$RepoAvailablePackage = & Choco search Microsoft-Teams-Update
#local paths
$Teams32Path = "${Env:ProgramFiles(x86)}\Teams Installer"
$Teams64Path = "${Env:ProgramFiles}\Teams Installer"
$Paths = @($Teams32Path, $Teams64Path)
Foreach ($Path in $Paths) {
    Switch (Test-Path $Path) {
        $True { 
            $LocalTeams = "$Path\Teams.exe"
        }
        $False {}
    }
}
#Local drive application version validation
Switch(Test-Path $LocalTeams){
    $True{
        $LocalTeamsVersion = (Get-Item $LocalTeams).VersionInfo.ProductVersion
        $LocalResult = Get-TeamsObjects -Version $LocalTeamsVersion  -RepoAvailablePackage $RepoAvailablePackage -Usage 'App'
         & Choco uninstall 'Microsoft-Teams-Update.PerMachine' -n -r --no-progress -y --skip-autouninstaller
    }
    $False {}
}
#User profile version validation
$Users = Get-ChildItem "${env:SystemDrive}\users" -Exclude 'defaultuser0', 'public' | Select-Object FullName, Name
ForEach ($User in $Users) {
    $UserPath = $User.FullName
    $Username = $User.Name
    $TeamsUserPath = "$UserPath\AppData\Local\Microsoft\Teams\current\Teams.exe"
    #Evaluation
    Switch (Test-Path $TeamsUserPath) {
        $True {
            $LocalUserTeamsVersion = (Get-Item $TeamsUserPath).VersionInfo.ProductVersion
            $UserResult = Get-TeamsObjects -Version $LocalUserTeamsVersion  -RepoAvailablePackage $RepoAvailablePackage -Username $Username -TeamsUserPath $TeamsUserPath -Usage 'User'
            #Write-Output "$Username have Teams"
        }
        $False {
            #Write-Output "$Username doesn't have Teams"
        }
    }
}
Exit $LASTEXITCODE
