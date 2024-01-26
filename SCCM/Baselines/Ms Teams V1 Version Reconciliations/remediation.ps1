<#
Update Ms Teams V1
Update Device Ms Teams V1 with a custom Chocolatey Package

Perform array and remove User Ms teams V1 across user profiles 

*skip user on device session too (Because otherwise the app will desappear from the user on the device session)

Once the user on the device session logoff, the latest teams will be updated in his user profile too.

It also run a housekeep for left over Ms Teams V1 files around user profiles.
#>
Function Get-TeamsObjects {
    param($Usage, $Version, $RepoAvailablePackage, $Username, $TeamsUserPath)
    #tailor
    $Package = $RepoAvailablePackage | Select-String -Pattern '\w*Microsoft-Teams-Update.PerMachine*'
    [regex]$regex = '(?<=\s).*'
    $RepoAvailableVersion = $regex.Matches($Package).Value
    If ($Usage -eq 'App') {
        Switch ($Version) {
            { $Null -eq $_ } {}
            { [Version]$_ -lt [Version]$RepoAvailableVersion } {
                Write-Output 'Device Teams needs update'
                & Choco upgrade 'Microsoft-Teams-Update.PerMachine' -r --no-progress -y
                & Choco uninstall 'Microsoft-Teams-Update.PerMachine' -n -r --no-progress -y --skip-autouninstaller
                Write-Output 'Device Teams updated'
            }
            { [Version]$_ -ge [Version]$RepoAvailableVersion } {}
        }
    }
    If ($Usage -eq 'User') {
        Switch ($Version) {
            { $Null -eq $_ } {}
            { [Version]$_ -lt [Version]$RepoAvailableVersion } {
                Write-Output "User Teams needs update for $Username"
                $uninstallerPath = $TeamsUserPath -replace ('\\\w*current\\\w*Teams.exe', '')
                $uninstaller = "$uninstallerPath\Update.exe"
                Switch (Test-Path $uninstaller) {
                    $True {
                        & $uninstaller --uninstall -s
                        Write-Output "Uninstall User teams from $Username"                               
                    }
                    $False {}
                }   
            }
            { [Version]$_ -ge [Version]$RepoAvailableVersion } {
                Write-Output "User Teams will be removed from $Username profile"
                $uninstallerPath = $TeamsUserPath -replace ('\\\w*current\\\w*Teams.exe', '')
                $uninstaller = "$uninstallerPath\Update.exe"
                Switch (Test-Path $uninstaller) {
                    $True {
                        & $uninstaller --uninstall -s
                        Write-Output "Uninstall User teams from $Username"                               
                    }
                    $False {}
                }
            } 
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
        $True { $LocalTeams = "$Path\Teams.exe" }
        $False {}
    }
}
#Local drive application version validation
Switch (Test-Path $LocalTeams) {
    $True {
        $LocalTeamsVersion = (Get-Item $LocalTeams).VersionInfo.ProductVersion
        $LocalResult = Get-TeamsObjects -Version $LocalTeamsVersion  -RepoAvailablePackage $RepoAvailablePackage -Usage 'App'
    }
    $False {}
}
#get user sessions
$RAWSessions = Get-Process -IncludeUserName | Select-Object Username -Unique  | Select-String -Pattern 'PPF.*\\.*'
$UserSessions = New-Object System.Collections.ArrayList
ForEach ($Object in $RAWSessions) {
    [Regex]$Regex = '(?<=\\)\w*'
    $UsernameOnSession = $Regex.Matches($Object).Value
    $UserSessions.add($UsernameOnSession) | Out-Null
}
#local disk users
$Users = Get-ChildItem "${env:SystemDrive}\users" -Exclude 'defaultuser0', 'public' | Select-Object FullName, Name
ForEach ($User in $Users) {
    $UserPath = $User.FullName
    $Username = $User.Name
    #path
    $TeamsUserPath = "$UserPath\AppData\Local\Microsoft\Teams\current\Teams.exe"
    #session checks
    If (($UserSessions | Select-String -Pattern $Username).count -gt 0) { Write-Output "$Username on Session, skip from update" }
    If (($UserSessions | Select-String -Pattern $Username).count -eq 0) {
        #Write-Output "$Username not in Session, passing for evaluations"
        #Evaluation
        Switch (Test-Path $TeamsUserPath) {
            $True {
                $LocalUserTeamsVersion = (Get-Item $TeamsUserPath).VersionInfo.ProductVersion
                $UserResult = Get-TeamsObjects -Version $LocalUserTeamsVersion  -RepoAvailablePackage $RepoAvailablePackage -Username $Username -TeamsUserPath $TeamsUserPath -Usage 'User'
            }
            $False {
                #check for dead path
                $TeamsDeadPath = $TeamsUserPath -replace ('\\\w*current\\\w*Teams.exe', '')
                If ((Test-path "$TeamsDeadPath\.dead") -eq $True) { 
                    Remove-Item $TeamsDeadPath -Force -Recurse -ErrorAction SilentlyContinue
                    Write-Output "Removing dead teams from $Username"
                }
                If ((Test-path $TeamsDeadPath) -eq $True -and (Test-path "$TeamsDeadPath\.dead") -eq $False -and (Test-path "$TeamsDeadPath\current") -eq $False) { 
                    Remove-Item $TeamsDeadPath -Force -Recurse -ErrorAction SilentlyContinue 
                    Write-Output "$Username dont have current teams folder nor dead file,removing left overs"
                }
            }
        }
    }
}
Write-Output $LocalResult
Write-Output $UserResult 
Exit $LASTEXITCODE
